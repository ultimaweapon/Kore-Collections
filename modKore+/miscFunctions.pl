#########################################################################
#  modKore - Hybrid :: Misc Function
#  http://modkore.sf.net
#
#  This software is open source, licensed under the GNU General Public
#  License, version 2.
#  Basically, this means that you're allowed to modify and distribute
#  this software. However, if you distribute modified versions, you MUST
#  also distribute the source code.
#  See http://www.gnu.org/licenses/gpl.html for the full license.
#########################################################################

##################################
# brought to you by: ragnarok.cc #
# --> http://www.ragnarok.cc <-- #
##################################

use System;
use Plugins;
#######################################
#INITIALIZE VARIABLES
#######################################
sub initConnectVars {
	initMapChangeVars();
	initStatusChangeVars();
	undef @{$chars[$config{'char'}]{'inventory'}};
	undef %{$chars[$config{'char'}]{'skills'}};
	undef @skillsID;
}

sub initMapChangeVars {
	@portalsID_old = @portalsID;
	%portals_old = %portals;
	%{$chars_old[$config{'char'}]{'pos_to'}} = %{$chars[$config{'char'}]{'pos_to'}};
	undef $chars[$config{'char'}]{'sitting'};
	undef $chars[$config{'char'}]{'dead'};
	$timeout{'play'}{'time'} = time;
	$timeout{'ai_sync'}{'time'} = time;
	$timeout{'ai_sit_idle'}{'time'} = time;
	$timeout{'ai_teleport_idle'}{'time'} = time;
	$timeout{'ai_teleport_search'}{'time'} = time;
	$timeout{'ai_teleport_safe_force'}{'time'} = time;
	undef %incomingDeal;
	undef %outgoingDeal;
	undef %currentDeal;
	undef $currentChatRoom;
	undef @currentChatRoomUsers;
	undef @playersID;
	undef @monstersID;
	undef @portalsID;
	undef @itemsID;
	undef @npcsID;
	undef @identifyID;
	undef @spellsID;
	undef @petsID;
	undef %players;
	undef %monsters;
	undef %portals;
	undef %items;
	undef %npcs;
	undef %spells;
	undef %incomingParty;
	undef $msg;
	undef %talk;
	undef %{$ai_v{'temp'}};
#Cart List bugfix - chobit aska 20030128
	undef @{$cart{'inventory'}};
# ChatAuto , Q'pet , Vender
	undef %ppllog;
	undef @venderItemList; 
	undef $venderID; 
	undef @venderListsID; 
	undef $venderLists; 
# Stuck Killer
	undef $old_x;
	undef $old_y;
	undef $old_pos_x;
	undef $old_pos_y;
	undef $move_x;
	undef $move_y;
	undef $move_pos_x;
	undef $move_pos_y;
	$calcFrom_SameSpot = 0;
	$calcTo_SameSpot = 0;
	$moveFrom_SameSpot = 0;
	$moveTo_SameSpot = 0;
	$route_stuck = 0;
	$totalStuckCount = 0 if ($totalStuckCount > 10 || $totalStuckCount < 0);
#guild
	undef %incomingGuild;
	$timeout{'hitAndRun'}{'time'} = time;
}

sub initStatusChangeVars {
	my $i = 0; 
	while (defined($config{"useSelf_item_$i"})) { 
		undef $ai_v{"useSelf_item_$i"."_time"}; 
		$i++;
	}
	$i = 0; 
	while (defined($config{"useSelf_skill_$i"})) { 
		undef $ai_v{"useSelf_skill_$i"."_time"};
		$i++;
	}
	$i = 0; 
	while (defined($config{"partySkill_$i"})) { 
		undef $ai_v{"partySkill_$i"."_time"};
		$i++;
	}
	undef @skillsST;
	undef $chars[$config{'char'}]{'spirits'};
}


#######################################
#######################################
#Check Connection
#######################################
#######################################

# $conState contains the connection state:
# 1: Not connected to anything (next step -> connect to master server).
# 2: Connected to master server (next step -> connect to login server)
# 3: Connected to login server (next step -> connect to character server)
# 4: Connected to character server (next step -> connect to map server)
# 5: Connected to map server; ready and functional.
# Skip this sub if run as X-Kore

sub checkConnection {

	if ($conState == 1 && !($System::remote_socket && $System::remote_socket->connected()) && timeOut(\%{$timeout_ex{'master'}}) && !$conState_tries) {
		System::message "Connecting to Master Server...\n","connection";
		$conState_tries++;
		undef $msg;
		connection(\$System::remote_socket, $config{"master_host_$config{'master'}"},$config{"master_port_$config{'master'}"});
# Secure Login
		if ($System::remote_socket && $System::remote_socket->connected()){
			if ($config{'SecureLogin'}) {
				undef $secureLoginKey;
				System::message "Secure Login : Sending Request Key \n","connection";
				sendMasterEncryptKeyRequest(\$System::remote_socket,$config{'SecureLogin_RequestCode'});
			}else{
				sendMasterLogin(\$System::remote_socket, $config{'username'}, $config{'password'});
			}
		}
		$timeout{'master'}{'time'} = time;
	} elsif ($conState == 1 && $config{'SecureLogin'} && $secureLoginKey ne "" && !timeOut(\%{$timeout{'master'}}) && $conState_tries) {
		System::message "Secure Login : Encrypt password\n","connection";
		sendMasterSecureLogin(\$System::remote_socket, $config{'username'}, $config{'password'}, $secureLoginKey);
		undef $secureLoginKey;

	} elsif ($conState == 1 && timeOut(\%{$timeout{'master'}}) && timeOut(\%{$timeout_ex{'master'}})) {
		System::message "Timeout on Master Server, reconnecting...\n","connection";
		$timeout_ex{'master'}{'time'} = time;
		$timeout_ex{'master'}{'timeout'} = $timeout{'reconnect'}{'timeout'};
		killConnection(\$System::remote_socket);
		undef $conState_tries;

	} elsif ($conState == 2 && !($System::remote_socket && $System::remote_socket->connected()) && ($config{'server'} ne "" || $config{'charServer_host'}) && !$conState_tries) {
		System::message "Connecting to Game Login Server...\n","connection";
		$conState_tries++;
		if ($config{'charServer_host'}) {
			connection(\$System::remote_socket, $config{'charServer_host'},$config{'charServer_port'});
		} else {
			connection(\$System::remote_socket, $servers[$config{'server'}]{'ip'},$servers[$config{'server'}]{'port'});
		}
		sendGameLogin(\$System::remote_socket, $accountID, $sessionID, $sessionID2 ,$accountSex);
		$timeout{'gamelogin'}{'time'} = time;

	} elsif ($conState == 2 && timeOut(\%{$timeout{'gamelogin'}}) && ($config{'server'} ne "" || $config{'charServer_host'})) {
		System::message "Timeout on Game Login Server, reconnecting...\n","connection";
		$timeout_ex{'master'}{'time'} = time;
		$timeout_ex{'master'}{'timeout'} = $timeout{'reconnect'}{'timeout'};
		killConnection(\$System::remote_socket);
		undef $conState_tries;
		$conState = 1;

	} elsif ($conState == 3 && !($System::remote_socket && $System::remote_socket->connected()) && $config{'char'} ne "" && !$conState_tries) {
		System::message "Connecting to Game Login Server...\n","connection";
		$conState_tries++;
		connection(\$System::remote_socket, $servers[$config{'server'}]{'ip'},$servers[$config{'server'}]{'port'});
		sendCharLogin(\$System::remote_socket, $config{'char'});
		$timeout{'charlogin'}{'time'} = time;

	} elsif ($conState == 3 && timeOut(\%{$timeout{'gamelogin'}}) && $config{'char'} ne "") {
		System::message "Timeout on Char Login Server, reconnecting...\n","connection";
		$timeout_ex{'master'}{'time'} = time;
		$timeout_ex{'master'}{'timeout'} = $timeout{'reconnect'}{'timeout'};
		killConnection(\$System::remote_socket);
		$conState = 1;
		undef $conState_tries;

	} elsif ($conState == 4 && !($System::remote_socket && $System::remote_socket->connected()) && !$conState_tries) {
		System::message "Connecting to Map Server...\n","connection";
		$conState_tries++;
		initConnectVars();
		if ($config{'charServer_host'}) {
			connection(\$System::remote_socket, $config{'charServer_host'},$map_port);
		} else {
			connection(\$System::remote_socket, $map_ip, $map_port);
		}
		sendMapLogin(\$System::remote_socket, $accountID, $charID, $sessionID, $accountSex2);
		$timeout{'maplogin'}{'time'} = time;

	} elsif ($conState == 4 && timeOut(\%{$timeout{'maplogin'}})) {
		System::message "Timeout on Map Server, connecting to Master Server...\n","connection";
		$timeout_ex{'master'}{'time'} = time;
		$timeout_ex{'master'}{'timeout'} = $timeout{'reconnect'}{'timeout'};
		killConnection(\$System::remote_socket);
		$conState = 1;
		undef $conState_tries;

	} elsif ($conState == 5 && !($System::remote_socket && $System::remote_socket->connected())) {
		$conState = 1;
		undef $conState_tries;

	} elsif ($conState == 5 && timeOut(\%{$timeout{'play'}})) {
		System::message "Timeout on Map Server, connecting to Master Server...\n","connection";
		$timeout_ex{'master'}{'time'} = time;
		$timeout_ex{'master'}{'timeout'} = $timeout{'reconnect'}{'timeout'};
		killConnection(\$System::remote_socket);
		$conState = 1;
		undef $conState_tries;
	}

}

sub checkSynchronized {
	if (timeOut(\%{$timeout{'injectKeepAlive'}})) {
		$conState = 1;
		my $procID = $GetProcByName->Call($System::xMode) || 0;
		if (!$procID && !$printed) {
			System::message "Error: Could not locate process ${System::xMode}.\n";
			System::message "Waiting for you to start the process...";
			$printed = 1;
		}
		if ($procID) {
			System::message "Process found\n";
			my $InjectDLL = new Win32::API("Tools", "InjectDLL", "NP", "I");
			my $retVal = $InjectDLL->Call($procID, $injectDLL_file) || System::error "This Process Could not inject DLL";
			System::message "Waiting for InjectDLL to connect...\n";
			$System::remote_socket = $System::injectServer_socket->accept();
			(inet_aton($System::remote_socket->peerhost()) == inet_aton('localhost')) || System::error "Inject Socket must be connected from localhost";
			System::message "InjectDLL Socket connected - Ready to start botting\n";
			$timeout{'injectKeepAlive'}{'time'} = time;
			$printed = 0;
		}
	}

	if (timeOut(\%{$timeout{'injectSync'}})) {
		sendSyncInject(\$System::remote_socket);
		$timeout{'injectSync'}{'time'} = time;
	}
}

###########################################
# TIME CHECKING
###########################################
sub checkTimer{
	if ($config{'autoRestart'} && time - $KoreStartTime > $config{'autoRestart'} && ($System::remote_socket && $System::remote_socket->connected()) && $conState == 5 
		&& $ai_seq[0] ne "attack" && $ai_seq[0] ne "take") {
		$conState = 1;
		undef $conState_tries;
		undef %ai_v;
		undef @ai_seq;
		undef @ai_seq_args;
		$KoreStartTime = time;
		System::message "\nAuto-restarting!!\n\n","connection",0,"w";
		$timeout_ex{'master'}{'time'} = time;
		$timeout_ex{'master'}{'timeout'} = $timeout{'reconnect'}{'timeout'};
		killConnection(\$System::remote_socket);
	}

#add waitingTime
	if ($config{'waitingTimeStart'} ne "" && $config{'waitingTimeStop'} ne "" && ($System::remote_socket && $System::remote_socket->connected())) {
		my $dtime = getFormattedDate(int(time));
		$dtime = substr($dtime,length($dtime)-8,8);
		if ($dtime eq $config{'waitingTimeStart'}) {
			my ($hr1,$min1,$sec1) = $config{'waitingTimeStart'}=~ /(\d+):(\d+):(\d+)/;
			my ($hr2,$min2,$sec2) = $config{'waitingTimeStop'}=~ /(\d+):(\d+):(\d+)/;
			my $halt_sec = 0;
			my $hr = $hr2-$hr1;
			my $min=$min2-$min1; 
			my $sec=$sec2-$sec1;
			if ($hr<0) { $hr=$hr+24;} 
			my $reconnect_time=$hr*3600+$min*60+$sec;
			$conState = 1;
			undef $conState_tries;
			undef %ai_v;
			undef @ai_seq;
			undef @ai_seq_args;
			$KoreStartTime = time;
			System::message "\nwaiting Time : $config{'waitingTimeStart'} to $config{'waitingTimeStop'}\n\n","connection",0,"w";
			$timeout_ex{'master'}{'time'} = time;
			$timeout_ex{'master'}{'timeout'} = $reconnect_time;
			killConnection(\$System::remote_socket);
		}
	}

# Quit when trying reconnect more than dcOnTryReConnect
	if ($config{'dcOnTryReConnect'} && $conState_tries >= $config{'dcOnTryReConnect'}) {
		System::message "Trying Reconnect more than $config{'dcOnTryReConnect'} , Quiting ...\n","connection",0,"w";
		quit();
	}
}

#######################################
#PARSE INPUT
#######################################

sub parseInput {
	my $input = shift;
	my $printType;
	my ($hook, $msg);
	$printType = shift if ($config{'XKore'});

	System::debug("Input: $input\n", "parseInput", 2);

#	if ($printType) {
#		my $hookOutput = sub {
#			my ($type, $domain, $level, $globalVerbosity, $message, $user_data) = @_;
#			$msg .= $message if ($type ne 'debug' && $level <= $globalVerbosity);
#		};
#		$hook = System::addHook($hookOutput);
#		$interface->writeOutput("console", "$input\n");
#	}
#	$XKore_dontRedirect = 1 if ($config{XKore});

	if (!$System::xMode && $conState == 2 && $waitingForInput) {
		$config{'server'} = $input;
		$waitingForInput = 0;
		FileParser::writeDataFileIntact("$System::def_config/config.txt", \%config);
	} elsif (!$System::xMode && $conState == 3 && $waitingForInput) {
		$config{'char'} = $input;
		$waitingForInput = 0;
		FileParser::writeDataFileIntact("$System::def_config/config.txt", \%config);
		sendCharLogin(\$System::remote_socket, $config{'char'});
		$timeout{'gamelogin'}{'time'} = time;

	} else {
		parseCommand($input);
		#Commands::run($input) || parseCommand($input);
	}

	if ($printType) {
		Log::delHook($hook);
		if ($config{'XKore'} && defined $msg && $conState == 5) {
			$msg =~ s/\n*$//s;
			$msg =~ s/\n/\\n/g;
			sendMessage(\$remote_socket, "k", $msg);
		}
	}
	$XKore_dontRedirect = 0 if ($config{XKore});
}

