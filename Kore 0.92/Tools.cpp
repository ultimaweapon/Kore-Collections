#include <windows.h>
#include <Tlhelp32.h>
#include <stdio.h>
#include <string.h>
#include <math.h>

#define SOLUTION_MAX 5000
#define FULL_LIST_MAX 480000
#define OPEN_LIST_MAX 160000
#define LOOKUPS_MAX 200000
#define SESSION_MAX 10

#define G_NORMAL 1

struct pos {
	unsigned short x;
	unsigned short y;
};

struct lookups {
	unsigned int x;
	float y;
};

struct pos_ai {
	pos p;
	float g;
	float f;
	int parent;
};

struct pos_list {
	unsigned int size;
	pos array[];
};

struct lookups_list {
	unsigned int size;
	lookups *array;
};

struct index_list {
	unsigned int size;
	int *array;
};

struct pos_ai_list {
	unsigned int size;
	pos_ai *array;
};

struct CalcPath_session {
	pos_list *solution;
	pos_ai_list fullList;
	index_list openList;
	lookups_list lookup;
	char* map;
	unsigned long width;
	unsigned long height;
	pos * start;
	pos * dest;
	DWORD time_max;
	BOOL active;
};

CalcPath_session g_sessions[SESSION_MAX];

int WINAPI InjectDLL(DWORD ProcID, LPCTSTR dll)
{
	HANDLE hProcessToAttach = OpenProcess(PROCESS_ALL_ACCESS, FALSE, ProcID);
	if (!hProcessToAttach)
		return 0;
	LPVOID pAttachProcessMemory = NULL;
	DWORD dwBytesWritten = 0;
	char * dllRemove;
	dllRemove = (char*)malloc(strlen(dll));
	memset((LPVOID)dllRemove, 0, strlen(dll));
	pAttachProcessMemory = VirtualAllocEx( 
		hProcessToAttach,      
		NULL, 
		strlen(dll), 
		MEM_COMMIT,   
		PAGE_EXECUTE_READWRITE );
	if (!pAttachProcessMemory)
		return 0;

	WriteProcessMemory( 
		hProcessToAttach, 
		pAttachProcessMemory, 
		(LPVOID)dll, strlen(dll), 
		&dwBytesWritten );

	if (!dwBytesWritten)
		return 0;

	HANDLE hThread = CreateRemoteThread( hProcessToAttach, NULL, 0, 
		(LPTHREAD_START_ROUTINE)LoadLibraryA, (LPVOID)pAttachProcessMemory, 0,   
		NULL);
	if (!hThread)
		return 0;
	
	WaitForSingleObject(hThread, INFINITE);
	
	WriteProcessMemory( 
		hProcessToAttach, 
		pAttachProcessMemory, 
		(LPVOID)dllRemove, strlen(dll), 
		&dwBytesWritten );

	if (!dwBytesWritten)
		return 0;
	VirtualFreeEx( 
		hProcessToAttach,      
		pAttachProcessMemory, 
		strlen(dll), 
		MEM_RELEASE);

	if(hThread) CloseHandle(hThread);
	return 1;
}


DWORD WINAPI GetProcByName (char * name) {
	HANDLE toolhelp;
	PROCESSENTRY32 pe;
	pe.dwSize = sizeof(PROCESSENTRY32);
	toolhelp = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
	if (Process32First(toolhelp,&pe)) {
		do {
			if (!stricmp(name, pe.szExeFile)) {
				CloseHandle(toolhelp);
				return pe.th32ProcessID;
			}
		} while (Process32Next(toolhelp,&pe));
	}
	CloseHandle(toolhelp);
	return 0;
}


inline char CalcPath_getMap(char *map, unsigned long width, unsigned long height, pos *p) {
	if (p->x >= width || p->y >= height) {
		return 1;
	} else {
		return map[(p->y*width)+p->x];
	}
}

