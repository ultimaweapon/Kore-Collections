======================================================================
                   Ragnarok Online Client Emulator
======================================================================
【作業系統】Windows 98/SE/ME/XP/2000
【免責事項】本程式為免費軟體，程式衍生的任何問題由各位自行承擔
【轉載條件】必須保持本壓縮檔之完整性，並放置在自行準備之空間
【技術支援】modKore & Clio by Karasu & Tiffany by AyonPan
【安裝說明】須加入Kore系列地圖檔案
【移除說明】不對系統機碼等做任何寫入動作，刪除時直接對資料夾做刪除即可
======================================================================

mKore參數
--help          顯示輔助訊息.
--control=path  指定control目錄.
--fields=path   指定fields目錄.
--logs=path     指定logs目錄.
--plugins=path  指定plugins目錄.
--tables=path   指定tables目錄.

┌──mKore v2.06.02──────────────────────────────────┐
│MD5 Checksum:	e3e40dc12a136fa203727fb3be64b96b  mKore.exe				│
│		5aaae72cecf298c6c938ab79d1023610  mapview.exe				│
│程式:											│
│  ☆＋ 修改組隊均分方式								│
│  ☆＋ 新增新封包部分解釋(未完整)							│
│											│
├──mKore v2.06.01──────────────────────────────────┤
│MD5 Checksum: 28e4a551c0229c4c5714eddb47763402 mKore.exe				│
│		5aaae72cecf298c6c938ab79d1023610 mapview.exe				│
│		54d0074ce0faee2f0e5b14a310e330de decode.exe(獨立發放)			│
│程式:											│
│    － 帳號密碼錯誤時取消重新詢問							│
│    ＊ 修正自動回應無法正確讀取變數設定						│
│    ＊ 修正路徑瞬移無法切換裝備							│
│    ＊ 修正s指令狀態C顯示								│
│    ＋ 定時送出組隊均分要求								│
│    ＊ 修改戰績經驗紀錄流程								│
│    ＋ 試驗性新增鐵匠系自動鍛造強悍屬性武器						│
│    ＊ 修正技能屬性顯示錯誤0147							│
│    ＊ 修正物品檢查錯誤造成程式關閉							│
│    ＊ BASE經驗值滿時無法顯示EXP的BUG							│
│    ＋ 新增音效套件									│
│											│
├───────────────────────────────────────────┤
│											│
│檔案:											│
│											│
│control/config.txt									│
│    ＋ hideMsg_make			- 隱藏鍛造製藥訊息				│
│    ＋ makeAuto_stone			- 鍛造武器所需屬性原石設定			│
│    ＋ makeAuto_stars			- 鍛造武器所需星星之角設定			│
│    ＋ recordExp			- 紀錄戰績統計資料				│
│    ＋ modifiedRoute_changeMap	- 移動到不同地圖的加重格數			│
│											│
│control/timeouts.txt									│
│    ＊ ai_skill_use_giveup 		- 預設值改為 0.7				│
│    ＋ ai_partyAutoShare		- 隊伍均分間隔週期				│
│    ＋ recordExp			- 戰績經驗紀錄間隔週期				│
│											│
│tables/*.txt										│
│    ＋ 新增修改部分檔案對應EP10.1							│
│											│
├──mKore v2.06.00 fix────────────────────────────────┤
│MD5 Checksum: 93224bf4e96b01d9ae3d0ceb93e7d5bc mKore.exe 				│
│程式:											│
│    ＊ 修正調整登入及倉庫密碼流程							│
│    ＊ 修正 X-Mode 顯示密鑰流程							│
│  ☆＋ 新增 X-Mode 密鑰直接寫入config.txt設定						│
│											│
├──mKore v2.06.00──────────────────────────────────┤
│MD5 Checksum:	7521b3ab585800a1a745b95bbe73d780   mKore.exe				│
│		5aaae72cecf298c6c938ab79d1023610  mapview.exe				│
│程式:											│
│  ☆＋ 新增登入密鑰設定								│
│  ☆＋ 新增開倉密鑰設定, X-Mode新增密鑰顯示						│
│  ☆＋ 減小與NPC對話時不必要的等待時間						│
│    ＊ 修正設定隊伍技能持續狀態的持續時間時, 無法有效偵測及重新施放			│
│    ＊ 修正對應艾斯恩魔女魔物蛋和愛麗絲女僕魔物蛋					│
│    ＊ 修正自動製藥及蓄氣的氣球偵測對應被領養的小孩					│
│    ＊ 修正特定時間會發生伺服器同步化失敗的問題					│
│    ＊ 修正連續撿物時順序處理錯誤							│
│    ＊ 調整自動鍛造(製藥)處理流程及指令, 加入製藥/製毒材料的判斷			│
│    ＊ 修正自動鍛造(製藥)中無法順利存取手推車						│
│    ＊ 修正交易時可以放置超過10樣物品造成物品消失的問題				│
│    ＊ 露天物品單價上限提高到9999萬							│
│    ＊ 修正walk.dat遺漏輸出人物素質至地圖檢測器					│
│    ＊ 取消帳號被凍結及點數到期自動關閉						│
│    ＋ 預計升級時間計算(exp)								│
│    ＋ 鍊金術師/神工匠排名要求							│
│    ＊ 修改製作箭矢支援使用箭矢筒							│
│											│
│指令:											│
│    ＊ 指令 automake			- 可直接指定要製作的物品名稱			│
│    ＋ 指令 BS|blacksmith		- 送出鐵匠排名要求				│
│    ＋ 指令 AM|alchemist		- 送出鍊金術師排名要求				│
│											│
├───────────────────────────────────────────┤
│											│
│檔案:											│
│    ＋ tables\material.txt								│
│											│
│control/config.txt									│
│    ＋ modifiedTalk									│
│    ＋ makeAuto_retry									│
│    ＋ storage_password								│
│    ＋ login_password									│
│    ＊ makeArrowAuto									│
│											│
│control/timeouts.txt									│
│    ＊ ai_makeAuto			- 預設值改為 1					│
│    ＊ ai_item_use_auto		- 最低值改為 0.3				│
│    ＋ ai_modifiedTalk_giveup								│
│											│
│tables/*.txt										│
│    ＋ 新增修改部分檔案對應EP10.1							│
│											│
│tables/language.txt									│
│    ＋ input_automake_retry								│
│    ＋ list_blacksmith_head								│
│    ＋ list_blacksmith								│
│    ＋ list_blacksmith_end								│
│    ＋ list_archer_head								│
│    ＋ list_archer									│
│    ＋ list_archer_end								│
│    ＋ passwordStatus_0								│
│    ＋ passwordStatus_1								│
│    ＋ passwordStatus_other								│
│    ＋ passwordResult_4								│
│    ＋ passwordResult_5								│
│    ＋ passwordResult_6								│
│    ＋ passwordResult_7								│
│    ＋ passwordResult_8								│
│    ＋ passwordResult_other								│
│    ＋ point_blacksmith								│
│    ＋ point_archer									│
│    ＋ useArrowAuto									│
│											│
├──mKore v2.05.04──────────────────────────────────┤
│MD5 Checksum:	0b2dcb4c041592361f3434c1eb6b9521  mKore.exe				│
│		5aaae72cecf298c6c938ab79d1023610  mapview.exe				│
│程式:											│
│    ＋ language 支援自訂記錄及自訂音效						│
│    ＊ 調整登入失敗時之處理, 並限制reconnect至少為1, 預設值為10			│
│    ＊ 對應相同地圖檔但不同地圖名稱的狀況						│
│    ＊ 部份設定支援負號型式								│
│    ＊ 修正觸發自動談話時不會觸發自動坐下						│
│    ＊ 調整部份隱藏訊息設定方式							│
│    ＊ 修正buyAuto_0_minAmount和buyAuto_0_maxAmount都空白的問題			│
│    ＊ 修正已裝備物品及已孵化寵物無法以指令放入倉庫,放入手推車			│
│    ＊ 修正自動存倉與自動賣物不會處理已孵化寵物					│
│    ＊ 修正已孵化寵物與裝備損壞偵測衝突,及裝備損壞會重複觸發自動談話			│
│    ＊ 修正經驗值統計可能會使程式關閉的問題						│
│    ＊ 修正死亡後被復活時的處理錯誤							│
│    ＊ 減小因為誤判而鎖定攻擊自己的寵物狀況						│
│											│
│指令:											│
│    ＊ 指令 set			- 修正設定與原本目錄相同時不會處理的問題	│
│    ＊ 指令 sell			- 顯示賣物列表					│
│    ＊ 指令 talk resp			- 修正顯示回應列表時無法正確顯示NPC資料		│
│    － 指令 store			- 併入指令 buy中				│
│											│
├───────────────────────────────────────────┤
│											│
│檔案:											│
│    ＋ tables\mapalias.txt								│
│											│
│control/config.txt									│
│    ＊ attackSkillSlot_0_monsters	- 支援負號型式					│
│    ＊ equipAuto_0_monsters		- 支援負號型式					│
│    ＊ hideMsg_groundEffect		- 支援負號型式					│
│    ＊ hideMsg_emotions		- 改變設定方法					│
│    ＊ sysLog_emo			- 改名為sysLog_emotions, 並改變設定方法		│
│    － alertSound_onDanger								│
│    － alertSound_onGMnotice								│
│    － alertSound_onItem								│
│    － alertSound_onPM								│
│    － alertSound_onShop								│
│    － hideMsg_charStatus								│
│    － hideMsg_partyStatus								│
│    － hideMsg_monsterStatus								│
│    － hideMsg_otherStatus								│
│    － hideMsg_charParam1								│
│    － hideMsg_charParam2								│
│    － hideMsg_charParam3								│
│    － hideMsg_partyParam1								│
│    － hideMsg_partyParam2								│
│    － hideMsg_partyParam3								│
│    － hideMsg_monsterParam1								│
│    － hideMsg_monsterParam2								│
│    － hideMsg_monsterParam3								│
│    － hideMsg_otherParam1								│
│    － hideMsg_otherParam2								│
│    － hideMsg_otherParam3								│
│    － hideMsg_otherUseSkill								│
│    ＋ hideMsg_param1_0								│
│    ＋ hideMsg_param1_0_source							│
│    ＋ hideMsg_param2_0								│
│    ＋ hideMsg_param2_0_source							│
│    ＋ hideMsg_param3_0								│
│    ＋ hideMsg_param3_0_source							│
│    ＋ hideMsg_status_0								│
│    ＋ hideMsg_status_0_source							│
│    ＋ hideMsg_attack_0_source							│
│    ＋ hideMsg_attack_0_target							│
│    ＋ hideMsg_skill_0								│
│    ＋ hideMsg_skill_0_source								│
│    ＋ hideMsg_skill_0_target								│
│											│
│control/timeouts.txt									│
│    ＋ ai_smartEquip_waitAfterChange							│
│											│
│tables/language.txt									│
│    ＊ 加入自訂記錄及自訂音效的設定							│
│    ＊ npcBuySellSelect		- 修改內容					│
│    ＊ npcBuySelect			- 修改內容					│
│    ＊ input_log			- 改名為 input_log_result			│
│    － input_store_head								│
│    － input_store									│
│    － input_store_end								│
│    ＋ list_buy_head									│
│    ＋ list_buy									│
│    ＋ list_buy_end									│
│    ＋ list_sell_head									│
│    ＋ list_sell									│
│    ＋ list_sell_end									│
│    ＋ input_buy_error_2								│
│    ＋ input_sell_error_2								│
│    ＋ sellFail_1									│
│    ＋ sysLog_items									│
│    ＋ sysLog_message									│
│    ＋ input_storageAdd_error2							│
│    ＋ input_storageAdd_error3							│
│    ＋ input_cartAdd_error2								│
│    ＋ input_cartAdd_error3								│
│											│
├──mKore v2.05.03──────────────────────────────────┤
│MD5 Checksum:	6996d47949184de0e08a6e6d4db1bb7d  mKore.exe				│
│		5aaae72cecf298c6c938ab79d1023610  mapview.exe				│
│程式:											│
│    ＊ 修正buyAuto無法正確處理auto編號						│
│    ＊ 特殊狀態及禁言狀態而瞬移失敗時記錄到Alert.txt					│
│    ＊ 補新增自動每小時經驗統計紀錄							│
│    ＋ 新增瞬移前裝配裝備								│
│    											│
├───────────────────────────────────────────┤
│檔案:											│
│											│
│control/config.txt									│
│    ＋ equipAuto_teleport								│
│											│
├──mKore v2.05.02──────────────────────────────────┤
│MD5 Checksum:	79bd0d1115fa3dbe0103c35711679567  mKore.exe				│
│程式:											│
│  ☆＊ 改善武僧連技系統								│
│  ☆＊ 縮小portalsLos.txt								│
│  ☆＊ 以NPC位置當作NPC編號的設定方式							│
│    ＊ 自動購物支援對話型購物方式							│
│    ＊ 可設定撿取重要物品後才會攻擊, 以及重要物品偵測距離				│
│    ＊ 可設定自動補給時才觸發自動對話							│
│    ＊ 微調使用autoGetSpeed時,行走的流暢度						│
│    ＊ 調整連續撿取時先後順序								│
│    ＊ 調整撿取無主物品時撿取優先順序, 並修改為攻擊怪物或撿取物品時不啟動		│
│    ＊ 瞬移路徑改以移動路徑距離做距離判斷,並修正部份地圖使用時的不正常情形		│
│　　＊ 修正指令 eq 及 露天商店 未顯示製作者名稱					│
│    ＊ 修正指令 i, cart, storage 及記錄倉庫物品功能 非裝備類未顯示製作者名稱		│
│    ＊ 修正指令 timeout 未將設定值寫入檔案						│
│    ＊ 修正好友上下線顯示								│
│    ＊ 修正指令 friend pm 錯誤							│
│    ＊ 修正更新NPC時未更新talkAuto的NPC編號						│
│    ＊ 修正人型傳點編號設為auto時, 角色未正確朝向NPC					│
│    ＊ 修正 HP,SP,負重為0時, 無法顯示正確數值及百分比					│
│    ＊ 修正物理攻擊和技能攻擊交替使用時, 無法立刻轉換的問題				│
│    ＊ 修正技能,物品的狀態判斷在部份情況下會誤判					│
│    ＊ 修正坐下時無法使用輔助技能							│
│    ＊ 修正攻擊目標死亡判定異常							│
│    ＊ 修正未知怪物無法自動取得名稱							│
│    ＊ 修正xmode下, kore與實際怪物名稱不相同時, 可能造成部份功能異常			│
│    ＊ 修正自動更換裝備設定使用預設裝備的條件						│
│    ＊ 修正經過主動說話NPC時可能造成補給及與人型傳點對話失敗				│
│    ＊ 修正使用modifiedRoute時,路徑選擇異常						│
│    ＊ 修正errors.txt儲存內容								│
│    ＊ 修正撿物及補給時不觸發瞬移搜尋							│
│    ＊ 修正撿取非重要物品時, 在部份狀況下瞬移開關2,瞬移開關3失效			│
│    ＊ 修正計算部份地圖在計算路徑時, 程式會當掉的錯誤					│
│  ☆＋ laguage.txt 支援自訂顏色標籤							│
│    ＋ 由clientinfo.xml直接讀取伺服器設定						│
│    ＋ 自訂隱藏特殊狀態								│
│  ☆＋ 角色陷入特殊狀態Ａ(石化、冰凍、昏迷、睡眠)時允許瞬移開關			│
│											│
│指令:											│
│											│
├───────────────────────────────────────────┤
│											│
│檔案:											│
│											│
│control/config.txt									│
│    ＊ talkAuto_0_npc_distance	- 修正為 talkAuto_0_distance			│
│    ＋ attackSkillSlot_0_delayTime							│
│    ＋ attackSkillSlot_0_prevSkill							│
│    ＋ modifiedRoute_NPC								│
│    ＋ modifiedRoute_diffPortal							│
│    ＋ modifiedRoute_samePortal							│
│    ＋ modifiedRoute_undef								│
│    ＋ importantItemDistance								│
│    ＋ importantItemFirst								│
│    ＋ importantItemSequence								│
│    ＋ useSelf_skill_0_waitAfterKill							│
│    ＋ itemsGatherDistance								│
│    ＋ itemsGatherCheckWall								│
│    ＋ itemsGatherInLockOnly								│
│    ＋ talkAuto_0_supplyOnly								│
│    ＋ buyAuto_0_talkMode								│
│    ＋ buyAuto_0_npc_steps								│
│    ＋ searchNPC_distance								│
│    ＋ searchNPC_useSamePosWhenFail							│
│    ＋ takeMaxRouteDistance								│
│    ＋ takeMaxRouteTime								│
│    ＋ modifiedSearch									│
│    ＋ hideMsg_charParam1								│
│    ＋ hideMsg_charParam2								│
│    ＋ hideMsg_charParam3								│
│    ＋ hideMsg_partyParam1								│
│    ＋ hideMsg_partyParam2								│
│    ＋ hideMsg_partyParam3								│
│    ＋ hideMsg_monsterParam1								│
│    ＋ hideMsg_monsterParam2								│
│    ＋ hideMsg_monsterParam3								│
│    ＋ hideMsg_otherParam1								│
│    ＋ hideMsg_otherParam2								│
│    ＋ hideMsg_otherParam3								│
│    ＋ teleportAuto_param1								│
│											│
│control/option.txt									│
│    ＋ use_clientInfo									│
│											│
│control/timeouts.txt									│
│    ＋ ai_skill_use_waitAfterKill							│
│    ＋ ai_talkAuto									│
│    ＋ ai_talkAuto_wait								│
│    ＋ ai_sitAuto_wait								│
│											│
│tables/colors_console.txt								│
│    ＊ skillAttack			- 改名為 skillRestore				│
│    － skillHeal									│
│											│
│tables/colors_Vx.txt									│
│    ＊ skillAttack			- 改名為 skillRestore				│
│    － skillHeal									│
│											│
│tables/language.txt									│
│    ＊ referRoute_error		- 修正為 preferRoute_error			│
│    ＊ vender, venderYou		- 修改參數					│
│    ＊ shopParam			- 修改文字內容					│
│    ＋ 顯示文字顏色設定								│
│    ＋ friendOffline									│
│    ＋ input_cri_error								│
│    ＋ input_moveStop									│
│    ＋ input_move_1									│
│    ＋ input_move_2									│
│    ＋ youAttackMonMiss								│
│    ＋ monAttackYouMiss								│
│    ＋ skillAttack									│
│    ＋ skillAttackMiss								│
│    ＋ teleport_search								│
│    ＋ teleport_idle									│
│    ＋ teleport_portal								│
│    ＋ teleRoute_0									│
│    ＋ itemGather_fail								│
│    ＋ take_fail									│
│    ＋ input_pet_error								│
│    ＋ param1_1									│
│    ＋ param1_2									│
│    ＋ param2_1									│
│    ＋ param2_2									│
│    ＋ param3_1									│
│    ＋ param3_2									│
│    ＋ status_1									│
│    ＋ status_2									│
│    － param1										│
│    － param2										│
│    － param3										│
│    － status										│
│    － paramFormat_1									│
│    － paramFormat_2									│
│    ＋ teleport_error_4								│
│											│
│tables/recvpackets.txt								│
│    ＋ 0144										│
│											│
├──mKore v2.05.01──────────────────────────────────┤
│MD5 Checksum:	9d42c96b585517b8be1a3d44b5925f8a  mKore.exe				│
│程式:											│
│  ＋ 顯示並記錄NPC廣播內容								│
│  ＊ 修正指令 talk answer及friend request 輸入文字時資料錯誤				│
│  ＊ 自動鍛造/製藥支援十字刺客自動製作毒藥						│
│  ＊ GM AID改成由clientinfo.xml取得							│
│											│
│檔案:											│
│  ＋ tables/clientinfo.xml								│
│  － tables/aids.txt									│
│											│
│tables/colors_console.txt								│
│  ＋ npc										│
│											│
│tables/colors_Vx.txt									│
│  ＋ npc										│
│											│
│tables/language.txt									│
│  ＋ message_npc									│
│											│
│tables/recvpackets.txt								│
│  ＋ 01C3										│				
│											│
├──mKore v2.05.00──────────────────────────────────┤
│MD5 Checksum:	3968f72d32a63ef18f16787c18d6cee1  mKore.exe				│
│程式:											│
│    ＊ 修正道具製作者顯示(藥品戒指等等)						│
│    ＊ 修改Tables支援EP8.5								│
│    ＊ 修正路徑計算									│
│    ＊ 修正自動傳陣錯誤								│
│檔案:											│
│tables/language.txt									│
│    ＋ pet_named									│
│    ＋ itemFix_pet									│
│    ＋ itemFix_identified								│
│    ＋ itemFix_named									│
│    ＋ itemFix_broken									│
│    ＋ itemFix_maker									│
│    ＋ itemFix_makerNone								│
│    ＋ sysLog_undef									│
│											│
├──mKore v2.04.02──────────────────────────────────┤
│MD5 Checksum:	22475db99dff708987aeb2eaf864874e  mKore.exe				│
│程式:											│
│    ＊ talkAuto修改成多組設定方式							│
│    ＊ 修正對裝備類物品在存領倉,買賣物,手推車取存的問題				│
│    ＊ 修正隊伍技能對多目標施放只對第一個有作用					│
│    ＊ 修正物品撿取開關設為-1時無法發揮作用						│
│    ＊ 修正攻擊撿取重要物品的怪物無法發揮作用						│
│    ＊ 修正轉移攻擊目標時無法顯示原本攻擊目標						│
│    ＊ 修正新增傳點功能記錄錯誤							│
│    ＊ shop.txt中價格的設定自動去掉逗號						│
│											│
│    											│
│檔案:											│
│control/config.txt									│
│    ＊ talkAuto_npc			- 改為 talkAuto_0_npc				│
│    ＊ talkAuto_npc_distance		- 改為 talkAuto_0_npc_distance			│
│    ＊ talkAuto_npc_steps		- 改為 talkAuto_0_npc_steps			│
│    ＊ talkAuto_hp			- 改為 talkAuto_0_hp				│
│    ＊ talkAuto_sp			- 改為 talkAuto_0_sp				│
│    ＊ talkAuto_brokenOnly		- 改為 talkAuto_0_brokenOnly			│
│    ＊ 更新tables\aids.txt中GM編號 2005-01-28gdata_tc.gpf by TalentKid		│
│											│
├──mKore v2.04.01──────────────────────────────────┤
│MD5 Checksum:69f723f1cda1f620d6c24b17ff3477d0  mKore.exe				│
│程式:											│
│  ☆＊ 重要物品改由pickupitems.txt統一設定						│
│    ＊ 修正重要物品功能在pickitems.txt裡設成2時顯示及記錄內容錯誤			│
│    ＊ 修正自動鍛造/製藥出現錯誤訊息時會讓程式關閉					│
│    ＊ 修正隱藏表情開關								│
│    ＊ 修正露天商品最大數量計算錯誤							│
│    ＊ 修正左右手裝備武器時的自動更換裝備的錯誤					│
│    ＊ 修正以指令relog重新登入後, 可能造成無法攻擊					│
│    ＋ 可設定撿取最大數量(重要物品不受此限制)						│
│    ＋ 經過沒有資料的傳點時自動加入portals.txt(原有功能)				│
│    ＋ 傳陣前往鎖定地圖								│
│    ＊ 指令開啟傳陣(warp)								│
│    ＋ 搶攻撿取重要物品怪物								│
│指令:											│
│											│
├───────────────────────────────────────────┤
│											│
│檔案:											│
│    － control/importantitems.txt	- 改由pickupitems.txt設定重要物品		│
│											│
│control/config.txt									│
│    ＋ lockMap_0_warpTo								│
│    ＋ partyAutoResurrect								│
│    ＋ partyAutoResurrectTime								│
│    ＋ partySkill_smartHeal								│
│    ＋ partySkill_0_statusTimeout							│
│    ＋ lockMap_warpTo									│
│    ＋ attackPickupMonsters								│
│control/pickupitems.txt								│
│    ＊ 格式改變, 增設重要物品及撿取最大數量設定					│
│											│
│control/timeout.txt									│
│    ＋ ai_resurrect									│
│    ＋ ai_skill_party									│
│    ＋ ai_attack_skillCancel 								│
│											│
│tables/language.txt									│
│    ＊ venderLog_shop	參數修正							│
│    ＋ importantItemsGet								│
│    ＋ importantItemsPlayer								│
│    ＋ list_warp_head									│
│    ＋ list_warp									│
│    ＋ list_warp_end									│
│    ＋ warp_random									│
│    ＋ warp_cancel									│
│    ＋ portalTrace									│
│    ＋ unknown_map									│
│    ＋ unknown_itemTypes								│
│    ＋ unknown_equipTypes								│
│    ＋ unknown_sex									│
│    ＋ input_warp_error_2								│
│    ＋ input_warp_error_3								│
│    ＋ input_warp_cancel								│
│    ＋ attackStop_1									│
│    ＋ attackPickupMonster								│
├──mKore v2.04.00──────────────────────────────────┤
│MD5 Checksum:	6ab379e795ea5818733d73f0ee2181e0  mKore.exe				│
│程式:											│
│  ☆＊ 改善地圖間路徑的計算速度及路徑選擇方式						│
│  ☆＊ 強化瞬移路徑									│
│  ☆＊ 自動鍛造/製藥改成以指令啟動後, 沒有AI任務時才會觸發, 並加入停止指令		│
│  ☆＊ 修正item_control.txt和cart_control.txt裡裝備類物品設定數量時並不具效果		│
│    ＊ 修正脫離指定地圖時，沒有使用技能或物品回儲存點					│
│    ＊ 修正部份座標無法計算路徑, 造成預先計算路徑及計算地圖路徑出現錯誤		│
│    ＊ 修正無法自動裝備箭矢及存領倉和自動賣物時裝備箭矢的動作				│
│    ＊ 修正暫時登出時在某些情況下造成程式沒有反應					│
│    ＊ 修正在Xmode下交易時, 以client輸入金錢, 在mkore裡無法正確顯示金額		│
│    ＊ 自動撿取設成1以下時不啟動重要物品功能, 自動丟棄必須設定全名才會有作用		│
│    ＊ 微調選擇攻擊怪物的方式								│
│    ＊ 自動買物修改成對相同NPC要購買的物品一次買齊					│
│    ＊ 修正更新NPC時,可能更新到錯誤的NPC編號						│
│    ＊ 除了以指令啟動補給任務外, 補給順序都為talkAuto->storageAuto->sellAuto->buyAuto	│
│    ＊ 自動重登秒數及閃躲GM暫時登出秒數可使用基本秒數+隨機秒數			│
│    ＊ 撿取物品時以距離最近的優先撿取							│
│    ＊ 攻擊時可設定不觸發自動領取及自動買物功能					│
│    ＊ 存倉任務時先處理手推車內物品放入倉庫						│
│    ＊ 改善人型傳點的編號設成auto時,容易抓錯NPC編號					│
│    ＊ 修正露天商品最大數量及裝備類商品設定數量不具效果的問題				│
│  ☆＋ 自動偵測移動速度								│
│  ☆＋ 自訂顯示文字及視窗題列	(\tables\language.txt)					│
│  ☆＋ talkAuto 獨立循環模式(自動換神鋁)						│
│    ＋ 多重傳點(同一人型傳點NPC到多個位置)						│
│    ＋ 手推車置物時, 自動偵測手推車最大負重量						│
│    ＋ 切換設定目錄指令								│
│    ＋ 閃躲GM暫時離線後或定時自動重登時自動切換設定目錄				│
│    ＋ 使用技能時可針對角色未有的技能進行更換裝備					│
│    ＋ 顯示對地持續技能及閃躲技能攻擊							│
│    ＋ 使用物品前如果到達補給下限則啟動補給流程					│
│    ＋ 載入tables\npcs.txt遇到NPC編號重覆時顯示訊息					│
│    ＋ 每小時經驗統計紀錄								│
│    ＊ 調整自動紀錄目前位置紀錄格式(walk.dat)						│
│    											│
│指令:											│
│    ＊ relog [<秒數>]			- 可指定秒數後自動重新連線(最小為5秒)		│
│    ＊ sl				- 改名為 sg					│
│    ＊ automake [<on | off >]		- 啟動/停止 自動鍛造/製藥			│
│    ＋ set <control | table> <目錄名稱>						│
│					- 切換設定目錄					│
│    ＋ sl				- 對地持續技能列表				│
│											│
├───────────────────────────────────────────┤
│											│
│檔案:											│
│    ＊ control/colors_console.txt	- 移到 tables/colors_console.txt		│
│    ＊ control/colors_Vx.txt		- 移到 tables/colors_Vx.txt			│
│    ＋ control/teleRoute_control.txt							│
│    ＋ tables/language.txt								│
│    ＋ mapview.exe fb97c57e5ae7f6a01f61f0522a63bcf1					│
│control/config.txt:									│
│    ＊ autoRestart			- 格式修改					│
│    ＊ avoid_reConnect		- 格式修改					│
│    ＋ autoGetSpeed									│
│    ＋ avoid_setDirectory								│
│    ＋ autoRestart_setDirectory							│
│    ＋ setDirectory_control								│
│    ＋ setDirectory_table								│
│    ＋ cartSmartWeight								│
│    ＋ teleportAuto_minAgNotorious							│
│    ＋ talkAuto_single								│
│    ＋ attackSkillSlot_0_smartEquip							│
│    ＋ useSelf_skill_0_smartEquip							│
│    ＋ partySkill_0_smartEquip							│
│    ＋ teleportAuto_skill_0 								│
│    ＋ teleportAuto_skill_0_castBy							│
│    ＋ teleportAuto_skill_0_castOn							│
│    ＋ teleportAuto_skill_0_dist							│
│    ＋ teleportAuto_skill_0_inCity							│
│    ＋ teleportAuto_skill_0_randomWalk						│
│    ＋ teleportAuto_spell_0								│
│    ＋ teleportAuto_spell_0_castBy							│
│    ＋ teleportAuto_spell_0_dist							│
│    ＋ teleportAuto_spell_0_inCity							│
│    ＋ teleportAuto_spell_0_randomWalk						│
│    ＋ useSelf_item_0_checkSupplyFirst						│
│    ＋ getAuto_peace									│
│    ＋ buyAuto_peace									│
│    ＋ hideMsg_groundEffect								│
│    ＋ hideMsg_groundEffect_timeout							│
│    ＋ modifiedRoute									│
│    ＋ equipAuto_0_useWeapon								│
│    ＋ equipAuto_0_attackDistance							│
│    ＋ attackSkillSlot_0_timeout							│
│    ＋ NotAttackNearSpell								│
│											│
│control\timeouts.txt									│
│    ＋ ai_teleport_spell								│
│    ＋ ai_makeAuto_giveup								│
│    ＋ ai_smart_follow								│
│											│
│tables/sendpackets.txt:								│
│    ＋ 01D5										│
│											│
│tables/skillssp.txt:									│
│    ＊ 加入二連矢,製作箭,衝鋒箭消耗SP資料						│
│											│
│tables/portals.txt:									│
│    ＊ 所有傳點NPC編號都改為auto							│
│											│
├──mKore v2.03.02──────────────────────────────────┤
│MD5 Checksum: 92f837cfc5d228675b91bd9da2e954e8  mKore.exe				│
│程式:											│
│  ☆＊ 改善怪物被搶先攻擊時的放棄動作及接近怪物的移動動作				│
│  ☆＊ 加強偵測GM功能									│
│    ＊ 禁言狀態及沒有物品可賣時, 只把關閉自動開店功能, 不去修改shop.txt內的開關	│
│    ＊ 自動調查露天價格BUG修正及調整成手動進露天時也有記錄				│
│    ＊ 修正無法因技能更換裝備	(目前只對自身擁有的技能)				│
│    ＊ 自動賣物修改成一次賣掉所有要賣的物品						│
│    ＊ 修正部份地圖計算路徑會當掉的問題 (大概吧)					│
│    ＊ 自動鍛造(製藥)可接上補給任務							│
│    ＊ 自動撿取之物品設成-1以下才會使用自動丟棄功能					│
│  ☆＋ 導入新型路徑計算功能								│
│  ☆＋ 不攻擊被障礙物阻擋的怪物							│
│    ＋ 自動存倉可將手堆車內物品放入倉庫						│
│    ＋ 自動使用物品可設定連續使用物品							│
│    ＋ 露天商店單項物品賣完時可設定自動關閉露天商店					│
│    － 取消對支援linux的部份 (反正也不能在linux上使用)				│
│											│
│指令:											│
│											│
├───────────────────────────────────────────┤
│											│
│檔案:											│
│    ＋ Tools-new.dll									│
│											│
│control/config.txt:									│
│    ＋ useSelf_item_0_repeat								│
│    ＋ NotAttackAfterWall								│
│    ＋ avoidGM_paranoia								│
│    ＋ modifiedAttack									│
│											│
│control/items_control.txt:								│
│    ＋ 加入第四個設定值								│
│											│
│control/pickupitems.txt:								│
│    ＊ 設成-1以下的物品使用自動丟棄功能						│
│											│
│control/option.txt:									│
│    ＋ use_newPathDLL									│
│											│
│control/shop.txt:									│
│    ＋ shop_close_sold_out								│
│											│
│tables/recvPackets.txt:								│
│    ＋ 006D										│
│											│
│tables/sendPackets.txt:								│
│    ＋ 018E										│
│											│
├──mKore v2.03.01──────────────────────────────────┤
│MD5 Checksum: 828d29fd48503cf55548c1530182e4c8  mKore.exe				│
│程式:											│
│    ＊ 實驗性嘗試修正幽靈道具	Part II (修正部份狀況會發生自動補給)			│
│  ☆＊ 自動切換裝備使用方式, 設定方式調整						│
│    ＋ 修正製藥清單顯示多餘資訊							│
│											│
│指令:											│
│											│
├───────────────────────────────────────────┤
│											│
│檔案:											│
│											│
│control/config.txt:									│
│    ＊ equipAuto_0			- 修改成 equipAuto_0_0				│
│    ＋ equipAuto_def_0								│
│    － equipAuto_0_def								│
│											│
│control/timeouts.txt:									│
│    ＋ ai_equip_waitAfterChange							│
│											│
├──mKore v2.03.00──────────────────────────────────┤
│MD5 Checksum:	b78852d9cde058170e25582e5ba97553  mKore.exe				│
│程式:											│
│    ＊ 修正輔助技能在某些情況下不會施放						│
│    ＊ 修正自動開啟聊天室會使程式結束							│
│    ＊ 修正自動製藥會不停使用技能							│
│    ＊ 修正NPC編號更新錯誤								│
│    ＊ 修正手推車物品分類錯誤								│
│    ＊ 修正露天商店死亡後無法走到定點開設						│
│    ＊ 修正自動賣物設為 0 會出現自動賣物失敗的訊息					│
│    ＊ 修正被人邀請進入公會,公會名稱無法顯示						│
│    ＊ 非對話頻道的記錄移到Alert.txt							│
│  ☆＋ AUTOTALK移植,並加入裝備損壞判斷						│
│  ☆＋ 強化露天商店自動補貨機能							│
│    ＋ 顯示裝備是否已損壞								│
│    ＋ 死亡時自動關閉露天商店								│
│    ＋ 使用Ctrl+C中斷程式時以正常方式結束程式						│
│    ＋ 實驗性嘗試修正幽靈道具								│
│    ＋ 強化原始碼安全(大概吧!)							│
│											│
│指令:											│
│    ＋ autotalk			- 強制引發talkAuto功能				│
│    ＋ pmcl 				- 刪除重複顯示的密語				│
│    － shop info			- 等同於shop，故刪除				│
│											│
├───────────────────────────────────────────┤
│											│
│檔案:											│
│tables/										│
│    ＊ itemsdescriptions.txt		- 修正部份錯誤					│
│    ＋ itemsweight.txt		- 物品重量					│
│    ＊ cards.txt			- 更改卡片顯示名稱				│
│											│
│control/cart_control.txt:								│
│    ＋ 手推車物品設定加入第4個設定值							│
│											│
│control/config.txt:									│
│    ＋ cartAuto									│
│    ＋ cartMaxWeight									│
│    ＋ talkAuto									│
│    ＋ talkAuto_npc									│
│    ＋ talkAuto_npc_distance								│
│    ＋ talkAuto_npc_steps								│
│    ＋ talkAuto_hp									│
│    ＋ talkAuto_sp									│
│    ＋ talkAuto_peace									│
│    ＋ talkAuto_brokenOnly								│
│											│
│control/shop.txt:									│
│    ＋ shop_start_idle								│
│    ＋ shop_start_wait								│
│    ＋ shop_look 									│
│    － shop_startTimeDelay								│
│											│
├──mKore v2.02.00──────────────────────────────────┤
│MD5 Checksum:9774ab9e96cc82add06dfaefc5ca3a80  mKore.exe				│
│程式:											│
│    ＊ 計算時間的重大BUG修正(影響效率的主因)						│
│    ＊ 使用技能或物品的狀態偵測補強							│
│    ＊ 瞬移後暫停時間由5秒改為2秒							│
│    ＊ 強化更新NPC編號機能								│
│    ＊ 和NPC對話會轉頭,並可在X-KORE模式下看到效果					│
│    ＊ NPC對話類型增加數字及文字							│
│    ＊ 寵物功能強化									│
│    ＊ 修正使用物品,隊伍技能 timeout設為空白的錯誤					│
│    ＊ 死亡時自動離開聊天室								│
│    ＊ 性別對應名稱改由sex.txt讀取							│
│    ＊ 鍛造武器的星星數對應名稱改由stars.txt讀取					│
│    ＊ revcPacker.txt 格式修改							│
│    ＊ \tables\aid.txt 格式修改與Tiffany同						│
│    ＋ 好友名單相關功能(自動回應邀請,好友指令)					│
│    ＋ 自動鍛造,製藥,製作箭								│
│    ＋ 自動查價									│
│    － 刪除自動新增未知傳點功能							│
│											│
│指令:											│
│    ＊ i desc				- 顯示物品說明					│
│    ＊ cart desc			- 顯示物品說明					│
│    ＊ storage desc			- 顯示物品說明					│
│    ＊ skills desc			- 顯示技能說明					│
│    ＊ pet call			- 孵化寵物					│
│    ＋ friend 			- 顯示好友列表					│
│    ＋ friend join <flag>		- 回應是否加入好友				│
│    ＋ friend request <player #>	- 邀請別人加入好友				│
│    ＋ friend kick <firend #>		- 刪除好友					│
│    ＋ friend pm <firend #> <message>	- 密語好友					│
│    ＋ make				- 鍛造/製藥					│
│    ＋ automake			- 自動鍛造/製藥					│
│    － send				- 用處不大的指令，故移除			│
│											│
├───────────────────────────────────────────┤
│											│
│檔案:											│
│											│
│control/config.txt:									│
│    ＊ useSelf_skill_0_inStatus,useSelf_skill_0_outStatus				│
│    					- 合併成useSelf_skill_0_status			│
│    ＊ useSelf_item_0_inStatus,useSelf_item_0_outStatus				│
│    					- 合併成useSelf_item_0_status			│
│    ＋ attackSkillSlot_0_param1							│
│    ＋ attackSkillSlot_0_param2							│
│    ＋ attackSkillSlot_0_param3							│
│    ＋ attackSkillSlot_0_status 							│
│    ＋ recordVender_clearName	 							│
│    ＋ shoppingAuto		 							│
│    ＋ makeArrowAuto		 							│
│    ＋ avoidGM_paranoia	 							│
│    ＋ friendAuto		 							│
│    ＋ petAuto_return									│
│    ＋ petAuto_protect	 							│
│    － petAutoFood									│
│    － attackSkillSlot_0_stopWhenFrozen						│
│    － useSelf_skill_0_monsters 							│
│											│
│control/option.txt:									│
│    － colorMode			- 改由colors_console.txt去設定			│
│											│
│control/timeouts.txt:									│
│    ＋ ai_makeArrow	 								│
│    ＋ ai_shoppingAuto_giveup	 							│
│    ＋ ai_shoppingAuto	 							│
│    ＋ ai_friendAuto		 							│
│											│
│tables/aids.txt:									│
│    ＊ 格式修改									│
│											│
│tables/revcPacker.txt:								│
│    ＊ 格式修改									│
│											│
└───────────────────────────────────────────┘

┌──mKore v2.01.03──────────────────────────────────┐
│MD5 Checksum:	8308c6bdb025a0c342b3207c0dc2c5d0  mKore.exe
				│
│程式:											│
│    ＊ GM AID編號檔修正		         					│
│    ＊ 修正公告頻道及關鍵字偵測        						│
└───────────────────────────────────────────┘

┌──mKore v2.01.01──────────────────────────────────┐
│MD5 Checksum:	d0a81166498caa65ad77da9253f1b7a0  mKore.exe
				│
│程式:											│
│    ＊ 主動攻擊所有怪物設定方式改變							│
│    ＊ 特定區域隨機移動,城市內隨機移動						│
│    ＊ 武器名稱表示方式改變								│
│    ＊ 金錢改以貨幣方式表示								│
│    ＊ 顯示寵物蛋命名狀態								│
│    ＊ 賣物品時暫時移除弓箭								│
│    ＊ 自動儲倉,自動買物,自動賣物路徑修正						│
│    ＊ 暴倉偵測修正									│
│    ＊ 取消找不到存倉NPC把自動存倉設為0						│
│    ＋ console模式自訂文字顏色							│
│    － 自動解毒取消改以物品或技能設定解毒						│
│											│
│指令:											│
│    ＊ e				- 顯示表情代號意義				│
│    ＊ eq				- 可顯示已裝備道具				│
│    ＊ look				- 顯示額外說明					│
│    ＊ ai <on=開 | off=關 | clear=清除>						│
│    － as				- 併入ai指令中					│
│    － cai				- 併入ai指令中					│
│    － v				- 用處不大的指令，故移除			│
│											│
├───────────────────────────────────────────┤
│											│
│檔案:											│
│control/										│
│    ＊ colors.txt			- 更名為 colors_Vx.txt				│
│    ＋ colors_console.txt								│
│											│
│tables/										│
│    － skillsst.txt			- 和msgstrings.txt作用相同, 故刪除		│
│											│
│control/config.txt:									│
│    ＊ 排列方式改變									│
│    ＊ attackAuto			- 刪掉 attackAuto 3 的設定方式			│
│    ＊ teleportAuto_maxRouteDistance	- 更名為 teleRouteDist				│
│    ＋ attackSkillSlot_0_spirits_lower						│
│    ＋ attackSkillSlot_0_spirits_upper						│
│    ＋ route_randomWalk_inCity							│
│    ＋ route_randomWalk_upLeft							│
│    ＋ chatRoom									│
│    ＋ chatRoomMode									│
│    ＋ hideMsg_arrowRemove								│
│    ＋ teleRoute									│
│    ＋ route_NPC_distance								│
│    ＋ recordStorage									│
│    ＋ guildAutoInfo									│
│    ＋ hideMsg_charStatus								│ 
│    ＋ hideMsg_partyStatus								│
│    ＋ hideMsg_monsterStatus								│
│    ＋ hideMsg_otherStatus								│
│    ＋ useSelf_skill_0_param2								│
│    ＋ useSelf_item_0_param2								│
│    － colorMode 			- 移入option.txt				│
│    － authPassword			- 刪除						│
│    － cureAuto_poison		- 改以物品或技能設定解毒			│
│											│
│control/option.txt:									│
│    ＋ colorMode									│
│											│
│control/timeouts.txt:									│
│    ＋ ai_teleRoute									│
│											│
│control/chatauto.txt:									│
│    － 移除聊天室相關設定								│
│											│
│control/mon_control.txt:								│
│    ＋ all 設定方式									│
│											│
│tables/recvpackets.txt:								│
│    ＊ 資料更新									│
│											│
│tables/elements.txt:									│
│    ＊ 資料更新									│
│											│
└───────────────────────────────────────────┘