sub parseCommand {
	my $input = shift;

	my ($switch, $args) = split(' ', $input, 2);
	my ($arg1, $arg2, $arg3, $arg4);

#Parse command...ugh
#improve a command by BowJung
	if ($switch eq "a") {
		my ($arg1) = $input =~ /^[\s\S]*? (\w+)/;
		my ($arg2) = $input =~ /^[\s\S]*? [\s\S]*? (\d+)/;
		if ($arg1 =~ /^\d+$/ && $monstersID[$arg1] eq "") {
			System::message "Error in function 'a' (Attack Monster)\n".
								 "Monster $arg1 does not exist.\n";
		} elsif ($arg1 =~ /^\d+$/) {
			attack($monstersID[$arg1]);
		} elsif ($arg1 eq "none") {
			configModify("attackAuto", 0);
		} elsif ($arg1 eq "no") {
			configModify("attackAuto", 1);
		} elsif ($arg1 eq "select") {
			configModify("attackAuto", 2);
		} elsif ($arg1 eq "yes") {
			configModify("attackAuto", 3);

		} else {
			System::message "Syntax Error in function 'a' (Attack Monster)\n".
								 "Usage: attack <monster # | none | no | select | yes >\n";
		}

#Toggle Ai
	} elsif ($switch eq "ai") {
		if ($AI) {
			undef $AI;
			$AI_forcedOff = 1;
			System::message "AI turned off\n";
		} else {
			$AI = 1;
			undef $AI_forcedOff;
			System::message "AI turned on\n";
		}

# ai Status
	}elsif ($switch eq "as" ){
		my $stuff = @ai_seq_args;
		System::message "AI: @ai_seq | $stuff\n";

	} elsif ($switch eq "auth") {
		my ($arg1, $arg2) = $input =~ /^[\s\S]*? ([\s\S]*) ([\s\S]*?)$/;
		if ($arg1 eq "" || ($arg2 ne "1" && $arg2 ne "0")) {
			System::message "Syntax Error in function 'auth' (Overall Authorize)\n".
									   "Usage: auth <username> <flag>\n";
		} else {
			auth($arg1, $arg2);
		}

#force command
	} elsif ($switch eq "autostorage") {
		unshift @ai_seq, "storageAuto";
		unshift @ai_seq_args, {};

	} elsif ($switch eq "autobuy") {
		unshift @ai_seq, "buyAuto";
		unshift @ai_seq_args, {};

	} elsif ($switch eq "autosell") {
		unshift @ai_seq, "sellAuto";
		unshift @ai_seq_args, {};

	} elsif ($switch eq "bestow") {
		my ($arg1) = $input =~ /^[\s\S]*? ([\s\S]*)/;
		if ($currentChatRoom eq "") {
			System::message "Error in function 'bestow' (Bestow Admin in Chat)\n";
			System::message "You are not in a Chat Room.\n";
		} elsif ($arg1 eq "") {
			System::message "Syntax Error in function 'bestow' (Bestow Admin in Chat)\n";
			System::message "Usage: bestow <user #>\n";
		} elsif ($currentChatRoomUsers[$arg1] eq "") {
			System::message "Error in function 'bestow' (Bestow Admin in Chat)\n".
									   "Chat Room User $arg1 doesn't exist\n";
		} else {
			sendChatRoomBestow(\$System::remote_socket, $currentChatRoomUsers[$arg1]);
		}

	} elsif ($switch eq "buy") {
		my ($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		my ($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)$/;
		if ($arg1 eq "") {
			System::message "Syntax Error in function 'buy' (Buy Store Item)\n".
									   "Usage: buy <item #> [<amount>]\n";
		} elsif ($storeList[$arg1] eq "") {
			System::message "Error in function 'buy' (Buy Store Item)\n".
									   "Store Item $arg1 does not exist.\n";
		} else {
			if ($arg2 <= 0) {
				$arg2 = 1;
			}
			sendBuy(\$System::remote_socket, $storeList[$arg1]{'nameID'}, $arg2);
		}

	} elsif ($switch eq "c") {
		my ($arg1) = $input =~ /^[\s\S]*? ([\s\S]*)/;
		if ($arg1 eq "") {
			System::message "Syntax Error in function 'c' (Chat)\n".
									   "Usage: c <message>\n";
		} else {
			sendMessage(\$System::remote_socket, "c", $arg1);
		}

	} elsif ($switch eq "cai") {
		$ai_v{'clear_aiQueue'} = 1;
		System::message "Clear Ai Route\n";

	#Cart command - chobit andy 20030101
	} elsif ($switch eq "cart") {
		my ($arg1) = $input =~ /^[\s\S]*? (\w+)/;
		my ($arg2) = $input =~ /^[\s\S]*? \w+ (\d+)/;
		my ($arg3) = $input =~ /^[\s\S]*? \w+ \d+ (\d+)/;
		if ($arg1 eq "") {
			System::message "-------------Cart--------------\n";
			System::message "#  Name\n";
			for ($i=0; $i < @{$cart{'inventory'}}; $i++) {
				next if (!%{$cart{'inventory'}[$i]});
				$display = "$cart{'inventory'}[$i]{'name'} x $cart{'inventory'}[$i]{'amount'}";
				System::message sprintf("%-2d %-34s\n",$i,$display);
			}
			System::message "\nCapacity: " . int($cart{'items'}) . "/" . int($cart{'items_max'}) . "  Weight: " . int($cart{'weight'}) . "/" . int($cart{'weight_max'}) . "\n";
			System::message "-------------------------------\n";

		} elsif ($arg1 eq "add" && $arg2 =~ /\d+/ && $chars[$config{'char'}]{'inventory'}[$arg2] eq "") {
			System::message "Error in function 'cart add' (Add Item to Cart)\n".
									   "Inventory Item $arg2 does not exist.\n";

		} elsif ($arg1 eq "add" && $arg2 =~ /\d+/) {
			if (!$arg3 || $arg3 > $chars[$config{'char'}]{'inventory'}[$arg2]{'amount'}) {
				$arg3 = $chars[$config{'char'}]{'inventory'}[$arg2]{'amount'};
			}
			sendCartAddFromInv(\$System::remote_socket, $chars[$config{'char'}]{'inventory'}[$arg2]{'index'}, $arg3);

		} elsif ($arg1 eq "add" && $arg2 eq "") {
			System::message "Syntax Error in function 'cart add' (Add Item to Cart)\n".
									   "Usage: cart add <item #>\n";

		} elsif ($arg1 eq "get" && $arg2 =~ /\d+/ && !%{$cart{'inventory'}[$arg2]}) {
			System::message "Error in function 'cart get' (Get Item from Cart)\n".
									   "Cart Item $arg2 does not exist.\n";

		} elsif ($arg1 eq "get" && $arg2 =~ /\d+/) {
			if (!$arg3 || $arg3 > $cart{'inventory'}[$arg2]{'amount'}) {
				$arg3 = $cart{'inventory'}[$arg2]{'amount'};
			}
			sendCartGetToInv(\$System::remote_socket, $arg2, $arg3);

		} elsif ($arg1 eq "get" && $arg2 eq "") {
			System::message "Syntax Error in function 'cart get' (Get Item from Cart)\n".
									   "Usage: cart get <cart item #>\n";
		}

	} elsif ($switch eq "chat") {
		my ($replace, $title) = $input =~ /(^[\s\S]*? \"([\s\S]*?)\" ?)/;
		my $qm = quotemeta $replace;
		$input =~ s/$qm//;
		my @arg = split / /, $input;
		if ($title eq "") {
			System::message "Syntax Error in function 'chat' (Create Chat Room)\n".
									   "Usage: chat \"<title>\" [<limit #> <public flag> <password>]\n";
		} elsif ($currentChatRoom ne "") {
			System::message "Error in function 'chat' (Create Chat Room)\n".
									   "You are already in a chat room.\n";
		} else {
			if ($arg[0] eq "") {
				$arg[0] = 20;
			}
			if ($arg[1] eq "") {
				$arg[1] = 1;
			}
			sendChatRoomCreate(\$System::remote_socket, $title, $arg[0], $arg[1], $arg[2]);
			$createdChatRoom{'title'} = $title;
			$createdChatRoom{'ownerID'} = $accountID;
			$createdChatRoom{'limit'} = $arg[0];
			$createdChatRoom{'public'} = $arg[1];
			$createdChatRoom{'num_users'} = 1;
			$createdChatRoom{'users'}{$chars[$config{'char'}]{'name'}} = 2;
		}


	} elsif ($switch eq "chatmod") {
		my ($replace, $title) = $input =~ /(^[\s\S]*? \"([\s\S]*?)\" ?)/;
		my $qm = quotemeta $replace;
		$input =~ s/$qm//;
		my @arg = split / /, $input;
		if ($title eq "") {
			System::message "Syntax Error in function 'chatmod' (Modify Chat Room)\n".
									   "Usage: chatmod \"<title>\" [<limit #> <public flag> <password>]\n";
		} else {
			if ($arg[0] eq "") {
				$arg[0] = 20;
			}
			if ($arg[1] eq "") {
				$arg[1] = 1;
			}
			sendChatRoomChange(\$System::remote_socket, $title, $arg[0], $arg[1], $arg[2]);
		}

#Sraet Chat Viewer
	} elsif ($switch eq "chist") {
		my (@chat,$profile);
		$profile = $config{'username'};
		open(CHAT, "logs\/$profile"."_Chat.txt") or System::error "Unable to open Chat file. \n","file"; 
		@chat = <CHAT>; 
		close(CHAT); 
		System::message "------ Chat History --------------------\n"; 
		for ($i = @chat - 5; $i < @chat;$i++) { 
			System::message $chat[$i]; 
		} 
		System::message "----------------------------------------\n"; 

	} elsif ($switch eq "cl") { 
		System::clearLog();

	} elsif ($switch eq "conf") {
		my ($arg1) = $input =~ /^[\s\S]*? (\w+)/;
		my ($arg2) = $input =~ /^[\s\S]*? \w+ ([\s\S]+)$/;
		@{$ai_v{'temp'}{'conf'}} = keys %config;
		if ($arg1 eq "") {
			System::message "Syntax Error in function 'conf' (Config Modify)\n".
									   "Usage: conf <variable> [<value>]\n";

		} elsif (binFind(\@{$ai_v{'temp'}{'conf'}}, $arg1) eq "") {
			System::message "Config variable $arg1 doesn't exist\n";

		} elsif ($arg2 eq "value") {
			System::message "Config '$arg1' is $config{$arg1}\n";
		} else{
			configModify($arg1, $arg2);
		}

	} elsif ($switch eq "cri") {
		if ($currentChatRoom eq "") {
			System::message "There is no chat room info - you are not in a chat room\n";
		} else {
			System::message "-----------Chat Room Info-----------\n".
									   "Title                     Users   Public/Private\n";
			my $public_string = ($chatRooms{$currentChatRoom}{'public'}) ? "Public" : "Private";
			my $limit_string = $chatRooms{$currentChatRoom}{'num_users'}."/".$chatRooms{$currentChatRoom}{'limit'};
			System::message sprintf("%-25s %-7s %-10s\n",$chatRooms{$currentChatRoom}{'title'},$limit_string,$public_string);
			System::message "-- Users --\n";
			for (my $i = 0; $i < @currentChatRoomUsers; $i++) {
				next if ($currentChatRoomUsers[$i] eq "");
				my $user_string = $currentChatRoomUsers[$i];
				my $admin_string = ($chatRooms{$currentChatRoom}{'users'}{$currentChatRoomUsers[$i]} > 1) ? "(Admin)" : "";
				System::message sprintf("%-3d %-26s %-10s\n",$i,$user_string,$admin_string);
			}
			System::message "------------------------------------\n";
		}

	} elsif ($switch eq "crl") {
		System::message "-----------Chat Room List-----------\n".
								   "#   Title                     Owner                Users   Public/Private\n";
		for (my $i = 0; $i < @chatRoomsID; $i++) {
			next if ($chatRoomsID[$i] eq "");
			my $owner_string = ($chatRooms{$chatRoomsID[$i]}{'ownerID'} ne $accountID) ? $players{$chatRooms{$chatRoomsID[$i]}{'ownerID'}}{'name'} : $chars[$config{'char'}]{'name'};
			my $public_string = ($chatRooms{$chatRoomsID[$i]}{'public'}) ? "Public" : "Private";
			my $limit_string = $chatRooms{$chatRoomsID[$i]}{'num_users'}."/".$chatRooms{$chatRoomsID[$i]}{'limit'};
			System::message sprintf("%-3d %-25s %-11s          %-7s %-10s\n",$i,$chatRooms{$chatRoomsID[$i]}{'title'},$owner_string,$limit_string,$public_string);
		}
		System::message "------------------------------------\n";

	} elsif ($switch eq "deal") {
		my @arg = split / /, $input;
		shift @arg;
		if (%currentDeal && $arg[0] =~ /\d+/) {
			System::message "Error in function 'deal' (Deal a Player)\n".
									   "You are already in a deal\n";

		} elsif (%incomingDeal && $arg[0] =~ /\d+/) {
			System::message "Error in function 'deal' (Deal a Player)\n".
									   "You must first cancel the incoming deal\n";

		} elsif ($arg[0] =~ /\d+/ && !$playersID[$arg[0]]) {
			System::message "Error in function 'deal' (Deal a Player)\n".
									   "Player $arg[0] does not exist\n";

		} elsif ($arg[0] =~ /\d+/) {
			$outgoingDeal{'ID'} = $playersID[$arg[0]];
			sendDeal(\$System::remote_socket, $playersID[$arg[0]]);

		} elsif ($arg[0] eq "no" && !%incomingDeal && !%outgoingDeal && !%currentDeal) {
			System::message "Error in function 'deal' (Deal a Player)\n".
									   "There is no incoming/current deal to cancel\n";

		} elsif ($arg[0] eq "no" && (%incomingDeal || %outgoingDeal)) {
			sendDealCancel(\$System::remote_socket);

		} elsif ($arg[0] eq "no" && %currentDeal) {
			sendCurrentDealCancel(\$System::remote_socket);

		} elsif ($arg[0] eq "" && !%incomingDeal && !%currentDeal) {
			System::message "Error in function 'deal' (Deal a Player)\n".
									   "There is no deal to accept\n";

		} elsif ($arg[0] eq "" && $currentDeal{'you_finalize'} && !$currentDeal{'other_finalize'}) {
			System::message "Error in function 'deal' (Deal a Player)\n".
									   "Cannot make the trade - $currentDeal{'name'} has not finalized\n";

		} elsif ($arg[0] eq "" && $currentDeal{'final'}) {
			System::message "Error in function 'deal' (Deal a Player)\n".
									   "You already accepted the final deal\n";

		} elsif ($arg[0] eq "" && %incomingDeal) {
			sendDealAccept(\$System::remote_socket);

		} elsif ($arg[0] eq "" && $currentDeal{'you_finalize'} && $currentDeal{'other_finalize'}) {
			sendDealTrade(\$System::remote_socket);
			$currentDeal{'final'} = 1;
			System::message "You accepted the final Deal\n";

		} elsif ($arg[0] eq "" && %currentDeal) {
			sendDealAddItem(\$System::remote_socket, 0, $currentDeal{'you_zenny'});
			sendDealFinalize(\$System::remote_socket);
			

		} elsif ($arg[0] eq "add" && !%currentDeal) {
			System::message "Error in function 'deal_add' (Add Item to Deal)\n".
									   "No deal in progress\n";

		} elsif ($arg[0] eq "add" && $currentDeal{'you_finalize'}) {
			System::message "Error in function 'deal_add' (Add Item to Deal)\n".
									   "Can't add any Items - You already finalized the deal\n";

		} elsif ($arg[0] eq "add" && $arg[1] =~ /\d+/ && !%{$chars[$config{'char'}]{'inventory'}[$arg[1]]}) {
			System::message "Error in function 'deal_add' (Add Item to Deal)\n".
									   "Inventory Item $arg[1] does not exist.\n";

		} elsif ($arg[0] eq "add" && $arg[2] && $arg[2] !~ /\d+/) {
			System::message "Error in function 'deal_add' (Add Item to Deal)\n".
									   "Amount must either be a number, or not specified.\n";

		} elsif ($arg[0] eq "add" && $arg[1] =~ /\d+/) {
			if (scalar(keys %{$currentDeal{'you'}}) < 10) {
				if (!$arg[2] || $arg[2] > $chars[$config{'char'}]{'inventory'}[$arg[1]]{'amount'}) {
					$arg[2] = $chars[$config{'char'}]{'inventory'}[$arg[1]]{'amount'};
				}
				$currentDeal{'lastItemAmount'} = $arg[2];
				sendDealAddItem(\$System::remote_socket, $chars[$config{'char'}]{'inventory'}[$arg[1]]{'index'}, $arg[2]);
			} else {
				System::message "You can't add any more items to the deal\n";
			}

		} elsif ($arg[0] eq "add" && $arg[1] eq "z") {
			if (!$arg[2] || $arg[2] > $chars[$config{'char'}]{'zenny'}) {
				$arg[2] = $chars[$config{'char'}]{'zenny'};
			}
			$currentDeal{'you_zenny'} = $arg[2];
			System::message "You put forward $arg[2] z to Deal\n";

		} else {
			System::message "Syntax Error in function 'deal' (Deal a player)\n".
									   "Usage: deal [<Player # | no | add>] [<item #>] [<amount>]\n";
		}

	} elsif ($switch eq "dl") {
		if (!%currentDeal) {
			System::message "There is no deal list - You are not in a deal\n";
		} else {
			my $other_string = $currentDeal{'name'};
			my $you_string = "You";
			my (@currentDealYou,@currentDealOther,$display,$display2);
			System::message "-----------Current Deal-----------\n";

			if ($currentDeal{'other_finalize'}) {
				$other_string .= " - Finalized";
			}
			if ($currentDeal{'you_finalize'}) {
				$you_string .= " - Finalized";
			}
			System::message sprintf("%-30s   %-30s\n",$you_string,$other_string);
			foreach (keys %{$currentDeal{'you'}}) {
				push @currentDealYou, $_;
			}
			foreach (keys %{$currentDeal{'other'}}) {
				push @currentDealOther, $_;
			}
			my $lastindex = @currentDealOther;
			$lastindex = @currentDealYou if (@currentDealYou > $lastindex);
			for (my $i = 0; $i < $lastindex; $i++) {
				if ($i < @currentDealYou) {
					$display = ($items_lut{$currentDealYou[$i]} ne "") 
						? $items_lut{$currentDealYou[$i]}
						: "Unknown ".$currentDealYou[$i];
					$display .= " x $currentDeal{'you'}{$currentDealYou[$i]}{'amount'}";
				} else {
					$display = "";
				}
				if ($i < @currentDealOther) {
					$display2 = ($items_lut{$currentDealOther[$i]} ne "") 
						? $items_lut{$currentDealOther[$i]}
						: "Unknown ".$currentDealOther[$i];
					$display2 .= " x $currentDeal{'other'}{$currentDealOther[$i]}{'amount'}";
				} else {
					$display2 = "";
				}
				System::message sprintf("%-30s   %-30s\n",$display,$display2);
			}
			$you_string = ($currentDeal{'you_zenny'} ne "") ? $currentDeal{'you_zenny'} : 0;
			$other_string = ($currentDeal{'other_zenny'} ne "") ? $currentDeal{'other_zenny'} : 0;
			System::message sprintf("Zenny: %-14d            Zenny: %-14d\n",$you_string,$other_string);
			System::message "----------------------------------\n";
		}


	} elsif ($switch eq "drop") {
		my ($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		my ($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)$/;
		if ($arg1 eq "") {
			System::message "Syntax Error in function 'drop' (Drop Inventory Item)\n".
									   "Usage: drop <item #> [<amount>]\n";
		} elsif (!%{$chars[$config{'char'}]{'inventory'}[$arg1]}) {
			System::message "Error in function 'drop' (Drop Inventory Item)\n".
									   "Inventory Item $arg1 does not exist.\n";
		} else {
			if (!$arg2 || $arg2 > $chars[$config{'char'}]{'inventory'}[$arg1]{'amount'}) {
				$arg2 = $chars[$config{'char'}]{'inventory'}[$arg1]{'amount'};
			}
			sendDrop(\$System::remote_socket, $chars[$config{'char'}]{'inventory'}[$arg1]{'index'}, $arg2);
		}

	} elsif ($switch eq "dump") {
		dumpData($msg);

	} elsif ($switch eq "e") {
		my ($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		if ($arg1 eq "" || $arg1 > 48 || $arg1 < 0) {
			System::message "Syntax Error in function 'e' (Emotion)\n".
									   "Usage: e <emotion # (0-48)>\n";
		} else {
			sendEmotion(\$System::remote_socket, $arg1);
		}

	} elsif ($switch eq "eq") {
		my ($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		my ($arg2) = $input =~ /^[\s\S]*? \d+ (\w+)/;
		if ($arg1 eq "") {
			System::message "Syntax Error in function 'equip' (Equip Inventory Item)\n".
									   "Usage: equip <item #> [r]\n";
		} elsif (!%{$chars[$config{'char'}]{'inventory'}[$arg1]}) {
			System::message "Error in function 'equip' (Equip Inventory Item)\n".
									   "Inventory Item $arg1 does not exist.\n";

		} elsif ($chars[$config{'char'}]{'inventory'}[$arg1]{'type_equip'} == 0 && $chars[$config{'char'}]{'inventory'}[$arg1]{'type'} != 10) {
			System::message "Error in function 'equip' (Equip Inventory Item)\n".
									   "Inventory Item $arg1 can't be equipped.\n";

		} else {
			sendEquip(\$System::remote_socket, $chars[$config{'char'}]{'inventory'}[$arg1]{'index'}, $chars[$config{'char'}]{'inventory'}[$arg1]{'type_equip'});
		}

	} elsif ($switch eq "exp") {
		# exp report
		my ($arg1) = $input =~ /^[\s\S]*? (\w+)/; 
		if($arg1 eq ""){ 
			my ($endTime_EXP,$w_hour,$w_min,$w_sec,$total,$bExpPerHour,$jExpPerHour,$EstB_hour,$EstB_min,$EstB_sec,$EstJ_hour,$EstB_min,$EstB_sec,$percentB,$percentJ);
			$endTime_EXP = time;
			$w_sec = int($endTime_EXP - $startTime_EXP); 
			$w_hour = $w_min = 0;
			if ($w_sec > 0) {
				$bExpPerHour = int($totalBaseExp / $w_sec * 3600); 
				$jExpPerHour = int($totalJobExp / $w_sec * 3600); 
				if ($w_sec >= 3600) { 
					$w_hour = int($w_sec / 3600); 
					$w_sec %= 3600; 
				}
				if ($w_sec >= 60) { 
					$w_min = int($w_sec / 60); 
					$w_sec %= 60; 
				}
				if ($chars[$config{'char'}]{'exp_max'} && $bExpPerHour){
					$percentB = "(".sprintf("%.2f",$totalBaseExp * 100 / $chars[$config{'char'}]{'exp_max'})."%)";
					$EstB_sec = int(($chars[$config{'char'}]{'exp_max'} - $chars[$config{'char'}]{'exp'})/($bExpPerHour/3600));
					$EstB_hour = ($EstB_sec >=3600) ? int($EstB_sec/3600):0;
					$EstB_sec %=3600;
					$EstB_min = ($EstB_sec >=60) ? int($EstB_sec/60):0;
					$EstB_sec %=60;
					$EstB_hour = "0" . $EstB_hour if ($EstB_hour < 10);
					$EstB_min = "0" . $EstB_min if ($EstB_min < 10);
					$EstB_sec = "0" . $EstB_sec if ($EstB_sec < 10);
				}
				 if ($chars[$config{'char'}]{'exp_job_max'} && $jExpPerHour){
					$percentJ = "(".sprintf("%.2f",$totalJobExp * 100 / $chars[$config{'char'}]{'exp_job_max'})."%)";
					$EstJ_sec = int(($chars[$config{'char'}]{'exp_job_max'} - $chars[$config{'char'}]{'exp_job'})/($jExpPerHour/3600));
					$EstJ_hour = ($EstJ_sec >=3600) ? int($EstJ_sec/3600):0;
					$EstJ_sec %=3600;
					$EstJ_min = ($EstJ_sec >=60) ? int($EstJ_sec/60):0;
					$EstJ_sec %=60;
					$EstJ_hour = "0" . $EstJ_hour if ($EstJ_hour < 10);
					$EstJ_min = "0" . $EstJ_min if ($EstJ_min < 10);
					$EstJ_sec = "0" . $EstJ_sec if ($EstJ_sec < 10);
				 }
			}
			System::message "------------Exp Report------------\n"; 
			System::message "Botting time : $w_hour Hours $w_min Minutes $w_sec Seconds\n"; 
			System::message "BaseExp      : $totalBaseExp $percentB\n"; 
			System::message "JobExp       : $totalJobExp $percentJ\n"; 
			System::message "BaseExp/Hour : $bExpPerHour\n"; 
			System::message "JobExp/Hour  : $jExpPerHour\n";
			System::message "Base Levelup Time Estimation : $EstB_hour:$EstB_min:$EstB_sec\n";
			System::message "Job Levelup Time Estimation : $EstJ_hour:$EstJ_min:$EstJ_sec\n";
			System::message "----------------------------------\n"; 
			System::message "#   Name                    Amount\n"; 
			for ($i=0; $i<@monstersKilledID; $i++) { 
				next if ($monstersKilledID[$i] eq ""); 
				System::message sprintf("%-3d %-23s %6d\n", $i, $monstersKilled{$monstersKilledID[$i]}{'name'}, $monstersKilled{$monstersKilledID[$i]}{'count'}); 
				$total += $monstersKilled{$monstersKilledID[$i]}{'count'}; 
			}
			System::message "----------------------------------\n";
			System::message "Total : $total\n"; 
			System::message "----------------------------------\n"; 
		} elsif($arg1 eq "reset") {
			($bExpSwitch,$jExpSwitch,$totalBaseExp,$totalJobExp) = (2,2,0,0);
			$startTime_EXP = time;
			undef @monstersKilledID;
			undef %monstersKilled;
		} else {
			System::message "Error in function 'exp' (Exp Report)\n".
									   "Usage: exp [reset]\n";
		}

	} elsif ($switch eq "follow") {
		my ($arg1) = $input =~ /^[\s\S]*? (\w+)/;
		if ($arg1 eq "") {
			System::message "Syntax Error in function 'follow' (Follow Player)\n".
									   "Usage: follow <player #>\n";

		} elsif ($arg1 eq "stop") {
			aiRemove("follow");
			configModify("follow", 0);

		} elsif ($playersID[$arg1] eq "") {
			System::message "Error in function 'follow' (Follow Player)\n".
									   "Player $arg1 does not exist.\n";

		} else {
			ai_follow($players{$playersID[$arg1]}{'name'});
			configModify("follow", 1);
			configModify("followTarget", $players{$playersID[$arg1]}{'name'});
		}

	#Guild Chat - chobit andy 20030101
	} elsif ($switch eq "g") { 
		my ($arg1) = $input =~ /^[\s\S]*? ([\s\S]*)/; 
		if ($arg1 eq "") { 
			System::message "Syntax Error in function 'g' (Guild Chat)\n".
									   "Usage: g <message>\n"; 
		} else { 
			sendMessage(\$System::remote_socket, "g", $arg1); 
		}

	} elsif ($switch eq "guild") {
		my ($arg1) = $input =~ /^.*? (\w+)/;
		my ($arg2) = $input =~ /^.*? \w+ (\w+)/;
		if ($arg1 eq "i") {
			sendGuildRequest(\$System::remote_socket, 0);
			System::message "---------- Guild Information ----------\n";
			System::message sprintf("Guild Name    : %-25s    Exp   : %10d\n", $chars[$config{'char'}]{'guild'}{'name'}, $chars[$config{'char'}]{'guild'}{'exp'});
			System::message sprintf("Guild Level   : %-25d    Next  : %10d\n", $chars[$config{'char'}]{'guild'}{'lv'}, $chars[$config{'char'}]{'guild'}{'next_exp'});
			System::message sprintf("Master Name   : %-25s    Point : %10d\n", $chars[$config{'char'}]{'guild'}{'master'}, $chars[$config{'char'}]{'guild'}{'offerPoint'});
			System::message sprintf("Guild Members : %3d/%-3d (Max: %d)\n", $chars[$config{'char'}]{'guild'}{'conMember'}, scalar(keys %{$chars[$config{'char'}]{'guild'}{'members'}}), $chars[$config{'char'}]{'guild'}{'maxMember'});
			System::message sprintf("Average Level : %-3d\n", $chars[$config{'char'}]{'guild'}{'average'});
			System::message sprintf("Guild Castle  : %-25s    ID    : %-20s\n", $chars[$config{'char'}]{'guild'}{'castle'}, getHex($chars[$config{'char'}]{'guild'}{'ID'}));
			System::message "---------------------------------------\n";

		} elsif ($arg1 eq "m") {
			sendGuildRequest(\$System::remote_socket, 1);
			my $i=0;
			System::message "------------ Guild  Member ------------\n";
			System::message "#    Name                     Position                 Job         Lv Exp\n";
			foreach (keys %{$chars[$config{'char'}]{'guild'}{'members'}}) {
				$online_string = ($chars[$config{'char'}]{'guild'}{'members'}{$_}{'online'}) ? "*" : "";
				System::message sprintf("%-2d %1s %-24s %-24s %-11s %2d %-8d\n", $i++, $online_string, $chars[$config{'char'}]{'guild'}{'members'}{$_}{'name'}, $chars[$config{'char'}]{'guild'}{'positions'}[$chars[$config{'char'}]{'guild'}{'members'}{$_}{'position'}]{'name'}, $jobs_lut{$chars[$config{'char'}]{'guild'}{'members'}{$_}{'job'}}, $chars[$config{'char'}]{'guild'}{'members'}{$_}{'lv'}, $chars[$config{'char'}]{'guild'}{'members'}{$_}{'exp'});
				#    printf "                                (ID: %11s)      (AccountID: %11s)\n", getHex($_), getHex($chars[$config{'char'}]{'guild'}{'members'}{$_}{'accountID'});
			}
			System::message "---------------------------------------\n";

		} elsif ($arg1 eq "p") {
			sendGuildRequest(\$System::remote_socket, 2);
			System::message "----------- Guild Positions -----------\n";
			System::message "#  Position Name            Join Kick EXP%\n";
			for (my $i = 0; $i < @{$chars[$config{'char'}]{'guild'}{'positions'}}; $i++) {
				System::message sprintf("%-2d %-24s %4s %4s  %2d%s\n", $i, $chars[$config{'char'}]{'guild'}{'positions'}[$i]{'name'}, $chars[$config{'char'}]{'guild'}{'positions'}[$i]{'join'}, $chars[$config{'char'}]{'guild'}{'positions'}[$i]{'kick'}, $chars[$config{'char'}]{'guild'}{'positions'}[$i]{'feeEXP'}, "%");
			}
			System::message "---------------------------------------\n";

		} elsif ($arg1 eq "") {
			System::message "Requesting : guild information\n".
									   "Usage: guild < i | m | p >\n";
			sendGuildInfoRequest(\$System::remote_socket);
			sendGuildRequest(\$System::remote_socket, 0);
			sendGuildRequest(\$System::remote_socket, 1);
		}

	} elsif ($switch eq "hide") {
		sendHide(\$System::remote_socket);

	} elsif ($switch eq "i") {
		my($arg1) = $input =~ /^[\s\S]*? (\w+)/;
		my($arg2) = $input =~ /^[\s\S]*? \w+ (\d+)/;
		if ($arg1 eq "" || $arg1 eq "eq" || $arg1 eq "u" || $arg1 eq "nu") {
			my (@useable,@equipment,@non_useable,$display,$index);
			for (my $i = 0; $i < @{$chars[$config{'char'}]{'inventory'}};$i++) {
				next if (!%{$chars[$config{'char'}]{'inventory'}[$i]});
				# Fix Show items
				if ($chars[$config{'char'}]{'inventory'}[$i]{'type'} == 3 
					||$chars[$config{'char'}]{'inventory'}[$i]{'type'} == 6
					||$chars[$config{'char'}]{'inventory'}[$i]{'type'} == 10) {
					push @non_useable, $i;
				} elsif ($chars[$config{'char'}]{'inventory'}[$i]{'type'} <= 2) {
					push @useable, $i;
				} else {
					push @equipment, $i;
				}
			}
			System::message "-----------Inventory-----------\n";
			if ($arg1 eq "" || $arg1 eq "eq") {
				System::message "-- Equipment --\n";
				for (my $i = 0; $i < @equipment; $i++) {
					my $domain = "";
					$display = $chars[$config{'char'}]{'inventory'}[$equipment[$i]]{'name'};
					if ($chars[$config{'char'}]{'inventory'}[$equipment[$i]]{'equipped'}) {
						$display .= " -- Eqp: $equipTypes_lut{$chars[$config{'char'}]{'inventory'}[$equipment[$i]]{'equipped'}}";
						$domain = "equip";
					}
					if (!$chars[$config{'char'}]{'inventory'}[$equipment[$i]]{'identified'}) {
						$display .= " -- Not Identified";
						$domain = "inventoryNoID";
					}
					$index = $equipment[$i];
					System::message sprintf("%-4d %s\n",$index,$display),$domain;
				}
			}
			if ($arg1 eq "" || $arg1 eq "nu") {
				System::message "-- Non-Useable --\n";
				for (my $i = 0; $i < @non_useable; $i++) {
					$display = $chars[$config{'char'}]{'inventory'}[$non_useable[$i]]{'name'};
					$display .= " x $chars[$config{'char'}]{'inventory'}[$non_useable[$i]]{'amount'}";
					$index = $non_useable[$i];
					System::message sprintf("% -4d %s\n",$index,$display);
				}
			}
			if ($arg1 eq "" || $arg1 eq "u") {
				System::message "-- Useable --\n";
				for (my $i = 0; $i < @useable; $i++) {
					$display = $chars[$config{'char'}]{'inventory'}[$useable[$i]]{'name'};
					$display .= " x $chars[$config{'char'}]{'inventory'}[$useable[$i]]{'amount'}";
					$index = $useable[$i];
					System::message sprintf("% -4d %s\n",$index,$display);
				}
			}
			System::message "-------------------------------\n";

		} else {
			System::message "Syntax Error in function 'i' (Iventory List)\n".
									   "Usage: i [<u|eq|nu>]\n";
		}

	} elsif ($switch eq "identify") {
		my ($arg1) = $input =~ /^[\s\S]*? (\w+)/;
		if ($arg1 eq "") {
			System::message "---------Identify List--------\n";
			for (my $i = 0; $i < @identifyID; $i++) {
				next if ($identifyID[$i] eq "");
				System::message sprintf("% -4d %s\n",$i,$chars[$config{'char'}]{'inventory'}[$identifyID[$i]]{'name'});
			}
			System::message "------------------------------\n";

		} elsif ($arg1 =~ /\d+/ && $identifyID[$arg1] eq "") {
			System::message "Error in function 'identify' (Identify Item)\n".
									   "Identify Item $arg1 does not exist\n";

		} elsif ($arg1 =~ /\d+/) {
			sendIdentify(\$System::remote_socket, $chars[$config{'char'}]{'inventory'}[$identifyID[$arg1]]{'index'});

		} else {
			System::message "Syntax Error in function 'identify' (Identify Item)\n".
									   "Usage: identify [<identify #>]\n";
		}


	} elsif ($switch eq "ignore") {
		my ($arg1, $arg2) = $input =~ /^[\s\S]*? (\d+) ([\s\S]*)/;
		if ($arg1 eq "" || $arg2 eq "" || ($arg1 ne "0" && $arg1 ne "1")) {
			System::message "Syntax Error in function 'ignore' (Ignore Player/Everyone)\n".
									   "Usage: ignore <flag> <name | all>\n";

		} else {
			if ($arg2 eq "all") {
				sendIgnoreAll(\$System::remote_socket, !$arg1);
			} else {
				sendIgnore(\$System::remote_socket, $arg2, !$arg1);
			}
		}

	} elsif ($switch eq "il") {
		System::message "-----------Item List-----------\n".
			"#    Name                      \n";
		for (my $i = 0; $i < @itemsID; $i++) {
			next if ($itemsID[$i] eq "");
			my $display = $items{$itemsID[$i]}{'name'};
			$display .= " x $items{$itemsID[$i]}{'amount'}";
			System::message sprintf("%-4d %-60s\n",$i,$display);
		}
		System::message "-------------------------------\n";

	} elsif ($switch eq "im") {
		my ($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		my ($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)/;
		if ($arg1 eq "" || $arg2 eq "") {
			System::message "Syntax Error in function 'im' (Use Item on Monster)\n".
									   "Usage: im <item #> <monster #>\n";

		} elsif (!%{$chars[$config{'char'}]{'inventory'}[$arg1]}) {
			System::message "Error in function 'im' (Use Item on Monster)\n".
									   "Inventory Item $arg1 does not exist.\n";

		} elsif ($chars[$config{'char'}]{'inventory'}[$arg1]{'type'} > 2) {
			System::message "Error in function 'im' (Use Item on Monster)\n".
									   "Inventory Item $arg1 is not of type Usable.\n";

		} elsif ($monstersID[$arg2] eq "") {
			System::message "Error in function 'im' (Use Item on Monster)\n".
									   "Monster $arg2 does not exist.\n";

		} else {
			sendItemUse(\$System::remote_socket, $chars[$config{'char'}]{'inventory'}[$arg1]{'index'}, $monstersID[$arg2]);
		}

	} elsif ($switch eq "ip") {
		my ($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		my ($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)/;
		if ($arg1 eq "" || $arg2 eq "") {
			System::message "Syntax Error in function 'ip' (Use Item on Player)\n".
									   "Usage: ip <item #> <player #>\n";

		} elsif (!%{$chars[$config{'char'}]{'inventory'}[$arg1]}) {
			System::message "Error in function 'ip' (Use Item on Player)\n".
									   "Inventory Item $arg1 does not exist.\n";

		} elsif ($chars[$config{'char'}]{'inventory'}[$arg1]{'type'} > 2) {
			System::message "Error in function 'ip' (Use Item on Player)\n".
									   "Inventory Item $arg1 is not of type Usable.\n";

		} elsif ($playersID[$arg2] eq "") {
			System::message "Error in function 'ip' (Use Item on Player)\n".
									   "Player $arg2 does not exist.\n";

		} else {
			sendItemUse(\$System::remote_socket, $chars[$config{'char'}]{'inventory'}[$arg1]{'index'}, $playersID[$arg2]);
		}

	} elsif ($switch eq "is") {
		my ($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		if ($arg1 eq "") {
			System::message "Syntax Error in function 'is' (Use Item on Self)\n".
									   "Usage: is <item #>\n";

		} elsif (!%{$chars[$config{'char'}]{'inventory'}[$arg1]}) {
			System::message "Error in function 'is' (Use Item on Self)\n".
									   "Inventory Item $arg1 does not exist.\n";

		} elsif ($chars[$config{'char'}]{'inventory'}[$arg1]{'type'} > 2) {
			System::message "Error in function 'is' (Use Item on Self)\n".
									   "Inventory Item $arg1 is not of type Usable.\n";

		} else {
			sendItemUse(\$System::remote_socket, $chars[$config{'char'}]{'inventory'}[$arg1]{'index'}, $accountID);
		}

	} elsif ($switch eq "join") {
		my ($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		my ($arg2) = $input =~ /^[\s\S]*? \d+ ([\s\S]*)$/;
		if ($arg1 eq "") {
			System::message "Syntax Error in function 'join' (Join Chat Room)\n".
									   "Usage: join <chat room #> [<password>]\n";

		} elsif ($currentChatRoom ne "") {
			System::message "Error in function 'join' (Join Chat Room)\n".
									   "You are already in a chat room.\n";

		} elsif ($chatRoomsID[$arg1] eq "") {
			System::message "Error in function 'join' (Join Chat Room)\n".
									   "Chat Room $arg1 does not exist.\n";

		} else {
			sendChatRoomJoin(\$System::remote_socket, $chatRoomsID[$arg1], $arg2);
		}

	} elsif ($switch eq "judge") {
		my ($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		my ($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)/;
		if ($arg1 eq "" || $arg2 eq "") {
			System::message "Syntax Error in function 'judge' (Give an alignment point to Player)\n".
									   "Usage: judge <player #> <0 (good) | 1 (bad)>\n";

		} elsif ($playersID[$arg1] eq "") {
			System::message "Error in function 'judge' (Give an alignment point to Player)\n".
									   "Player $arg1 does not exist.\n";
		} else {
			$arg2 = ($arg2 >= 1);
			sendAlignment(\$System::remote_socket, $playersID[$arg1], $arg2);
		}

	} elsif ($switch eq "kick") {
		my ($arg1) = $input =~ /^[\s\S]*? ([\s\S]*)/;
		if ($currentChatRoom eq "") {
			System::message "Error in function 'kick' (Kick from Chat)\n".
									   "You are not in a Chat Room.\n";
		} elsif ($arg1 eq "") {
			System::message "Syntax Error in function 'kick' (Kick from Chat)\n".
									   "Usage: kick <user #>\n";
		} elsif ($currentChatRoomUsers[$arg1] eq "") {
			System::message "Error in function 'kick' (Kick from Chat)\n".
									   "Chat Room User $arg1 doesn't exist\n";
		} else {
			sendChatRoomKick(\$System::remote_socket, $currentChatRoomUsers[$arg1]);
		}

	} elsif ($switch eq "leave") {
		if ($currentChatRoom eq "") {
			System::message "Error in function 'leave' (Leave Chat Room)\n".
									   "You are not in a Chat Room.\n";
		} else {
			sendChatRoomLeave(\$System::remote_socket);
		}

# Def-Con LogView
	} elsif ($switch eq "log") {
		my ($arg1) = $input =~ /^[\s\S]*? (\w+)/;
		my $profile = $config{'username'};
		if ($arg1 eq "i" && -e "logs\/${profile}_Items.txt") {
			System::message "\n----------Items Log---------\n";
			my (@printItem, %sItem , $line,$tItem);
			open (TMPMONSTI, "logs\/${profile}_Items.txt"); 
			while ($line = <TMPMONSTI>) { 
				@printItem = split(/\n/, $line); 
				foreach $tItem (@printItem) {
					my ($data,$amount) = $tItem =~ /.+ : ([\s\S]*) x (\d+)/;
					$sItem{$data} += $amount;
				} 
			}
			foreach $tItem (sort keys %sItem) { 
				System::message sprintf("%-18s x %6d\n",$tItem,$sItem{$tItem});
			}
			close (TMPMONSTI); 
			System::message "-------------------------\n";
		} elsif ( $arg1 eq "m" && -e "logs\/${profile}_Monsters.txt") {
			my (@printMonster,%sMonster,$totalmon,$line,$tMonster);
			System::message "\n------Monster Log------\n"; 
			$totalmon=0;
			open (TMPMONSTI, "logs\/$config{profile}_Monsters.txt"); 
			while ($line = <TMPMONSTI>) { 
				@printMonster = split(/\n/, $line); 
				foreach $tMonster (@printMonster) {
					my ($data) = $tMonster =~ /.+ : ([\s\S]*)/;
					$sMonster{$data}++; 
					$totalmon++;
				} 
			} 
			foreach $tMonster (sort keys %sMonster) { 
				System::message sprintf("%-18s %6d\n",$tMonster,$sMonster{$tMonster});
			}
			close (TMPMONSTI); 
			System::message "-------------------------\n"; 
			System::message "Total :: $totalmon\n";
			System::message "-------------------------\n"; 

		} elsif ($arg1 eq "c") {
			System::clearLog();
			System::message "System log cleared.\n";

		} else {
			System::message "Error log file not found.\n";
			System::message "Syntax Error in function 'log' (Log Viewer)\n".
									   "Usage : log < i | m | c >\n";
		}

	} elsif ($switch eq "look") {
		my ($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		my ($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)$/;
		if ($arg1 eq "") {
			System::message "Syntax Error in function 'look' (Look a Direction)\n".
									   "Usage: look <body dir> [<head dir>]\n";

		} else {
			look($arg1, $arg2);
		}

	} elsif ($switch eq "memo") {
		sendMemo(\$System::remote_socket);

	} elsif ($switch eq "marker") {
		$marker = (!defined($marker) || !$marker) ? 1 : 0;
		System::message "Marker : ",($marker) ? "On" : "Off","\n";
		injectMessage("Marker : ".(($marker) ? "On" : "Off")) if ($config{'verbose'} && $System::xMode);

	} elsif ($switch eq "ml") {
		System::message "-----------Monster List ( Coordinate : $chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'} ) -----------\n".
								   "#    Name                     DmgTo    DmgFrom     (x,y)\n";
		for (my $i = 0; $i < @monstersID; $i++) {
			next if ($monstersID[$i] eq "");
			my $dmgTo = ($monsters{$monstersID[$i]}{'dmgTo'} ne "") ? $monsters{$monstersID[$i]}{'dmgTo'} : 0;
			my $dmgFrom = ($monsters{$monstersID[$i]}{'dmgFrom'} ne "") ? $monsters{$monstersID[$i]}{'dmgFrom'} : 0;
			my $type = "($monsters{$monstersID[$i]}{'pos_to'}{'x'},$monsters{$monstersID[$i]}{'pos_to'}{'y'})";
			System::message sprintf("%-4d %-24s %-5d    %-5d    %-11s\n",$i,$monsters{$monstersID[$i]}{'name'},$dmgTo,$dmgFrom,$type);
		}
		System::message "-------------------------------------------------------------\n";

	} elsif ($switch eq "move") {
		my ($arg1, $arg2, $arg3) = $input =~ /^[\s\S]*? (\d+) (\d+)(.*?)$/;
		
		undef $ai_v{'temp'}{'map'};
		if ($arg1 eq "") {
			($ai_v{'temp'}{'map'}) = $input =~ /^[\s\S]*? (.*?)$/;
		} else {
			$ai_v{'temp'}{'map'} = $arg3;
		}
		$ai_v{'temp'}{'map'} =~ s/\s//g;
		if (($arg1 eq "" || $arg2 eq "") && !$ai_v{'temp'}{'map'}) {
			System::message "Syntax Error in function 'move' (Move Player)\n".
									   "Usage: move <x> <y> &| <map>\n";
		} elsif ($ai_v{'temp'}{'map'} eq "stop") {
			aiRemove("move");
			aiRemove("route");
			aiRemove("route_getRoute");
			aiRemove("route_getMapRoute");
			System::message "Stopped all movement\n";
		} else {
			$ai_v{'temp'}{'map'} = $field{'name'} if ($ai_v{'temp'}{'map'} eq "");
			if ($maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}) {
				if ($arg2 ne "") {
					System::message "Calculating route to: $maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}($ai_v{'temp'}{'map'}): $arg1, $arg2\n","route";
					$ai_v{'temp'}{'x'} = $arg1;
					$ai_v{'temp'}{'y'} = $arg2;
				} else {
					System::message "Calculating route to: $maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}($ai_v{'temp'}{'map'})\n","route";
					undef $ai_v{'temp'}{'x'};
					undef $ai_v{'temp'}{'y'};
				}
				ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'x'}, $ai_v{'temp'}{'y'}, $ai_v{'temp'}{'map'}, 0, 0, 1, 0, 0, 1);
			} else {
				System::message "Map $ai_v{'temp'}{'map'} does not exist\n";
			}
		}

	} elsif ($switch eq "nl") {
		System::message "-----------NPC List-----------\n".
								   "#    Name                         Coordinates\n";
		for (my $i = 0; $i < @npcsID; $i++) {
			next if ($npcsID[$i] eq "");
			$ai_v{'temp'}{'pos_string'} = "($npcs{$npcsID[$i]}{'pos'}{'x'}, $npcs{$npcsID[$i]}{'pos'}{'y'})";
			System::message sprintf("%-4d %-28s %-11s   %-10d\n",$i,$npcs{$npcsID[$i]}{'name'},$ai_v{'temp'}{'pos_string'},$npcs{$npcsID[$i]}{'nameID'});
		}
		System::message "---------------------------------\n";

	} elsif ($switch eq "p") {
		my ($arg1) = $input =~ /^[\s\S]*? ([\s\S]*)/;
		if ($arg1 eq "") {
			System::message "Syntax Error in function 'p' (Party Chat)\n".
									   "Usage: p <message>\n";
		} else {
			sendMessage(\$System::remote_socket, "p", $arg1);
		}

	} elsif ($switch eq "party") {
		my ($arg1) = $input =~ /^[\s\S]*? (\w*)/;
		my ($arg2) = $input =~ /^[\s\S]*? [\s\S]*? (\d+)\b/;
		if ($arg1 eq "" && !%{$chars[$config{'char'}]{'party'}}) {
			System::message "Error in function 'party' (Party Functions)\n".
									   "Can't list party - you're not in a party.\n";

		} elsif ($arg1 eq "") {
			System::message "----------Party-----------\n";
			System::message $chars[$config{'char'}]{'party'}{'name'}."\n";
			System::message "#      Name                  Map                    Online    HP\n";
			for (my $i = 0; $i < @partyUsersID; $i++) {
				next if ($partyUsersID[$i] eq "");
				my $coord_string = "";
				my $hp_string = "";
				my $name_string = $chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'name'};
				my $admin_string = ($chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'admin'}) ? "(A)" : "";
				my ($online_string,$map_string);
				if ($partyUsersID[$i] eq $accountID) {
					$online_string = "Yes";
					($map_string) = $map_name =~ /([\s\S]*)\.gat/;
					$coord_string = $chars[$config{'char'}]{'pos'}{'x'}. ", ".$chars[$config{'char'}]{'pos'}{'y'};
					$hp_string = $chars[$config{'char'}]{'hp'}."/".$chars[$config{'char'}]{'hp_max'}
							." (".int($chars[$config{'char'}]{'hp'}/$chars[$config{'char'}]{'hp_max'} * 100)
							."%)";
				} else {
					$online_string = ($chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'online'}) ? "Yes" : "No";
					($map_string) = $chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'map'} =~ /([\s\S]*)\.gat/;
					$coord_string = $chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'pos'}{'x'}
						. ", ".$chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'pos'}{'y'}
						if ($chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'pos'}{'x'} ne ""
							&& $chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'online'});
					$hp_string = $chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'hp'}."/".$chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'hp_max'}
							." (".int($chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'hp'}/$chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'hp_max'} * 100)
							."%)" if ($chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'hp_max'} && $chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'online'});
				}
				System::message sprintf("%2d %-3s %-21s %-13s %-8s %-3s       %-19s\n",$i,$admin_string,$name_string,$map_string,$coord_string,$online_string,$hp_string);
			}
			System::message "--------------------------\n";
			
		} elsif ($arg1 eq "create") {
			my ($arg2) = $input =~ /^[\s\S]*? [\s\S]*? \"([\s\S]*?)\"/;
			if ($arg2 eq "") {
				System::message "Syntax Error in function 'party create' (Organize Party)\n".
										   "Usage: party create \"<party name>\"\n";
			} else {
				sendPartyOrganize(\$System::remote_socket, $arg2);
			}

		} elsif ($arg1 eq "join" && $arg2 ne "1" && $arg2 ne "0") {
			System::message "Syntax Error in function 'party join' (Accept/Deny Party Join Request)\n".
									   "Usage: party join <flag>\n";

		} elsif ($arg1 eq "join" && $incomingParty{'ID'} eq "") {
			System::message "Error in function 'party join' (Join/Request to Join Party)\n".
									   "Can't accept/deny party request - no incoming request.\n";

		} elsif ($arg1 eq "join") {
			sendPartyJoin(\$System::remote_socket, $incomingParty{'ID'}, $arg2);
			undef %incomingParty;

		} elsif ($arg1 eq "request" && !%{$chars[$config{'char'}]{'party'}}) {
			System::message "Error in function 'party request' (Request to Join Party)\n".
									   "Can't request a join - you're not in a party.\n";

		} elsif ($arg1 eq "request" && $playersID[$arg2] eq "") {
			System::message "Error in function 'party request' (Request to Join Party)\n".
									   "Can't request to join party - player $arg2 does not exist.\n";

		} elsif ($arg1 eq "request") {
			sendPartyJoinRequest(\$System::remote_socket, $playersID[$arg2]);


		} elsif ($arg1 eq "leave" && !%{$chars[$config{'char'}]{'party'}}) {
			System::message "Error in function 'party leave' (Leave Party)\n".
									   "Can't leave party - you're not in a party.\n";

		} elsif ($arg1 eq "leave") {
			sendPartyLeave(\$System::remote_socket);


		} elsif ($arg1 eq "share" && !%{$chars[$config{'char'}]{'party'}}) {
			System::message "Error in function 'party share' (Set Party Share EXP)\n".
									   "Can't set share - you're not in a party.\n";

		} elsif ($arg1 eq "share" && $arg2 ne "1" && $arg2 ne "0") {
			System::message "Syntax Error in function 'party share' (Set Party Share EXP)\n".
									   "Usage: party share <flag>\n";

		} elsif ($arg1 eq "share") {
			sendPartyShareEXP(\$System::remote_socket, $arg2);


		} elsif ($arg1 eq "kick" && !%{$chars[$config{'char'}]{'party'}}) {
			System::message "Error in function 'party kick' (Kick Party Member)\n".
									   "Can't kick member - you're not in a party.\n";

		} elsif ($arg1 eq "kick" && $arg2 eq "") {
			System::message "Syntax Error in function 'party kick' (Kick Party Member)\n".
									   "Usage: party kick <party member #>\n";

		} elsif ($arg1 eq "kick" && $partyUsersID[$arg2] eq "") {
			System::message "Error in function 'party kick' (Kick Party Member)\n".
									   "Can't kick member - member $arg2 doesn't exist.\n";

		} elsif ($arg1 eq "kick") {
			sendPartyKick(\$System::remote_socket, $partyUsersID[$arg2]
					,$chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$arg2]}{'name'});

		}