DWORD WINAPI CalcPath_init (pos_list *solution, char* map, unsigned long width, unsigned long height, 
							pos * start, pos * dest, DWORD time_max) {
	DWORD i;
	int session = -1;
	int index;
	for (i=0;i<SESSION_MAX;i++) {
		if (!g_sessions[i].active) {
			session = i;
			break;
		}
	}
	if (session < 0) {
		return session;
	}
	g_sessions[session].active = 1;
	g_sessions[session].solution = solution;
	g_sessions[session].map = map;
	g_sessions[session].width = width;
	g_sessions[session].height = height;
	g_sessions[session].start = start;
	g_sessions[session].dest = dest;
	g_sessions[session].time_max = time_max;

	g_sessions[session].fullList.array = (pos_ai*)malloc(FULL_LIST_MAX*sizeof(pos_ai));
	g_sessions[session].openList.array = (int*)malloc(OPEN_LIST_MAX*sizeof(int));
	g_sessions[session].lookup.array = (lookups*)malloc(LOOKUPS_MAX*sizeof(lookups));
	
	pos_ai_list *fullList = &g_sessions[session].fullList;
	index_list *openList = &g_sessions[session].openList;
	lookups_list *lookup = &g_sessions[session].lookup;

	solution->size = 0;
	openList->size = 0;
	fullList->size = 0;
	fullList->array[0].p = *start;
	fullList->array[0].g = 0;
	fullList->array[0].f = abs(start->x - dest->x) + abs(start->y - dest->y);
	fullList->array[0].parent = -1;
	fullList->size++;
	openList->array[0] = 0;
	openList->size++;
	for (i = 0; i < width*height;i++) {
		lookup->array[i].x = 9999;
		lookup->array[i].y = 9999;
	}
	index = fullList->array[0].p.y*width + fullList->array[0].p.x;
	lookup->array[index].x = 0;
	lookup->array[index].y = fullList->array[0].g;
	lookup->size = width*height;
	return session;
}