#mod Start
# Pet Function Add-on
	} elsif ($switch eq "pet") {
		my ($arg1) = $input =~ /^[\s\S]*? (\w+)/;
		if ( $arg1 eq "info" || $arg1 eq "") {
			System::message "----- Pet Info -----\n";
			System::message sprintf("Pet Name : %-10s    Pet Lv : %-2d\n",$chars[$config{'char'}]{'pet'}{'name'},$chars[$config{'char'}]{'pet'}{'level'});
			System::message sprintf("Pet Hungry : %-10d  Pet Relation : %-4d\n",$chars[$config{'char'}]{'pet'}{'hungry'},$chars[$config{'char'}]{'pet'}{'friendly'});
			System::message "--------------------\n";

		}elsif ( $arg1 eq "feed"){
			my $petfood = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{'petAutoFood'});
			if ($petfood ne ""){
				sendPetCommand(\$System::remote_socket,1);
				System::message " You're feeding your pet \n";
			}else{
				System::message "You can't give : ".$config{'petAutoFood'}."\n";
			}

		}elsif ( $arg1 eq "play"){
			sendPetCommand(\$System::remote_socket,2);
			System::message " You're Playing your pet \n";

		}elsif ( $arg1 eq "back"){
			sendPetCommand(\$System::remote_socket,3);
			System::message " Your pet turning to Eggs\n";

		}else{
			System::message "Syntax Error in function 'pet' ( Q'pet command )\n".
									   "Usage : pet < info | feed | play | back >";
		}
#mod Stop
	} elsif ($switch eq "petl") {
		System::message "-----------Pet List-----------\n".
								   "#    Type                     Name\n";
		for (my $i = 0; $i < @petsID; $i++) {
			next if ($petsID[$i] eq "");
			System::message sprintf("%-4d %-24s %s\n",$i,$pets{$petsID[$i]}{'name'},$pets{$petsID[$i]}{'name_given'});
		}
		System::message "----------------------------------\n";

	} elsif ($switch eq "potion"){
		my ($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		if ($arg1 eq "") {
			System::message "-------Potion Making List------\n";
			for ($i = 0; $i < @pharmacyID; $i++) {
				next if ($pharmacyID[$i] eq "");
				System::message sprintf("%2d %s\n",$i, $items_lut{$pharmacyID[$i]});
			}
			System::message "-------------------------------\n";
		} elsif ($arg1 =~ /\d+/ && $pharmacyID[$arg1] eq "") {
			System::message "Error in function 'potion' (Make Potion)\n".
									   "Potion making option #$arg1 does not exist\n";
		} elsif ($arg1 =~ /\d+/) {
			sendPharmacy(\$System::remote_socket, $pharmacyID[$arg1]);
			undef @pharmacyID;
		} else {
			System::message "Syntax Error in function 'potion' (Make Potion)\n".
									   "Usage: potion [<potion #>]\n";
		}

	} elsif ($switch eq "pm") {
		my ($arg1, $arg2) =$input =~ /^[\s\S]*? "([\s\S]*?)" ([\s\S]*)/;
		my $type = 0;
		if (!$arg1) {
			($arg1, $arg2) =$input =~ /^[\s\S]*? (\d+) ([\s\S]*)/;
			$type = 1;
		}
		if ($arg1 eq "" || $arg2 eq "") {
			System::message "Syntax Error in function 'pm' (Private Message)\n".
									   "Usage: pm (\"<username>\" | <pm #>) <message>\n";
		} elsif ($type) {
			if ($arg1 - 1 >= @privMsgUsers) {
				System::message "Error in function 'pm' (Private Message)\n".
										   "Quick look-up $arg1 does not exist\n";

			} else {
				sendMessage(\$System::remote_socket, "pm", $arg2, $privMsgUsers[$arg1 - 1]);
				$lastpm{'msg'} = $arg2;
				$lastpm{'user'} = $privMsgUsers[$arg1 - 1];
			}
		} else {
			if ($arg1 =~ /^%(\d*)$/) {
				$arg1 = $1;
			}
#pml bugfix - chobit andy 20030127
			if (binFind(\@privMsgUsers, $arg1) eq "") {
				$privMsgUsers[@privMsgUsers] = $arg1;
			}
			sendMessage(\$System::remote_socket, "pm", $arg2, $arg1);
			$lastpm{'msg'} = $arg2;
			$lastpm{'user'} = $arg1;
		}

	} elsif ($switch eq "pml") {
		System::message "-----------PM LIST-----------\n";
		for (my $i = 1; $i <= @privMsgUsers; $i++) {
			System::message sprintf("%-4d %-24s\n",$i,$privMsgUsers[$i - 1]);
		}
		System::message "-----------------------------\n";


	} elsif ($switch eq "pl") {
		System::message "-----------Player List ( Coordinate : $chars[$config{'char'}]{'pos_to'}{'x'},$chars[$config{'char'}]{'pos_to'}{'y'} ) -----------\n".
								   "#    Name                                 Sex   Job      (x,y)\n";
		for (my $i = 0; $i < @playersID; $i++) {
			next if ($playersID[$i] eq "");
			my ($name,$type);
			if (%{$players{$playersID[$i]}{'guild'}}) {
				$name = "$players{$playersID[$i]}{'name'} [$players{$playersID[$i]}{'guild'}{'name'}]";
			} else {
				$name = $players{$playersID[$i]}{'name'};
			}
			$type = "($players{$playersID[$i]}{'pos_to'}{'x'}, $players{$playersID[$i]}{'pos_to'}{'y'})";
			System::message sprintf("%-4d %-36s %-5s %-8s %-10s\n",$i,$name,$sex_lut[$players{$playersID[$i]}{'sex'}],$jobs_lut{$players{$playersID[$i]}{'jobID'}},$type);
		}
		System::message "------------------------------------------------------------\n";

	} elsif ($switch eq "portals") {
		System::message "-----------Portal List-----------\n"
			,"#    Name                                Coordinates\n";
		for (my $i = 0; $i < @portalsID; $i++) {
			next if ($portalsID[$i] eq "");
			my $coords = "($portals{$portalsID[$i]}{'pos'}{'x'},$portals{$portalsID[$i]}{'pos'}{'y'})";
			System::message sprintf("%-4d %-35s %-10s\n",$i,$portals{$portalsID[$i]}{'name'},$coords);
		}
		System::message "---------------------------------\n";

	} elsif ($switch eq "quit" || $switch eq "exit") {
		quit();

	} elsif ($switch eq "rc") {
		($args) = $input =~ /^[\s\S]*? ([\s\S]*)/;
		$args = ($args eq "") ? "miscFunctions.pl" : $args;
		my $ok = 1;
		if (! -f "$args") {
			$ok = 0;
			System::message "Unable to reload code: $args does not exist\n";
		} elsif (-f $Config{'perlpath'}) {
			$ok = 0;
			System::message "Checking $args for errors...\n";
			system($Config{'perlpath'}, '-c', $args);
			if ($? == -1) {
				System::message "Error: failed to execute $Config{'perlpath'}\n";
			} elsif ($? & 127) {
				System::message "Error: $Config{'perlpath'} exited abnormally\n";
			} elsif (($? >> 8) == 0) {
				System::message "$args passed syntax check.\n";
				$ok = 1;
			} else {
				System::message "Error: $args contains syntax errors.\n";
			}
		}
		if ($ok) {
			System::message "Reloading $args...";
			if (!do $args || $@) {
				System::message "Unable to reload $args\n";
				System::message "$@\n"if ($@);
			}else{
				System::message "Done\n";
			}
		}

	} elsif ($switch eq "reload") {
		my ($arg1) = $input =~ /^[\s\S]*? ([\s\S]*)/;
		if (FileParser::parseReload($arg1)) {
			Plugins::callHook('postloadfiles');
		}

	} elsif ($switch eq "relog") {
		relog();

#remaining time improve by BowJung
	} elsif ($switch eq "remain") {
		my ($Remain,$endTime_EXP,$w_hour,$w_min,$w_sec,$r_day,$r_hour,$r_min,$r_sec);
		$endTime_EXP = time;
		$w_sec = int($endTime_EXP - $startTime_EXP);
		$w_hour = $w_min = 0;
		if ($w_sec >= 3600) { 
			$w_hour = int($w_sec / 3600); 
			$w_sec %= 3600; 
		}
		if ($w_sec >= 60) { 
			$w_min = int($w_sec / 60); 
			$w_sec %= 60; 
		}
		$Remain = int(($chars[$config{'char'}]{'Airtime'}{'day'}*86400)+($chars[$config{'char'}]{'Airtime'}{'hour'}*3600)+($chars[$config{'char'}]{'Airtime'}{'minute'}*60));
		$r_sec = int($Remain - $w_sec);
			$r_day = $r_hour = $r_min = 0;
			if ($r_sec >= 86400) { 
				$r_day = int($r_sec / 86400); 
				$r_sec %= 86400; 
			}
			if ($r_sec >= 3600) { 
				$r_hour = int($r_sec / 3600); 
				$r_sec %= 3600; 
			}
			if ($r_sec >= 60) { 
				$r_min = int($r_sec / 60); 
				$r_sec %= 60; 
			}			
		System::message "----------- Airtime Remaining -----------\n";
		#print sprintf("Day: %-3d Hour: %-3d Minutes: %-3d\n",$chars[$config{'char'}]{'Airtime'}{'day'},$chars[$config{'char'}]{'Airtime'}{'hour'},$chars[$config{'char'}]{'Airtime'}{'minute'});
		System::message sprintf("Login at: %-30s\n",$chars[$config{'char'}]{'Airtime'}{'loginat'});
		System::message "Botting time : $w_hour Hours $w_min Minutes $w_sec Seconds\n";
		System::message "Now Remain : $r_day Days $r_hour Hours $r_min Minutes $r_sec Seconds\n";
		System::message "-----------------------------------------\n";

	} elsif ($switch eq "respawn") {
		useTeleport(2);
# Force StorageAuto & SellAuto
		if ($config{'storageAuto'}) {
			shift @ai_seq;
			shift @ai_seq_args;
			unshift @ai_seq, "storageAuto";
			unshift @ai_seq_args, {};
		}elsif ($config{'sellAuto'}){
			shift @ai_seq;
			shift @ai_seq_args;
			unshift @ai_seq, "sellAuto";
			unshift @ai_seq_args, {};
		}

	} elsif ($switch eq "s") {
		my ($id,$baseEXPKill,$jobEXPKill,$hp_string, $sp_string, $base_string, $job_string, $weight_string, $job_name_string, $zeny_string);
		if ($chars[$config{'char'}]{'exp_last'} > $chars[$config{'char'}]{'exp'}) {
			$baseEXPKill = $chars[$config{'char'}]{'exp_max_last'} - $chars[$config{'char'}]{'exp_last'} + $chars[$config{'char'}]{'exp'};
		} elsif ($chars[$config{'char'}]{'exp_last'} == 0 && $chars[$config{'char'}]{'exp_max_last'} == 0) {
			$baseEXPKill = 0;
		} else {
			$baseEXPKill = $chars[$config{'char'}]{'exp'} - $chars[$config{'char'}]{'exp_last'};
		}
		if ($chars[$config{'char'}]{'exp_job_last'} > $chars[$config{'char'}]{'exp_job'}) {
			$jobEXPKill = $chars[$config{'char'}]{'exp_job_max_last'} - $chars[$config{'char'}]{'exp_job_last'} + $chars[$config{'char'}]{'exp_job'};
		} elsif ($chars[$config{'char'}]{'exp_job_last'} == 0 && $chars[$config{'char'}]{'exp_job_max_last'} == 0) {
			$jobEXPKill = 0;
		} else {
			$jobEXPKill = $chars[$config{'char'}]{'exp_job'} - $chars[$config{'char'}]{'exp_job_last'};
		}
		$hp_string = $chars[$config{'char'}]{'hp'}."/".$chars[$config{'char'}]{'hp_max'}
						   ." (".$chars[$config{'char'}]{'percent_hp'}."%)";
		$sp_string = $chars[$config{'char'}]{'sp'}."/".$chars[$config{'char'}]{'sp_max'}
						   ." (".$chars[$config{'char'}]{'percent_sp'}."%)";
		$base_string = $chars[$config{'char'}]{'exp'}."/".$chars[$config{'char'}]{'exp_max'}." /$baseEXPKill ("
				.sprintf("%.2f",$chars[$config{'char'}]{'exp'}/$chars[$config{'char'}]{'exp_max'} * 100)
				."%)" if $chars[$config{'char'}]{'exp_max'};
		$job_string = $chars[$config{'char'}]{'exp_job'}."/".$chars[$config{'char'}]{'exp_job_max'}." /$jobEXPKill ("
				.sprintf("%.2f",$chars[$config{'char'}]{'exp_job'}/$chars[$config{'char'}]{'exp_job_max'} * 100)
				."%)" if $chars[$config{'char'}]{'exp_job_max'};
		$weight_string = $chars[$config{'char'}]{'weight'}."/".$chars[$config{'char'}]{'weight_max'}
								 ." (".$chars[$config{'char'}]{'percent_weight'}."%)";
		$job_name_string = "$jobs_lut{$chars[$config{'char'}]{'jobID'}} $sex_lut[$chars[$config{'char'}]{'sex'}]";
		$id = unpack("L1",$accountID);
		System::message "----------- Status ( GID: ".$id." ) --------\n";
		System::message sprintf("%-25s HP: %-20s\n",$chars[$config{'char'}]{'name'},$hp_string);
		System::message sprintf("%-25s SP: %-20s\n",$job_name_string,$sp_string);
		System::message sprintf("Base: %-3d %-35s\n",$chars[$config{'char'}]{'lv'},$base_string);
		System::message sprintf("Job:  %-3d %-35s\n",$chars[$config{'char'}]{'lv_job'},$job_string);
		System::message sprintf("Weight: %-17s Zenny: %-15s\n",$weight_string,$chars[$config{'char'}]{'zenny'});
		System::message "Status: @skillsST\n";
		System::message "-------------------------------------"."-" x length($id)."\n";


	} elsif ($switch eq "sell") {
		my ($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		my ($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)$/;
		if ($arg1 eq "" && $talk{'buyOrSell'}) {
			sendGetSellList(\$System::remote_socket, $talk{'ID'});

		} elsif ($arg1 eq "") {
			System::message "Syntax Error in function 'sell' (Sell Inventory Item)\n".
									   "Usage: sell <item #> [<amount>]\n";

		} elsif (!%{$chars[$config{'char'}]{'inventory'}[$arg1]}) {
			System::message "Error in function 'sell' (Sell Inventory Item)\n".
									   "Inventory Item $arg1 does not exist.\n";

		} else {
			if (!$arg2 || $arg2 > $chars[$config{'char'}]{'inventory'}[$arg1]{'amount'}) {
				$arg2 = $chars[$config{'char'}]{'inventory'}[$arg1]{'amount'};
			}
			sendSell(\$System::remote_socket, $chars[$config{'char'}]{'inventory'}[$arg1]{'index'}, $arg2);
		}

	} elsif ($switch eq "send") {
		my ($args) = $input =~ /^[\s\S]*? ([\s\S]*)/;
		sendRaw(\$System::remote_socket, $args);

	} elsif ($switch eq "sit") {
		$ai_v{'attackAuto_old'} = $config{'attackAuto'};
		$ai_v{'route_randomWalk_old'} = $config{'route_randomWalk'};
		$ai_v{'teleportAuto_idle_old'} = $config{'teleportAuto_idle'};
		configModify("attackAuto", 1);
		configModify("route_randomWalk", 0);
		configModify("teleportAuto_idle", 0);
		aiRemove("move");
		aiRemove("route");
		aiRemove("route_getRoute");
		aiRemove("route_getMapRoute");
		sit();
		$ai_v{'sitAuto_forceStop'} = 0;

	} elsif ($switch eq "sm") {
		my ($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		my ($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)/;
		my ($arg3) = $input =~ /^[\s\S]*? \d+ \d+ (\d+)/;
		if ($arg1 eq "" || $arg2 eq "") {
			System::message "Syntax Error in function 'sm' (Use Skill on Monster)\n".
									   "Usage: sm <skill #> <monster #> [<skill lvl>]\n";

		} elsif ($monstersID[$arg2] eq "") {
			System::message "Error in function 'sm' (Use Skill on Monster)\n".
									   "Monster $arg2 does not exist.\n";

		} elsif ($skillsID[$arg1] eq "") {
			System::message "Error in function 'sm' (Use Skill on Monster)\n".
									   "Skill $arg1 does not exist.\n";

		} else {
			if (!$arg3 || $arg3 > $chars[$config{'char'}]{'skills'}{$skillsID[$arg1]}{'lv'}) {
				$arg3 = $chars[$config{'char'}]{'skills'}{$skillsID[$arg1]}{'lv'};
			}
			if (!ai_getSkillUseType($skillsID[$arg1])) {
				ai_skillUse($chars[$config{'char'}]{'skills'}{$skillsID[$arg1]}{'ID'}, $arg3, 0,0, $monstersID[$arg2]);
			} else {
				ai_skillUse($chars[$config{'char'}]{'skills'}{$skillsID[$arg1]}{'ID'}, $arg3, 0,0, $monsters{$monstersID[$arg2]}{'pos_to'}{'x'}, $monsters{$monstersID[$arg2]}{'pos_to'}{'y'});
			}
		}
	} elsif ($switch eq "shop"){
		my ($arg1) = $input =~ /^[\s\S]*? (\w+)/;
		if ($arg1 eq "" || $arg1 eq "info") {
			if ($ai_v{'temp'}{'shopOpen'}){
				System::message "---------- $shop{'shop_title'} -------------\n"; 
				System::message "#  Name                          Type     Amount      Price\n";
				for (my $i = 0; $i < @articles; $i++) {
					next if ($articles[$i] eq "");
					System::message sprintf("%-2d %-29s %-8s %-6s %-10s z\n",$i,$articles[$i]{'name'},$itemTypes_lut{$articles[$i]{'type'}},$articles[$i]{'amount'},$articles[$i]{'price'});
				}
				System::message "-------------------------"."-"x length($shop{'shop_title'})."\n"; 
				System::message "You have earned : $shop{'earned'}z.\n";
				System::message "-------------------------"."-"x length($shop{'shop_title'})."\n"; 
			}else{
				System::message "Your Shop Status : Closed\n";
			}
		}elsif ($arg1 eq "open"){
			if (!$ai_v{'temp'}{'shopOpen'}){
				openShop(\$System::remote_socket);
			}else{
				System::message "Error: a shop has already been opened.\n";
			}
		}elsif ($arg1 eq "close"){
			sendcloseShop(\$System::remote_socket);
			System::message "Closing Your Shop \n";
			$ai_v{'temp'}{'shopOpen'} = 0;
		}else {
			System::message "Syntax Error in function 'shop' (Show Shop Detail)\n".
									   "Usage: shop [<info|open|close>]\n";
		}
	} elsif ($switch eq "skills") {
		my ($arg1) = $input =~ /^[\s\S]*? (\w+)/;
		my ($arg2) = $input =~ /^[\s\S]*? \w+ (\d+)/;
		if ($arg1 eq "") {
			System::message "----------Skill List-----------\n";
			System::message "#  Skill Name                    Lv     SP\n";
			for (my $i=0; $i < @skillsID; $i++) {
				System::message sprintf("%-2d %-28s %3s   %4s\n",$i,$skills_lut{$skillsID[$i]},$chars[$config{'char'}]{'skills'}{$skillsID[$i]}{'lv'},$skillsSP_lut{$skillsID[$i]}{$chars[$config{'char'}]{'skills'}{$skillsID[$i]}{'lv'}});
			}
			System::message "\nSkill Points: $chars[$config{'char'}]{'points_skill'}\n";
			System::message "-------------------------------\n";


		} elsif ($arg1 eq "add" && $arg2 =~ /\d+/ && $skillsID[$arg2] eq "") {
			System::message "Error in function 'skills add' (Add Skill Point)\n".
									   "Skill $arg2 does not exist.\n";

		} elsif ($arg1 eq "add" && $arg2 =~ /\d+/ && $chars[$config{'char'}]{'points_skill'} < 1) {
			System::message "Error in function 'skills add' (Add Skill Point)\n".
									   "Not enough skill points to increase $skills_lut{$skillsID[$arg2]}.\n";

		} elsif ($arg1 eq "add" && $arg2 =~ /\d+/) {
			sendAddSkillPoint(\$System::remote_socket, $chars[$config{'char'}]{'skills'}{$skillsID[$arg2]}{'ID'});
		} else {
			System::message "Syntax Error in function 'skills' (Skills Functions)\n".
									   "Usage: skills [<add>] [<skill #>]\n";
		}

	} elsif ($switch eq "sl") {
		my ($skill_num,$x,$y,$lvl) = $input =~ /^[\s\S]*? (\d+) (\d+) (\d+) (\d+)/;
		if (!$skill_num) {
			System::message "Syntax Error in function 'sl' (Use Skill on Location)\n".
									   "Usage: sl <skill #> <x> <y> [<skill lvl>]\n";

		} elsif (!ai_getSkillUseType($skillsID[$skill_num]) || $skillsID[$skill_num] eq "") {
			System::message "Error in function 'sl' (Use Skill on Location)\n".
									   "Skill $skill_num does not exist.\n";

		}elsif (!$x || !$y){
			System::message "Error in function 'sl' (Use Skill on Location)\n".
									   "Skill Position does not exist.\n";

		} else {
			my $skill = $chars[$config{'char'}]{'skills'}{$skillsID[$skill_num]};
			if (!$lvl || $lvl > $skill->{'lv'}) {
				$lvl = $skill->{'lv'};
			}
			ai_skillUse($skill->{'ID'}, $lvl, 0, 0, $x, $y);
		}

	} elsif ($switch eq "sp") {
		my ($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		my ($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)/;
		my ($arg3) = $input =~ /^[\s\S]*? \d+ \d+ (\d+)/;
		if ($arg1 eq "" || $arg2 eq "") {
			System::message "Syntax Error in function 'sp' (Use Skill on Player)\n".
									   "Usage: sp <skill #> <player #> [<skill lvl>]\n";

		} elsif ($playersID[$arg2] eq "") {
			System::message "Error in function 'sp' (Use Skill on Player)\n".
									   "Player $arg2 does not exist.\n";

		} elsif ($skillsID[$arg1] eq "") {
			System::message "Error in function 'sp' (Use Skill on Player)\n".
									   "Skill $arg1 does not exist.\n";

		} else {
			if (!$arg3 || $arg3 > $chars[$config{'char'}]{'skills'}{$skillsID[$arg1]}{'lv'}) {
				$arg3 = $chars[$config{'char'}]{'skills'}{$skillsID[$arg1]}{'lv'};
			}
			if (!ai_getSkillUseType($skillsID[$arg1])) {
				ai_skillUse($chars[$config{'char'}]{'skills'}{$skillsID[$arg1]}{'ID'}, $arg3, 0,0, $playersID[$arg2]);
			} else {
				ai_skillUse($chars[$config{'char'}]{'skills'}{$skillsID[$arg1]}{'ID'}, $arg3, 0,0, $players{$playersID[$arg2]}{'pos_to'}{'x'}, $players{$playersID[$arg2]}{'pos_to'}{'y'});
			}
		}

	} elsif ($switch eq "spell") {
		my ($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		if ($arg1 eq "") {
			System::message "-------Auto Casting List------\n";
			for ($i = 0; $i < @autospellID; $i++) {
				next if ($autospellID[$i] eq "");
				System::message sprintf("%-4d %-60s\n",$i,$skillsID_lut{$autospellID[$i]});
			}
			System::message	"------------------------------\n";
		} elsif ($arg1 =~ /\d+/ && $autospellID[$arg1] eq "") {
			System::message "Error in function 'spell' (Auto Spell Cast)\n".
					"Auto casting option #$arg1 does not exist\n";
		} elsif ($arg1 =~ /\d+/) {
			sendAutospell(\$remote_socket, $autospellID[$arg1]);
		} else {
			System::message "Syntax Error in function 'spell' (Auto Spell Cast)\n".
					"Usage: spell [<autospell #>]\n";
		}

	} elsif ($switch eq "ss") {
		my ($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		my ($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)/;
		if ($arg1 eq "") {
			System::message "Syntax Error in function 'ss' (Use Skill on Self)\n".
									   "Usage: ss <skill #> [<skill lvl>]\n";

		} elsif ($skillsID[$arg1] eq "") {
			System::message "Error in function 'ss' (Use Skill on Self)\n".
									   "Skill $arg1 does not exist.\n";

		} else {
			if (!$arg2 || $arg2 > $chars[$config{'char'}]{'skills'}{$skillsID[$arg1]}{'lv'}) {
				$arg2 = $chars[$config{'char'}]{'skills'}{$skillsID[$arg1]}{'lv'};
			}
			if (!ai_getSkillUseType($skillsID[$arg1])) {
				ai_skillUse($chars[$config{'char'}]{'skills'}{$skillsID[$arg1]}{'ID'}, $arg2, 0,0, $accountID);
			} else {
				ai_skillUse($chars[$config{'char'}]{'skills'}{$skillsID[$arg1]}{'ID'}, $arg2, 0,0, $chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'});
			}
		}

	} elsif ($switch eq "st") {
		System::message "----------- Char Stats -----------\n";
		my $tilde = "~";
		System::message sprintf("Str: %3d+%3d #%2d Atk:  %3d+%3d Def:  %3d+%3d\n",$chars[$config{'char'}]{'str'},$chars[$config{'char'}]{'str_bonus'},$chars[$config{'char'}]{'points_str'},$chars[$config{'char'}]{'attack'},$chars[$config{'char'}]{'attack_bonus'},$chars[$config{'char'}]{'def'},$chars[$config{'char'}]{'def_bonus'});
		System::message sprintf("Agi: %3d+%3d #%2d Matk: %3d%s%3d Mdef: %3d+%3d\n",$chars[$config{'char'}]{'agi'},$chars[$config{'char'}]{'agi_bonus'},$chars[$config{'char'}]{'points_agi'},$chars[$config{'char'}]{'attack_magic_min'},$tilde,$chars[$config{'char'}]{'attack_magic_max'},$chars[$config{'char'}]{'def_magic'},$chars[$config{'char'}]{'def_magic_bonus'});
		System::message sprintf("Vit: %3d+%3d #%2d Hit:  %3d     Flee: %3d+%3d\n",$chars[$config{'char'}]{'vit'},$chars[$config{'char'}]{'vit_bonus'},$chars[$config{'char'}]{'points_vit'},$chars[$config{'char'}]{'hit'},$chars[$config{'char'}]{'flee'},$chars[$config{'char'}]{'flee_bonus'});
		System::message sprintf("Int: %3d+%3d #%2d Critical: %3d Aspd: %3d\n",$chars[$config{'char'}]{'int'},$chars[$config{'char'}]{'int_bonus'},$chars[$config{'char'}]{'points_int'},$chars[$config{'char'}]{'critical'},$chars[$config{'char'}]{'attack_speed'});
		System::message sprintf("Dex: %3d+%3d #%2d Status Points: %3d\n",$chars[$config{'char'}]{'dex'},$chars[$config{'char'}]{'dex_bonus'},$chars[$config{'char'}]{'points_dex'},$chars[$config{'char'}]{'points_free'});
		System::message sprintf("Luk: %3d+%3d #%2d Guild: %-25s\n",$chars[$config{'char'}]{'luk'},$chars[$config{'char'}]{'luk_bonus'},$chars[$config{'char'}]{'points_luk'},$chars[$config{'char'}]{'guild'}{'name'});
		System::message "----------------------------------\n";

	} elsif ($switch eq "stand") {
		if ($ai_v{'attackAuto_old'} ne "") {
			configModify("attackAuto", $ai_v{'attackAuto_old'});
			configModify("route_randomWalk", $ai_v{'route_randomWalk_old'});
			configModify("teleportAuto_idle", $ai_v{'teleportAuto_idle_old'});
			undef $ai_v{'attackAuto_old'};
			undef $ai_v{'route_randomWalk_old'};
			undef $ai_v{'teleportAuto_idle_old'};
		}
		stand();
		$ai_v{'sitAuto_forceStop'} = 1;

	} elsif ($switch eq "stat_add") {
		my ($arg1) = $input =~ /^[\s\S]*? ([\s\S]*)$/;
		if ($arg1 ne "str" &&  $arg1 ne "agi" && $arg1 ne "vit" && $arg1 ne "int" 
			&& $arg1 ne "dex" && $arg1 ne "luk") {
			System::message "Syntax Error in function 'stat_add' (Add Status Point)\n".
									   "Usage: stat_add <str | agi | vit | int | dex | luk>\n";
		} else {
			if ($arg1 eq "str") {
				$ID = 0x0D;
			} elsif ($arg1 eq "agi") {
				$ID = 0x0E;
			} elsif ($arg1 eq "vit") {
				$ID = 0x0F;
			} elsif ($arg1 eq "int") {
				$ID = 0x10;
			} elsif ($arg1 eq "dex") {
				$ID = 0x11;
			} elsif ($arg1 eq "luk") {
				$ID = 0x12;
			}
			if ($chars[$config{'char'}]{"points_$arg1"} > $chars[$config{'char'}]{'points_free'}) {
				System::message "Error in function 'stat_add' (Add Status Point)\n".
										   "Not enough status points to increase $arg1\n";

			} elsif ($chars[$config{'char'}]{$arg1}<99) {
				$chars[$config{'char'}]{$arg1} += 1;
				sendAddStatusPoint(\$System::remote_socket, $ID);
			} else {
				System::message "Reach to Maximum Stat Limit (99)\n";
			}
		}

	} elsif ($switch eq "storage") {
		my ($arg1) = $input =~ /^[\s\S]*? (\w+)/;
		my ($arg2) = $input =~ /^[\s\S]*? \w+ (\d+)/;
		my ($arg3) = $input =~ /^[\s\S]*? \w+ \d+ (\d+)/;
		if ($arg1 eq "") {
			System::message "----------Storage-----------\n";
			System::message "#  Name\n";
			for (my $i=0; $i < @{$storage{'inventory'}};$i++) {
				next if (!%{$storage{'inventory'}[$i]});
				my $display = "$storage{'inventory'}[$i]{'name'} x $storage{'inventory'}[$i]{'amount'}";
				System::message sprintf("%2d %-35s\n",$i,$display);
			}
			System::message "\nCapacity: $storage{'items'}/$storage{'items_max'}\n";
			System::message "-------------------------------\n";


		} elsif ($arg1 eq "add" && $arg2 =~ /\d+/ && $chars[$config{'char'}]{'inventory'}[$arg2] eq "") {
			System::message "Error in function 'storage add' (Add Item to Storage)\n".
									   "Inventory Item $arg2 does not exist\n";

		} elsif ($arg1 eq "add" && $arg2 =~ /\d+/) {
			if (!$arg3 || $arg3 > $chars[$config{'char'}]{'inventory'}[$arg2]{'amount'}) {
				$arg3 = $chars[$config{'char'}]{'inventory'}[$arg2]{'amount'};
			}
			sendStorageAddFromInv(\$System::remote_socket, $chars[$config{'char'}]{'inventory'}[$arg2]{'index'}, $arg3);

		} elsif ($arg1 eq "get" && $arg2 =~ /\d+/ && !%{$storage{'inventory'}[$arg2]}) {
			System::message "Error in function 'storage get' (Get Item from Storage)\n".
									   "Storage Item $arg2 does not exist\n";

		} elsif ($arg1 eq "get" && $arg2 =~ /\d+/) {
			if (!$arg3 || $arg3 > $storage{'inventory'}[$arg2]{'amount'}) {
				$arg3 = $storage{'inventory'}[$arg2]{'amount'};
			}
			sendStorageGetToInv(\$System::remote_socket, $arg2, $arg3);

		} elsif ($arg1 eq "close") {
			sendStorageClose(\$System::remote_socket);

		} else {
			System::message "Syntax Error in function 'storage' (Storage Functions)\n".
									   "Usage: storage [<add | get | close>] [<inventory # | storage #>] [<amount>]\n";
		}

	} elsif ($switch eq "store") {
		my ($arg1) = $input =~ /^[\s\S]*? (\w+)/;
		my ($arg2) = $input =~ /^[\s\S]*? \w+ (\d+)/;
		if ($arg1 eq "" && !$talk{'buyOrSell'}) {
			System::message "----------Store List-----------\n";
			System::message "#  Name                    Type           Price\n";
			for (my $i=0; $i < @storeList;$i++) {
				my $display = $storeList[$i]{'name'};
				System::message sprintf("%2d %-23s %-14s %8sz\n",$i,$display,$itemTypes_lut{$storeList[$i]{'type'}},$storeList[$i]{'price'});
			}
			System::message "-------------------------------\n";
		} elsif ($arg1 eq "" && $talk{'buyOrSell'}) {
			sendGetStoreList(\$System::remote_socket, $talk{'ID'});
		}

	} elsif ($switch eq "take") {
		my ($arg1) = $input =~ /^[\s\S]*? (\d+)$/;
		if ($arg1 eq "") {
			System::message "Syntax Error in function 'take' (Take Item)\n".
									   "Usage: take <item #>\n";

		} elsif ($itemsID[$arg1] eq "") {
			System::message "Error in function 'take' (Take Item)\n".
									   "Item $arg1 does not exist.\n";

		} else {
			take($itemsID[$arg1]);
		}


	} elsif ($switch eq "talk") {
		my ($arg1) = $input =~ /^[\s\S]*? (\w+)/;
		my ($arg2) = $input =~ /^[\s\S]*? [\s\S]*? (\d+)/;

		if ($arg1 =~ /^\d+$/ && $npcsID[$arg1] eq "") {
			System::message "Error in function 'talk' (Talk to NPC)\n".
									   "NPC $arg1 does not exist\n";

		} elsif ($arg1 =~ /^\d+$/) {
			sendTalk(\$System::remote_socket, $npcsID[$arg1]);

		} elsif ($arg1 eq "resp" && !%talk) {
			System::message "Error in function 'talk resp' (Respond to NPC)\n".
									   "You are not talking to any NPC.\n";

		} elsif ($arg1 eq "resp" && $arg2 eq "") {
			my $display = $npcs{$talk{'nameID'}}{'name'};
			System::message "----------Responses-----------\n";
			System::message "NPC: $display\n";
			System::message "#  Response\n";
			for (my $i=0; $i < @{$talk{'responses'}};$i++) {
				System::message sprintf("%2d %-23s\n",$i,$talk{'responses'}[$i]);
			}
			System::message "-------------------------------\n";

		} elsif ($arg1 eq "resp" && $arg2 ne "" && $talk{'responses'}[$arg2] eq "") {
			System::message "Error in function 'talk resp' (Respond to NPC)\n".
									   "Response $arg2 does not exist.\n";

		} elsif ($arg1 eq "resp" && $arg2 ne "") {
			if ($talk{'responses'}[$arg2] eq "Cancel Chat") {
				$arg2 = 255;
			} else {
				$arg2 += 1;
			}
			sendTalkResponse(\$System::remote_socket, $talk{'ID'}, $arg2);


		} elsif ($arg1 eq "cont" && !%talk) {
			System::message "Error in function 'talk cont' (Continue Talking to NPC)\n".
									   "You are not talking to any NPC.\n";
		} elsif ($arg1 eq "cont") {
			sendTalkContinue(\$System::remote_socket, $talk{'ID'});


		} elsif ($arg1 eq "no") {
			sendTalkCancel(\$System::remote_socket, $talk{'ID'});


		} else {
			System::message "Syntax Error in function 'talk' (Talk to NPC)\n".
									   "Usage: talk <NPC # | cont | resp> [<response #>]\n";
		}

	} elsif ($switch eq "tank") {
		my ($arg1) = $input =~ /^[\s\S]*? (\w+)/;
		if ($arg1 eq "") {
			System::message "Syntax Error in function 'tank' (Tank for a Player)\n".
									   "Usage: tank <player #>\n";

		} elsif ($arg1 eq "stop") {
			configModify("tankMode", 0);

		} elsif ($playersID[$arg1] eq "") {
			System::message "Error in function 'tank' (Tank for a Player)\n".
									   "Player $arg1 does not exist.\n";

		} else {
			configModify("tankMode", 1);
			configModify("tankModeTarget", $players{$playersID[$arg1]}{'name'});
		}

	} elsif ($switch eq "tele") {
		my ($map) = $input =~ /^[\s\S]*? ([\s\S]*)/;
		if (defined $maps_lut{$map.'.rsw'} ) {
			System::message "\"$map\"";
			sendTeleport(\$System::remote_socket,"$map.gat");
		}else{
			useTeleport(1);
		}

	} elsif ($switch eq "timeout") {
		my ($arg1, $arg2) = $input =~ /^[\s\S]*? ([\s\S]*) ([\s\S]*?)$/;
		if ($arg1 eq "") {
			System::message "Syntax Error in function 'timeout' (set a timeout)\n".
									   "Usage: timeout <type> [<seconds>]\n";

		} elsif ($timeout{$arg1} eq "") {
			System::message "Error in function 'timeout' (set a timeout)\n".
									   "Timeout $arg1 doesn't exist\n";

		} elsif ($arg2 eq "") {
			System::message "Timeout '$arg1' is $config{$arg1}\n";
		} else {
			setTimeout($arg1, $arg2);
		}


	} elsif ($switch eq "uneq") {
		my ($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		if ($arg1 eq "") {
			System::message "Syntax Error in function 'unequip' (Unequip Inventory Item)\n".
									   "Usage: unequip <item #>\n";

		} elsif (!%{$chars[$config{'char'}]{'inventory'}[$arg1]}) {
			System::message "Error in function 'unequip' (Unequip Inventory Item)\n".
									   "Inventory Item $arg1 does not exist.\n";

		} elsif ($chars[$config{'char'}]{'inventory'}[$arg1]{'equipped'} == 0) {
			System::message "Error in function 'unequip' (Unequip Inventory Item)\n".
									   "Inventory Item $arg1 is not equipped.\n";

		} else {
			sendUnequip(\$System::remote_socket, $chars[$config{'char'}]{'inventory'}[$arg1]{'index'});
		}
	} elsif ($switch eq "unhide") {
		sendUnHide(\$System::remote_socket);

	} elsif ($switch eq "v") {
		if ($config{'verbose'}) {
			configModify("verbose", 0);
		} else {
			configModify("verbose", 1);
		}

#Vendering
	} elsif ($switch eq "vender") {
		my ($arg1) = $input =~ /^.*? (\d+)/;
		my ($arg2) = $input =~ /^.*? \d+ (\d+)/;
		my ($arg3) = $input =~ /^.*? \d+ \d+ (\d+)/;
		if ($arg1 eq "") {
			System::message "Error in function 'vender' (Vender Shop)\n".
									   "Usage: vender <vender # | end> [<item #> <amount>]\n";

		} elsif ($arg1 eq "end") {
			undef @venderItemList;
			undef $venderID;
		} elsif ($venderListsID[$arg1] eq "") {
			System::message  "Error in function 'vender' (Vender Shop)\n".
									    "Vender $arg1 does not exist.\n";

		} elsif ($arg2 eq "") {
			sendEnteringVender(\$System::remote_socket, $venderListsID[$arg1]);

		} elsif ($venderListsID[$arg1] ne $venderID) {
			System::message  "Error in function 'vender' (Vender Shop)\n".
									    "Vender ID is wrong.\n";

		} else {
			if ($arg3 <= 0) {
				$arg3 = 1;
			}
			sendBuyVender(\$System::remote_socket, $arg2, $arg3);
		}

	} elsif ($switch eq "version"){
		System::message "---------------------------------------------------------------\n";
		System::showVersion();
		System::message "---------------------------------------------------------------\n";

	} elsif ($switch eq "vl") {
		System::message "-----------Vender List-----------\n";
		System::message "#   Title                                Owner\n";
		for (my $i = 0; $i < @venderListsID; $i++) {
			next if ($venderListsID[$i] eq "");
			my $owner_string = ($venderListsID[$i] ne $accountID) ? $players{$venderListsID[$i]}{'name'} : $chars[$config{'char'}]{'name'};
			System::message sprintf("%3d %-36s %-20s\n",$i,$venderLists{$venderListsID[$i]}{'title'},$owner_string);
		}
		System::message "----------------------------------\n";

	} elsif ($switch eq "warp") {
		my ($map) = $input =~ /^[\s\S]*? ([\s\S]*)/;

		if (!defined $map) {
			System::message "Error in function 'warp' (Open/List Warp Portal)\n" .
				"Usage: warp <map name|#|list>\n";

		} elsif ($map =~ /^\d$/) {
			if ($map < 0 || $map > @{$chars[$config{'char'}]{'warp'}{'memo'}}) {
				System::message "Invalid map number $map.\n";
			} else {
				my $name = $chars[$config{'char'}]{'warp'}{'memo'}[$map];
				my $rsw = "$name.rsw";
				System::message "Attempting to open a warp portal to $maps_lut{$rsw} ($name)\n";
				sendOpenWarp(\$System::remote_socket, "$name.gat");
			}

		} elsif ($map eq 'list') {
			System::message "----------------- Warp Portal --------------------\n";
			System::message "#  Place                           Map\n";
			for (my $i = 0; $i < @{$chars[$config{'char'}]{'warp'}{'memo'}}; $i++) {
            System::message sprintf("%3d %-36s %-20s\n",$i, $maps_lut{$chars[$config{'char'}]{'warp'}{'memo'}[$i].'.rsw'},$chars[$config{'char'}]{'warp'}{'memo'}[$i]);
			}
			System::message "--------------------------------------------------\n";

		} elsif (!defined $maps_lut{$map.'.rsw'}) {
			System::message "Map '$map' does not exist.\n";

		} else {
			my $rsw = "$map.rsw";
			System::message "Attempting to open a warp portal to $maps_lut{$rsw} ($map)\n";
			sendOpenWarp(\$System::remote_socket, "$map.gat");
		}

	} elsif ($switch eq "where") {
		my ($map_string) = $field{'name'};
		System::message "------------------------------------\n";
		System::message "Location $maps_lut{$map_string.'.rsw'}($map_string) : $chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'}\n";
		System::message "Last destination calculated : (".int($old_x).", ".int($old_y).") from spot (".int($old_pos_x).", ".int($old_pos_y).").\n";
		System::message "------------------------------------\n";

	} elsif ($switch eq "who") {
		sendWho(\$System::remote_socket);


	} else{
		my %params = ( switch => $switch, input => $input );
		Plugins::callHook('Command_post', \%params);
		if (!$params{return}) {
			System::error "Unknown command '$switch'. Please read the documentation for a list of commands.\n";
		}
	}


	if ($printType) {
		close(BUFFER);
		open(BUFREAD, '<buffer');

		my $msg = '';
		while (<BUFREAD>) {
			$msg .= $_;
		}
		close(BUFREAD);
		select(STDOUT);
		System::message "$input\n";
		System::message $msg;
		if ($System::xMode) {
			$msg =~ s/\n*$//s;
			$msg =~ s/\n/\\n/g;
			sendMessage(\$System::remote_socket, "k", $msg);
		}
	}
}

sub attack {
	my $ID = shift;
	my %args;
	$args{'ai_attack_giveup'}{'time'} = time;
	$args{'ai_attack_giveup'}{'timeout'} = $timeout{'ai_attack_giveup'}{'timeout'};
	$args{'ID'} = $ID;
	%{$args{'pos_to'}} = %{$monsters{$ID}{'pos_to'}};
	%{$args{'pos'}} = %{$monsters{$ID}{'pos'}};
	unshift @ai_seq, "attack";
	unshift @ai_seq_args, \%args;
	System::message "Attacking: $monsters{$ID}{'name'} ($monsters{$ID}{'binID'})\n","attacking";
	injectMessage("Attacking: $monsters{$ID}{'name'} ($monsters{$ID}{'binID'})") if ($config{'verbose'} && $System::xMode);
#Mod Start
AUTOEQUIP: {
	my $i = 0;
	my ($Rdef,$Ldef,$Req,$Leq,$arrow,$j);
	while ($config{"autoSwitch_$i"} ne "") { 
		if (existsInList($config{"autoSwitch_$i"}, $monsters{$ID}{'name'})) {
			System::message "Encounter Monster : ".$monsters{$ID}{'name'}."\n";
			injectMessage("Encounter Monster : $monsters{$ID}{'name'}") if ($config{'verbose'} && $System::xMode);

			$Req = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{"autoSwitch_$i"."_RightHand"}) if ($config{"autoSwitch_$i"."_RightHand"});
			$Leq = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{"autoSwitch_$i"."_LeftHand"}) if ($config{"autoSwitch_$i"."_LeftHand"});
			$arrow = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{"autoSwitch_$i"."_Arrow"}) if ($config{"autoSwitch_$i"."_Arrow"});

			if ($Leq ne "" && !$chars[$config{'char'}]{'inventory'}[$Leq]{'equipped'}) { 
				$Ldef = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "equipped",32);
				sendUnequip(\$System::remote_socket,$chars[$config{'char'}]{'inventory'}[$Ldef]{'index'}) if($Ldef ne "");
				System::message "Auto Equiping [L] :".$config{"autoSwitch_$i"."_LeftHand"}." ($Leq)\n";
				injectMessage("Auto Equiping [L] :".$config{"autoSwitch_$i"."_LeftHand"}." ($Leq)") if ($config{'verbose'} && $System::xMode);
				sendEquip(\$System::remote_socket, $chars[$config{'char'}]{'inventory'}[$Leq]{'index'},$chars[$config{'char'}]{'inventory'}[$Leq]{'type_equip'}); 
			}
			if ($Req ne "" && !$chars[$config{'char'}]{'inventory'}[$Req]{'equipped'} || $config{"autoSwitch_$i"."_RightHand"} eq "[NONE]") {
				$Rdef = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "equipped",34);
				$Rdef = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "equipped",2) if($Rdef eq "");
				#Debug for 2hand Quicken and Bare Hand attack with 2hand weapon
				if(((binFind(\@skillsST,$skillsST_lut{2}) eq "" && binFind(\@skillsST,$skillsST_lut{23}) eq "" && binFind(\@skillsST,$skillsST_lut{68}) eq "") 
					|| $config{"autoSwitch_$i"."_RightHand"} eq "[NONE]" )
					&& $Rdef ne ""){
					sendUnequip(\$System::remote_socket,$chars[$config{'char'}]{'inventory'}[$Rdef]{'index'});
				}
				if ($Req eq $Leq) {
					for ($j=0; $j < @{$chars[$config{'char'}]{'inventory'}};$j++) {
						next if (!%{$chars[$config{'char'}]{'inventory'}[$j]});
						if ($chars[$config{'char'}]{'inventory'}[$j]{'name'} eq $config{"autoSwitch_$i"."_RightHand"} && $j != $Leq) {
							$Req = $j;
							last;
						}
					}
				}
				if ($config{"autoSwitch_$i"."_RightHand"} ne "[NONE]") {
					System::message "Auto Equiping [R] :".$config{"autoSwitch_$i"."_RightHand"}."($Req)\n"; 
					injectMessage("Auto Equiping [R] :".$config{"autoSwitch_$i"."_RightHand"}."($Req)") if ($config{'verbose'} && $System::xMode);
					sendEquip(\$System::remote_socket, $chars[$config{'char'}]{'inventory'}[$Req]{'index'},$chars[$config{'char'}]{'inventory'}[$Req]{'type_equip'});
				}
			}
			if ($arrow ne "" && !$chars[$config{'char'}]{'inventory'}[$arrow]{'equipped'}) { 
				System::message "Auto Equiping [A] :".$config{"autoSwitch_$i"."_Arrow"}."\n";
				injectMessage("Auto Equiping [A] :".$config{"autoSwitch_$i"."_Arrow"}) if ($config{'verbose'} && $System::xMode);
				sendEquip(\$System::remote_socket, $chars[$config{'char'}]{'inventory'}[$arrow]{'index'},0); 
			}
			if ($config{"autoSwitch_$i"."_Distance"} && $config{"autoSwitch_$i"."_Distance"} != $config{'attackDistance'}) { 
				$ai_v{'attackDistance'} = $config{'attackDistance'};
				$config{'attackDistance'} = $config{"autoSwitch_$i"."_Distance"};
				System::message "Change Attack Distance to : ".$config{'attackDistance'}."\n";
				injectMessage("Change Attack Distance to : ".$config{'attackDistance'}) if ($config{'verbose'} && $System::xMode);
			}
			if ($config{"autoSwitch_$i"."_useWeapon"} ne "") { 
				$ai_v{'attackUseWeapon'} = $config{'attackUseWeapon'};
				$config{'attackUseWeapon'} = $config{"autoSwitch_$i"."_useWeapon"};
				System::message "Change Attack useWeapon to : ".$config{'attackUseWeapon'}."\n";
				injectMessage("Change Attack useWeapon to : ".$config{'attackUseWeapon'}) if ($config{'verbose'} && $System::xMode);
			}
			last AUTOEQUIP; 
		}
		$i++;
	}
	if ($config{'autoSwitch_default_LeftHand'}) { 
		$Leq = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{'autoSwitch_default_LeftHand'});
		if($Leq ne "" && !$chars[$config{'char'}]{'inventory'}[$Leq]{'equipped'}) {
			$Ldef = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "equipped",32);
			sendUnequip(\$System::remote_socket,$chars[$config{'char'}]{'inventory'}[$Ldef]{'index'}) if($Ldef ne "" && $chars[$config{'char'}]{'inventory'}[$Ldef]{'equipped'});
			System::message "Auto equiping default [L] :".$config{'autoSwitch_default_LeftHand'}."\n";
			injectMessage("Auto equiping default [L] :".$config{'autoSwitch_default_LeftHand'}."($Leq)") if ($config{'verbose'} && $System::xMode);
			sendEquip(\$System::remote_socket, $chars[$config{'char'}]{'inventory'}[$Leq]{'index'},$chars[$config{'char'}]{'inventory'}[$Leq]{'type_equip'});
		}
	}
	if ($config{'autoSwitch_default_RightHand'}) { 
		$Req = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{'autoSwitch_default_RightHand'}); 
		if($Req ne "" && !$chars[$config{'char'}]{'inventory'}[$Req]{'equipped'}) {
			System::message "Auto equiping default [R] :".$config{'autoSwitch_default_RightHand'}."\n"; 
			injectMessage("Auto equiping default [R] :".$config{'autoSwitch_default_RightHand'}."($Req)") if ($config{'verbose'} && $System::xMode);
			sendEquip(\$System::remote_socket, $chars[$config{'char'}]{'inventory'}[$Req]{'index'},$chars[$config{'char'}]{'inventory'}[$Req]{'type_equip'});
		}
	}
	if ($config{'autoSwitch_default_Arrow'}) { 
		$arrow = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{'autoSwitch_default_Arrow'}); 
		if($arrow ne "" && !$chars[$config{'char'}]{'inventory'}[$arrow]{'equipped'}) {
			System::message "Auto equiping default [A] :".$config{'autoSwitch_default_Arrow'}."\n"; 
			injectMessage("Auto equiping default [A] :".$config{'autoSwitch_default_Arrow'}."($arrow)") if ($config{'verbose'} && $System::xMode);
			sendEquip(\$System::remote_socket, $chars[$config{'char'}]{'inventory'}[$arrow]{'index'},0);
		}
	}
	if ($ai_v{'attackDistance'} && $config{'attackDistance'} != $ai_v{'attackDistance'}) { 
		$config{'attackDistance'} = $ai_v{'attackDistance'};
		System::message "Change Attack Distance to Default : ".$config{'attackDistance'}."\n";
		injectMessage("Change Attack Distance to default : ".$config{'attackDistance'}) if ($config{'verbose'} && $System::xMode);
	}
	if ($ai_v{'attackUseWeapon'} ne "" && $config{'attackUseWeapon'} != $ai_v{'attackUseWeapon'}) { 
		$config{'attackUseWeapon'} = $ai_v{'attackUseWeapon'};
		System::message "Change Attack useWeapon to default : ".$config{'attackUseWeapon'}."\n";
		injectMessage("Change Attack useWeapon to default : ".$config{'attackUseWeapon'}) if ($config{'verbose'} && $System::xMode);
	}
} #END OF BLOCK AUTOEQUIP 
#Mod Stop
}