DWORD WINAPI CalcPath_pathStep(DWORD session) {
	DWORD i, j;
	int cur;
	char type = 0;
	pos mappos;
	float newg;
	unsigned char successors_size;
	int smallestIndex, successors_start,suc, found, openFound,index;
	float smallestF;
	BOOL first;
	BOOL done = 1;
	DWORD timeout = GetTickCount();

	pos_list *solution = g_sessions[session].solution;
	pos_ai_list *fullList = &g_sessions[session].fullList;
	index_list *openList = &g_sessions[session].openList;
	lookups_list *lookup = &g_sessions[session].lookup;
	char* map = g_sessions[session].map;
	unsigned long width = g_sessions[session].width;
	unsigned long height = g_sessions[session].height;
	pos * start = g_sessions[session].start;
	pos * dest = g_sessions[session].dest;
	DWORD time_max = g_sessions[session].time_max;

	if (CalcPath_getMap(map, width, height, start) || CalcPath_getMap(map, width, height, dest)) {
		return 0;
	}
	while (1) {
		if (GetTickCount() - timeout > time_max) {
			break;
		}
		//get next from the list
		smallestIndex = -1;
		smallestF = -1;
		first = 1;
		for (i = 0; i < openList->size; i++) {
			if (openList->array[i] == -1)
				continue;
			if (first || fullList->array[openList->array[i]].f < smallestF) {
				if (first)
					first = 0;
				smallestF = fullList->array[openList->array[i]].f;
				smallestIndex = i;
			}
		}
		if (smallestIndex == -1) {
			//failed!
			done = 0;
			break;
		}
		cur = openList->array[smallestIndex];
		openList->array[smallestIndex] = -1;
		//check if finished
		if (dest->x == fullList->array[cur].p.x && dest->y == fullList->array[cur].p.y) {
			do {
				solution->array[solution->size] = fullList->array[cur].p;
				cur = fullList->array[cur].parent;
				solution->size++;
			} while (cur != -1);
			done = 0;
			break;
		}
	
		//Get successors
		successors_start = fullList->size;
		successors_size = 0;
		mappos.x = fullList->array[cur].p.x-1;
		mappos.y = fullList->array[cur].p.y;
		if (CalcPath_getMap(map, width, height, &mappos) == type
			&& !(fullList->array[cur].parent >= 0 && fullList->array[fullList->array[cur].parent].p.x == mappos.x 
			&& fullList->array[fullList->array[cur].parent].p.y == mappos.y)) {
			fullList->array[fullList->size].p = mappos;
			fullList->size++;
			successors_size++;
		}

		mappos.x = fullList->array[cur].p.x;
		mappos.y = fullList->array[cur].p.y-1;
		if (CalcPath_getMap(map, width, height, &mappos) == type
			&& !(fullList->array[cur].parent >= 0 && fullList->array[fullList->array[cur].parent].p.x == mappos.x 
			&& fullList->array[fullList->array[cur].parent].p.y == mappos.y)) {
			fullList->array[fullList->size].p = mappos;
			fullList->size++;
			successors_size++;
		}	

		mappos.x = fullList->array[cur].p.x+1;
		mappos.y = fullList->array[cur].p.y;
		if (CalcPath_getMap(map, width, height, &mappos) == type
			&& !(fullList->array[cur].parent >= 0 && fullList->array[fullList->array[cur].parent].p.x == mappos.x 
			&& fullList->array[fullList->array[cur].parent].p.y == mappos.y)) {
			fullList->array[fullList->size].p = mappos;
			fullList->size++;
			successors_size++;
		}
		
		mappos.x = fullList->array[cur].p.x;
		mappos.y = fullList->array[cur].p.y+1;
		if (CalcPath_getMap(map, width, height, &mappos) == type
			&& !(fullList->array[cur].parent >= 0 && fullList->array[fullList->array[cur].parent].p.x == mappos.x 
			&& fullList->array[fullList->array[cur].parent].p.y == mappos.y)) {
			fullList->array[fullList->size].p = mappos;
			fullList->size++;
			successors_size++;
		}

		//do the step
		newg = fullList->array[cur].g + G_NORMAL;
		for (j=0;j < successors_size;j++) {
			suc = successors_start+j;
			found = 0;
			openFound = 0;
			index = fullList->array[suc].p.y*width + fullList->array[suc].p.x;
			if (lookup->array[index].y != 9999) {
				if (newg >= lookup->array[index].y) {
					found = 1;
				} else {
					openFound = 1;
				}
			}
			if (found)
				continue;

			fullList->array[suc].g = newg;
			fullList->array[suc].f = newg + abs(fullList->array[suc].p.x - dest->x) + abs(fullList->array[suc].p.y - dest->y);
			fullList->array[suc].parent = cur;

			if (openFound) {
				lookup->array[index].y = fullList->array[suc].g;
				openList->array[lookup->array[index].x] = suc;
			} else {
				lookup->array[index].x = openList->size;
				lookup->array[index].y = fullList->array[suc].g;
				openList->array[openList->size] = suc;
				openList->size++;
			}
		}
	}
	return (DWORD)done;
}

void WINAPI CalcPath_destroy(DWORD session) {
	g_sessions[session].active = 0;
	free(g_sessions[session].fullList.array);
	free(g_sessions[session].openList.array);
	free(g_sessions[session].lookup.array);
}

BOOL WINAPI DllMain(HINSTANCE hInstance, DWORD dwReason, LPVOID _Reserved)
{
	switch(dwReason)
	{
	case DLL_PROCESS_ATTACH:
		int i;
		for (i=0;i<SESSION_MAX;i++) {
			g_sessions[i].active = 0;
		}
		break;

	case DLL_THREAD_ATTACH:
		break;

	case DLL_THREAD_DETACH:
		break;

	case DLL_PROCESS_DETACH:
		break;
	}
	return true;
}