sub gather {
	my $ID = shift;
	my %args;
	$args{'ai_items_gather_giveup'}{'time'} = time;
	$args{'ai_items_gather_giveup'}{'timeout'} = $timeout{'ai_items_gather_giveup'}{'timeout'};
	$args{'ID'} = $ID;
	%{$args{'pos'}} = %{$items{$ID}{'pos'}};
	unshift @ai_seq, "items_gather";
	unshift @ai_seq_args, \%args;
	System::message "Targeting for Gather: $items{$ID}{'name'} ($items{$ID}{'binID'})\n" if $config{'debug'};
}


sub look {
	my $body = shift;
	my $head = shift;
	my %args;
	unshift @ai_seq, "look";
	$args{'look_body'} = $body;
	$args{'look_head'} = $head;
	unshift @ai_seq_args, \%args;
}

sub move {
	my $x = shift;
	my $y = shift;
#mod Start
	my $pos_x;
	my $pos_y;
	my $triggeredByRoute = shift;
	my $attackID = shift; 

	$pos_x = int($chars[$config{'char'}]{'pos_to'}{'x'}) if ($chars[$config{'char'}]{'pos_to'}{'x'} ne "");
	$pos_y = int($chars[$config{'char'}]{'pos_to'}{'y'}) if ($chars[$config{'char'}]{'pos_to'}{'y'} ne "");
#mod Stop
	my %args;
	$args{'move_to'}{'x'} = $x;
	$args{'move_to'}{'y'} = $y;
	$args{'triggeredByRoute'} = $triggeredByRoute;
	$args{'attackID'} = $attackID; 
	$args{'ai_move_giveup'}{'time'} = time;
	$args{'ai_move_giveup'}{'timeout'} = $timeout{'ai_move_giveup'}{'timeout'};
	unshift @ai_seq, "move";
	unshift @ai_seq_args, \%args;
#mod Start
#if kore is stuck
	if (($move_x || $move_y) && ($move_x == $x) && ($move_y == $y)) {
		$moveTo_SameSpot++;
	} else {
		$moveTo_SameSpot = 0;
		$move_x = $x;
		$move_y = $y;
	}
	if ($moveTo_SameSpot == 20) {
		ClearRouteAI("Keep trying to move to same spot, clearing route AI to unstuck ...\n");
	}
	if ($moveTo_SameSpot >= 50) {
		$moveTo_SameSpot = 0;
		Unstuck("Keep trying to move to same spot, teleporting to unstuck ...\n");
	}

	if (($move_pos_x || $move_pos_y) && ($move_pos_x == $pos_x) && ($move_pos_y == $pos_y)) {
		$moveFrom_SameSpot++;
	} else {
		$moveFrom_SameSpot = 0;
		$move_pos_x = $pos_x;
		$move_pos_y = $pos_y;
	}
	if ($moveFrom_SameSpot == 20) {
		ClearRouteAI("Keep trying to move from same spot, clearing route AI to unstuck ...\n");
	}
	if ($moveFrom_SameSpot >= 50) {
		$moveFrom_SameSpot = 0;
		Unstuck("Keep trying to move from same spot, teleport to unstuck ...\n");
	}											    

	if ($totalStuckCount >= 10) {
		RespawnUnstuck();
	}	
#mod Stop
}

sub quit {
	$quit = 1;
	System::message "Exiting...\n";
}

sub relog {
	$conState = 1;
	undef $conState_tries;
	initMapChangeVars();
	undef %ai_v;
	undef @ai_seq;
	undef @ai_seq_args;
	$timeout_ex{'master'}{'time'} = time;
	$timeout_ex{'master'}{'timeout'} = 5;
	killConnection(\$System::remote_socket);
	System::message "Relogging in 5 seconds...\n";
}


sub sit {
	$timeout{'ai_sit_wait'}{'time'} = time;
	unshift @ai_seq, "sitting";
	unshift @ai_seq_args, {};
}

sub stand {
	unshift @ai_seq, "standing";
	unshift @ai_seq_args, {};
}

sub take {
	my $ID = shift;
	my %args;
	$args{'ai_take_giveup'}{'time'} = time;
	$args{'ai_take_giveup'}{'timeout'} = $timeout{'ai_take_giveup'}{'timeout'};
	$args{'ID'} = $ID;
	%{$args{'pos'}} = %{$items{$ID}{'pos'}};
	unshift @ai_seq, "take";
	unshift @ai_seq_args, \%args;
	System::message "Targeting for Pickup: $items{$ID}{'name'} ($items{$ID}{'binID'})\n" if $config{'debug'};
}

#Karusu
#mod Start
# Teleport Fix
sub useTeleport { 
	my $level = shift;
	my $invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "nameID", 600 + $level);
	my $skillindex = binFind(\@skillsID, 'AL_TELEPORT') || defined($chars[$config{'char'}]{'skills'}{'AL_TELEPORT'}{'lv'});
	if (!$chars[$config{'char'}]{'ban_period'} && ($skillindex || $invIndex ne "")) {
		# Closing Chatroom Before Teleporting
		if ($currentChatRoom ne ""){
			sendChatRoomLeave(\$System::remote_socket);
		}
		# Stand up before teleporting 
		if ($chars[$config{'char'}]{'sitting'}) { 
			sendStand(\$System::remote_socket); 
			sleep(0.5); 
		}
		if ($skillindex ne "") {
			sendSkillUse(\$System::remote_socket, $skillsID_rlut{teleport},$config{'teleportAuto_useSP'}, $accountID) if ($config{'teleportAuto_useSP'});
			sendTeleport(\$System::remote_socket, "Random") if ($level == 1); 
			sendTeleport(\$System::remote_socket, $config{'saveMap'}.".gat") if ($level == 2);
		} elsif ($invIndex ne "") { 
			sendItemUse(\$System::remote_socket, $chars[$config{'char'}]{'inventory'}[$invIndex]{'index'}, $accountID);
		}
		ClearRouteAIAfterTeleport();
	}elsif (!$chars[$config{'char'}]{'skills'}{'AL_TELEPORT'}{'lv'} || $invIndex eq ""){
		System::message "Can't teleport or respawn - need wing or skill\n";
	}elsif ($chars[$config{'char'}]{'ban_period'}){
		System::message "[Warn] You are in Ban period ($chars[$config{'char'}]{'ban_period'} min), Can't use Skill / item\n","warn";
	}
} 
#mod Stop

#######################################
#######################################
#CONFIG MODIFIERS
#######################################
#######################################

sub auth {
	my $user = shift;
	my $flag = shift;
	if ($flag) {
		System::message "Authorized user '$user' for admin\n";
	} else {
		System::message "Revoked admin privilages for user '$user'\n";
	}	
	$overallAuth{$user} = $flag;
	FileParser::writeDataFile("control/overallAuth.txt", \%overallAuth);
}

sub configModify {
	my $key = shift;
	my $val = shift;
	System::message "Config '$key' set to $val\n","conf";
	$config{$key} = $val;
	FileParser::writeDataFileIntact("$System::def_config/config.txt", \%config);
}

sub setTimeout {
	my $timeout = shift;
	my $time = shift;
	$timeout{$timeout}{'timeout'} = $time;
	System::message "Timeout '$timeout' set to $time\n";
	FileParser::writeDataFileIntact2("control/timeouts.txt", \%timeout);
}


#######################################
#######################################
#CONNECTION FUNCTIONS
#######################################
#######################################


sub connection {
	my $r_socket = shift;
	my $host = shift;
	my $port = shift;
	System::message "Connecting ($host:$port)... ","connection";
	$$r_socket = IO::Socket::INET->new(
			PeerAddr	=> $host,
			PeerPort	=> $port,
			Proto		=> 'tcp',
			Timeout		=> 4);
	($$r_socket && inet_aton($$r_socket->peerhost()) eq inet_aton($host)) ? System::message "connected\n","connection" : System::message "couldn't connect\n","connection";
}

sub killConnection {
	my $r_socket = shift;
	my $log = shift;
	sendQuit($r_socket) if ($conState == 5 && $$r_socket && $$r_socket->connected());
	if ($$r_socket && $$r_socket->connected()) {
		System::message "Disconnecting (".$$r_socket->peerhost().":".$$r_socket->peerport().")... ","connection";
		System::sysLog("D","*** Disconnected ***\n") if (defined $log);
		close($$r_socket);
		!$$r_socket->connected() ? System::message "disconnected\n","connection" : System::message "couldn't disconnect\n","connection";
	}
}

#######################################
#######################################
#FILE PARSING AND WRITING
#######################################
#######################################

sub dumpData {
	my $msg = shift;
	my $mode = shift;
	my $dump;
	my $rawdata;
	my $profile = $config{'username'};
	my $i;
	$dump = "\n\n================================================\n".getFormattedDate(int(time))."\n\n".length($msg)." bytes\n\n";
	for ($i=0; $i + 15 < length($msg);$i += 16) {
		$rawdata = substr($msg,$i,16);
		$rawdata =~ s/\W/./g;
		$dump .= getHex(substr($msg,$i,8))."    ".getHex(substr($msg,$i+8,8))."\t$rawdata\n";
	}
	$rawdata = substr($msg,$i,length($msg) - $i);
	$rawdata =~ s/\W/./g;
	if (length($msg) - $i > 8) {
		$dump .= getHex(substr($msg,$i,8))."    ".getHex(substr($msg,$i+8,length($msg) - $i - 8))." " x (3 * ($i + 16 - length($msg)) + 4)."\t$rawdata\n";
	} elsif (length($msg) > 0) {
		$dump .= getHex(substr($msg,$i,length($msg) - $i))." " x (3 * ($i + 16 - length($msg)) + 7)."\t$rawdata\n";
	}
	if ($mode) {
		open DUMP, ">> logs\/${profile}_sendDUMP.txt";
	}else{
		open DUMP, ">> logs\/${profile}_recvDUMP.txt";
	}
	print DUMP $dump;
	close DUMP;
	print "$dump\n" if $config{'debug'} >= 2;
	print "Message Dumped into DUMP.txt!\n";
}

sub getResponse {
	my $type = shift;
	my $key;
	my @keys;
	my $msg;
	foreach $key (keys %responses) {
		if ($key =~ /^$type\_\d+$/) {
			push @keys, $key;
		} 
	}
	$msg = $responses{$keys[int(rand(@keys))]};
	$msg =~ s/\%\$(\w+)/$responseVars{$1}/eig;
	return $msg;
}

sub updateDamageTables {
	my ($ID1, $ID2, $damage) = @_;
	if ($ID1 eq $accountID) {
		if (%{$monsters{$ID2}}) {
			$monsters{$ID2}{'dmgTo'} += $damage;
			$monsters{$ID2}{'dmgFromYou'} += $damage;
			if ($damage == 0) {
				$monsters{$ID2}{'missedFromYou'}++;
				$monsters{$ID2}{'missedContFromYou'}++;
			}elsif ($monsters{$ID2}{'missedContFromYou'} > 0){
				$monsters{$ID2}{'missedContFromYou'} = 0;
			}
		}
	} elsif ($ID2 eq $accountID) {
		if (%{$monsters{$ID1}}) {
			$monsters{$ID1}{'dmgFrom'} += $damage;
			$monsters{$ID1}{'dmgToYou'} += $damage;
			if ($damage == 0) {
				$monsters{$ID1}{'missedYou'}++;
			}
			$monsters{$ID1}{'attackedByPlayer'} = 0;
			$monsters{$ID1}{'attackedYou'}++ unless ($monsters{$ID1}{'dmgFromPlayer'} || $monsters{$ID1}{'missedFromPlayer'} || $monsters{$ID1}{'missedToPlayer'} || $monsters{$ID1}{'dmgToPlayer'});

			my $teleported = 0;
			if ($mon_control{lc($monsters{$ID1}{'name'})}{'teleport_auto'}==2){
				System::message "[Act] Teleport due to $monsters{$ID1}{'name'} attack\n";
				$teleported = 1;
			}elsif($config{'teleportAuto_deadly'} && $damage >= $chars[$config{'char'}]{'hp'}){
				System::message "[Act] Next $damage dmg could kill you. Teleporting...\n";
				$teleported = 1;
			}elsif($config{'teleportAuto_maxDmg'} && $damage >= $config{'teleportAuto_maxDmg'}){
				System::message "[Act] $monsters{$ID1}{'name'} attack you more than $config{'teleportAuto_maxDmg'} dmg. Teleporting...\n";
				$teleported = 1;
			}
			useTeleport(1) if ($teleported);
		}
	} elsif (%{$monsters{$ID1}}) {
		if (%{$players{$ID2}}) {
			$monsters{$ID1}{'dmgFrom'} += $damage;
			$monsters{$ID1}{'dmgToPlayer'}{$ID2} += $damage;
			$players{$ID2}{'dmgFromMonster'}{$ID1} += $damage;
			if ($damage == 0) {
				$monsters{$ID1}{'missedToPlayer'}{$ID2}++;
				$players{$ID2}{'missedFromMonster'}{$ID1}++;
			}
			if (%{$chars[$config{'char'}]{'party'}} && %{$chars[$config{'char'}]{'party'}{'users'}{$ID2}}) {
				$monsters{$ID1}{'dmgToParty'} += $damage;
				$monsters{$ID1}{'attackedByPlayer'} = 0 if ($config{'attackAuto_party'} || ( 
				$config{'attackAuto_followTarget'} && 
				$config{'follow'} && $players{$ID2}{'name'} eq $config{'followTarget'})); 
			} else { 
				$monsters{$ID1}{'attackedByPlayer'} = 1 unless ($config{'attackAuto_followTarget'} && 
				$config{'follow'} && $players{$ID2}{'name'} eq $config{'followTarget'});
			}
		}
		
	} elsif (%{$players{$ID1}}) {
		if (%{$monsters{$ID2}}) {
			$monsters{$ID2}{'dmgTo'} += $damage;
			$monsters{$ID2}{'dmgFromPlayer'}{$ID1} += $damage;
			$players{$ID1}{'dmgToMonster'}{$ID2} += $damage;
			if ($damage == 0) {
				$monsters{$ID2}{'missedFromPlayer'}{$ID1}++;
				$players{$ID1}{'missedToMonster'}{$ID2}++;
			}
			if (%{$chars[$config{'char'}]{'party'}} && %{$chars[$config{'char'}]{'party'}{'users'}{$ID1}}) {
				$monsters{$ID2}{'dmgFromParty'} += $damage;
			}
		}
	}
}


#######################################
#######################################
#MISC FUNCTIONS
#######################################
#######################################

sub compilePortals {
	undef %mapPortals;
	foreach (keys %portals_lut) {
		%{$mapPortals{$portals_lut{$_}{'source'}{'map'}}{$_}{'pos'}} = %{$portals_lut{$_}{'source'}{'pos'}};
	}
	my $l = 0;
	foreach my $map (keys %mapPortals) {
		foreach my $portal (keys %{$mapPortals{$map}}) {
			foreach (keys %{$mapPortals{$map}}) {
				next if ($_ eq $portal);
				if ($portals_los{$portal}{$_} eq "" && $portals_los{$_}{$portal} eq "") {
					if ($field{'name'} ne $map) {
						System::message "Processing map $map\n";
						FileParser::getField("$System::def_field/$map.fld", \%field);
					}
					System::message "Calculating portal route $portal -> $_\n";
					ai_route_getRoute(\@solution, \%field, \%{$mapPortals{$map}{$portal}{'pos'}}, \%{$mapPortals{$map}{$_}{'pos'}});
					compilePortals_getRoute();
					$portals_los{$portal}{$_} = (@solution) ? 1 : 0;
				}
			}
		}
	}

	FileParser::writePortalsLOS("$System::def_table/portalsLOS.txt", \%portals_los);

	System::message "Wrote portals Line of Sight table to '$System::def_table/portalsLOS.txt'\n";

}

sub compilePortals_check {
	my %mapPortals;
	foreach (keys %portals_lut) {
		%{$mapPortals{$portals_lut{$_}{'source'}{'map'}}{$_}{'pos'}} = %{$portals_lut{$_}{'source'}{'pos'}};
	}
	foreach my $map (keys %mapPortals) {
		foreach my $portal (keys %{$mapPortals{$map}}) {
			foreach (keys %{$mapPortals{$map}}) {
				next if ($_ eq $portal);
				if ($portals_los{$portal}{$_} eq "" && $portals_los{$_}{$portal} eq "") {
					return 1;
				}
			}
		}
	}
	return 0;
}

sub compilePortals_getRoute {	
	if ($ai_seq[0] eq "route_getRoute") {
		if (!$ai_seq_args[0]{'init'}) {
			undef @{$ai_v{'temp'}{'subSuc'}};
			undef @{$ai_v{'temp'}{'subSuc2'}};
			if (ai_route_getMap(\%{$ai_seq_args[0]}, $ai_seq_args[0]{'start'}{'x'}, $ai_seq_args[0]{'start'}{'y'})) {
				ai_route_getSuccessors(\%{$ai_seq_args[0]}, \%{$ai_seq_args[0]{'start'}}, \@{$ai_v{'temp'}{'subSuc'}},0);
				ai_route_getDiagSuccessors(\%{$ai_seq_args[0]}, \%{$ai_seq_args[0]{'start'}}, \@{$ai_v{'temp'}{'subSuc'}},0);
				foreach (@{$ai_v{'temp'}{'subSuc'}}) {
					ai_route_getSuccessors(\%{$ai_seq_args[0]}, \%{$_}, \@{$ai_v{'temp'}{'subSuc2'}},0);
					ai_route_getDiagSuccessors(\%{$ai_seq_args[0]}, \%{$_}, \@{$ai_v{'temp'}{'subSuc2'}},0);
				}
				if (@{$ai_v{'temp'}{'subSuc'}}) {
					%{$ai_seq_args[0]{'start'}} = %{$ai_v{'temp'}{'subSuc'}[0]};
				} elsif (@{$ai_v{'temp'}{'subSuc2'}}) {
					%{$ai_seq_args[0]{'start'}} = %{$ai_v{'temp'}{'subSuc2'}[0]};
				}
			}
			undef @{$ai_v{'temp'}{'subSuc'}};
			undef @{$ai_v{'temp'}{'subSuc2'}};
			if (ai_route_getMap(\%{$ai_seq_args[0]}, $ai_seq_args[0]{'dest'}{'x'}, $ai_seq_args[0]{'dest'}{'y'})) {
				ai_route_getSuccessors(\%{$ai_seq_args[0]}, \%{$ai_seq_args[0]{'dest'}}, \@{$ai_v{'temp'}{'subSuc'}},0);
				ai_route_getDiagSuccessors(\%{$ai_seq_args[0]}, \%{$ai_seq_args[0]{'dest'}}, \@{$ai_v{'temp'}{'subSuc'}},0);
				foreach (@{$ai_v{'temp'}{'subSuc'}}) {
					ai_route_getSuccessors(\%{$ai_seq_args[0]}, \%{$_}, \@{$ai_v{'temp'}{'subSuc2'}},0);
					ai_route_getDiagSuccessors(\%{$ai_seq_args[0]}, \%{$_}, \@{$ai_v{'temp'}{'subSuc2'}},0);
				}
				if (@{$ai_v{'temp'}{'subSuc'}}) {
					%{$ai_seq_args[0]{'dest'}} = %{$ai_v{'temp'}{'subSuc'}[0]};
				} elsif (@{$ai_v{'temp'}{'subSuc2'}}) {
					%{$ai_seq_args[0]{'dest'}} = %{$ai_v{'temp'}{'subSuc2'}[0]};
				}
			}
			$ai_seq_args[0]{'timeout'} = 90000;
		}
		$ai_seq_args[0]{'init'} = 1;
		ai_route_searchStep(\%{$ai_seq_args[0]});
		ai_route_getRoute_destroy(\%{$ai_seq_args[0]});
		shift @ai_seq;
		shift @ai_seq_args;
	}
}

#---------------------------------------------- Mod Add-On --------------------------------------------------------------------------------------------#

# Weapon Name Modifier
sub modifingName { 
	my $r_hash = shift;
	my $modified = ""; 
	my @card; 
	my $prefix="";
	my $postfix=""; 
	my ($i, $j, $k); 
	
	if (!$$r_hash{'elements'} && !$$r_hash{'refined'} && !$$r_hash{'card'}[0] && !$$r_hash{'star'}) { 
		return 0;
	} else {
		$modified = "+$$r_hash{'refined'} " if ($$r_hash{'refined'});
		if ($$r_hash{'star'}==1){
			$modified .="V Strong ";
		}elsif ($$r_hash{'star'}==2){
			$modified .="VV Strong ";
		}elsif ($$r_hash{'star'}==3){
			$modified .="VVV Strong ";
		}
		$modified .= $elements_lut{$$r_hash{'elements'}}." " if ($$r_hash{'elements'});

		for ($i = 0; $i < 4; $i++) {
			last if !$$r_hash{'card'}[$i];
			if (@card) { 
				for ($j = 0; $j <= @card; $j++) { 
					if ($card[$j]{'ID'} eq $$r_hash{'card'}[$i]) { 
						$card[$j]{'amount'}++; 
						last; 
					} elsif ($card[$j]{'ID'} eq "") { 
						$card[$j]{'ID'} = $$r_hash{'card'}[$i]; 
						$card[$j]{'amount'} = 1; 
						last; 
					}
				}
			}else{
				$card[0]{'ID'} = $$r_hash{'card'}[$i]; 
				$card[0]{'amount'} = 1; 
			}
		}
		if (@card) {
			for ($i = 0; $i < @card; $i++) { 
				if ($cards_lut{$card[$i]{'ID'}} =~/^of*/ || $cards_lut{$card[$i]{'ID'}} eq "Under a Cast" || $cards_lut{$card[$i]{'ID'}} =~/^from*/) { 
					if ($card[$i]{'amount'} == 1) { 
						$postfix .= " $cards_lut{$card[$i]{'ID'}}";
					} elsif ($card[$i]{'amount'} == 2) { 
						$postfix .= " $cards_lut{$card[$i]{'ID'}} Double";
					} elsif ($card[$i]{'amount'} == 3) { 
						$postfix .= " $cards_lut{$card[$i]{'ID'}} Triple";
					} elsif ($card[$i]{'amount'} == 4) { 
						$postfix .= " $cards_lut{$card[$i]{'ID'}} Quadraple";
					}
				} else {
					if ($card[$i]{'amount'} == 1) {
						$prefix .= "$cards_lut{$card[$i]{'ID'}} "; 
					} elsif ($card[$i]{'amount'} == 2) { 
						$prefix .= "Double $cards_lut{$card[$i]{'ID'}} "; 
					} elsif ($card[$i]{'amount'} == 3) { 
						$prefix .= "Triple $cards_lut{$card[$i]{'ID'}} "; 
					} elsif ($card[$i]{'amount'} == 4) { 
						$prefix .= "Quadraple $cards_lut{$card[$i]{'ID'}} "; 
					}
				}
			}
		}
		$$r_hash{'name'} = $modified.$prefix.$$r_hash{'name'}.$postfix;
	}
}

# ChatAuto Function
sub getResMsg {
	my $key = shift;
	my @keys;
	my $msg,$word;
	foreach $key1 (keys %qmsg) {
		if(($key =~ /^\/[\w+]/ && $key =~ /$key1/)||($key =~ /$key1/ && !($key1 =~ /^\/[\w+]/))){
			push @keys,$key1;
		}
	}
	if (scalar(@keys)!=0) {
		$word = $keys[int(rand(@keys))];
		$msg = $qmsg{'/ans'}{$qmsg{$word}}[int(rand(scalar(@{$qmsg{'/ans'}{$qmsg{$word}}})))];
	}
	$msg =~ s/\%\$(\w+)/$chars[$config{'char'}]{$1}/eig;
	return $msg;
}


# Stuck Killer
sub ClearRouteAIAfterTeleport {
	my $msg = shift;
	$totalStuckCount=0;
	$old_x = 0;
	$old_y = 0;
	$old_pos_x = 0;
	$old_pos_y = 0;
	$move_x = 0;
	$move_y = 0;
	$move_pos_x = 0;
	$move_pos_y = 0;
	$calcTo_SameSpot = 0;
	$calcFrom_SameSpot = 0;
	$moveTo_SameSpot = 0;
	$moveFrom_SameSpot = 0;
	$route_stuck = 0;
	System::message $msg if (defined($msg));
	aiRemove("move");
	aiRemove("route");
	aiRemove("route_getRoute");
	aiRemove("route_getMapRoute");
	ai_clientSuspend(0, 5);
}

sub ClearRouteAI {
	my $msg = shift;
	System::message $msg;
	aiRemove("move");
	aiRemove("route");
	aiRemove("route_getRoute");
	aiRemove("route_getMapRoute");
	ai_clientSuspend(0, 5);
}

sub Unstuck {
	my $msg = shift;
	$totalStuckCount++;
	$old_x = 0;
	$old_y = 0;
	$old_pos_x = 0;
	$old_pos_y = 0;
	$move_x = 0;
	$move_y = 0;
	$move_pos_x = 0;
	$move_pos_y = 0;
	System::message $msg;
	aiRemove("move");
	aiRemove("route");
	aiRemove("route_getRoute");
	aiRemove("route_getMapRoute");
	useTeleport(1);
	ai_clientSuspend(0, 5);
}

sub RespawnUnstuck {
	$totalStuckCount = 0;
	$calcTo_SameSpot = 0;
	$calcFrom_SameSpot = 0;
	$moveTo_SameSpot = 0;
	$moveFrom_SameSpot = 0;
	$route_stuck = 0;
	$old_x = 0;
	$old_y = 0;
	$old_pos_x = 0;
	$old_pos_y = 0;
	$move_x = 0;
	$move_y = 0;
	$move_pos_x = 0;
	$move_pos_y = 0;
	System::message "Cannot calculate route, respawning to saveMap ...\n","stuck";
	aiRemove("move");
	aiRemove("route");
	aiRemove("route_getRoute");
	aiRemove("route_getMapRoute");
	useTeleport(2);
	ai_clientSuspend(0, 5);
}

#auto generated ppl avoid
sub updatepplControl {
	my $file = shift;
	my $name = shift;
	my $ID = shift;
	my @args = split / /,$config{'ppl_defaultFlag'};
	open FILE, ">> $file";
	print FILE "#$ID\n$name\t$config{'ppl_defaultFlag'}\n";
	close FILE;
	$ppl_control{$name}{'ignored_auto'} = $args[0];
	$ppl_control{$name}{'teleport_auto'} = $args[1];
	$ppl_control{$name}{'disconnect_auto'} = $args[2];
}

sub alertsound {
	my $wav = shift;
	my $vol = shift;
	Win32::Sound::Play($wav,"SND_ASYNC");
}

sub checkNPC{
	my $position = shift;
	my ($IDOld, $mapOld,%posOld);
	my %pos=%{$npcs_lut{$config{$position}}{'pos'}}; 
	foreach (@npcsID) { 
		next if (!$_); 
		if($npcs_lut{$config{$position}}{'map'} eq $field{'name'} 
			&& $pos{'x'}==$npcs{$_}{'pos'}{'x'} && $pos{'y'}==$npcs{$_}{'pos'}{'y'}
			&& $npcs{$_}{'nameID'} ne $config{$position}){
			$IDOld= $npcs{$_}{'nameID'};
			$mapOld = $npcs_lut{$npcs{$_}{'nameID'}}{'map'}; 
			%posOld = %{$npcs_lut{$npcs{$_}{'nameID'}}{'pos'}}; 
			$npcs_lut{$npcs{$_}{'nameID'}}{'name'}=$npcs_lut{$config{$position}}{'name'}; 
			$npcs_lut{$npcs{$_}{'nameID'}}{'map'}=$field{'name'}; 
			%{$npcs_lut{$npcs{$_}{'nameID'}}{'pos'}}=%{$npcs{$_}{'pos'}}; 
			WriteNPCLUT($IDOld,$mapOld,%posOld,$npcs_lut{$npcs{$_}{'nameID'}}{'name'}); 
			configModify($position, $npcs{$_}{'nameID'});
			System::message "**Auto-Update $position : $position\n","C";
			last; 
		} 
	}
}

sub WriteNPCLUT { 
	my $file="$System::def_table/npcs.txt";
	my ($IDOld,$mapOld,%posOLD,$nameOld) = @_; 
	open(FILE,">$file"); 
	foreach (sort keys %npcs_lut) {
		if($_ == $IDOld){ 
			print FILE "$IDOld $mapOld $posOLD{'x'} $posOLD{'y'} $nameOld\n"; 
		}else{
			print FILE "$_ $npcs_lut{$_}{'map'} $npcs_lut{$_}{'pos'}{'x'} $npcs_lut{$_}{'pos'}{'y'} $npcs_lut{$_}{'name'}\n"; 
		} 
	} 
	close FILE; 
}

sub openShop {
	my $r_socket = shift;
	my ($i,$index,$totalitem,$items_selling,$citem,$oldid);
	my %itemtosell;
	my @itemtosellorder;
	if($chars[$config{'char'}]{'skills'}{'MC_VENDING'}{'lv'} && $shop{'shop_title'} ne ""){
		$i=0;
		$items_selling=0;
		while ($shop{"name_$i"} ne "" && $items_selling < $chars[$config{'char'}]{'skills'}{'MC_VENDING'}{'lv'}+2) {
			for ($index=0; $index< @{$cart{'inventory'}}; $index++) {
				next if (!%{$cart{'inventory'}[$index]});
				if (lc($cart{'inventory'}[$index]{'name'}) eq lc($shop{"name_$i"})) {
					$citem = $index;
					foreach (keys %itemtosell) {
						if ($_ eq $index) {
							$oldid = $_;
							$citem = -1;
						}
					}
					if ($citem>-1) {
						#amount calculate
						if ($shop{"quantity_$i"}>0 && $cart{'inventory'}[$index]{'amount'} >= $shop{"quantity_$i"}) {
							$itemtosell{$index}{'amount'} = $shop{"quantity_$i"};
						}elsif ($shop{"quantity_$i"}>0 && $cart{'inventory'}[$index]{'amount'} < $shop{"quantity_$i"}){
							$itemtosell{$index}{'amount'} = $cart{'inventory'}[$index]{'amount'};
						}else{
							$itemtosell{$index}{'amount'} = 1;
						}
						#price calculate
						if ($shop{"price_$i"}>10000000){
							$itemtosell{$index}{'price'} = 10000000;
						}elsif ($shop{"price_$i"}>0){
							$itemtosell{$index}{'price'} = $shop{"price_$i"};
						}else{
							$itemtosell{$index}{'price'} = 1;
						}
						$itemtosellorder[$items_selling] = $index;
						$items_selling++;
						last;
					}
				}
			}
			$i++;
		}

		my $length = 0x55 + 0x08 * $items_selling;

		my $msg = pack("C*", 0xB2, 0x01) . pack("S*", $length) . 
		$shop{'shop_title'} . chr(0) x (80 - length($shop{'shop_title'})) .  pack("C*", 0x01);

		foreach  (@itemtosellorder) {
			$msg .= pack("S1",$_) . pack("S1", $itemtosell{$_}{'amount'}) . pack("L1", $itemtosell{$_}{'price'});
		}
		if( length($msg) == $length ) {
			sendMsgToServer($r_socket, $msg);
			System::message "Openning Your Shop ( $shop{'shop_title'} )\n";
			$ai_v{'temp'}{'shopOpen'} = 1;
		}else{
			System::message "Error : opening shop...\n";
			shopconfigModify("shop_autoStart",0) if ($shop{'shop_autoStart'});
		}
		if ($ai_seq[0] eq "shopauto") {
			shift @ai_seq;
			shift @ai_seq_args;
		}
	}else{
		System::message "Can not  open shop ( no skill to use or Empty Shop name )\n";
		shopconfigModify("shop_autoStart",0) if ($shop{'shop_autoStart'});
	}
}

sub shopconfigModify {
	my $key = shift;
	my $val = shift;
	System::message "Shop Config '$key' set to $val\n";
	$shop{$key} = $val;
	FileParser::writeDataFileIntact("$System::def_config/shop.txt", \%shop);
}

sub changeDirection {
	my $r_hash1 = shift;
	my $r_hash2 = shift;
	my ($c_x,$c_y,$direction);
	$c_x = $$r_hash2{'x'} - $$r_hash1{'x'};
	$c_y = $$r_hash2{'y'} - $$r_hash1{'y'};
	
	if ($c_x > 0){
		$direction = ($c_y > 0) ? 7 : 5;
	}else{
		$direction = ($c_y > 0) ? 1 : 3;
	}
	System::message "Item:($$r_hash2{'x'},$$r_hash2{'y'}) Char:($$r_hash1{'x'},$$r_hash1{'y'}) Look to:$direction\n" if ($config{'debug'});
	sendLook(\$System::remote_socket,$direction,0);
}

sub JudgeAttackSameTarget{
	my $ID = shift;
	my $flag;
	if ((!$monsters{$ID}{'judge'} || ($monsters{$ID}{'judge'}<=$config{'antiJam_Count'} && $config{'antiJam_Count'}))&& $monsters{$ID}{'dmgTo'} ne $monsters{$ID}{'dmgFromYou'}){
		if(!$monsters{$ID}{'judge'} && $monsters{$ID}{'dmgFrom'} == 0 && $monsters{$ID}{'missedYou'} == 0 && $monsters{$ID}{'missedToPlayer'}>0 && $monsters{$ID}{'dmgToPlayer'}>0){
			$flag = "/sorry";
			$monsters{$ID}{'attack_failed'}++;
			attackStop(\$System::remote_socket, $ID);
		}else{
			$flag = "/angry";
		}
		$monsters{$ID}{'judge'}++;
		if ($config{'antiJam'}==1) {
			if ($config{'antiJam_Count'} && $monsters{$ID}{'judge'}<=$config{'antiJam_Count'}) {
				$ai_cmdQue[$ai_cmdQue]{'msg'} = $flag;
				$ai_cmdQue[$ai_cmdQue]{'user'} = "";
				$ai_cmdQue[$ai_cmdQue]{'type'} = "C";
				$ai_cmdQue[$ai_cmdQue]{'time'} = time;
				$ai_cmdQue++;
			}else{ useTeleport(1); }
		}elsif ($config{'antiJam'}==2){
			useTeleport(1);
		}
	}
}


sub attackStop {
	my $r_socket = shift;
	my $ID = shift;
	System::message "[Rep] Stop Attack : $monsters{$ID}{'name'} ($monsters{$ID}{'binID'})\n";
	shift @ai_seq;
	shift @ai_seq_args;
	sendAttackStop(\$$r_socket);
}

sub selectTarget{
	my @targetID = @_;
	my ($dist,$distMin,$foundID,$first);
	$first = 1;
	foreach (@targetID) {
		next if (positionNearPortal(\%{$monsters{$_}{'pos_to'}}, 4) || positionNearPortal(\%{$monsters{$_}{'pos'}}, 4));
		$dist = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$_}{'pos_to'}});
		if (($first || $dist<$distMin)
			&& (!defined(%{$mon_control{lc($monsters{$_}{'name'})}}) || ($mon_control{lc($monsters{$_}{'name'})}{'attack_auto'} > 0 && $mon_control{lc($monsters{$_}{'name'})}{'attack_auto'} > $mon_control{lc($monsters{$foundID}{'name'})}{'attack_auto'}))
			) {
			$distMin = $dist;
			$foundID = $_;
			$first = 0;
		}
	}
	return $foundID;
}

sub positionNearPortal {
	my $r_hash = shift;
	my $dist = shift;
	for (my $i = 0; $i < @portalsID; $i++) {
		next if ($portalsID[$i] eq "");
		return 1 if (distance($r_hash, \%{$portals{$portalsID[$i]}{'pos'}}) <= $dist);
	}
	return 0;
}

sub checkAuthorized{
	my $md5 = Digest::MD5->new;
	$md5->add($config{'username'});
	if ($config{'SecureCode'} ne $md5->hexdigest) {
		$md5->add($config{'username'});
		
		System::message "\n\nNot Authorized to used\n\n";
		$main::quit = 1;
	}
}

sub wipeCheck {
		##### MISC #####
	if (timeOut(\%{$timeout{'ai_wipe_check'}})) {
		foreach (keys %players_old) {
			delete $players_old{$_} if (time - $players_old{$_}{'gone_time'} >= $timeout{'ai_wipe_old'}{'timeout'});
		}
		foreach (keys %monsters_old) {
			delete $monsters_old{$_} if (time - $monsters_old{$_}{'gone_time'} >= $timeout{'ai_wipe_old'}{'timeout'});
		}
		foreach (keys %npcs_old) {
			delete $npcs_old{$_} if (time - $npcs_old{$_}{'gone_time'} >= $timeout{'ai_wipe_old'}{'timeout'});
		}
		foreach (keys %items_old) {
			delete $items_old{$_} if (time - $items_old{$_}{'gone_time'} >= $timeout{'ai_wipe_old'}{'timeout'});
		}
		foreach (keys %portals_old) {
			delete $portals_old{$_} if (time - $portals_old{$_}{'gone_time'} >= $timeout{'ai_wipe_old'}{'timeout'});
		}
		$timeout{'ai_wipe_check'}{'time'} = time;
		System::message "Wiped old\n" if ($config{'debug'} >= 2);
	}

	if (timeOut(\%{$timeout{'ai_getInfo'}})) {
		foreach (keys %players) {
			if ($players{$_}{'name'} eq "Unknown") {
				sendGetPlayerInfo(\$System::remote_socket, $_);
				last if (!$config{'fastInfoDetect'});
			}
		}
		foreach (keys %monsters) {
			if ($monsters{$_}{'name'} =~ /Unknown/) {
				sendGetPlayerInfo(\$System::remote_socket, $_);
				last if (!$config{'fastInfoDetect'});
			}
		}
		foreach (keys %npcs) { 
			if ($npcs{$_}{'name'} =~ /Unknown/) { 
				sendGetPlayerInfo(\$System::remote_socket, $_); 
				last if (!$config{'fastInfoDetect'});
			}
		}
		foreach (keys %pets) { 
			if ($pets{$_}{'name_given'} =~ /Unknown/) { 
				sendGetPlayerInfo(\$System::remote_socket, $_); 
				last if (!$config{'fastInfoDetect'});
			}
		}
		$timeout{'ai_getInfo'}{'time'} = time;
	}

	if (!$System::xMode && timeOut(\%{$timeout{'ai_sync'}})) {
		$timeout{'ai_sync'}{'time'} = time;
		sendSync(\$System::remote_socket, getTickCount());
	}
}

sub mainLoop{
	if (!$System::seedMode) {
		my $charName = $chars[$config{'char'}]{'name'};
		$charName .= ': ' if defined $charName;
		if ($conState == 5) {
			my ($title, $basePercent, $jobPercent, $weight, $pos);

			$tbase = sprintf("%.2f", $chars[$config{'char'}]{'exp'} / $chars[$config{'char'}]{'exp_max'} * 100) if $chars[$config{'char'}]{'exp_max'};
			$tjob = sprintf("%.2f", $chars[$config{'char'}]{'exp_job'} /$ chars[$config{'char'}]{'exp_job_max'} * 100) if $chars[$config{'char'}]{'exp_job_max'};
			$tweight = int($chars[$config{'char'}]{'weight'} / $chars[$config{'char'}]{'weight_max'} * 100) . "%" if $chars[$config{'char'}]{'weight_max'};
			$pos = "$field{'name'} : $chars[$config{'char'}]{'pos_to'}{'x'},$chars[$config{'char'}]{'pos_to'}{'y'}";
			
			$title = "$System::NAME - ${charName} (B$chars[$config{'char'}]{'lv'}:$tbase J$chars[$config{'char'}]{'lv_job'}:$tjob) w$tweight : ${pos}";
			$System::interface->title($title);

		} elsif ($conState == 1) {
			$System::interface->title("$System::NAME - Not connected");
		} else {
			$System::interface->title("$System::NAME - Connecting");
		}
	}
	Plugins::callHook("update");
	checkTimer();
}

1;