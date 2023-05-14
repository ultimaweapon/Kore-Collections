#########################################################################
#  modKore - Hybrid :: Packet Parser
#  http://modkore.sf.net
#
#  This software is open source, licensed under the GNU General Public
#  License, version 2.
#  Basically, this means that you're allowed to modify and distribute
#  this software. However, if you distribute modified versions, you MUST
#  also distribute the source code.
#  See http://www.gnu.org/licenses/gpl.html for the full license.
#########################################################################

#######################################
#######################################
#Parse RO Client Send Message
#######################################
#######################################

sub parseSendMsg {
	my $msg = shift;
	$sendMsg = $msg;
	if (length($msg) >= 4 && $conState >= 4 && length($msg) >= unpack("S1", substr($msg, 0, 2)) && $config{'encrypt'}) {
		decrypt(\$msg, $msg, $config{'encrypt'});
	}
	$switch = uc(unpack("H2", substr($msg, 1, 1))) . uc(unpack("H2", substr($msg, 0, 1)));

	# If the player tries to manually do something in the RO client, disable AI for a small period
	# of time using ai_clientSuspend().

	if ($switch eq "0066") {
		# Login character selected
		configModify("char", unpack("C*",substr($msg, 2, 1)));

	} elsif ($switch eq "0072") {
		# Map login
		if ($config{'sex'} ne "") {
			$sendMsg = substr($sendMsg, 0, 18) . pack("C",$config{'sex'});
		}

	} elsif ($switch eq "007D") {
		# Map loaded
		$conState = 5;
		$timeout{'ai'}{'time'} = time;
		$timeout{'ai_storagegetAuto'}{'time'} = time;
		if ($firstLoginMap) {
			undef $sentWelcomeMessage;
			undef $firstLoginMap;
		}
		$timeout{'welcomeText'}{'time'} = time;
		print "Map loaded\n";

	} elsif ($switch eq "0085") {
		# Move
		aiRemove("clientSuspend");
		makeCoords(\%coords, substr($msg, 2, 3));
		ai_clientSuspend($switch, (distance(\%{$chars[$config{'char'}]{'pos'}}, \%coords) * $config{'seconds_per_block'}) + 2);
	} elsif ($switch eq "0089") {
		# Attack
		if (!($config{'tankMode'} && binFind(\@ai_seq, "attack") ne "")) {
			aiRemove("clientSuspend");
			ai_clientSuspend($switch, 2, unpack("C*",substr($msg,6,1)), substr($msg,2,4));
		} else {
			undef $sendMsg;
		}
	} elsif ($switch eq "008C" || $switch eq "0108" || $switch eq "017E") {
		# Public, party and guild chat
		my $length = unpack("S",substr($msg,2,2));
		my $message = substr($msg, 4, $length - 4);
		my ($chat) = $message =~ /^[\s\S]*? : ([\s\S]*)\000?/;
		$chat =~ s/^\s*//;
		if ($chat =~ /^$config{'commandPrefix'}/) {
			$chat =~ s/^$config{'commandPrefix'}//;
			$chat =~ s/^\s*//;
			$chat =~ s/\s*$//;
			$chat =~ s/\000*$//;
			parseInput($chat, 1);
			undef $sendMsg;
		}

	} elsif ($switch eq "0096") {
		# Private message
		$length = unpack("S",substr($msg,2,2));
		($user) = substr($msg, 4, 24) =~ /([\s\S]*?)\000/;
		$chat = substr($msg, 28, $length - 29);
		$chat =~ s/^\s*//;
		if ($chat =~ /^$config{'commandPrefix'}/) {
			$chat =~ s/^$config{'commandPrefix'}//;
			$chat =~ s/^\s*//;
			$chat =~ s/\s*$//;
			parseInput($chat, 1);
			undef $sendMsg;
		} else {
			undef %lastpm;
			$lastpm{'msg'} = $chat;
			$lastpm{'user'} = $user;
			push @lastpm, {%lastpm};
		}
	} elsif ($switch eq "009F") {
		# Take
		aiRemove("clientSuspend");
		ai_clientSuspend($switch, 2, substr($msg,2,4));

	} elsif ($switch eq "00B2") {
		# Trying to exit (Respawn)
		aiRemove("clientSuspend");
		ai_clientSuspend($switch, 10);

	} elsif ($switch eq "018A") {
		# Trying to exit
		aiRemove("clientSuspend");
		ai_clientSuspend($switch, 10);
	}
	if ($config{'debug_sendPacket'}) {
		if (!defined($spackets{$switch}) && $sendMsg ne "" ) {
			dumpData($sendMsg,1);
		}
	}
	if ($sendMsg ne "") {
		sendToServerByInject(\$remote_socket, $sendMsg);
	}
}


#######################################
#######################################
#Parse Message
#######################################
#######################################



sub parseMsg {
	my $msg = shift;
	my $msg_size;

	if (length($msg) < 2) {
		return $msg;
	}

	$switch = uc(unpack("H2", substr($msg, 1, 1))) . uc(unpack("H2", substr($msg, 0, 1)));
	if (length($msg) >= 4 && substr($msg,0,4) ne $accountID && $conState >= 4 && $lastswitch ne $switch
		&& length($msg) >= unpack("S1", substr($msg, 0, 2)) && $config{'encrypt'}) {
		decrypt(\$msg, $msg, $config{'encrypt'});
	}

	$switch = uc(unpack("H2", substr($msg, 1, 1))) . uc(unpack("H2", substr($msg, 0, 1)));


	print "Packet Switch: $switch\n" if ($config{'debug'});

	if ($lastswitch eq $switch && length($msg) > $lastMsgLength) {
		$errorCount++;
	} else {
		$errorCount = 0;
	}
	if ($errorCount > 3) {
		dumpData($msg);
		$msg_size = length($msg);
		print "$last_know_switch > $switch ($msg_size): Caught unparsed packet error, potential loss of data.\n";
		$errorCount = 0;
	}
	
	$lastswitch = $switch;

	if (substr($msg,0,4) ne $accountID || ($conState != 2 && $conState != 4)) {
		if ($rpackets{$switch} eq "-") {
			# Complete packet; the size of this packet is equal to the size of the entire data
			$msg_size = length($msg);
		} elsif ($rpackets{$switch} eq "0") {
			# Variable length packet
			if (length($msg) < 4) {
				return $msg;
			}
			$msg_size = unpack("S1", substr($msg, 2, 2));
			if (length($msg) < $msg_size) {
				return $msg;
			}
		} elsif ($rpackets{$switch} > 1) {
			if (length($msg) < $rpackets{$switch}) {
				return $msg;
			}
			$msg_size = $rpackets{$switch};
		}else{
			dumpData($last_know_msg.$msg);
		}
		$last_know_msg = substr($msg, 0, $msg_size);
		$last_know_switch = $switch;
		dumpData($msg,$msg_size) if ($msg_size && $config{'debug_recv'});
	}

	$lastMsgLength = length($msg);

	if (substr($msg,0,4) eq $accountID && ($conState == 2 || $conState == 4)) {
		$accountID = substr($msg, 0, 4);
		$AI = 1 if (!$AI_forcedOff);
		if ($config{'encrypt'} && $conState == 4) {
			$encryptKey1 = unpack("L1", substr($msg, 6, 4));
			$encryptKey2 = unpack("L1", substr($msg, 10, 4));
			{
				use integer;
				$imult = (($encryptKey1 * $encryptKey2) + $encryptKey1) & 0xFF;
				$imult2 = ((($encryptKey1 * $encryptKey2) << 4) + $encryptKey2 + ($encryptKey1 * 2)) & 0xFF;
			}
			$encryptVal = $imult + ($imult2 << 8);
			$msg_size = 14;
		} else {
			$msg_size = 4;
		}
	} elsif ($switch eq "0069") {
		#0069 <len>.w <login ID1>.l <account ID>.l <login ID2>.l ?.32B <sex>.B {<IP>.l <port>.w <server name>.20B <login users>.w <maintenance>.w <new>.w}.32B*
		#Login info
		$conState = 2;
		undef $conState_tries;
		if ($versionSearch) {
			$versionSearch = 0;
			writeDataFileIntact("$def_config/config.txt",\%config);
		}
		$sessionID = substr($msg, 4, 4);
		$accountID = substr($msg, 8, 4);
		$sessionID2 = substr($msg, 12, 4);
		$accountSex = unpack("C1",substr($msg, 46, 1));
		$accountSex2 = ($config{'sex'} ne "") ? $config{'sex'} : $accountSex;
		print "---------Account Info----------\n";
		print sprintf("Account ID: %-20s\n",getHex($accountID));
		print sprintf("Sex:        %-20s\n",$sex_lut[$accountSex]);
		print sprintf("Session ID: %-20s\n",getHex($sessionID));
		print sprintf("            %-20s\n",getHex($sessionID2));
		print "-------------------------------\n";
		my $num = 0;
		undef @servers;
		print "--------- Servers ----------\n";
		print "#         Name            Users  IP              Port  Main  new\n";
		for(my $i = 47; $i < $msg_size; $i+=32) {
			$servers[$num]{'ip'} = makeIP(substr($msg, $i, 4));
			$servers[$num]{'port'} = unpack("S1", substr($msg, $i+4, 2));
			($servers[$num]{'name'}) = substr($msg, $i + 6, 20) =~ /([\s\S]*?)\000/;
			$servers[$num]{'users'} = unpack("S1",substr($msg, $i + 26, 2));
			$servers[$num]{'maintenance'} = unpack("S1",substr($msg, $i + 28, 2));
			$servers[$num]{'new'} = unpack("S1",substr($msg, $i + 30, 2));
			print sprintf("%-3d %-21s %-6d %-15s %-6d%-6d%-6d\n",$num,$servers[$num]{'name'},$servers[$num]{'users'},$servers[$num]{'ip'},$servers[$num]{'port'},$servers[$num]{'maintenance'},$servers[$num]{'new'});
			$num++;
		}
		print "-------------------------------\n";
		if (!$sys{'Xmode'}) {
			print "Closing connection to Master Server\n";
			killConnection(\$remote_socket);
			if (!$config{'charServer_host'} && $config{'server'} eq "") {
				print "Choose your server.  Enter the server number:\n";
				$waitingForInput = 1;
			} elsif ($config{'charServer_host'}) {
				print "Forcing connect to char server $config{'charServer_host'}:$config{'charServer_port'}\n";
			} else {
				print "Server $config{'server'} selected\n";
			}
		}
	} elsif ($switch eq "006A") {
		#006a <error No>.B
		#login error
		my $type = unpack("C1",substr($msg, 2, 1));
		if ($type == 0) {
			print "Account name doesn't exist\n";
			if (!$sys{'Xmode'}) {
				print "Enter Username Again: \n";
				if (!$sys{'Vx_interface'}) {
					$msg = Input::readLine();
				}else{
					until ($msg ne "") {
						Vx::update();
						$msg = Vx::getInput();
					}
				}
				$config{'username'} = $msg;
				writeDataFileIntact("$def_config/config.txt", \%config);
			}
		} elsif ($type == 1) {
			print "Password Error\n";
			if (!$sys{'Xmode'}) {
				print "Enter Password Again: \n";
				if (!$sys{'Vx_interface'}) {
					$msg = Input::readLine();
				}else{
					until ($msg ne "") {
						Vx::update();
						$msg = Vx::getInput();
					}
				}
				$config{'password'} = $msg;
				writeDataFileIntact("$def_config/config.txt", \%config);
			}
		} elsif ($type == 3) {
			print "Server connection has been denied\n";
		} elsif ($type == 4) {
			print "Critical Error: Account has been disabled by evil Gravity\n";
			quit();
		} elsif ($type == 5) {
			print "Version $config{'version'} failed...trying to find version\n";
			$config{'version'}++;
			if (!$versionSearch) {
				$config{'version'} = 0;
				$versionSearch = 1;
			}
		} elsif ($type == 6) {
			print "The server is temporarily blocking your connection\n";
		}
		if ($type != 5 && $versionSearch) {
			$versionSearch = 0;
			writeDataFileIntact("$def_config/config.txt", \%config);
		}

	} elsif ($switch eq "006B") {
		#006b <len>.w <charactor select data>.106B*
		#Character select connection success & character data 
		print "Recieved characters from Game Login Server\n";
		$conState = 3;
		undef $conState_tries;
		my $startVal;
		if ($config{"master_version_$config{'master'}"} == 0) {
			$startVal = 24;
		} else {
			$startVal = 4;
		}
		for(my $i = $startVal; $i < $msg_size; $i+=106) {
			#exp display bugfix - chobit andy 20030129
			$num = unpack("C1", substr($msg, $i + 104, 1));
			$chars[$num]{'exp'} = unpack("L1", substr($msg, $i + 4, 4));
			$chars[$num]{'zenny'} = unpack("L1", substr($msg, $i + 8, 4));
			$chars[$num]{'exp_job'} = unpack("L1", substr($msg, $i + 12, 4));
			$chars[$num]{'lv_job'} = unpack("C1", substr($msg, $i + 16, 1));
			#$chars[$num]{'hp'} = unpack("S1", substr($msg, $i + 42, 2));
			$chars[$num]{'hp_max'} = unpack("S1", substr($msg, $i + 44, 2));
			#$chars[$num]{'sp'} = unpack("S1", substr($msg, $i + 46, 2));
			$chars[$num]{'sp_max'} = unpack("S1", substr($msg, $i + 48, 2));
			$chars[$num]{'jobID'} = unpack("C1", substr($msg, $i + 52, 1));
			$chars[$num]{'lv'} = unpack("C1", substr($msg, $i + 58, 1));
			($chars[$num]{'name'}) = substr($msg, $i + 74, 24) =~ /([\s\S]*?)\000/;
			$chars[$num]{'str'} = unpack("C1", substr($msg, $i + 98, 1));
			$chars[$num]{'agi'} = unpack("C1", substr($msg, $i + 99, 1));
			$chars[$num]{'vit'} = unpack("C1", substr($msg, $i + 100, 1));
			$chars[$num]{'int'} = unpack("C1", substr($msg, $i + 101, 1));
			$chars[$num]{'dex'} = unpack("C1", substr($msg, $i + 102, 1));
			$chars[$num]{'luk'} = unpack("C1", substr($msg, $i + 103, 1));
			$chars[$num]{'sex'} = $accountSex2;
			calPercent(\%{$chars[$num]},"hp",unpack("S1", substr($msg, $i + 42, 2)));
			calPercent(\%{$chars[$num]},"sp",unpack("S1", substr($msg, $i + 46, 2)));
		}
		for (my $num = 0; $num < @chars; $num++) {
			print sprintf("-------  Character %2d ---------\n",$num);
			print sprintf("Name: %-25s\n",$chars[$num]{'name'});
			print sprintf("Job:  %-8s      Job Exp: %-8s\n",$jobs_lut{$chars[$num]{'jobID'}},$chars[$num]{'exp_job'});
			print sprintf("Lv:   %-8s      Str: %-8s\n",$chars[$num]{'lv'},$chars[$num]{'str'});
			print sprintf("J.Lv: %-8s      Agi: %-8s\n",$chars[$num]{'lv_job'},$chars[$num]{'agi'});
			print sprintf("Exp:  %-8s      Vit: %-8s\n",$chars[$num]{'exp'},$chars[$num]{'vit'});
			print sprintf("HP:   %-4s/%-4s   Int: %-8s\n",$chars[$num]{'hp'},$chars[$num]{'hp_max'},$chars[$num]{'int'});
			print sprintf("SP:   %-4s/%-4s   Dex: %-8s\n",$chars[$num]{'sp'},$chars[$num]{'sp_max'},$chars[$num]{'dex'});
			print sprintf("Zenny: %-12s  Luk: %-8s\n",$chars[$num]{'zenny'},$chars[$num]{'luk'});
			print "-------------------------------\n";
		}
		if (!$sys{'Xmode'}) {
			if ($config{'char'} eq "") {
				print "Choose your character.  Enter the character number:\n";
				$waitingForInput = 1;
			} else {
				print "Character $config{'char'} selected\n";
				sendCharLogin(\$remote_socket, $config{'char'});
				$timeout{'gamelogin'}{'time'} = time;
			}
		}
		$firstLoginMap = 1;
		$sentWelcomeMessage = 1;

	} elsif ($switch eq "006C") {
		#006c <error No> B
		#Failure of character selection 
		print "Error logging into Game Login Server (invalid character specified)...\n";
		$conState = 1;
		undef $conState_tries;
		$timeout_ex{'master'}{'time'} = time;
		$timeout_ex{'master'}{'timeout'} = $timeout{'reconnect'}{'timeout'};
		killConnection(\$remote_socket);

	#006e <error No> B 
	#Failure of character compilation

	#006f
	#Character deletion success

	#0070 <error No> B
	#Failure of character deletion 

	} elsif ($switch eq "0071") {
		#0071 <character ID> l <map name> 16B <ip> l <port> w 
		#Character selection success & map name & game IP/port
		print "Recieved character ID and Map IP from Game Login Server\n";
		$conState = 4;
		undef $conState_tries;
		$charID = substr($msg, 2, 4);
		($map_name) = substr($msg, 6, 16) =~ /([\s\S]*?)\000/;

		($ai_v{'temp'}{'map'}) = $map_name =~ /([\s\S]*)\./;
		sysLog("B"," *** Welcome to modKore - Hybrid *** \n");
		if ($ai_v{'temp'}{'map'} ne $field{'name'}) {
			getField("$def_field/$ai_v{'temp'}{'map'}.fld", \%field);
			sysLog("M","**Map : $field{'name'}\n");
			if ($sys{'Vx_interface'}) {
				if ($field{'name'} eq $config{"lockMap_$ai_v{'lockMapIndex'}"} || !$config{"lockMap_$ai_v{'lockMapIndex'}"}) {
					Vx::status_update("On Map : $field{'name'}");
				}else{
					Vx::status_update("On Map : $field{'name'} | LockMap : ".$config{"lockMap_$ai_v{'lockMapIndex'}"});
				}
			}
		}
		$map_ip = makeIP(substr($msg, 22, 4));
		$map_port = unpack("S1", substr($msg, 26, 2));
		print "---------Game Info----------\n";
		print sprintf("Char ID: %-20s\n",getHex($charID));
		print sprintf("MAP Name: %-20s\n",$map_name);
		print sprintf("MAP IP: %-20s\n",$map_ip);
		print sprintf("MAP Port: %-20s\n",$map_port);
		print "-------------------------------\n";
		print "Closing connection to Game Login Server\n" if (!$sys{'Xmode'});
		killConnection(\$remote_socket) if (!$sys{'Xmode'});

	} elsif ($switch eq "0073") {
		#0073 <server tick> l <coordinate> 3B? 2B 
		#Game connection success & server side 1ms clock & appearance position 
		$conState = 5 if (!$sys{'Xmode'});
		undef $conState_tries;
		makeCoords(\%{$chars[$config{'char'}]{'pos'}}, substr($msg, 6, 3));
		%{$chars[$config{'char'}]{'pos_to'}} = %{$chars[$config{'char'}]{'pos'}};
		Vx::pos_update($chars[$config{'char'}]{'pos'}{'x'},$chars[$config{'char'}]{'pos'}{'y'}) if ($sys{'Vx_interface'});
		print "Your Coordinates: $chars[$config{'char'}]{'pos'}{'x'}, $chars[$config{'char'}]{'pos'}{'y'}\n" if $config{'debug'};
		if (!$sys{'Xmode'}) {
			print "You are now in the game\n";
			sendMapLoaded(\$remote_socket);
			sendLook(\$remote_socket,int(rand(8)),int(rand(3)));
			$timeout{'ai'}{'time'} = time;
			$timeout{'ai_storagegetAuto'}{'time'} = time;
		}else{
			print "Waiting for map to load...\n";
		}
		# Ignored Ppl
		if ($config{'ignoredAll'}) {
			print "Forcing Ignored-All...\n";
			sendIgnoreAll(\$remote_socket,0);
		}elsif (%ppl_control){
			print "Ignored Player in Ignored List....";
			 foreach $ppl ( keys %ppl_control ) {
				sendIgnore(\$remote_socket, $ppl, 0) if ($ppl_control{$ppl}{'ignored_auto'});
			 }
			 print "Done\n";
		}

	} elsif ($switch eq "0075") {
		$conState = 5 if ($conState != 4 && $sys{'Xmode'});

	} elsif ($switch eq "0077") {
		$conState = 5 if ($conState != 4 && $sys{'Xmode'});

	} elsif ($switch eq "0078" || $switch eq "01D8") {
		#0078 <ID> l <speed> w <opt1> w <opt2> w <option> w <class> w <hair> w <weapon> w <head option bottom> w <shield> w <head option top> w <head option mid> w <hair color> w? W <head dir> w <guild> l <emblem> l <manner> w <karma> B <sex> B <X_Y_dir> 3B? B? B <sit> B <Lv> B
		#01d8 <ID>.l <speed>.w <opt1>.w <opt2>.w <option>.w <class>.w <hair>.w <item id1>.w <item id2>.w <head option bottom>.w <head option top>.w <head option mid>.w <hair color>.w ?.w <head dir>.w <guild>.l <emblem>.l <manner>.w <karma>.B <sex>.B <X_Y_dir>.3B ?.B ?.B <sit>.B <Lv>.B ?.B
		#0078 mainly is monster , portal
		#01D8 = npc + player for episode 4+
		$conState = 5 if ($conState != 4 && $sys{'Xmode'});
		my $ID = substr($msg, 2, 4);
		my $state = unpack("S*",substr($msg, 8, 2));
		# if ($option > 1024) -> ID is hiding !!.
		my $option = unpack("S1",substr($msg, 12,  2));
		my $type = unpack("S*",substr($msg, 14,  2));
		my $pet = unpack("C*",substr($msg, 16,  1));
		my $sex = unpack("C*",substr($msg, 45,  1));
		makeCoords(\%coords, substr($msg, 46, 3));
		my $sitting = unpack("C*",substr($msg, 51,  1));

		if ($jobs_lut{$type}) {
			if (!%{$players{$ID}}) {
				Vx::addObj($ID,"p") if ($sys{'Vx_interface'});
				binAdd(\@playersID, $ID);
				$players{$ID}{'jobID'} = $type;
				$players{$ID}{'sex'} = $sex;
				$players{$ID}{'name'} = "Unknown";
				$players{$ID}{'nameID'} = unpack("L1", $ID);
				$players{$ID}{'binID'} = binFind(\@playersID, $ID);
				$players{$ID}{'appear_time'} = time;
				$players{$ID}{'option'} = $option;
			}
			$players{$ID}{'sitting'} = $sitting > 0;
			%{$players{$ID}{'pos'}} = %coords;
			%{$players{$ID}{'pos_to'}} = %coords;
			print "Player Exists: $players{$ID}{'name'} ($players{$ID}{'binID'}) $sex_lut[$players{$ID}{'sex'}] $jobs_lut{$players{$ID}{'jobID'}} \n" if ($config{'debug'});

		} elsif ($type >= 1000) {
			if ($pet) {
				if (!%{$pets{$ID}}) {
					$pets{$ID}{'appear_time'} = time;
					$display = ($monsters_lut{$type} ne "") ? $monsters_lut{$type}: "Unknown ".$type;
					binAdd(\@petsID, $ID);
					$pets{$ID}{'nameID'} = $type;
					$pets{$ID}{'name'} = $display;
					$pets{$ID}{'name_given'} = "Unknown";
					$pets{$ID}{'binID'} = binFind(\@petsID, $ID);
				}
				if (%{$monsters{$ID}}) {
					if ($sys{'Vx_interface'}) {
						Vx::removeObj($ID);
					}
					binRemove(\@monstersID, $ID);
					undef %{$monsters{$ID}};
				}
				%{$pets{$ID}{'pos'}} = %coords;
				%{$pets{$ID}{'pos_to'}} = %coords;
				print "Pet Exists: $pets{$ID}{'name'} ($pets{$ID}{'binID'})\n" if ($config{'debug'});
			} else {
				if (!%{$monsters{$ID}}) {
					$monsters{$ID}{'appear_time'} = time;
					$display = ($monsters_lut{$type} ne "") 
							? $monsters_lut{$type}
							: "Unknown ".$type;
					binAdd(\@monstersID, $ID);
					$monsters{$ID}{'nameID'} = $type;
					$monsters{$ID}{'name'} = $display;
					$monsters{$ID}{'binID'} = binFind(\@monstersID, $ID);
				}
				my $prevState = $monsters{$ID}{'state'};
				$monsters{$ID}{'state'} = $state;
				$monsters{$ID}{'state'} = 0 if ($monsters{$ID}{'state'} == 5);
				%{$monsters{$ID}{'pos'}} = %coords;
				%{$monsters{$ID}{'pos_to'}} = %coords;
				Vx::addObj($ID,"m") if ($sys{'Vx_interface'});
				print "Monster Exists: $monsters{$ID}{'name'} ($monsters{$ID}{'binID'})\n" if ($config{'debug'});
			}

		} elsif ($type == 45) {
			if (!%{$portals{$ID}}) {
				$portals{$ID}{'appear_time'} = time;
				$nameID = unpack("L1", $ID);
				$exists = portalExists(\%portals_lut,$field{'name'}, \%coords);
				$display = ($exists ne "") 
					? "$portals_lut{$exists}{'source'}{'map'} -> $portals_lut{$exists}{'dest'}{'map'}"
					: "Unknown ".$nameID;
				binAdd(\@portalsID, $ID);
				$portals{$ID}{'source'}{'map'} = $field{'name'};
				$portals{$ID}{'type'} = $type;
				$portals{$ID}{'nameID'} = $nameID;
				$portals{$ID}{'name'} = $display;
				$portals{$ID}{'binID'} = binFind(\@portalsID, $ID);
			}
			%{$portals{$ID}{'pos'}} = %coords;
			print "Portal Exists: $portals{$ID}{'name'} - ($portals{$ID}{'binID'})\n";

		} elsif ($type < 1000) {
			if (!%{$npcs{$ID}}) {
				Vx::addObj($ID,"npc") if ($sys{'Vx_interface'});
				$npcs{$ID}{'appear_time'} = time;
				$nameID = unpack("L1", $ID);
				$display = (%{$npcs_lut{$nameID}}) ? $npcs_lut{$nameID}{'name'} : "Unknown ".$nameID;
				binAdd(\@npcsID, $ID);
				$npcs{$ID}{'type'} = $type;
				$npcs{$ID}{'nameID'} = $nameID;
				$npcs{$ID}{'name'} = $display;
				$npcs{$ID}{'binID'} = binFind(\@npcsID, $ID);
			}
			%{$npcs{$ID}{'pos'}} = %coords;
			print "NPC Exists: $npcs{$ID}{'name'} - $npcs{$ID}{'nameID'} - ($npcs{$ID}{'binID'})\n";

		} else {
			print "Unknown Exists: $type - ".unpack("L*",$ID)."\n" if $config{'debug'};
		}
		Vx::moveObj($ID,"un",$coords{'x'},$coords{'y'}) if ($sys{'Vx_interface'} && $type !=45 && !$pet);

	} elsif ($switch eq "0079" || $switch eq "01D9") {
		#0079 <ID>.l <speed>.w <opt1>.w <opt2>.w <option>.w <class>.w <hair>.w <weapon>.w <head option bottom>.w <sheild>.w <head option top>.w <head option mid>.w <hair color>.w ?.w <head dir>.w <guild>.l <emblem>.l <manner>.w <karma>.B <sex>.B <X_Y_dir>.3B ?.B ?.B <Lv>.B
		#01d9 <ID>.l <speed>.w <opt1>.w <opt2>.w <option>.w <class>.w <hair>.w <item id1>.w <item id2>.w.<head option bottom>.w <head option top>.w <head option mid>.w <hair color>.w ?.w <head dir>.w <guild>.l <emblem>.l <manner>.w <karma>.B <sex>.B <X_Y_dir>.3B ?.B ?.B <Lv>.B ?.B
		#For boiling Character inside the indicatory range of teleport and the like, it faces and is not attached Character information? 
		$conState = 5 if ($conState != 4 && $sys{'Xmode'});
		my $ID = substr($msg, 2, 4);
		makeCoords(\%coords, substr($msg, 46, 3));
		my $type = unpack("S*",substr($msg, 14,  2));
		my $sex = unpack("C*",substr($msg, 45,  1));

		if ($jobs_lut{$type}) {
			if (!%{$players{$ID}}) {
				binAdd(\@playersID, $ID);
				$players{$ID}{'jobID'} = $type;
				$players{$ID}{'sex'} = $sex;
				$players{$ID}{'name'} = "Unknown";
				$players{$ID}{'nameID'} = unpack("L1", $ID);
				$players{$ID}{'binID'} = binFind(\@playersID, $ID);
				$players{$ID}{'appear_time'} = time;
			}
			%{$players{$ID}{'pos'}} = %coords;
			%{$players{$ID}{'pos_to'}} = %coords;
			print "Player Connected: $players{$ID}{'name'} ($players{$ID}{'binID'}) $sex_lut[$players{$ID}{'sex'}] $jobs_lut{$players{$ID}{'jobID'}}\n" if ($config{'debug'});

		} else {
			print "Unknown Connected: $type - ".getHex($ID)."\n" if $config{'debug'};
		}
		if ($sys{'Vx_interface'}) {
			Vx::moveObj($ID,"p",$coords{'x'},$coords{'y'});
		}

	} elsif ($switch eq "007A") {
		$conState = 5 if ($conState != 4 && $sys{'Xmode'});

	} elsif ($switch eq "007B" || $switch eq "01DA") {
		#007b <ID> l <speed> w <opt1> w <opt2> w <option> w <class> w <hair> w <weapon> w <head option bottom> w <server tick> l <shield> w <head option top> w <head option mid> w <hair color> w? W <head dir> w <guild> l <emblem> l <manner> w <karma> B <sex> B <X_Y_X_Y> 5B? B? B? B <Lv> B 
		#01da <ID>.l <speed>.w <opt1>.w <opt2>.w <option>.w <class>.w <hair>.<item id1>.w <item id2>.w <head option bottom>.w <server tick>.l <head option top>.w <head option mid>.w <hair color>.w ?.w <head dir>.w <guild>.l <emblem>.l <manner>.w <karma>.B <sex>.B <X_Y_X_Y>.5B ?.B ?.B ?.B <Lv>.B ?.B
		#Information of Character movement inside indicatory range 
		$conState = 5 if ($conState != 4 && $sys{'Xmode'});
		my $ID = substr($msg, 2, 4);
		makeCoords(\%coordsFrom, substr($msg, 50, 3));
		makeCoords2(\%coordsTo, substr($msg, 52, 3));
		# if ($option > 1024) -> ID is hiding !!.
		my $option = unpack("S1",substr($msg, 12,  2));
		my $type = unpack("S1",substr($msg, 14,  2));
		my $pet = unpack("C1",substr($msg, 16,  1));
		my $sex = unpack("C1",substr($msg, 49,  1));

		if ($jobs_lut{$type}) {
			if (!%{$players{$ID}}) {
				Vx::addObj($ID,"p") if ($sys{'Vx_interface'});
				binAdd(\@playersID, $ID);
				$players{$ID}{'jobID'} = $type;
				$players{$ID}{'sex'} = $sex;
				$players{$ID}{'name'} = "Unknown";
				$players{$ID}{'nameID'} = unpack("L1", $ID);
				$players{$ID}{'binID'} = binFind(\@playersID, $ID);
				$players{$ID}{'appear_time'} = time;
				$players{$ID}{'option'} = $option;
				print "Player Appeared: $players{$ID}{'name'} ($players{$ID}{'binID'}) $sex_lut[$sex] $jobs_lut{$type}\n" if $config{'debug'};
			}
			%{$players{$ID}{'pos'}} = %coordsFrom;
			%{$players{$ID}{'pos_to'}} = %coordsTo;
			print "Player Moved: $players{$ID}{'name'} ($players{$ID}{'binID'}) $sex_lut[$players{$ID}{'sex'}] $jobs_lut{$players{$ID}{'jobID'}}\n" if ($config{'debug'} >= 2);

		} elsif ($type >= 1000) {
			if ($pet) {
				if (!%{$pets{$ID}}) {
					$pets{$ID}{'appear_time'} = time;
					$display = ($monsters_lut{$type} ne "") ? $monsters_lut{$type}: "Unknown ".$type;
					binAdd(\@petsID, $ID);
					$pets{$ID}{'nameID'} = $type;
					$pets{$ID}{'name'} = $display;
					$pets{$ID}{'name_given'} = "Unknown";
					$pets{$ID}{'binID'} = binFind(\@petsID, $ID);
				}
				%{$pets{$ID}{'pos'}} = %coords;
				%{$pets{$ID}{'pos_to'}} = %coords;
				if (%{$monsters{$ID}}) {
					if ($sys{'Vx_interface'}) {
						Vx::removeObj($ID);
					}
					binRemove(\@monstersID, $ID);
					undef %{$monsters{$ID}};
				}
				print "Pet Moved: $pets{$ID}{'name'} ($pets{$ID}{'binID'})\n" if ($config{'debug'});
			} else {
				if (!%{$monsters{$ID}}) {
					Vx::addObj($ID,"m") if ($sys{'Vx_interface'});
					binAdd(\@monstersID, $ID);
					$monsters{$ID}{'appear_time'} = time;
					$monsters{$ID}{'nameID'} = $type;
					$display = ($monsters_lut{$type} ne "") ? $monsters_lut{$type} : "Unknown ".$type;
					$monsters{$ID}{'nameID'} = $type;
					$monsters{$ID}{'name'} = $display;
					$monsters{$ID}{'binID'} = binFind(\@monstersID, $ID);
					print "Monster Appeared: $monsters{$ID}{'name'} ($monsters{$ID}{'binID'})\n" if $config{'debug'};
				}
				%{$monsters{$ID}{'pos'}} = %coordsFrom;
				%{$monsters{$ID}{'pos_to'}} = %coordsTo;
				print "Monster Moved: $monsters{$ID}{'name'} ($monsters{$ID}{'binID'})\n" if ($config{'debug'} >= 2);
			}

		} else {
			print "Unknown Moved: $type - ".getHex($ID)."\n" if $config{'debug'};
		}
		if ($sys{'Vx_interface'}) {
			Vx::moveObj($ID,"un",$coordsFrom{'x'},$coordsFrom{'y'},$coordsTo{'x'},$coordsTo{'y'});
		}

	} elsif ($switch eq "007C") {
		#007c <ID> l <speed> w? 6w <class> w? 7w <X_Y> 3B? 2B 
		#Character information inside the indicatory range for NPC
		$conState = 5 if ($conState != 4 && $sys{'Xmode'});
		my $ID = substr($msg, 2, 4);
		makeCoords(\%coords, substr($msg, 36, 3));
		my $type = unpack("S*",substr($msg, 20,  2));
		my $sex = unpack("C*",substr($msg, 35,  1));

		if ($jobs_lut{$type}) {
			if (!%{$players{$ID}}) {
				binAdd(\@playersID, $ID);
				$players{$ID}{'jobID'} = $type;
				$players{$ID}{'sex'} = $sex;
				$players{$ID}{'name'} = "Unknown";
				$players{$ID}{'nameID'} = unpack("L1", $ID);
				$players{$ID}{'binID'} = binFind(\@playersID, $ID);
				$players{$ID}{'appear_time'} = time;
			}
			%{$players{$ID}{'pos'}} = %coords;
			%{$players{$ID}{'pos_to'}} = %coords;
			if ($sys{'Vx_interface'}) {
				Vx::addObj($ID,"p");
			}
			print "Player Spawned: $players{$ID}{'name'} ($players{$ID}{'binID'}) $sex_lut[$players{$ID}{'sex'}] $jobs_lut{$players{$ID}{'jobID'}}\n" if ($config{'debug'});

		} elsif ($type >= 1000) {
			if (!%{$monsters{$ID}}) {
				binAdd(\@monstersID, $ID);
				$monsters{$ID}{'nameID'} = $type;
				$monsters{$ID}{'appear_time'} = time;
				$display = ($monsters_lut{$monsters{$ID}{'nameID'}} ne "") ? $monsters_lut{$monsters{$ID}{'nameID'}}
						: "Unknown ".$monsters{$ID}{'nameID'};
				$monsters{$ID}{'name'} = $display;
				$monsters{$ID}{'binID'} = binFind(\@monstersID, $ID);
			}
			%{$monsters{$ID}{'pos'}} = %coords;
			%{$monsters{$ID}{'pos_to'}} = %coords;
			if ($sys{'Vx_interface'}) {
				Vx::addObj($ID,"m");
			}
			print "Monster Spawned: $monsters{$ID}{'name'} ($monsters{$ID}{'binID'})\n" if ($config{'debug'});
		} else {
			print "Unknown Spawned: $type - ".getHex($ID)."\n" if $config{'debug'};
		}
		if ($sys{'Vx_interface'}) {
			Vx::moveObj($ID,"un",$coords{'x'},$coords{'y'});
		}

	} elsif ($switch eq "007F") {
		#007f <server tick> l 
		#Server side 1ms timer transmission 
		$conState = 5 if ($conState != 4 && $sys{'Xmode'});
		my $time = unpack("L1",substr($msg, 2, 4));
		print "Recieved Sync\n" if ($config{'debug'} >= 2);
		$timeout{'play'}{'time'} = time;
	
	} elsif ($switch eq "0080") {
		#0080 <ID> l <type> B
		#Character Status (include other)
		$conState = 5 if ($conState != 4 && $sys{'Xmode'});
		my $ID = substr($msg, 2, 4);
		my $type = unpack("C1",substr($msg, 6, 1));
		
		if ($ID eq $accountID) {
			print "You have died\n";
			$chars[$config{'char'}]{'dead'} = 1;
			$chars[$config{'char'}]{'dead_time'} = time;
			sysLog("c","You've die (${maps_lut{$field{'name'}.'.rsw'}}:$field{'name'})\n");
		} elsif (%{$monsters{$ID}}) {
			%{$monsters_old{$ID}} = %{$monsters{$ID}}; 
			$monsters_old{$ID}{'gone_time'} = time; 
			if ($type == 0) { 
				print "Monster Disappeared: $monsters{$ID}{'name'}($monsters{$ID}{'binID'})\n" if ($config{'debug'}); 
				$monsters_old{$ID}{'disappeared'} = 1; 
			} elsif ($type == 1) {
				print "Monster Died: $monsters{$ID}{'name'}($monsters{$ID}{'binID'})\n" if ($config{'debug'}); 
				$monsters_old{$ID}{'dead'} = 1; 
			} elsif ($type == 3) { 
				print "Monster Teleported: $monsters{$ID}{'name'}($monsters{$ID}{'binID'})\n" if $config{'debug'}; 
				$monsters_old{$ID}{'teleported'} = 1; 
			}
			binRemove(\@monstersID, $ID); 
			undef %{$monsters{$ID}}; 
		} elsif (%{$players{$ID}}) {
			if ($type == 0) {
				print "Player Disappeared: $players{$ID}{'name'} ($players{$ID}{'binID'}) $sex_lut[$players{$ID}{'sex'}] $jobs_lut{$players{$ID}{'jobID'}}\n" if $config{'debug'};
				$players_old{$ID}{'disappeared'} = 1;
			} elsif ($type == 1) {
				print "Player Died: $players{$ID}{'name'} ($players{$ID}{'binID'}) $sex_lut[$players{$ID}{'sex'}] $jobs_lut{$players{$ID}{'jobID'}}\n";
				$players{$ID}{'dead'} = 1;
			} elsif ($type == 2) {
				print "Player Disconnected: $players{$ID}{'name'}\n" if $config{'debug'};
				$players_old{$ID}{'disconnected'} = 1;
			} elsif ($type == 3) {
				print "Player Teleported: $players{$ID}{'name'}\n" if $config{'debug'};
				$players_old{$ID}{'disappeared'} = 1;
			}
			if ($type != 1) {
				%{$players_old{$ID}} = %{$players{$ID}};
				$players_old{$ID}{'gone_time'} = time;
				binRemove(\@playersID, $ID);
				undef %{$players{$ID}};
				for ($i = 0; $i < @partyUsersID; $i++) { 
					next if ($partyUsersID[$i] eq ""); 
					undef %{$chars[$config{'char'}]{'party'}{'users'}{$ID}{'pos'}} if ($ID eq $_);
				} 
			}
			if (%{$venderLists{$ID}}) {
				binRemove(\@venderListsID, $ID); 
				undef %{$venderLists{$ID}}; 
			}
		} elsif (%{$players_old{$ID}}) {
			if ($type != 1) {
				print "Player Disconnected: $players_old{$ID}{'name'}\n" if $config{'debug'};
				$players_old{$ID}{'disconnected'} = 1;
			}
		} elsif (%{$portals{$ID}}) {
			print "Portal Disappeared: $portals{$ID}{'name'} ($portals{$ID}{'binID'})\n" if ($config{'debug'});
			%{$portals_old{$ID}} = %{$portals{$ID}};
			$portals_old{$ID}{'disappeared'} = 1;
			$portals_old{$ID}{'gone_time'} = time;
			binRemove(\@portalsID, $ID);
			undef %{$portals{$ID}};
		} elsif (%{$npcs{$ID}}) {
			print "NPC Disappeared: $npcs{$ID}{'name'} ($npcs{$ID}{'binID'})\n" if ($config{'debug'});
			%{$npcs_old{$ID}} = %{$npcs{$ID}};
			$npcs_old{$ID}{'disappeared'} = 1;
			$npcs_old{$ID}{'gone_time'} = time;
			binRemove(\@npcsID, $ID);
			undef %{$npcs{$ID}};
			# removing talk service when npc disappeared
			if ($talk{'ID'} eq $ID) { undef %talk; }
		} elsif (%{$pets{$ID}}) {
			undef %{$chars[$config{'char'}]{'pet'}} if ($chars[$config{'char'}]{'pet'}{'ID'} == $ID);
			print "Pet Disappeared: $pets{$ID}{'name'} ($pets{$ID}{'binID'})\n" if ($config{'debug'});
			binRemove(\@petsID, $ID);
			undef %{$pets{$ID}};
		} else {
			print "Unknown Disappeared: ".getHex($ID)."\n" if $config{'debug'};
		}
		if ($sys{'Vx_interface'}) {
			Vx::removeObj($ID);
		}

	} elsif ($switch eq "0081") {
		#0081 <type> B
		#Login Failure 2
		my $type = unpack("C1", substr($msg, 2, 1));
		$conState = 1;
		undef $conState_tries;
		$timeout_ex{'master'}{'time'} = time;
		$timeout_ex{'master'}{'timeout'} = $timeout{'reconnect'}{'timeout'};
		if ($type == 2) {
			print "Critical Error: Dual login prohibited - Someone trying to login!\n";
			if ($config{'dcOnDualLogin'} == 1) {
				print "Disconnect immediately!\n";
				quit();
			} elsif ($config{'dcOnDualLogin'} >= 2) {
				print "Disconnect for $config{'dcOnDualLogin'} seconds...\n";
				$timeout_ex{'master'}{'time'} = time;
				$timeout_ex{'master'}{'timeout'} = $config{'dcOnDualLogin'};
			}
		} elsif ($type == 3) {
			print "Error: Out of sync with server\n";
		} elsif ($type == 5) {
			print "Critical Error: Your age under 18\n";
			quit();
		} elsif ($type == 6) {
			print "Critical Error: You must pay to play this account!\n";
			quit();
		} elsif ($type == 8) {
			print "Error: The server still recognizes your last connection\n";
		}

	} elsif ($switch eq "0087") {
		#0087 <server tick> l <X_Y_X_Y> 5B? B 
		#Movement response 
		$conState = 5 if ($conState != 4 && $sys{'Xmode'});
		makeCoords(\%coordsFrom, substr($msg, 6, 3));
		makeCoords2(\%coordsTo, substr($msg, 8, 3));
		%{$chars[$config{'char'}]{'pos'}} = %coordsFrom;
		%{$chars[$config{'char'}]{'pos_to'}} = %coordsTo;
		Vx::pos_update($coordsTo{'x'},$coordsTo{'y'}) if ($sys{'Vx_interface'});
		print "You move to $field{'name'} : $coordsTo{'x'}, $coordsTo{'y'}\n" if ($config{'debug'});
		$chars[$config{'char'}]{'time_move'} = time;
		$chars[$config{'char'}]{'time_move_calc'} = distance(\%{$chars[$config{'char'}]{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}}) * $config{'seconds_per_block'};

	} elsif ($switch eq "0088") {
		#0088 <ID> l <X> w <Y> w
		# Long distance attack solution 
		my $ID = substr($msg, 2, 4); 
		undef %coords; 
		$coords{'x'} = unpack("S1", substr($msg, 6, 2)); 
		$coords{'y'} = unpack("S1", substr($msg, 8, 2)); 
		if ($ID eq $accountID) { 
			%{$chars[$config{'char'}]{'pos'}} = %coords; 
			%{$chars[$config{'char'}]{'pos_to'}} = %coords; 
			print "Movement interrupted, your coordinates: $chars[$config{'char'}]{'pos'}{'x'}, $chars[$config{'char'}]{'pos'}{'y'}\n" if $config{'debug'}; 
			aiRemove("move"); 
		} elsif (%{$monsters{$ID}}) { 
			%{$monsters{$ID}{'pos'}} = %coords; 
			%{$monsters{$ID}{'pos_to'}} = %coords; 
		} elsif (%{$players{$ID}}) { 
			%{$players{$ID}{'pos'}} = %coords; 
			%{$players{$ID}{'pos_to'}} = %coords; 
		} 

	} elsif ($switch eq "008A") {
		#008a <src ID> l <dst ID> l <server tick> l <src speed> l <dst speed> l <param1> w <param2> w <type> B <param3> w
		#malee attack
		$conState = 5 if ($conState != 4 && $sys{'Xmode'});
		my $ID1 = substr($msg, 2, 4);
		my $ID2 = substr($msg, 6, 4);
		my $standing = unpack("C1", substr($msg, 26, 2)) - 2;
		my $damage = unpack("S1", substr($msg, 22, 2));
		my $type = unpack("C1",substr($msg,26,1));
		my $dmgdisplay;
		if ($damage == 0) {
			$dmgdisplay = "Miss!";
		} else{
			$dmgdisplay = $damage;
		}
		$dmgdisplay .= "!" if ($type==11 || $type == 10);
		updateDamageTables($ID1, $ID2, $damage);
		if ($ID1 eq $accountID) {
			if (%{$monsters{$ID2}}) {
			# Display Hp / Sp when Attack & Avoid Miss
				$CONSOLE->Attr($main::FG_BROWN|$main::BG_BLACK) if ($dmgdisplay ne "Miss!" && $config{'colorMode'} && !$sys{'Vx_interface'}) ;
				print addTag($sys{'Vx_interface'},"attacked",$damage)
						,sprintf("[Atk %3d|%3d]",$chars[$config{'char'}]{'percent_hp'},$chars[$config{'char'}]{'percent_sp'})
						,"Attack : $monsters{$ID2}{'name'} ($monsters{$ID2}{'binID'}) - Dmg: $dmgdisplay\n";
				$CONSOLE->Attr($ATTR_NORMAL) if ($dmgdisplay ne "Miss!" && $config{'colorMode'} && !$sys{'Vx_interface'});
				#teleport when atk miss - anu mod
				if ($config{'teleportAuto_AtkMiss'} && $monsters{$ID2}{'missedContFromYou'} >= $config{'teleportAuto_AtkMiss'}) {
					print "You attack miss! $config{'teleportAuto_AtkMiss'} times or more, then teleport..\n";
					sysLog("D","You attack miss! $config{'teleportAuto_AtkMiss'} times or more, then teleport...\n");
					useTeleport(1);
				#disconnect when atk miss
				} elsif ($config{'dcOnAtkMiss'} && $monsters{$ID2}{'missedContFromYou'} >= $config{'dcOnAtkMiss'}) {
					print "You attack miss! $config{'dcOnAtkMiss'} times or more, then disconnect...\n";
					sysLog("D","You attack miss! $config{'dcOnAtkMiss'} times or more, then disconnect...\n");
					quit();
				}
			} elsif (%{$items{$ID2}}) {
				print "You pick up Item: $items{$ID2}{'name'} ($items{$ID2}{'binID'})\n" if $config{'debug'};
				$items{$ID2}{'takenBy'} = $accountID;
			} elsif ($ID2 == 0) {
				if ($standing) {
					$chars[$config{'char'}]{'sitting'} = 0;
					print addTag($sys{'Vx_interface'},"stand"),"You're Standing\n";
				} else {
					$chars[$config{'char'}]{'sitting'} = 1;
					print addTag($sys{'Vx_interface'},"sit"),"You're Sitting\n";
				}
			}
		} elsif ($ID2 eq $accountID) {
			if (%{$monsters{$ID1}}) {
			# Display Hp / Sp when Damage
				$CONSOLE->Attr($main::FG_LIGHTRED|$main::BG_BLACK) if ($dmgdisplay ne "Miss!" && $config{'colorMode'} && !$sys{'Vx_interface'});
				print addTag($sys{'Vx_interface'},"attacking",$damage)
						,sprintf("[Def %3d|%3d]",$chars[$config{'char'}]{'percent_hp'},$chars[$config{'char'}]{'percent_sp'})
						,"Get Dmg : $monsters{$ID1}{'name'} ($monsters{$ID1}{'binID'}) - Dmg: $dmgdisplay\n";
				$CONSOLE->Attr($ATTR_NORMAL) if ($dmgdisplay ne "Miss!" && $config{'colorMode'} && !$sys{'Vx_interface'});
				useTeleport(1) if ($monsters{$ID1}{'name'} eq "");
			}
			undef $chars[$config{'char'}]{'time_cast'};
		} elsif (%{$monsters{$ID1}}) {
			if (%{$players{$ID2}}) {
				print "Monster $monsters{$ID1}{'name'} ($monsters{$ID1}{'binID'}) attacks Player $players{$ID2}{'name'} ($players{$ID2}{'binID'}) - Dmg: $dmgdisplay\n" if ($config{'debug'});
			}
		} elsif (%{$players{$ID1}}) {
			if (%{$monsters{$ID2}}) {
				if (!%{$chars[$config{'char'}]{'party'}{'users'}{$ID1}} && $ID2 eq $ai_seq_args[0]{'ID'}) {
					#print addTag($sys{'Vx_interface'},"jam"),"$players{$ID1}{'name'} ($players{$ID1}{'binID'}) attacks Monster $monsters{$ID2}{'name'} ($monsters{$ID2}{'binID'}) - Dmg: $dmgdisplay\n";
					JudgeAttackSameTarget($ID2);
				}
			} elsif (%{$items{$ID2}}) {
				$items{$ID2}{'takenBy'} = $ID1;
				print "Player $players{$ID1}{'name'} ($players{$ID1}{'binID'}) picks up Item $items{$ID2}{'name'} ($items{$ID2}{'binID'})\n" if ($config{'debug'});
			} elsif ($ID2 == 0) {
				if ($standing) {
					$players{$ID1}{'sitting'} = 0;
					print "Player is Standing: $players{$ID1}{'name'} ($players{$ID1}{'binID'})\n" if $config{'debug'};
				} else {
					$players{$ID1}{'sitting'} = 1;
					print "Player is Sitting: $players{$ID1}{'name'} ($players{$ID1}{'binID'})\n" if $config{'debug'};
				}
			}
		} else {
			print "Unknown ".getHex($ID1)." attacks ".getHex($ID2)." - Dmg: $dmgdisplay\n" if $config{'debug'};
		}

	} elsif ($switch eq "008D") {
		#008d <len> w <ID> l <str>.? B
		#The speech reception ID. The inside of the chat becomes one for speech within the chat 
		my $ID = substr($msg, 4, 4);
		my $chat = substr($msg, 8, $msg_size - 8);
		$chat =~ s/\000//g;
		my ($chatMsgUser, $chatMsg) = $chat =~ /([\s\S]*?) : ([\s\S]*)/;
		$chatMsgUser =~ s/ $//;
		my $dis = int(distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$players{$ID}{'pos_to'}}));
		sysLog("c","[gid:".unpack("L1",$ID)." dist:".$dis."] ".$chat."\n");
		$ai_cmdQue[$ai_cmdQue]{'type'} = "c";
		$ai_cmdQue[$ai_cmdQue]{'ID'} = $ID;
		$ai_cmdQue[$ai_cmdQue]{'user'} = $chatMsgUser;
		$ai_cmdQue[$ai_cmdQue]{'msg'} = $chatMsg;
		$ai_cmdQue[$ai_cmdQue]{'time'} = time;
		$ai_cmdQue++;
		$CONSOLE->Attr($main::FG_YELLOW |$main::BG_BLACK) if ($config{'colorMode'} && !$sys{'Vx_interface'});
		print addTag($sys{'Vx_interface'},"chat"),"[Chat dist:$dis]$chat\n";
		$CONSOLE->Attr($ATTR_NORMAL) if ($config{'colorMode'} && !$sys{'Vx_interface'});

	} elsif ($switch eq "008E") {
		#008e <len> w <str>.? B
		#Your own speech reception. The inside of the chat becomes one for speech within the chat
		my $chat = substr($msg, 4, $msg_size - 4);
		my ($chatMsgUser, $chatMsg) = $chat =~ /([\s\S]*?) : ([\s\S]*)\000/;
		sysLog("c",$chat."\n");
		$CONSOLE->Attr($main::FG_YELLOW|$main::BG_BLACK) if ($config{'colorMode'} && !$sys{'Vx_interface'});
		print addTag($sys{'Vx_interface'},"chat"),"[Chat]$chat\n";
		$CONSOLE->Attr($ATTR_NORMAL) if ($config{'colorMode'} && !$sys{'Vx_interface'});

	} elsif ($switch eq "0091") {
		#0091 <map name> 16B <X> w <Y> w 
		#Business such as movement, teleport and fly between maps inside 
		$conState = 5 if ($conState != 4 && $sys{'Xmode'});
		initMapChangeVars();
		for (my $i = 0; $i < @ai_seq; $i++) {
			ai_setMapChanged($i);
		}
		my ($map_name) = substr($msg, 2, 16) =~ /([\s\S]*?)\000/;
		($ai_v{'temp'}{'map'}) = $map_name =~ /([\s\S]*)\./;
		if ($ai_v{'temp'}{'map'} ne $field{'name'}) {
			getField("$def_field/$ai_v{'temp'}{'map'}.fld", \%field);
			#Map log
			sysLog("M","**Map : $field{'name'}\n");
			if ($sys{'Vx_interface'}) {
				if ($field{'name'} eq $config{"lockMap_$ai_v{'lockMapIndex'}"} || !$config{"lockMap_$ai_v{'lockMapIndex'}"}) {
					Vx::status_update("On Map : $field{'name'}");
				}else{
					Vx::status_update("On Map : $field{'name'} | LockMap : ".$config{"lockMap_$ai_v{'lockMapIndex'}"});
				}
				Vx::loadMap(\%field) if (Vx::is_showMap());
			}
		}
		$coords{'x'} = unpack("S1", substr($msg, 18, 2));
		$coords{'y'} = unpack("S1", substr($msg, 20, 2));
		%{$chars[$config{'char'}]{'pos'}} = %coords;
		%{$chars[$config{'char'}]{'pos_to'}} = %coords;
		if ($sys{'Vx_interface'}){
			Vx::pos_update($coords{'x'},$coords{'y'});
			Vx::removeAllObj();
		}
		$CONSOLE->Attr($main::FG_LIGHTCYAN |$main::BG_BLACK) if ($config{'colorMode'} && !$sys{'Vx_interface'});
		print "Map Change: $map_name\n";
		print "Your Coordinates: $chars[$config{'char'}]{'pos'}{'x'}, $chars[$config{'char'}]{'pos'}{'y'}\n" if $config{'debug'};
		print "Sending Map Loaded\n" if ($config{'debug'} && !$sys{'Xmode'});
		$CONSOLE->Attr($ATTR_NORMAL) if ($config{'colorMode'} && !$sys{'Vx_interface'});
		sendMapLoaded(\$remote_socket) if (!$sys{'Xmode'});

	} elsif ($switch eq "0092") {
		#0092 <map name> 16B <X> w <Y> w <IP> l <port> w 
		#Movement between
		$conState = 4;
		initMapChangeVars();
		initStatusChangeVars();
		undef $conState_tries;
		for (my $i = 0; $i < @ai_seq; $i++) {
			ai_setMapChanged($i);
		}
		($map_name) = substr($msg, 2, 16) =~ /([\s\S]*?)\000/;
		($ai_v{'temp'}{'map'}) = $map_name =~ /([\s\S]*)\./;

		if ($ai_v{'temp'}{'map'} ne $field{'name'}) {
			getField("$def_field/$ai_v{'temp'}{'map'}.fld", \%field);
			#Map Log
			sysLog("M","**Map : $field{'name'}\n");
			if ($sys{'Vx_interface'}) {
				Vx::loadMap(\%field) if (Vx::is_showMap());
				Vx::removeAllObj();
				if ($field{'name'} eq $config{"lockMap_$ai_v{'lockMapIndex'}"} || !$config{"lockMap_$ai_v{'lockMapIndex'}"}) {
					Vx::status_update("On Map : $field{'name'}");
				}else{
					Vx::status_update("On Map : $field{'name'} | LockMap : ".$config{"lockMap_$ai_v{'lockMapIndex'}"});
				}
			}
		}
		$map_ip = makeIP(substr($msg, 22, 4));
		$map_port = unpack("S1", substr($msg, 26, 2));
		print "---------Map Change Info----------\n";
		print sprintf("MAP Name: %-20s\n",$map_name);
		print sprintf("MAP IP: %-20s\n",$map_ip);
		print sprintf("MAP Port: %-20s\n",$map_port);
		print "-------------------------------\n";
		print "Closing connection to Map Server\n";
		killConnection(\$remote_socket) if (!$sys{'Xmode'});

	} elsif ($switch eq "0095") {
		#0095 <ID> l <nick> 24B 
		#Answer to the 0094 of NPC and guild not yet post PC 
		$conState = 5 if ($conState != 4 && $sys{'Xmode'});
		my $ID = substr($msg, 2, 4);
		my $binID;
		if (%{$players{$ID}}) {
			($players{$ID}{'name'}) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/;
			if ($config{'debug'} >= 2) {
				$binID = binFind(\@playersID, $ID);
				print "Player Info: $players{$ID}{'name'} ($binID)\n";
			}
		}
		if (%{$monsters{$ID}}) {
			($monsters{$ID}{'name'}) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/;
			if ($config{'debug'} >= 2) {
				$binID = binFind(\@monstersID, $ID);
				print "Monster Info: $monsters{$ID}{'name'} ($binID)\n";
			}
			if ($monsters_lut{$monsters{$ID}{'nameID'}} eq "" && !%{$pets{$ID}}) {
				$monsters_lut{$monsters{$ID}{'nameID'}} = $monsters{$ID}{'name'};
				updateMonsterLUT("$def_table/monsters.txt", $monsters{$ID}{'nameID'}, $monsters{$ID}{'name'});
			}
		}
		if (%{$npcs{$ID}}) {
			($npcs{$ID}{'name'}) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/; 
			if ($config{'debug'} >= 2) { 
				$binID = binFind(\@npcsID, $ID); 
				print "NPC Info: $npcs{$ID}{'name'} ($binID)\n"; 
			}
			if (!%{$npcs_lut{$npcs{$ID}{'nameID'}}}) {
				$npcs_lut{$npcs{$ID}{'nameID'}}{'name'} = $npcs{$ID}{'name'};
				$npcs_lut{$npcs{$ID}{'nameID'}}{'map'} = $field{'name'};
				%{$npcs_lut{$npcs{$ID}{'nameID'}}{'pos'}} = %{$npcs{$ID}{'pos'}};
				updateNPCLUT("$def_table/npcs.txt", $npcs{$ID}{'nameID'}, $field{'name'}, $npcs{$ID}{'pos'}{'x'}, $npcs{$ID}{'pos'}{'y'}, $npcs{$ID}{'name'}); 
			}
		}
		if (%{$pets{$ID}}) {
			($pets{$ID}{'name_given'}) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/;
			if ($config{'debug'} >= 2) {
				$binID = binFind(\@petsID, $ID);
				print "Pet Info: $pets{$ID}{'name_given'} ($binID)\n";
			}
		}

	} elsif ($switch eq "0097") {
		#0097 <len> w <nick> 24B <message>.? B 
		#Whisper reception 
		$conState = 5 if ($conState != 4 && $sys{'Xmode'});
		decrypt(\$newmsg, substr($msg, 28, length($msg)-28), $config{'encrypt'});
		$msg = substr($msg, 0, 28).$newmsg;
		my ($privMsgUser) = substr($msg, 4, 24) =~ /([\s\S]*?)\000/;
		my $privMsg = substr($msg, 28, $msg_size - 29);
		if ($privMsgUser ne "" && binFind(\@privMsgUsers, $privMsgUser) eq "") {
			$privMsgUsers[@privMsgUsers] = $privMsgUser;
		}
		sysLog("pm","(From: $privMsgUser) : $privMsg\n");
		$ai_cmdQue[$ai_cmdQue]{'type'} = "pm";
		$ai_cmdQue[$ai_cmdQue]{'user'} = $privMsgUser;
		$ai_cmdQue[$ai_cmdQue]{'msg'} = $privMsg;
		$ai_cmdQue[$ai_cmdQue]{'time'} = time;
		$ai_cmdQue++;
		$CONSOLE->Attr($main::FG_YELLOW |$main::BG_BLACK) if ($config{'colorMode'} && !$sys{'Vx_interface'});
		print addTag($sys{'Vx_interface'},"pm"),"(From: $privMsgUser) : $privMsg\n";
		$CONSOLE->Attr($ATTR_NORMAL) if ($config{'colorMode'} && !$sys{'Vx_interface'});

		#Def-Con AutoAdd PM
		Vx::pm_add($privMsgUser) if ($sys{'Vx_interface'});

		if ($config{'avoid_onPM'}==1 || ($config{'avoid_onPM'}==2 && existsInPatternList($config{'avoid_namePattern'},$privMsgUser))){
			print "[Act] Avoiding pm message by : $privMsgUser\n";
			sysLog("D","Avoiding pm message by : $privMsgUser\n");
			$timeout_ex{'master'}{'time'} = time;
			$timeout_ex{'master'}{'timeout'} = $config{'avoid_reConnect'};
			killConnection(\$remote_socket);
		}

	} elsif ($switch eq "0098") {
		#0098 <type> B
		#Whisper Tranmis status
		my $type = unpack("C1",substr($msg, 2, 1));
		$CONSOLE->Attr($main::FG_YELLOW |$main::BG_BLACK) if ($config{'colorMode'} && !$sys{'Vx_interface'});
		if ($type == 0) {
			print addTag($sys{'Vx_interface'},"pm"),"(To $lastpm[0]{'user'}) : $lastpm[0]{'msg'}\n";
			sysLog("pm", "(To: $lastpm[0]{'user'}) : $lastpm[0]{'msg'}\n");
		} elsif ($type == 1) {
			print "$lastpm[0]{'user'} is not online\n";
		} elsif ($type == 2) {
			print "Player can't hear you - you are ignored\n";
		}
		shift @lastpm;
		$CONSOLE->Attr($ATTR_NORMAL) if ($config{'colorMode'} && !$sys{'Vx_interface'});

	} elsif ($switch eq "009A") {
		#009a <len> w <message>.? B 
		#Voice of the heaven from GM 
		my $chat = substr($msg, 4, $msg_size - 4);
		$chat =~ s/\000$//g;
		sysLog("s", $chat."\n");
		$CONSOLE->Attr($main::FG_YELLOW |$main::BG_BLACK) if ($config{'colorMode'} && !$sys{'Vx_interface'});
		print addTag($sys{'Vx_interface'},"GMnotice"),"$chat\n";
		$CONSOLE->Attr($ATTR_NORMAL) if ($config{'colorMode'} && !$sys{'Vx_interface'});

	} elsif ($switch eq "009C") {
		#009c <ID> l <head dir> w <dir> B 
		#The body of ID & direction modification of head
		$conState = 5 if ($conState != 4 && $sys{'Xmode'});
		my $ID = substr($msg, 2, 4);
		my $body = unpack("C1",substr($msg, 8, 1));
		my $head = unpack("C1",substr($msg, 6, 1));
		if ($ID eq $accountID) {
			$chars[$config{'char'}]{'look'}{'head'} = $head;
			$chars[$config{'char'}]{'look'}{'body'} = $body;
			print "You look at $chars[$config{'char'}]{'look'}{'body'}, $chars[$config{'char'}]{'look'}{'head'}\n" if ($config{'debug'} >= 2);
		} elsif (%{$players{$ID}}) {
			$players{$ID}{'look'}{'head'} = $head;
			$players{$ID}{'look'}{'body'} = $body;
			print "Player $players{$ID}{'name'} ($players{$ID}{'binID'}) looks at $players{$ID}{'look'}{'body'}, $players{$ID}{'look'}{'head'}\n" if ($config{'debug'} >= 2);
		} elsif (%{$monsters{$ID}}) {
			$monsters{$ID}{'look'}{'head'} = $head;
			$monsters{$ID}{'look'}{'body'} = $body;
			print "Monster $monsters{$ID}{'name'} ($monsters{$ID}{'binID'}) looks at $monsters{$ID}{'look'}{'body'}, $monsters{$ID}{'look'}{'head'}\n" if ($config{'debug'} >= 2);
		}

	} elsif ($switch eq "009D") {
		#009d <ID> l <item ID> w <identify flag> B <X> w <Y> w <amount> w <subX> B <subY> B 
		#When the floor item goes inside the picture with such as movement, 
		$conState = 5 if ($conState != 4 && $sys{'Xmode'});
		my $ID = substr($msg, 2, 4);
		my $type = unpack("S1",substr($msg, 6, 2));
		my $x = unpack("S1", substr($msg, 9, 2));
		my $y = unpack("S1", substr($msg, 11, 2));
		my $amount = unpack("S1", substr($msg, 13, 2));
		if (!%{$items{$ID}}) {
			binAdd(\@itemsID, $ID);
			$items{$ID}{'appear_time'} = time;
			$items{$ID}{'amount'} = $amount;
			$items{$ID}{'nameID'} = $type;
			$display = ($items_lut{$items{$ID}{'nameID'}} ne "") 
				? $items_lut{$items{$ID}{'nameID'}}
				: "Unknown ".$items{$ID}{'nameID'};
			$items{$ID}{'binID'} = binFind(\@itemsID, $ID);
			$items{$ID}{'name'} = $display;
		}
		$items{$ID}{'pos'}{'x'} = $x;
		$items{$ID}{'pos'}{'y'} = $y;
		print "Item Exists: $items{$ID}{'name'} ($items{$ID}{'binID'}) x $items{$ID}{'amount'}\n" if (!$config{'hideMsg_itemExists'});

	} elsif ($switch eq "009E") {
		#009e <ID> l <item ID> w <identify flag> B <X> w <Y> w <subX> B <subY> B <amount> w 
		#Item drop. Why, position & the quantity inside 009d and the mass eye insert and have changed 
		$conState = 5 if ($conState != 4 && $sys{'Xmode'});
		my $ID = substr($msg, 2, 4);
		my $type = unpack("S1",substr($msg, 6, 2));
		my $x = unpack("S1", substr($msg, 9, 2));
		my $y = unpack("S1", substr($msg, 11, 2));
		my $amount = unpack("S1", substr($msg, 15, 2));
		if (!%{$items{$ID}}) {
			binAdd(\@itemsID, $ID);
			$items{$ID}{'appear_time'} = time;
			$items{$ID}{'amount'} = $amount;
			$items{$ID}{'nameID'} = $type;
			$display = ($items_lut{$items{$ID}{'nameID'}} ne "") 
				? $items_lut{$items{$ID}{'nameID'}}
				: "Unknown ".$items{$ID}{'nameID'};
			$items{$ID}{'binID'} = binFind(\@itemsID, $ID);
			$items{$ID}{'name'} = $display;
		}
		$items{$ID}{'pos'}{'x'} = $x;
		$items{$ID}{'pos'}{'y'} = $y;
		print "Item Appeared: $items{$ID}{'name'} ($items{$ID}{'binID'}) x $items{$ID}{'amount'}\n" if (!$config{'hideMsg_itemAppeared'});
		# Take Item in the Air
		if ($itemsPickup{lc($items{$ID}{'name'})}==2 && distance(\%{$items{$ID}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}})<=5) {
			$items{'takefirst'}=$items{$ID}{'name'};
			sendTake(\$remote_socket, $ID);
		}

	} elsif ($switch eq "00A0") {
		#00a0 <index>.w <amount>.w <item ID>.w <identify flag>.B <attribute?>.B <refine>.B <card>.4w <equip type>.w <type>.B <fail>.B
		#item add to inventory
		my $index = unpack("S1",substr($msg, 2, 2));
		my $amount = unpack("S1",substr($msg, 4, 2));
		my $ID = unpack("S1",substr($msg, 6, 2));
		my $type = unpack("C1",substr($msg, 21, 1));
		my $type_equip = unpack("S1",substr($msg, 19, 2));
		my $fail = unpack("C1",substr($msg, 22, 1));
		my $log_item="";
		undef $invIndex;
#Search with index, not name! Otherwise non-stackable item will screw it up!
		$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
		if ($fail == 0) {
			if ($invIndex eq "") {
				$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", "");
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'index'} = $index;
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'} = $ID;
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} = $amount;
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'type'} = $type;
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'type_equip'} = $type_equip;
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'identified'} = unpack("C1",substr($msg, 8, 1));
				#display name
				$display = ($items_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'}} ne "")
				? $items_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'}}
				: "Unknown ".$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'};
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} = $display;
# parse Card & Elements
				#------------------------------------------------------------------------------------------------------------
				if ($chars[$config{'char'}]{'inventory'}[$invIndex]{'type_equip'}) {
					$chars[$config{'char'}]{'inventory'}[$invIndex]{'refined'} = unpack("C1", substr($msg, 10, 1));
					if (unpack("S1", substr($msg, 11, 2)) == 0x00FF) {
						$chars[$config{'char'}]{'inventory'}[$invIndex]{'elements'} = unpack("C1", substr($msg, 13, 1));
						$chars[$config{'char'}]{'inventory'}[$invIndex]{'star'}      = unpack("C1", substr($msg, 14, 1)) / 0x05;
					} else {
						$chars[$config{'char'}]{'inventory'}[$invIndex]{'card'}[0]   = unpack("S1", substr($msg, 11, 2));
						$chars[$config{'char'}]{'inventory'}[$invIndex]{'card'}[1]   = unpack("S1", substr($msg, 13, 2));
						$chars[$config{'char'}]{'inventory'}[$invIndex]{'card'}[2]   = unpack("S1", substr($msg, 15, 2));
						$chars[$config{'char'}]{'inventory'}[$invIndex]{'card'}[3]   = unpack("S1", substr($msg, 17, 2));
					}
					modifingName(\%{$chars[$config{'char'}]{'inventory'}[$invIndex]});
				}
				#------------------------------------------------------------------------------------------------------------
			} else {
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} += $amount;
			}
#Take items in the air II
			if ($items{'takefirst'} ne "") {
				$log_item = "** ";
				$items{'takefirst'} = "";
			}
			sysLog("i",$log_item."$chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} x $amount\n") if ($config{'sysLog_items'});

			$CONSOLE->Attr($main::FG_LIGHTGREEN|$main::BG_BLACK) if ($config{'colorMode'} && !$sys{'Vx_interface'});
			print addTag($sys{'Vx_interface'},"inventoryAdd"),"Item added to inventory: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex) x $amount "
					,"- $itemTypes_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'type'}} ($chars[$config{'char'}]{'inventory'}[$invIndex]{'type'})\n";
#Auto - Drop
			if ($itemsPickup{lc($items_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'}})} eq "0" 
				&& binFind(\@ai_seq, "storageAuto") eq "" && binFind(\@ai_seq, "buyAuto") eq "") {
				sendDrop(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$invIndex]{'index'}, $amount);
				print "Auto-Drop Item : $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex) x $amount \n";
			}
			$CONSOLE->Attr($ATTR_NORMAL) if ($config{'colorMode'} && !$sys{'Vx_interface'});
#Cart - addAuto
			if ($chars[$config{'char'}]{'cart'} && $invIndex ne "" && $cart_control{lc($chars[$config{'char'}]{'inventory'}[$invIndex]{'name'})}{'addAuto'}
				&& ($cart{'items'} < $cart{'items_max'}) && ($cart{'weight'} < $cart{'weight_max'})
				&& $chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} > $cart_control{lc($chars[$config{'char'}]{'inventory'}[$invIndex]{'name'})}{'keep'}
				) {
				my $cartAmount = $chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} - $cart_control{lc($chars[$config{'char'}]{'inventory'}[$invIndex]{'name'})}{'keep'};
				sendCartAddFromInv(\$remote_socket,$chars[$config{'char'}]{'inventory'}[$invIndex]{'index'}, $cartAmount) if ($cartAmount>0);
			}
		} elsif ($fail == 6) {
			print "Can't loot item...wait...\n";
		}

	} elsif ($switch eq "00A1") {
		#00a1 <ID> l 
		#The floor item elimination of ID 
		$conState = 5 if ($conState != 4 && $sys{'Xmode'});
		my $ID = substr($msg, 2, 4);
		if (%{$items{$ID}}) {
			print "Item Disappeared: $items{$ID}{'name'} ($items{$ID}{'binID'})\n" if $config{'debug'};
			%{$items_old{$ID}} = %{$items{$ID}};
			$items_old{$ID}{'disappeared'} = 1;
			$items_old{$ID}{'gone_time'} = time;
			undef %{$items{$ID}};
			binRemove(\@itemsID, $ID);
		}

	} elsif ($switch eq "00A3" || $switch eq "01EE") {
		#00a3 <len> w {<index> w <item ID> w <type> B <identify flag> B <amount> w? 2B} 10B* 
		#Possession consumable & collection item list 
		$conState = 5 if ($conState != 4 && $sys{'Xmode'});
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4), $config{'encrypt'});
		$msg = substr($msg, 0, 4).$newmsg;
		my $psize = ($switch eq "00A3") ? 10 : 18;
		undef $invIndex;
		for(my $i = 4; $i < $msg_size; $i+=$psize) {
			my $index = unpack("S1", substr($msg, $i, 2));
			my $ID = unpack("S1", substr($msg, $i + 2, 2));
			my $invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
			if ($invIndex eq "") {
				$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "nameID", "");
			}
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'index'} = $index;
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'} = $ID;
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} = unpack("S1", substr($msg, $i + 6, 2));
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'type'} = unpack("C1", substr($msg, $i + 4, 1));
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} = ($items_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'}} ne "")
				? $items_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'}}
				: "Unknown ".$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'};
			print "Inventory: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex) x $chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} - $itemTypes_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'type'}}\n" if $config{'debug'};	
		}

	} elsif ($switch eq "00A4") {
		#00a4 <len> w {<index> w <item ID> w <type> B <identify flag> B <equip type> w <equip point> w <attribute? > B <refine> B <card> 4w} 20B* 
		#Possession equipment list 
		$conState = 5 if ($conState != 4 && $sys{'Xmode'});
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4), $config{'encrypt'});
		$msg = substr($msg, 0, 4).$newmsg;
		undef $invIndex;
		for(my $i = 4; $i < $msg_size; $i+=20) {
			my $index = unpack("S1", substr($msg, $i, 2));
			my $ID = unpack("S1", substr($msg, $i + 2, 2));
			my $invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
			if ($invIndex eq "") {
				$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "nameID", "");
			}
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'index'} = $index;
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'} = $ID;
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} = 1;
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'type'} = unpack("C1", substr($msg, $i + 4, 1));
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'identified'} = unpack("C1", substr($msg, $i + 5, 1));
			$display = ($items_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'}} ne "")
				? $items_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'}}
				: "Unknown ".$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'};
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} = $display;
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'type_equip'} = unpack("S1", substr($msg, $i + 6, 2));
# parse Card & Elements
			#------------------------------------------------------------------------------------------------------------
			if ($chars[$config{'char'}]{'inventory'}[$invIndex]{'type_equip'}) {
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'equipped'} = unpack("S1", substr($msg, $i + 8, 2));
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'refined'} = unpack("C1", substr($msg, $i + 11, 1)); 
				if(unpack("S1", substr($msg,$i+12, 2)) == 0x00FF){ 
					$chars[$config{'char'}]{'inventory'}[$invIndex]{'elements'} = unpack("C1", substr($msg,$i+14, 1)); 
					$chars[$config{'char'}]{'inventory'}[$invIndex]{'star'} = unpack("C1", substr($msg,$i+15, 1)) / 0x05; 
				}else{
					$chars[$config{'char'}]{'inventory'}[$invIndex]{'card'}[0] = unpack("S1", substr($msg,$i+12, 2));
					$chars[$config{'char'}]{'inventory'}[$invIndex]{'card'}[1] = unpack("S1", substr($msg,$i+14, 2)); 
					$chars[$config{'char'}]{'inventory'}[$invIndex]{'card'}[2] = unpack("S1", substr($msg,$i+16, 2)); 
					$chars[$config{'char'}]{'inventory'}[$invIndex]{'card'}[3] = unpack("S1", substr($msg,$i+18, 2)); 
				}
				modifingName(\%{$chars[$config{'char'}]{'inventory'}[$invIndex]}); 
			}
			#------------------------------------------------------------------------------------------------------------
			print "Inventory: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex) x $chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} - $itemTypes_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'type'}} - $equipTypes_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'equipped'}}\n" if $config{'debug'};
		}

	} elsif ($switch eq "00A5" || $switch eq "01F0") {
		#00a5 <len> w {<index> w <item ID> w <type> B <identify flag> B <amount> w? 2B} 10B* 
		#Consumable & collection item list which are deposited to the Kapra
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4), $config{'encrypt'});
		$msg = substr($msg, 0, 4).$newmsg;
		undef %storage;
		my $psize = ($switch eq "00A5") ? 10 : 18;
		for(my $i = 4; $i < $msg_size; $i+=$psize) {
			my $index = unpack("S1", substr($msg, $i, 2));
			my $ID = unpack("S1", substr($msg, $i + 2, 2));
			$storage{'inventory'}[$index]{'nameID'} = $ID;
			$storage{'inventory'}[$index]{'amount'} = unpack("S1", substr($msg, $i + 6, 2));
			$storage{'inventory'}[$index]{'name'} = ($items_lut{$ID} ne "") ? $items_lut{$ID} : "Unknown ".$ID;
			print "Storage: $storage{'inventory'}[$index]{'name'} ($index)\n" if $config{'debug'};
		}
		print "Storage opened\n";

	} elsif ($switch eq "00A6") {
		#00a6 <len> w {<index> w <item ID> w <type> B <identify flag> B <equip type> w <equip point> w <attribute? > B <refine> B <card> 4w} 20B* 
		#Equipment list which is deposited to the Kapra
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4), $config{'encrypt'});
 		$msg = substr($msg, 0, 4).$newmsg; 
		for(my $i = 4; $i < $msg_size; $i+=20) {
			my $index = unpack("S1", substr($msg, $i, 2));
			my $ID = unpack("S1", substr($msg, $i + 2, 2));
			$storage{'inventory'}[$index]{'index'} = $index;
			$storage{'inventory'}[$index]{'nameID'} = $ID;
			$storage{'inventory'}[$index]{'amount'} = 1;
			$storage{'inventory'}[$index]{'type'} = unpack("C1", substr($msg, $i + 4, 1));
			$storage{'inventory'}[$index]{'identified'} = unpack("C1", substr($msg, $i + 5, 1));
			$storage{'inventory'}[$index]{'type_equip'} = unpack("S1", substr($msg, $i + 6, 2));
			$display = ($items_lut{$ID} ne "") ? $items_lut{$ID} : "Unknown ".$ID;
			$storage{'inventory'}[$index]{'name'} = $display;
# parse Card & Elements
			if ($storage{'inventory'}[$index]{'type_equip'}){
			#------------------------------------------------------------------------------------------------------------
				$storage{'inventory'}[$index]{'equipped'} = unpack("S1", substr($msg, $i + 8, 2));
				$storage{'inventory'}[$index]{'refined'} = unpack("C1", substr($msg, $i+11, 1));
				if (unpack("S1", substr($msg, $i+12, 2)) == 0x00FF) {
					$storage{'inventory'}[$index]{'elements'} = unpack("C1", substr($msg, $i+14, 1));
					$storage{'inventory'}[$index]{'star'}        = unpack("C1", substr($msg, $i+15, 1)) / 0x05;
				} else {
					$storage{'inventory'}[$index]{'card'}[0]   = unpack("S1", substr($msg, $i+12, 2));
					$storage{'inventory'}[$index]{'card'}[1]   = unpack("S1", substr($msg, $i+14, 2));
					$storage{'inventory'}[$index]{'card'}[2]   = unpack("S1", substr($msg, $i+16, 2));
					$storage{'inventory'}[$index]{'card'}[3]   = unpack("S1", substr($msg, $i+18, 2));
				}
				modifingName(\%{$storage{'inventory'}[$index]});
			#------------------------------------------------------------------------------------------------------------
			}
			print "Storage Item: $storage{'inventory'}[$index]{'name'} ($index) x $storage{'inventory'}[$index]{'amount'}\n" if $config{'debug'};
		}

	} elsif ($switch eq "00A8") {
		#00a8 <index> w <amount> w <type> B 
		#Item use response.
		$conState = 5 if ($conState != 4 && $sys{'Xmode'});
		my $index = unpack("S1",substr($msg, 2, 2));
		my $amount = unpack("C1",substr($msg, 6, 1));
		undef $invIndex;
		$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
		$chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} -= $amount;
		print addTag($sys{'Vx_interface'},"useItem"),"You used Item: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex) x $amount\n";
		if ($chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} <= 0) {
			undef %{$chars[$config{'char'}]{'inventory'}[$invIndex]};
		}

	} elsif ($switch eq "00AA") {
		#00aa <index> w <equip point> w <type> B 
		#Item equipment response
		my $index = unpack("S1",substr($msg, 2, 2));
		my $type = unpack("S1",substr($msg, 4, 2));
		my $fail = unpack("C1",substr($msg, 6, 1));
		undef $invIndex;
		$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
		if ($fail == 0) {
			print "You can't put on $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex)\n";
		} else {
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'equipped'} = $type;
			print "You equip $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex) - $equipTypes_lut{$type} ($type)\n";
		}

	} elsif ($switch eq "00AC") {
		#00ac <index> w <equip point> w <type> B 
		#Equipment cancellation response
		$conState = 5 if ($conState != 4 && $sys{'Xmode'});
		$index = unpack("S1",substr($msg, 2, 2));
		$type = unpack("S1",substr($msg, 4, 2));
		$fail = unpack("C1",substr($msg, 6, 1));
		undef $invIndex;
		$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
		if ($fail ==0) {
			print "You can't unequip on $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex)\n";
		}else{
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'equipped'}=0;
			print "You unequip $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex) - $equipTypes_lut{$type} ($type)\n";
		}

	} elsif ($switch eq "00AF") {
		#00af <index> w <amount> w 
		#Item several decreases. Amount just decreases
		$conState = 5 if ($conState != 4 && $sys{'Xmode'});
		my $index = unpack("S1",substr($msg, 2, 2));
		my $amount = unpack("S1",substr($msg, 4, 2));
		undef $invIndex;
		$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
		if (!$chars[$config{'char'}]{'arrow'} || ($chars[$config{'char'}]{'arrow'} && !($chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} =~/arrow/i))) {
			print addTag($sys{'Vx_interface'},"inventoryRemove"),"Inventory Item Removed: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex) x $amount\n";
		}
		$chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} -= $amount;
		if ($chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} <= 0) {
			undef %{$chars[$config{'char'}]{'inventory'}[$invIndex]};
		}

	} elsif ($switch eq "00B0") {
		#00b0 <type> w <val> l 
		#Renewal of various performance figures. Below type: Enumerating the numerical value which corresponds 
		$conState = 5 if ($conState != 4 && $sys{'Xmode'});
		my $type = unpack("S1",substr($msg, 2, 2));
		my $val = unpack("L1",substr($msg, 4, 4));
		if ($type == 0) {
			print "Something1: $val\n" if $config{'debug'};
		} elsif ($type == 3) {
			print "Something2: $val\n" if $config{'debug'};
		} elsif ($type == 4) {
			$val = (0xFFFFFFFF - $val)+1;
			if ($val >0) {
				$chars[$config{'char'}]{'ban_period'} = $val;
				shopconfigModify("shop_autoStart",0) if ($shop{'shop_autoStart'});
				unshift @ai_seq, "avoid";
				unshift @ai_seq_args, {};
			}elsif ($ai_seq[0] eq "avoid"){
				undef $chars[$config{'char'}]{'ban_period'};
				shift @ai_seq;
				shift @ai_seq_args;
			}
			print "GM Skill Ban Period Left : $val minute\n";
			sysLog("warn","GM Skill Ban Period Left : $val minute\n");
		} elsif ($type == 5) {
			#calculate permanent HP percent
			calPercent(\%{$chars[$config{'char'}]},"hp",$val);
			print "Hp: $val\n" if $config{'debug'};
		} elsif ($type == 6) {
			$chars[$config{'char'}]{'hp_max'} = $val;
			print "Max Hp: $val\n" if $config{'debug'};
		} elsif ($type == 7) {
			#calculate permanent SP percent
			calPercent(\%{$chars[$config{'char'}]},"sp",$val);
			print "Sp: $val\n" if $config{'debug'};
		} elsif ($type == 8) {
			$chars[$config{'char'}]{'sp_max'} = $val;
			print "Max Sp: $val\n" if $config{'debug'};
		} elsif ($type == 9) {
			$chars[$config{'char'}]{'points_free'} = $val;
			print "Status Points: $val\n" if $config{'debug'};
		} elsif ($type == 11) {
			$chars[$config{'char'}]{'lv'} = $val;
			print "Level: $val\n" if $config{'debug'};
		} elsif ($type == 12) {
			$chars[$config{'char'}]{'points_skill'} = $val;
			print "Skill Points: $val\n" if $config{'debug'};
		} elsif ($type == 24) {
			#calculate permanent weight percent
			calPercent(\%{$chars[$config{'char'}]},"weight", int($val / 10));
			print "Weight: $chars[$config{'char'}]{'weight'}\n" if $config{'debug'};
		} elsif ($type == 25) {
			$chars[$config{'char'}]{'weight_max'} = int($val / 10);
			print "Max Weight: $chars[$config{'char'}]{'weight_max'}\n" if $config{'debug'};
		} elsif ($type == 41) {
			$chars[$config{'char'}]{'attack'} = $val;
			print "Attack: $val\n" if $config{'debug'};
		} elsif ($type == 42) {
			$chars[$config{'char'}]{'attack_bonus'} = $val;
			print "Attack Bonus: $val\n" if $config{'debug'};
		} elsif ($type == 43) {
			$chars[$config{'char'}]{'attack_magic_min'} = $val;
			print "Magic Attack Min: $val\n" if $config{'debug'};
		} elsif ($type == 44) {
			$chars[$config{'char'}]{'attack_magic_max'} = $val;
			print "Magic Attack Max: $val\n" if $config{'debug'};
		} elsif ($type == 45) {
			$chars[$config{'char'}]{'def'} = $val;
			print "Defense: $val\n" if $config{'debug'};
		} elsif ($type == 46) {
			$chars[$config{'char'}]{'def_bonus'} = $val;
			print "Defense Bonus: $val\n" if $config{'debug'};
		} elsif ($type == 47) {
			$chars[$config{'char'}]{'def_magic'} = $val;
			print "Magic Defense: $val\n" if $config{'debug'};
		} elsif ($type == 48) {
			$chars[$config{'char'}]{'def_magic_bonus'} = $val;
			print "Magic Defense Bonus: $val\n" if $config{'debug'};
		} elsif ($type == 49) {
			$chars[$config{'char'}]{'hit'} = $val;
			print "Hit: $val\n" if $config{'debug'};
		} elsif ($type == 50) {
			$chars[$config{'char'}]{'flee'} = $val;
			print "Flee: $val\n" if $config{'debug'};
		} elsif ($type == 51) {
			$chars[$config{'char'}]{'flee_bonus'} = $val;
			print "Flee Bonus: $val\n" if $config{'debug'};
		} elsif ($type == 52) {
			$chars[$config{'char'}]{'critical'} = $val;
			print "Critical: $val\n" if $config{'debug'};
		} elsif ($type == 53) { 
			$chars[$config{'char'}]{'attack_speed'} = 200 - $val/10; 
			print "Attack Speed: $chars[$config{'char'}]{'attack_speed'}\n" if $config{'debug'};
		} elsif ($type == 55) {
			$chars[$config{'char'}]{'lv_job'} = $val;
			print "Job Level: $val\n" if $config{'debug'};
		} elsif ($type == 124) {
			print "Something3: $val\n" if $config{'debug'};
		} else {
			print "Something: $val\n" if $config{'debug'};
		}

	} elsif ($switch eq "00B1") {
		#00b1 <type> w <val> l 
		#Renewal of various performance figures. Below type: Enumerating the numerical value which corresponds 
		$conState = 5 if ($conState != 4 && $sys{'Xmode'});
		my $type = unpack("S1",substr($msg, 2, 2));
		my $val = unpack("L1",substr($msg, 4, 4));
		if ($type == 1) {
			$chars[$config{'char'}]{'exp_last'} = $chars[$config{'char'}]{'exp'};
			$chars[$config{'char'}]{'exp'} = $val;
			print "Exp: $val\n" if $config{'debug'};
			# exp report
			if (!$bExpSwitch) {
				$bExpSwitch = 1;
			} else {
				if ($chars[$config{'char'}]{'exp_last'} > $chars[$config{'char'}]{'exp'}) {
					$monsterBaseExp = 0;
				} else {
					$monsterBaseExp = $chars[$config{'char'}]{'exp'} - $chars[$config{'char'}]{'exp_last'};
				}
				$totalBaseExp += $monsterBaseExp;
				if ($bExpSwitch == 1) {
					$totalBaseExp += $monsterBaseExp; 
					$bExpSwitch = 2;
				}
			}
		} elsif ($type == 2) {
			$chars[$config{'char'}]{'exp_job_last'} = $chars[$config{'char'}]{'exp_job'};
			$chars[$config{'char'}]{'exp_job'} = $val;
			print "Job Exp: $val\n" if $config{'debug'};
			# exp report 
			if ($jExpSwitch == 0) {
				$jExpSwitch = 1;
			} else {
				if ($chars[$config{'char'}]{'exp_job_last'} > $chars[$config{'char'}]{'exp_job'}) {
					$monsterJobExp = 0;
				} else {
					$monsterJobExp = $chars[$config{'char'}]{'exp_job'} - $chars[$config{'char'}]{'exp_job_last'};
				}
				$totalJobExp += $monsterJobExp;
				if ($jExpSwitch == 1) {
					$totalJobExp += $monsterJobExp;
					$jExpSwitch = 2;
				}
			}
		} elsif ($type == 20) {
			$chars[$config{'char'}]{'zenny'} = $val;
			print "Zenny: $val\n" if $config{'debug'};
		} elsif ($type == 22) {
			$chars[$config{'char'}]{'exp_max_last'} = $chars[$config{'char'}]{'exp_max'};
			$chars[$config{'char'}]{'exp_max'} = $val;
			print "Required Exp: $val\n" if $config{'debug'};
		} elsif ($type == 23) {
			$chars[$config{'char'}]{'exp_job_max_last'} = $chars[$config{'char'}]{'exp_job_max'};
			$chars[$config{'char'}]{'exp_job_max'} = $val;
			print "Required Job Exp: $val\n" if $config{'debug'};
		}
		# exp report 
		if ($type == 2 && $monsterBaseExp) { 
			$CONSOLE->Attr($main::FG_LIGHTMAGENTA|$main::BG_BLACK) if ($config{'colorMode'} && !$sys{'Vx_interface'});
			if (!$config{'hideMsg_expDisplay'}) {
				my $percentB = "(".sprintf("%.2f",$monsterBaseExp * 100 / $chars[$config{'char'}]{'exp_max'})."%)" if ($chars[$config{'char'}]{'exp_max'});
				my $percentJ = "(".sprintf("%.2f",$monsterJobExp * 100 / $chars[$config{'char'}]{'exp_job_max'})."%)" if ($chars[$config{'char'}]{'exp_job_max'});
				print addTag($sys{'Vx_interface'},"exp"),"[Exp] BaseExp: $monsterBaseExp $percentB| JobExp: $monsterJobExp $percentJ\n";
			}
			$CONSOLE->Attr($ATTR_NORMAL) if ($config{'colorMode'} && !$sys{'Vx_interface'});
		}

	} elsif ($switch eq "00B3") {
		#00b3 <type> B 
		#Type=01 character select response 
		$conState = 2;

	} elsif ($switch eq "00B4") {
		#00b4 <len> w <ID> l <str>.? B 
		#The message from NPC of ID 
		decrypt(\$newmsg, substr($msg, 8, length($msg)-8), $config{'encrypt'});
		$msg = substr($msg, 0, 8).$newmsg;
		my $ID = substr($msg, 4, 4);
		($talk) = substr($msg, 8, $msg_size - 8) =~ /([\s\S]*?)\000/;
		$talk{'ID'} = $ID;
		$talk{'nameID'} = unpack("L1", $ID);
		$talk{'msg'} = $talk;
		print "$npcs{$ID}{'name'} : $talk{'msg'}\n";

	} elsif ($switch eq "00B5") {
		#00b5 <ID> l 
		#"NEXT" icon is put out to message window of NPC of ID
		my $ID = substr($msg, 2, 4);
		print "$npcs{$ID}{'name'} : Type 'talk cont' to continue talking\n";

	} elsif ($switch eq "00B6") {
		#00b6 <ID> l 
		#"CLOSE" icon is put out to message window of NPC of ID
		my $ID = substr($msg, 2, 4);
		#undef %talk;
		print "$npcs{$ID}{'name'} : Done talking\n";

	} elsif ($switch eq "00B7" ) {
		#00b7 <len> w <ID> l <str>.? B 
		#In the conversation of NPC of ID selection item indication. Each item is divided with '':''
		decrypt(\$newmsg, substr($msg, 8, length($msg)-8), $config{'encrypt'});
		$msg = substr($msg, 0, 8).$newmsg;
		my $ID = substr($msg, 4, 4);
		($talk) = substr($msg, 8, $msg_size - 8) =~ /([\s\S]*?)\000/;
		@preTalkResponses = split /:/, $talk;
		undef @{$talk{'responses'}};
		foreach (@preTalkResponses) {
			push @{$talk{'responses'}}, $_ if $_ ne "";
		}
		$talk{'responses'}[@{$talk{'responses'}}] = "Cancel Chat";
		print "$npcs{$ID}{'name'} : Type 'talk resp' and choose a response.\n";
	
	} elsif ($switch eq "00BC") {
		#00bc <type> w <fail> B <val> B 
		#Status up response. fail=01 If success. As for type the same as 00bb. As for val after rising, the number 
		my $type = unpack("S1",substr($msg, 2, 2));
		my $val = unpack("C1",substr($msg, 5, 1));
		if ($val == 207) {
			print "Not enough stat points to add\n";
		} else {
			if ($type == 13) {
				$chars[$config{'char'}]{'str'} = $val;
				print "Strength: $val\n" if $config{'debug'};
			} elsif ($type == 14) {
				$chars[$config{'char'}]{'agi'} = $val;
				print "Agility: $val\n" if $config{'debug'};
			} elsif ($type == 15) {
				$chars[$config{'char'}]{'vit'} = $val;
				print "Vitality: $val\n" if $config{'debug'};
			} elsif ($type == 16) {
				$chars[$config{'char'}]{'int'} = $val;
				print "Intelligence: $val\n" if $config{'debug'};
			} elsif ($type == 17) {
				$chars[$config{'char'}]{'dex'} = $val;
				print "Dexterity: $val\n" if $config{'debug'};
			} elsif ($type == 18) {
				$chars[$config{'char'}]{'luk'} = $val;
				print "Luck: $val\n" if $config{'debug'};
			} else {
				print "Something: $val\n";
			}
		}

	} elsif ($switch eq "00BD") {
		#00bd <status point> w <STR> B <STRupP> B <AGI> B <AGIupP> B <VIT> B <VITupP> B <INT> B <INTupP> B <DEX> B <DEXupP> B <LUK> B <LUKupP> B <ATK> w <ATKbonus> w <MATKmax> w <MATKmin> w <DEF> w <DEFbonus> w <MDEF> w <MDEFbonus> w <HIT> w <FLEE> w <FLEEbonus> w <critical> w? W 
		#Collecting, the packet which sends status information 
		$chars[$config{'char'}]{'points_free'} = unpack("S1", substr($msg, 2, 2));
		$chars[$config{'char'}]{'str'} = unpack("C1", substr($msg, 4, 1));
		$chars[$config{'char'}]{'points_str'} = unpack("C1", substr($msg, 5, 1));
		$chars[$config{'char'}]{'agi'} = unpack("C1", substr($msg, 6, 1));
		$chars[$config{'char'}]{'points_agi'} = unpack("C1", substr($msg, 7, 1));
		$chars[$config{'char'}]{'vit'} = unpack("C1", substr($msg, 8, 1));
		$chars[$config{'char'}]{'points_vit'} = unpack("C1", substr($msg, 9, 1));
		$chars[$config{'char'}]{'int'} = unpack("C1", substr($msg, 10, 1));
		$chars[$config{'char'}]{'points_int'} = unpack("C1", substr($msg, 11, 1));
		$chars[$config{'char'}]{'dex'} = unpack("C1", substr($msg, 12, 1));
		$chars[$config{'char'}]{'points_dex'} = unpack("C1", substr($msg, 13, 1));
		$chars[$config{'char'}]{'luk'} = unpack("C1", substr($msg, 14, 1));
		$chars[$config{'char'}]{'points_luk'} = unpack("C1", substr($msg, 15, 1));
		$chars[$config{'char'}]{'attack'} = unpack("S1", substr($msg, 16, 2));
		$chars[$config{'char'}]{'attack_bonus'} = unpack("S1", substr($msg, 18, 2));
		$chars[$config{'char'}]{'attack_magic_min'} = unpack("S1", substr($msg, 20, 2));
		$chars[$config{'char'}]{'attack_magic_max'} = unpack("S1", substr($msg, 22, 2));
		$chars[$config{'char'}]{'def'} = unpack("S1", substr($msg, 24, 2));
		$chars[$config{'char'}]{'def_bonus'} = unpack("S1", substr($msg, 26, 2));
		$chars[$config{'char'}]{'def_magic'} = unpack("S1", substr($msg, 28, 2));
		$chars[$config{'char'}]{'def_magic_bonus'} = unpack("S1", substr($msg, 30, 2));
		$chars[$config{'char'}]{'hit'} = unpack("S1", substr($msg, 32, 2));
		$chars[$config{'char'}]{'flee'} = unpack("S1", substr($msg, 34, 2));
		$chars[$config{'char'}]{'flee_bonus'} = unpack("S1", substr($msg, 36, 2));
		$chars[$config{'char'}]{'critical'} = unpack("S1", substr($msg, 38, 2));
		print	"Strength: $chars[$config{'char'}]{'str'} #$chars[$config{'char'}]{'points_str'}\n"
			,"Agility: $chars[$config{'char'}]{'agi'} #$chars[$config{'char'}]{'points_agi'}\n"
			,"Vitality: $chars[$config{'char'}]{'vit'} #$chars[$config{'char'}]{'points_vit'}\n"
			,"Intelligence: $chars[$config{'char'}]{'int'} #$chars[$config{'char'}]{'points_int'}\n"
			,"Dexterity: $chars[$config{'char'}]{'dex'} #$chars[$config{'char'}]{'points_dex'}\n"
			,"Luck: $chars[$config{'char'}]{'luk'} #$chars[$config{'char'}]{'points_luk'}\n"
			,"Attack: $chars[$config{'char'}]{'attack'}\n"
			,"Attack Bonus: $chars[$config{'char'}]{'attack_bonus'}\n"
			,"Magic Attack Min: $chars[$config{'char'}]{'attack_magic_min'}\n"
			,"Magic Attack Max: $chars[$config{'char'}]{'attack_magic_max'}\n"
			,"Defense: $chars[$config{'char'}]{'def'}\n"
			,"Defense Bonus: $chars[$config{'char'}]{'def_bonus'}\n"
			,"Magic Defense: $chars[$config{'char'}]{'def_magic'}\n"
			,"Magic Defense Bonus: $chars[$config{'char'}]{'def_magic_bonus'}\n"
			,"Hit: $chars[$config{'char'}]{'hit'}\n"
			,"Flee: $chars[$config{'char'}]{'flee'}\n"
			,"Flee Bonus: $chars[$config{'char'}]{'flee_bonus'}\n"
			,"Critical: $chars[$config{'char'}]{'critical'}\n"
			,"Status Points: $chars[$config{'char'}]{'points_free'}\n"
			if $config{'debug'};

	} elsif ($switch eq "00BE") {
		#00be <type> w <val> B 
		#Necessary status point renewal packet. Type 0020 - 0025 corresponds to STR - LUK to order 
		my $type = unpack("S1",substr($msg, 2, 2));
		my $val = unpack("C1",substr($msg, 4, 1));
		if ($type == 32) {
			$chars[$config{'char'}]{'points_str'} = $val;
			print "Points needed for Strength: $val\n" if $config{'debug'};
		} elsif ($type == 33) {
			$chars[$config{'char'}]{'points_agi'} = $val;
			print "Points needed for Agility: $val\n" if $config{'debug'};
		} elsif ($type == 34) {
			$chars[$config{'char'}]{'points_vit'} = $val;
			print "Points needed for Vitality: $val\n" if $config{'debug'};
		} elsif ($type == 35) {
			$chars[$config{'char'}]{'points_int'} = $val;
			print "Points needed for Intelligence: $val\n" if $config{'debug'};
		} elsif ($type == 36) {
			$chars[$config{'char'}]{'points_dex'} = $val;
			print "Points needed for Dexterity: $val\n" if $config{'debug'};
		} elsif ($type == 37) {
			$chars[$config{'char'}]{'points_luk'} = $val;
			print "Points needed for Luck: $val\n" if $config{'debug'};
		}

	} elsif ($switch eq "00C0") {
		#00c0 <ID> l <type> B 
		#The person of ID voiced emotion. As for type the same as 00bf 
		my $ID = substr($msg, 2, 4);
		my $type = unpack("C*", substr($msg, 6, 1));
# add Emotion to Ai TalkQueue
		my $chat;
		if ($ID eq $accountID) {
			$chat = "$chars[$config{'char'}]{'name'} : $emotions_lut{$type}";
		} elsif (%{$players{$ID}}) {
			$chat = "$players{$ID}{'name'} : $emotions_lut{$type}";
			$ai_cmdQue[$ai_cmdQue]{'type'} = "e";
			$ai_cmdQue[$ai_cmdQue]{'ID'} = $ID;
			$ai_cmdQue[$ai_cmdQue]{'user'} = $players{$ID}{'name'};
			$ai_cmdQue[$ai_cmdQue]{'msg'} = "/emo".$type;
			$ai_cmdQue[$ai_cmdQue]{'time'} = time;
			$ai_cmdQue++;
		} elsif (%{$monsters{$ID}}){
			$chat = "$monsters{$ID}{'name'} : $emotions_lut{$type}";
		}
		$CONSOLE->Attr($main::FG_YELLOW |$main::BG_BLACK) if ($config{'colorMode'} && !$sys{'Vx_interface'});
		print addTag($sys{'Vx_interface'},"emotion"),"$chat\n" if ($chat);
		$CONSOLE->Attr($ATTR_NORMAL) if ($config{'colorMode'} && !$sys{'Vx_interface'});
		sysLog("e","[".unpack("L1",$ID)."]"."$chat\n") if ($config{'sysLog_emo'});

	} elsif ($switch eq "00C2") {
		#00c2 <val> l 
		#Login number of people response 
		my $users = unpack("L*", substr($msg, 2, 4));
		print "There are currently $users users online\n";

#00c3 <ID> l <type> B <val> B 
#The eye modification which you saw. As for type with 00 substance (when and the like switching jobs), 02 weapon, 03 head (under), 04 head (on), 05 head (in), 08 shield 

	} elsif ($switch eq "00C4") {
		#00c4 <ID> l 
		#Story it meaning that NPC which was applied is the merchant, the buy/sell selection window coming out 
		my $ID = substr($msg, 2, 4);
		undef %talk;
		$talk{'buyOrSell'} = 1;
		$talk{'ID'} = $ID;
		print "$npcs{$ID}{'name'} : Type 'store' to start buying, or type 'sell' to start selling\n";

#00c5 <ID> l <type> B 
#Buy/sell selection. If type=00 buy. If type=01 sell 

	} elsif ($switch eq "00C6") {
		#00c6 <len> w {<value> l <DCvalue> l <type> B <item ID> w} 11B* 
		#At the time of the store buy selection of NPC. As for DCvalue price after merchant DC 
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4), $config{'encrypt'});
		$msg = substr($msg, 0, 4).$newmsg;
		undef @storeList;
		my $storeList = 0;
		undef $talk{'buyOrSell'};
		for (my $i = 4; $i < $msg_size; $i+=11) {
			my $price = unpack("L1", substr($msg, $i, 4));
			my $type = unpack("C1", substr($msg, $i + 8, 1));
			my $ID = unpack("S1", substr($msg, $i + 9, 2));
			$storeList[$storeList]{'nameID'} = $ID;
			$storeList[$storeList]{'name'} = ($items_lut{$ID} ne "") ? $items_lut{$ID} : "Unknown ".$ID;
			$storeList[$storeList]{'nameID'} = $ID;
			$storeList[$storeList]{'type'} = $type;
			$storeList[$storeList]{'price'} = $price;
			print "Item added to Store: $storeList[$storeList]{'name'} - $price z\n" if ($config{'debug'} >= 2);
			$storeList++;
		}
		print "$npcs{$talk{'ID'}}{'name'} : Check my store list by typing 'store'\n";

	} elsif ($switch eq "00C7") {
		#00c7 <len> w {<index> w <value> l <OCvalue> l} 10B* 
		#At the time of the store sell selection of NPC. As for OCvalue price after merchant OC 
		#sell list, similar to buy list
		if (length($msg) > 4) {
			decrypt(\$newmsg, substr($msg, 4, length($msg)-4), $config{'encrypt'});
			$msg = substr($msg, 0, 4).$newmsg;
		}
		undef $talk{'buyOrSell'};
		print "Ready to start selling items\n";

#00ca <type> B 
#From NPC purchase end. Type=00 success 

#00cb <type> B 
#To NPC sale end. Type=00 success 

	} elsif ($switch eq "00CD") {
		#00cd <ID? > l 
		#GM Kick
		print "**GM kick you from server\n";
		sysLog("D","**GM kick you from server\n");
		print "**Quit .....\n";
		sysLog("D","**Quit .....\n");
		dumpData(substr($msg, 0, $msg_size));
		quit();

	} elsif ($switch eq "00D1") {
		#00d1 < type >.B < fail >.B 
		#ignored player
		my $type = unpack("C1", substr($msg, 2, 1));
		my $error = unpack("C1", substr($msg, 3, 1));
		if ($type == 0) {
			print "Player ignored\n";
		} elsif ($type == 1) {
			if ($error == 0) {
				print "Player unignored\n";
			}
		}

	} elsif ($switch eq "00D2") {
		#00d2 < type >.B < fail >.B 
		# /exall
		my $type = unpack("C1", substr($msg, 2, 1));
		my $error = unpack("C1", substr($msg, 3, 1));
		if ($type == 0) {
			print "All Players ignored\n";
		} elsif ($type == 1) {
			if ($error == 0) {
				print "All players unignored\n";
			}
		}

	} elsif ($switch eq "00D6") {
		#00d6 < fail >.B 
		#Chat raising response 
		$currentChatRoom = "new";
		%{$chatRooms{'new'}} = %createdChatRoom;
		binAdd(\@chatRoomsID, "new");
		binAdd(\@currentChatRoomUsers, $chars[$config{'char'}]{'name'});
		print addTag($sys{'Vx_interface'},"chatroom"),"Chat Room Created ($chatRooms{$currentChatRoom}{'title'})\n";

	} elsif ($switch eq "00D7") {
		#00d7 < len >.w < owner ID >.l < chat ID >.l < limit >.w < users >.w < pub >.B < title >.? B 
		#Chat information inside picture 
		decrypt(\$newmsg, substr($msg, 17, length($msg)-17), $config{'encrypt'});
		$msg = substr($msg, 0, 17).$newmsg;
		my $ID = substr($msg,8,4);
		if (!%{$chatRooms{$ID}}) {
			binAdd(\@chatRoomsID, $ID);
		}
		$chatRooms{$ID}{'title'} = substr($msg,17,$msg_size - 17);
		$chatRooms{$ID}{'ownerID'} = substr($msg,4,4);
		$chatRooms{$ID}{'limit'} = unpack("S1",substr($msg,12,2));
		$chatRooms{$ID}{'public'} = unpack("C1",substr($msg,16,1));
		$chatRooms{$ID}{'num_users'} = unpack("S1",substr($msg,14,2));

	} elsif ($switch eq "00D8") {
		#00d8 < chat ID >.l 
		#Chat elimination 
		my $ID = substr($msg,2,4);
		binRemove(\@chatRoomsID, $ID);
		undef %{$chatRooms{$ID}};

	} elsif ($switch eq "00DA") {
		#00da < fail >.B 
		#Failure of Chat participation
		my $type = unpack("C1",substr($msg, 2, 1));
		if ($type == 1) {
			print "Can't join Chat Room - Incorrect Password\n";
		} elsif ($type == 2) {
			print "Can't join Chat Room - You're banned\n";
		}

	} elsif ($switch eq "00DB") {
		#00db < len >.w < chat ID >.l { < index >.l < nick >.24b }.28b* 
		#Chat participant list 
		decrypt(\$newmsg, substr($msg, 8, length($msg)-8), $config{'encrypt'});
		$msg = substr($msg, 0, 8).$newmsg;
		my $ID = substr($msg,4,4);
		$currentChatRoom = $ID;
		$chatRooms{$currentChatRoom}{'num_users'} = 0;
		for (my $i = 8; $i < $msg_size; $i+=28) {
			my $type = unpack("C1",substr($msg,$i,1));
			my ($chatUser) = substr($msg,$i + 4,24) =~ /([\s\S]*?)\000/;
			if ($chatRooms{$currentChatRoom}{'users'}{$chatUser} eq "") {
				binAdd(\@currentChatRoomUsers, $chatUser);
				if ($type == 0) {
					$chatRooms{$currentChatRoom}{'users'}{$chatUser} = 2;
				} else {
					$chatRooms{$currentChatRoom}{'users'}{$chatUser} = 1;
				}
				$chatRooms{$currentChatRoom}{'num_users'}++;
			}
		}
		print qq~You have joined the Chat Room "$chatRooms{$currentChatRoom}{'title'}"\n~;

	} elsif ($switch eq "00DC") {
		#00dc < users >.w < nick >.24b 
		#Participant addition to Chat (?) 
		if ($currentChatRoom ne "") {
			my $num_users = unpack("S1", substr($msg,2,2));
			my ($joinedUser) = substr($msg,4,24) =~ /([\s\S]*?)\000/;
			binAdd(\@currentChatRoomUsers, $joinedUser);
			$chatRooms{$currentChatRoom}{'users'}{$joinedUser} = 1;
			$chatRooms{$currentChatRoom}{'num_users'} = $num_users;
			print "$joinedUser has joined the Chat Room\n";
		}
	
	} elsif ($switch eq "00DD") {
		#00dd < index >.w < nick >.24b < fail >.B 
		#From Chat participant to come out 
		my $num_users = unpack("S1", substr($msg,2,2));
		my ($leaveUser) = substr($msg,4,24) =~ /([\s\S]*?)\000/;
		$chatRooms{$currentChatRoom}{'users'}{$leaveUser} = "";
		binRemove(\@currentChatRoomUsers, $leaveUser);
		$chatRooms{$currentChatRoom}{'num_users'} = $num_users;
		if ($leaveUser eq $chars[$config{'char'}]{'name'}) {
			binRemove(\@chatRoomsID, $currentChatRoom);
			undef %{$chatRooms{$currentChatRoom}};
			undef @currentChatRoomUsers;
			$currentChatRoom = "";
			print "You left the Chat Room\n";
		} else {
			print "$leaveUser has left the Chat Room\n";
		}

	} elsif ($switch eq "00DF") {
		#00df < len >.w < owner ID >.l < chat ID >.l < limit >.w < users >.w < pub >.B < title >.? B 
		#Chat status modification success 
		decrypt(\$newmsg, substr($msg, 17, length($msg)-17), $config{'encrypt'});
		$msg = substr($msg, 0, 17).$newmsg;
		my $ID = substr($msg,8,4);
		my $ownerID = substr($msg,4,4);
		if ($ownerID eq $accountID) {
			$chatRooms{'new'}{'title'} = substr($msg,17,$msg_size - 17);
			$chatRooms{'new'}{'ownerID'} = $ownerID;
			$chatRooms{'new'}{'limit'} = unpack("S1",substr($msg,12,2));
			$chatRooms{'new'}{'public'} = unpack("C1",substr($msg,16,1));
			$chatRooms{'new'}{'num_users'} = unpack("S1",substr($msg,14,2));
		} else {
			$chatRooms{$ID}{'title'} = substr($msg,17,$msg_size - 17);
			$chatRooms{$ID}{'ownerID'} = $ownerID;
			$chatRooms{$ID}{'limit'} = unpack("S1",substr($msg,12,2));
			$chatRooms{$ID}{'public'} = unpack("C1",substr($msg,16,1));
			$chatRooms{$ID}{'num_users'} = unpack("S1",substr($msg,14,2));
		}
		print "Chat Room Properties Modified\n";

	} elsif ($switch eq "00E1") {
		#00e1 < index >.l < nick >.24b 
		#Chat participant number it does again to attach? 
		my $type = unpack("C1",substr($msg, 2, 1));
		my ($chatUser) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/;
		if ($type == 0) {
			if ($chatUser eq $chars[$config{'char'}]{'name'}) {
				$chatRooms{$currentChatRoom}{'ownerID'} = $accountID;
			} else {
				$key = findKeyString(\%players, "name", $chatUser);
				$chatRooms{$currentChatRoom}{'ownerID'} = $key;
			}
			$chatRooms{$currentChatRoom}{'users'}{$chatUser} = 2;
		} else {
			$chatRooms{$currentChatRoom}{'users'}{$chatUser} = 1;
		}

	} elsif ($switch eq "00E5") {
		#00e5 < nick >.24b 
		#Transaction request to receive
		my ($dealUser) = substr($msg, 2, 24) =~ /([\s\S]*?)\000/;
		$incomingDeal{'name'} = $dealUser;
		$timeout{'ai_dealAuto'}{'time'} = time;
		print "$dealUser Requests a Deal\n";
		if ($config{'AntiIncoming'}) {
			$ai_cmdQue[$ai_cmdQue]{'type'} = "C";
			$ai_cmdQue[$ai_cmdQue]{'user'} = $dealUser;
			$ai_cmdQue[$ai_cmdQue]{'msg'} = "/deal";
			$ai_cmdQue[$ai_cmdQue]{'time'} = time;
			$ai_cmdQue++;
		}

	} elsif ($switch eq "00E7") {
		#00e7 < fail >.B 
		#Transaction request response 
		my $type = unpack("C1", substr($msg, 2, 1));
		if ($type == 3) {
			if (%incomingDeal) {
				$currentDeal{'name'} = $incomingDeal{'name'};
			} else {
				$currentDeal{'ID'} = $outgoingDeal{'ID'};
				$currentDeal{'name'} = $players{$outgoingDeal{'ID'}}{'name'};
			} 
			print "Engaged Deal with $currentDeal{'name'}\n";
		}
		undef %outgoingDeal;
		undef %incomingDeal;

	} elsif ($switch eq "00E9") {
		#00e9 < amount >.l < type ID >.w < identify flag >.B < attribute? >.B < refine >.B < card >.4w 
		#Item addition from partners 
		my $amount = unpack("L*", substr($msg, 2,4));
		my $ID = unpack("S*", substr($msg, 6,2));
		if ($ID > 0) {
			$currentDeal{'other'}{$ID}{'amount'} += $amount;
			$currentDeal{'other'}{$ID}{'name'} = ($items_lut{$ID} ne "") ? $items_lut{$ID} : "Unknown ".$ID;
			#------------------------------------------------------------------------------------------------------------
			$currentDeal{'other'}{$ID}{'refined'} = unpack("C1",substr($msg,10,1));
			if (unpack("S1", substr($msg, 11, 2)) == 0x00FF) {
				$currentDeal{'other'}{$ID}{'elements'} = unpack("C1",substr($msg,9,1));
				$currentDeal{'other'}{$ID}{'star'} = unpack("C1",substr($msg,14,1)) / 0x05;
			} else {
				$currentDeal{'other'}{$ID}{'card'}[0]   = unpack("S1", substr($msg, 11, 2));
				$currentDeal{'other'}{$ID}{'card'}[1]   = unpack("S1", substr($msg, 13, 2));
				$currentDeal{'other'}{$ID}{'card'}[2]   = unpack("S1", substr($msg, 15, 2));
				$currentDeal{'other'}{$ID}{'card'}[3]   = unpack("S1", substr($msg, 17, 2));
			}
			modifingName(\%{$currentDeal{'other'}{$ID}}) if ($amount == 1);
			#------------------------------------------------------------------------------------------------------------
			print "$currentDeal{'name'} added Item to Deal: $currentDeal{'other'}{$ID}{'name'} x $amount\n";
		} elsif ($amount > 0) {
			$currentDeal{'other_zenny'} += $amount;
			print "$currentDeal{'name'} added $amount z to Deal\n";
		}

	} elsif ($switch eq "00EA") {
		#00ea < index >.w < fail >.B 
		#item add to deal
		my $index = unpack("S1", substr($msg, 2, 2));
		undef $invIndex;
		if ($index > 0) {
			$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
			$currentDeal{'you'}{$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'}}{'amount'} += $currentDeal{'lastItemAmount'};
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} -= $currentDeal{'lastItemAmount'};
			print "You added Item to Deal: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} x $currentDeal{'lastItemAmount'}\n";
			if ($chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} <= 0) {
				undef %{$chars[$config{'char'}]{'inventory'}[$invIndex]};
			}
		} elsif ($currentDeal{'lastItemAmount'} > 0) {
			$chars[$config{'char'}]{'zenny'} -= $currentDeal{'you_zenny'};
		}

	} elsif ($switch eq "00EC") {
		#00ec < fail >.B 
		my $type = unpack("C1", substr($msg, 2, 1));
		if ($type == 1) {
			$currentDeal{'other_finalize'} = 1;
			print "$currentDeal{'name'} finalized the Deal\n";
		} else {
			$currentDeal{'you_finalize'} = 1;
			print "You finalized the Deal\n";
		}

	} elsif ($switch eq "00EE") {
		#00ee 
		#Transaction was cancelled 
		undef %incomingDeal;
		undef %outgoingDeal;
		undef %currentDeal;
		print "Deal Cancelled\n";

	} elsif ($switch eq "00F0") {
		#00f0 
		#Completion of transaction
		print "Deal Complete\n";
		undef %currentDeal;

	} elsif ($switch eq "00F2") {
		#00f2 < num >.w < limit >.w 
		#Kapra approved item quantity & present condition 
		$storage{'items'} = unpack("S1", substr($msg, 2, 2));
		$storage{'items_max'} = unpack("S1", substr($msg, 4, 2));

	} elsif ($switch eq "00F4") {
		#00f4 < index >.w < amount >.l < type ID >.w < identify flag >.B < attribute? >.B < refine >.B < card >.4w 
		#Item addition of Kapra warehouse 
		my $index = unpack("S1", substr($msg, 2, 2));
		my $amount = unpack("L1", substr($msg, 4, 4));
		my $ID = unpack("S1", substr($msg, 8, 2));
		if (%{$storage{'inventory'}[$index]}) {
			$storage{'inventory'}[$index]{'amount'} += $amount;
		} else {
			$storage{'inventory'}[$index]{'nameID'} = $ID;
			$storage{'inventory'}[$index]{'amount'} = $amount;
			$display = ($items_lut{$ID} ne "") ? $items_lut{$ID} : "Unknown ".$ID;
			$storage{'inventory'}[$index]{'name'} = $display;
		}
# parse Card & Elements
		#------------------------------------------------------------------------------------------------------------
		my $is_equipType=0;
		$storage{'inventory'}[$index]{'refined'} = unpack("C1", substr($msg, 10, 1));
		if (unpack("S1", substr($msg, 11, 2)) == 0x00FF) {
			$storage{'inventory'}[$index]{'elements'} = unpack("C1", substr($msg, 13, 1));
			$storage{'inventory'}[$index]{'star'}      = unpack("C1", substr($msg, 14, 1));
			$is_equipType = 1;
		} else {
			$storage{'inventory'}[$index]{'card'}[0]   = unpack("S1", substr($msg, 11, 2));
			$storage{'inventory'}[$index]{'card'}[1]   = unpack("S1", substr($msg, 13, 2));
			$storage{'inventory'}[$index]{'card'}[2]   = unpack("S1", substr($msg, 15, 2));
			$storage{'inventory'}[$index]{'card'}[3]   = unpack("S1", substr($msg, 17, 2));
			$is_equipType = 1 if ($storage{'inventory'}[$index]{'card'}[0]);
		}
		modifingName(\%{$storage{'inventory'}[$index]}) if ($is_equipType);
		#------------------------------------------------------------------------------------------------------------
		$CONSOLE->Attr($main::FG_LIGHTGREEN|$main::BG_BLACK) if ($config{'colorMode'} && !$sys{'Vx_interface'});
		print "Storage Item Added: $storage{'inventory'}[$index]{'name'} ($index) x $amount\n";
		$CONSOLE->Attr($ATTR_NORMAL) if ($config{'colorMode'} && !$sys{'Vx_interface'});

	} elsif ($switch eq "00F6") {
		#00f6 < index >.w < amount >.l 
		#Item deletion of Kapra warehouse 
		my $index = unpack("S1", substr($msg, 2, 2));
		my $amount = unpack("L1", substr($msg, 4, 4));
		$storage{'inventory'}[$index]{'amount'} -= $amount;
		print "Storage Item Removed: $storage{'inventory'}[$index]{'name'} ($index) x $amount\n";
		if ($storage{'inventory'}[$index]{'amount'} <= 0) {
			undef %{$storage{'inventory'}[$index]};
		}

	} elsif ($switch eq "00F8") {
		#00f8 
		#Kapra warehouse closing response 
		print "Storage Closed\n";
#asimov Storage Log
		open  STCHAT, "> logs\/$config{'username'}_Storage.txt";
		print STCHAT "----------Storage ". getFormattedDate(int(time)) ."-----------\n";
		print STCHAT "#  Name\n";
			for (my $i=0; $i < @{$storage{'inventory'}};$i++) {
				next if (!%{$storage{'inventory'}[$i]});
				my $display = "$storage{'inventory'}[$i]{'name'} x $storage{'inventory'}[$i]{'amount'}";
				print STCHAT sprintf("%2d %-35s\n",$i,$display);
			}
		print STCHAT "\nCapacity: $storage{'items'}/$storage{'items_max'}\n";
		print STCHAT "-------------------------------\n";
		close STCHAT;

	} elsif ($switch eq "00FA") {
		#00fa < fail >.B
		#party organized
		my $type = unpack("C1", substr($msg, 2, 1));
		if ($type == 1) {
			print "Can't organize party - party name exists\n";
		} 

	} elsif ($switch eq "00FB") {
		#00fb < len >.w < party name >.24b { < ID >.l < nick >.24b < map name >.16b < leader >.B < offline >.B }.46b* 
		#Party information collecting, to send 
		decrypt(\$newmsg, substr($msg, 28, length($msg)-28), $config{'encrypt'});
		$msg = substr($msg, 0, 28).$newmsg;
		($chars[$config{'char'}]{'party'}{'name'}) = substr($msg, 4, 24) =~ /([\s\S]*?)\000/;
		for (my $i = 28; $i < $msg_size;$i+=46) {
			my $ID = substr($msg, $i, 4);
			my $num = unpack("C1",substr($msg, $i + 44, 1));
			if (!%{$chars[$config{'char'}]{'party'}{'users'}{$ID}}) {
				binAdd(\@partyUsersID, $ID);
			}
			($chars[$config{'char'}]{'party'}{'users'}{$ID}{'name'}) = substr($msg, $i + 4, 24) =~ /([\s\S]*?)\000/;
			($chars[$config{'char'}]{'party'}{'users'}{$ID}{'map'}) = substr($msg, $i + 28, 16) =~ /([\s\S]*?)\000/;
			$chars[$config{'char'}]{'party'}{'users'}{$ID}{'online'} = !(unpack("C1",substr($msg, $i + 45, 1)));
			$chars[$config{'char'}]{'party'}{'users'}{$ID}{'admin'} = 1 if ($num == 0);
		}
		sendPartyShareEXP(\$remote_socket, 1) if ($config{'partyAutoShare'} && %{$chars[$config{'char'}]{'party'}});

	} elsif ($switch eq "00FD") {
		#00fd < nick >.24b < fail >.B 
		#party join
		my ($name) = substr($msg, 2, 24) =~ /([\s\S]*?)\000/;
		my $type = unpack("C1", substr($msg, 26, 1));
		if ($type == 0) {
			print "Join request failed: $name is already in a party\n";
		} elsif ($type == 1) {
			print "Join request failed: $name denied request\n";
		} elsif ($type == 2) {
			print "$name accepted your request\n";
		}

	} elsif ($switch eq "00FE") {
		my $ID = substr($msg, 2, 4);
		my ($name) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/;
		print "Incoming Request to join $players{$ID} party '$name'\n";
		$incomingParty{'ID'} = $ID;
		$timeout{'ai_partyAutoDeny'}{'time'} = time;
		if ($config{'AntiIncoming'}) {
			$ai_cmdQue[$ai_cmdQue]{'type'} = "C";
			$ai_cmdQue[$ai_cmdQue]{'ID'} = $ID;
			$ai_cmdQue[$ai_cmdQue]{'user'} = $players{$ID}{'name'};
			$ai_cmdQue[$ai_cmdQue]{'msg'} = "/party";
			$ai_cmdQue[$ai_cmdQue]{'time'} = time;
			$ai_cmdQue++;
		}

	} elsif ($switch eq "0101") {
		my $type = unpack("C1", substr($msg, 2, 1));
		if ($type == 0) {
			print "Party EXP set to Individual Take\n";
		} elsif ($type == 1) {
			print "Party EXP set to Even Share\n";
		} else {
			print "Error setting party option\n";
		}
		
	} elsif ($switch eq "0104") {
		my $ID = substr($msg, 2, 4);
		my $x = unpack("S1", substr($msg,10, 2));
		my $y = unpack("S1", substr($msg,12, 2));
		my $type = unpack("C1",substr($msg, 14, 1));
		my ($name) = substr($msg, 15, 24) =~ /([\s\S]*?)\000/;
		my ($partyUser) = substr($msg, 39, 24) =~ /([\s\S]*?)\000/;
		my ($map) = substr($msg, 63, 16) =~ /([\s\S]*?)\000/;
		if (!%{$chars[$config{'char'}]{'party'}{'users'}{$ID}}) {
			binAdd(\@partyUsersID, $ID);
			if ($ID eq $accountID) {
				print "You joined party '$name'\n";
			} else {
				print "$partyUser joined your party '$name'\n";
			}
		}
		if ($type == 0) {
			$chars[$config{'char'}]{'party'}{'users'}{$ID}{'online'} = 1;
		} elsif ($type == 1) {
			$chars[$config{'char'}]{'party'}{'users'}{$ID}{'online'} = 0;
		}
		$chars[$config{'char'}]{'party'}{'name'} = $name;
		$chars[$config{'char'}]{'party'}{'users'}{$ID}{'pos'}{'x'} = $x;
		$chars[$config{'char'}]{'party'}{'users'}{$ID}{'pos'}{'y'} = $y;
		$chars[$config{'char'}]{'party'}{'users'}{$ID}{'map'} = $map;
		$chars[$config{'char'}]{'party'}{'users'}{$ID}{'name'} = $partyUser;
		
	} elsif ($switch eq "0105") {
		my $ID = substr($msg, 2, 4);
		my ($name) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/;
		undef %{$chars[$config{'char'}]{'party'}{'users'}{$ID}};
		binRemove(\@partyUsersID, $ID);
		if ($ID eq $accountID) {
			print "You left the party\n";
			undef %{$chars[$config{'char'}]{'party'}};
			$chars[$config{'char'}]{'party'} = "";
			undef @partyUsersID;
		} else {
			print "$name left the party\n";
		}

	} elsif ($switch eq "0106") {
		$ID = substr($msg, 2, 4);
		$chars[$config{'char'}]{'party'}{'users'}{$ID}{'hp_max'} = unpack("S1", substr($msg, 8, 2));
		calPercent(\%{$chars[$config{'char'}]{'party'}{'users'}{$ID}},"hp",unpack("S1", substr($msg, 6, 2)));

	} elsif ($switch eq "0107") {
		$ID = substr($msg, 2, 4);
		$x = unpack("S1", substr($msg,6, 2));
		$y = unpack("S1", substr($msg,8, 2));
		$chars[$config{'char'}]{'party'}{'users'}{$ID}{'pos'}{'x'} = $x;
		$chars[$config{'char'}]{'party'}{'users'}{$ID}{'pos'}{'y'} = $y;
		$chars[$config{'char'}]{'party'}{'users'}{$ID}{'online'} = 1;
		print "Party member location: $chars[$config{'char'}]{'party'}{'users'}{$ID}{'name'} - $x, $y\n" if ($config{'debug'} >= 2);

	} elsif ($switch eq "0108") {
		$type =  unpack("S1",substr($msg, 2, 2));
		$index = unpack("S1",substr($msg, 4, 2));
		$enchant = unpack("S1",substr($msg, 6, 2));
		$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
		$chars[$config{'char'}]{'inventory'}[$invIndex]{'elements'} = $enchant;
		print "Your Weapon Element changed to : $elements_lut{$enchant}\n";

	} elsif ($switch eq "0109") {
		decrypt(\$newmsg, substr($msg, 8, length($msg)-8), $config{'encrypt'});
		$msg = substr($msg, 0, 8).$newmsg;
		$chat = substr($msg, 8, $msg_size - 8);
		$chat =~ s/\000$//g;
		($chatMsgUser, $chatMsg) = $chat =~ /([\s\S]*?) : ([\s\S]*)\000/;
		sysLog("p",$chat."\n");
		$ai_cmdQue[$ai_cmdQue]{'type'} = "p";
		$ai_cmdQue[$ai_cmdQue]{'user'} = $chatMsgUser;
		$ai_cmdQue[$ai_cmdQue]{'msg'} = $chatMsg;
		$ai_cmdQue[$ai_cmdQue]{'time'} = time;
		$ai_cmdQue++;
		$CONSOLE->Attr($main::FG_YELLOW |$main::BG_BLACK) if ($config{'colorMode'} && !$sys{'Vx_interface'});
		print addTag($sys{'Vx_interface'},"party"),"%$chat\n";
		$CONSOLE->Attr($ATTR_NORMAL) if ($config{'colorMode'} && !$sys{'Vx_interface'});

	# wooooo MVP info
	} elsif ($switch eq "010A") {
		$ID = unpack("S1", substr($msg, 2, 2)); 
		print "You get MVP Item : ".$items_lut{$ID}."\n"; 
		sysLog("c","You get MVP Item : ".$items_lut{$ID}."\n");

	} elsif ($switch eq "010B") { 
		$val = unpack("L1",substr($msg, 2, 4)); 
		print "You're MVP!!! Special exp gained: $val\n";
		sysLog("c","You're MVP!!! Special exp gained: $val\n");

	} elsif ($switch eq "010C") {
		$ID = substr($msg, 2, 4); 
		$display = "Unknown"; 
		if (%{$players{$ID}}) { 
			$display = "Player ". $players{$ID}{'name'} . "(" . $players{$ID}{'binID'} . ") "; 
		} elsif ($ID eq $accountID) { 
			$display = "Your"; 
		} 
		print "$display become MVP!\n"; 
		sysLog("c", $display . " become MVP!\n"); 

	} elsif ($switch eq "010E") {
		$ID = unpack("S1",substr($msg, 2, 2));
		$lv = unpack("S1",substr($msg, 4, 2));
		$chars[$config{'char'}]{'skills'}{$skills_rlut{lc($skillsID_lut{$ID})}}{'lv'} = $lv;
		print "Skill $skillsID_lut{$ID}: $lv\n" if $config{'debug'};

	} elsif ($switch eq "010F") {
		$conState = 5 if ($conState != 4 && $sys{'Xmode'});
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4), $config{'encrypt'});
		$msg = substr($msg, 0, 4).$newmsg;
		undef @skillsID;
		for($i = 4;$i < $msg_size;$i+=37) {
			$ID = unpack("S1", substr($msg, $i, 2));
			($name) = substr($msg, $i + 12, 24) =~ /([\s\S]*?)\000/;
			if (!$name) {
				$name = $skills_rlut{lc($skillsID_lut{$ID})};
			}
			$chars[$config{'char'}]{'skills'}{$name}{'ID'} = $ID;
			if (!$chars[$config{'char'}]{'skills'}{$name}{'lv'}) {
				$chars[$config{'char'}]{'skills'}{$name}{'lv'} = unpack("S1", substr($msg, $i + 6, 2));
			}
			$skillsID_lut{$ID} = $skills_lut{$name};
			binAdd(\@skillsID, $name);
		}

	} elsif ($switch eq "0110") {
		# < skill ID >.w < basic type >.w? < fail >.B < type >.B 
		my $skillID = unpack("S1",substr($msg, 2, 2));
		my $basicType = unpack("S1",substr($msg, 4, 2));
		my $fail = unpack("C1",substr($msg, 6, 1));
		my $type = unpack("C1",substr($msg, 7, 1));
		print "Skill has failed (SkillID = $skillID : BasicType = $basicType : Fail = $fail : Type = $type)\n";

	} elsif ($switch eq "0114" || $switch eq "01DE") {
		#< skill ID >.w < src ID >.l < dst ID >.l < server tick >.l < src speed >.l < dst speed >.l < param1 >.w < param2 >.w < param3 >.w < type >.B
		$conState = 5 if ($conState != 4 && $sys{'Xmode'});
		$skillID = unpack("S1",substr($msg, 2, 2));
		$sourceID = substr($msg, 4, 4);
		$targetID = substr($msg, 8, 4);
		$damage = unpack("S1",substr($msg, 24, 2));
		$level = ($switch eq "0114") ? unpack("S1",substr($msg, 26, 2)) : unpack("S1",substr($msg, 28, 2));
		undef $sourceDisplay;
		undef $targetDisplay;
		undef $extra;
		if (%{$spells{$sourceID}}) {
			$sourceID = $spells{$sourceID}{'sourceID'}
		}

		updateDamageTables($sourceID, $targetID, $damage) if ($damage != 35536);
		if (%{$monsters{$sourceID}}) {
			$sourceDisplay = "$monsters{$sourceID}{'name'} ($monsters{$sourceID}{'binID'}) uses";
		} elsif (%{$players{$sourceID}}) {
			$sourceDisplay = "$players{$sourceID}{'name'} ($players{$sourceID}{'binID'}) uses";
			
		} elsif ($sourceID eq $accountID) {
			$sourceDisplay = "You use";
			$chars[$config{'char'}]{'skills'}{$skills_rlut{lc($skillsID_lut{$skillID})}}{'time_used'} = time;
			undef $chars[$config{'char'}]{'time_cast'};
		} else {
			$sourceDisplay = "Unknown uses";
		}

		if (%{$monsters{$targetID}}) {
			$targetDisplay = "$monsters{$targetID}{'name'} ($monsters{$targetID}{'binID'})";
			if ($sourceID eq $accountID) {
				$monsters{$targetID}{'castOnByYou'}++;
			} elsif (%{$players{$sourceID}}) {
				$monsters{$targetID}{'castOnByPlayer'}{$sourceID}++;
			}
		} elsif (%{$players{$targetID}}) {
			$targetDisplay = "$players{$targetID}{'name'} ($players{$targetID}{'binID'})";
		} elsif ($targetID eq $accountID) {
			if ($sourceID eq $accountID) {
				$targetDisplay = "yourself";
			} else {
				$targetDisplay = "you";
			}
		} else {
			$targetDisplay = "unknown";
		}
		$type = (($targetDisplay eq "yourself" || $targetDisplay eq "you")&& $sourceID eq $accountID) ? "skillon" : "skillAttack";
		if (!$config{'hideMsg_otherUseSkill'} || ($sourceID eq $accountID || (%{$monsters{$sourceID}} && $targetID eq $accountID))) {
			if ($damage != 35536) {
				$damage = "Miss!" if (!$damage);
				if ($level == 65535) {
					print addTag($sys{'Vx_interface'},"$type"),"$sourceDisplay $skillsID_lut{$skillID} on $targetDisplay$extra - Dmg: $damage\n"; 
				}else{
					print addTag($sys{'Vx_interface'},"$type"),"$sourceDisplay $skillsID_lut{$skillID} (lvl $level) on $targetDisplay$extra - Dmg: $damage\n"; 
				}
			} else {
				if ($level == 65535) {
					print addTag($sys{'Vx_interface'},"$type"),"$sourceDisplay $skillsID_lut{$skillID}\n";
				}else{
					print addTag($sys{'Vx_interface'},"$type"),"$sourceDisplay $skillsID_lut{$skillID} (lvl $level)\n"; 
				}
			}
		}
#		if ($sourceID eq $accountID && %{$monsters{$targetID}} && $skillID==263) {
#			ai_skillUse($chars[$config{'char'}]{'skills'}{'MO_CHAINCOMBO'}{'ID'},10, 0,0,$accountID);
#		}

	} elsif ($switch eq "0117") {
		my $skillID = unpack("S1",substr($msg, 2, 2));
		my $sourceID = substr($msg, 4, 4);
		my $lv = unpack("S1",substr($msg, 8, 2));
		my $x = unpack("S1",substr($msg, 10, 2));
		my $y = unpack("S1",substr($msg, 12, 2));
		
		undef $sourceDisplay;
		if (%{$monsters{$sourceID}}) {
			$sourceDisplay = "$monsters{$sourceID}{'name'} ($monsters{$sourceID}{'binID'}) uses";
		} elsif (%{$players{$sourceID}}) {
			$sourceDisplay = "$players{$sourceID}{'name'} ($players{$sourceID}{'binID'}) uses";
		} elsif ($sourceID eq $accountID) {
			$sourceDisplay = "You use";
			$chars[$config{'char'}]{'skills'}{$skills_rlut{lc($skillsID_lut{$skillID})}}{'time_used'} = time;
			undef $chars[$config{'char'}]{'time_cast'};
		} else {
			$sourceDisplay = "Unknown uses";
		}
		print "$sourceDisplay $skillsID_lut{$skillID} on location ($x, $y)\n";

#cureAuto_poison - Chobit Andy 20030408 
#mod Start
	} elsif ($switch eq "0119") { 
		my $ID = substr($msg, 2, 4);
		my $param1 = unpack("S1", substr($msg, 6, 2));
		my $param2 = unpack("S1", substr($msg, 8, 2));
		my $param3 = unpack("S1", substr($msg, 10, 2));
		if ($ID eq $accountID) { 
			if ($param2 == 1) { 
				print "You have affected by poison\n";
				if ($config{'cureAuto_poison'}) {
					if ($chars[$config{'char'}]{'skills'}{'TF_DETOXIFY'}{'lv'}) {
						print "Auto-Cure Poison use Skill : Detoxify\n";
						ai_skillUse($chars[$config{'char'}]{'skills'}{'TF_DETOXIFY'}{'ID'}, 1, 0,0, $accountID);
					}else{
						undef $ai_v{'temp'}{'invIndex'}; 
						$ai_v{'temp'}{'invIndex'} = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "nameID", 511);
						$ai_v{'temp'}{'invIndex'} = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "nameID", 506) if ($ai_v{'temp'}{'invIndex'} eq "");
						$ai_v{'temp'}{'invIndex'} = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "nameID", 525) if ($ai_v{'temp'}{'invIndex'} eq "");
						if ($ai_v{'temp'}{'invIndex'} ne "") { 
							print "Auto-Cure Poison use item : $items_lut{$chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'nameID'}}\n";
							sendItemUse(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'index'}, $accountID); 
						}else{
							print "No item to Auto-Cure Poison\n";
						}
					}
				}
			}elsif ($param2 == 4){
				print "Your are slept\n";
				ai_setSuspend(0);
			}elsif ($param2 == 16){
				print "Your are Blind\n";
			}elsif ($param2){
				print "[Rep] Affected Unknown $param2\n";
			}
			# cookiemaster cart support
			if ($param3 == 8 || $param3==128 || $param3==256 || $param3==512 || $param3==1024) {
				# cart
				$chars[$config{'char'}]{'cart'} = 1;
				print "you have the cart\n" if ($config{'debug'});
			} elsif ($param3 == 16) {
				# falcon
				$chars[$config{'char'}]{'falcon'} = 1;
				print "you have the falcon\n" if ($config{'debug'});
			} elsif ($param3 == 32) {
				# peco peco
				$chars[$config{'char'}]{'peco'} = 1;
				print "you ride the pecopeco\n" if ($config{'debug'});
			} elsif ($param3) {
				print "you have Unknown $param3\n";
			}
		}elsif (%{$players{$ID}}){
			if ($param2 ==1) {
				print "$players{$ID}{'name'} has affected by poison\n" if ($config{'debug'});
			}elsif ($param1 >=1){
				print "$players{$ID}{'name'} has affected froze or trap\n" if ($config{'debug'});
				$players{$ID}{'state'} = $param1;
			}elsif ($param3 >=64){
				print "[Warn] gid:".unpack("L1",$ID)." is hiding\n";
				if ($sys{'Xmode'}) {
					injectMessage("[Warn] gid:".unpack("L1",$ID)." is hiding\n") if ($config{'verbose'} && $sys{'Xmode'});
				}
				sysLog("D","**Player (".unpack("L1",$ID).") is hiding\n");
			}
		}elsif (%{$monsters{$ID}}){
			if ($param2 ==1) {
				print "$monsters{$ID}{'name'} is poisoned\n";
			}
			if ($param1 == 1) {
				$monsters{$ID}{'state'} = $param1;
				print "$monsters{$ID}{'name'} is trapped\n";
			}elsif ($param1 == 2) {
				$monsters{$ID}{'state'} = $param1;
				$CONSOLE->Attr($main::FG_BLUE|$main::BG_BLACK) if ($config{'colorMode'} && !$sys{'Vx_interface'});
				print "$monsters{$ID}{'name'} is frozen\n";
				$CONSOLE->Attr($ATTR_NORMAL) if ($config{'colorMode'} && !$sys{'Vx_interface'});
			#reverse state
			}elsif (defined($monsters{$ID}{'state'})){
				undef $monsters{$ID}{'state'};
			}
#mod Stop
		}

	} elsif ($switch eq "011A") {
		$conState = 5 if ($conState != 4 && $sys{'Xmode'});
		my $skillID = unpack("S1",substr($msg, 2, 2));
		my $targetID = substr($msg, 6, 4);
		my $sourceID = substr($msg, 10, 4);
		my $amount = unpack("S1",substr($msg, 4, 2));
		my ($sourceDisplay,$targetDisplay,$extra);
		if (%{$spells{$sourceID}}) {
			$sourceID = $spells{$sourceID}{'sourceID'}
		}
		if (%{$monsters{$sourceID}}) {
			$sourceDisplay = "$monsters{$sourceID}{'name'} ($monsters{$sourceID}{'binID'}) uses";
		} elsif (%{$players{$sourceID}}) {
			$sourceDisplay = "$players{$sourceID}{'name'} ($players{$sourceID}{'binID'}) uses";
		} elsif ($sourceID eq $accountID) {
			$sourceDisplay = "You use";
			$chars[$config{'char'}]{'skills'}{$skills_rlut{lc($skillsID_lut{$skillID})}}{'time_used'} = time;
			undef $chars[$config{'char'}]{'time_cast'};
		} else {
			$sourceDisplay = "Unknown uses";
		}
		if (%{$monsters{$targetID}}) {
			$targetDisplay = "$monsters{$targetID}{'name'} ($monsters{$targetID}{'binID'})";
			if ($sourceID eq $accountID) {
				$monsters{$targetID}{'castOnByYou'}++;
			} elsif (%{$players{$sourceID}}) {
				$monsters{$targetID}{'castOnByPlayer'}{$sourceID}++;
			}
		} elsif (%{$players{$targetID}}) {
			$targetDisplay = "$players{$targetID}{'name'} ($players{$targetID}{'binID'})";
		} elsif ($targetID eq $accountID) {
			if ($sourceID eq $accountID) {
				$targetDisplay = "yourself";
			} else {
				$targetDisplay = "you";
			}
		} else {
			$targetDisplay = "unknown";
		}
		my $type = "skillAttack";
		if ($skillID == 28) {
			$extra = ": $amount hp gained";
			$type = "skillHeal";
		} elsif ($amount != 65535) {
			$extra = ": Lv $amount";
			$type = "skillon";
		}
		if (!$config{'hideMsg_otherUseSkill'} || ($sourceID eq $accountID || (%{$monsters{$sourceID}} && $targetID eq $accountID))) {
			print addTag($sys{'Vx_interface'},$type),"$sourceDisplay $skillsID_lut{$skillID} on $targetDisplay$extra\n";
		}
#mod Start
# Detect Heal
		#skill to monster
		if (($skillID==28 || $skillID==29 || $skillID == 34) && $targetID eq $ai_seq_args[0]{'ID'} && $config{'AntiSkillonMonster'} 
			&& %{$players{$sourceID}} && %{$monsters{$targetID}}){
			$CONSOLE->Attr($main::FG_RED|$main::BG_BLACK) if ($config{'colorMode'} && !$sys{'Vx_interface'});
			print addTag($sys{'Vx_interface'},"danger"),"$players{$sourceID}{'name'} use $skillsID_lut{$skillID} on Your Attacked Monster \n";
			sysLog("D","** $players{$sourceID}{'name'} use $skillsID_lut{$skillID} on Your Attacked Monster \n");
			updatepplControl("$def_config/ppl_control.txt",$players{$sourceID}{'name'},unpack("L1",$sourceID)) if (!defined(%{$ppl_control{$players{$sourceID}{'name'}}}));
			if ($ai_seq[0] eq "attack") {
				shift @ai_seq;
				shift @ai_seq_args;
				ai_setSuspend(0);
				sendAttackStop(\$remote_socket) if ($config{'attackUseWeapon'});
			}
			if ($config{'ChatAuto'} && (!defined($ppllog{'cmd'}{"$players{$sourceID}{'name'}"}{'resp'}) || $ppllog{'cmd'}{"$players{$sourceID}{'name'}"}{'resp'}<$config{'ChatAuto_Max'})) {
				$ai_cmdQue[$ai_cmdQue]{'type'} = "C";
				$ai_cmdQue[$ai_cmdQue]{'ID'} = $sourceID;
				$ai_cmdQue[$ai_cmdQue]{'user'} = $players{$sourceID}{'name'};
				$ai_cmdQue[$ai_cmdQue]{'msg'} = "/antiskill$skillID";
				$ai_cmdQue[$ai_cmdQue]{'time'} = time;
				$ai_cmdQue++;
			}elsif (!$config{'ChatAuto'} || $ppllog{'cmd'}{"$players{$sourceID}{'name'}"}{'resp'}>=$config{'ChatAuto_Max'}){
				if ($ppl_control{$players{$sourceID}{'name'}}{'teleport_auto'}) {
					useTeleport($ppl_control{$players{$sourceID}{'name'}}{'teleport_auto'});
					print addTag($sys{'Vx_interface'},"danger"),"Teleport Away by Method : ($ppl_control{$players{$sourceID}{'name'}}{'teleport_auto'}) ...\n";
					sysLog("D","** Teleport Away by Method : ($ppl_control{$players{$sourceID}{'name'}}{'teleport_auto'}) ...\n");
				}elsif ($config{'avoidGM'}<3 && $config{'avoidGM'}>0){
					useTeleport($config{'avoidGM'});
					print addTag($sys{'Vx_interface'},"danger"),"Teleport Away by Method : ($config{'avoidGM'}) ...\n";
					sysLog("D","** Teleport Away by Method : ($config{'avoidGM'}) ...\n");
				}
				if ($ppl_control{$players{$sourceID}{'name'}}{'disconnect_auto'} || $config{'avoidGM'}==3) {
					print "Avoiding $players{$sourceID}{'name'} ($players{$sourceID}{'nameID'}), Disconnect...\n";
					sysLog("D","**Avoiding $players{$sourceID}{'name'} ($players{$sourceID}{'nameID'}), Disconnect...\n");
					$timeout_ex{'master'}{'time'} = time;
					$timeout_ex{'master'}{'timeout'} = $config{'avoid_reConnect'};
					killConnection(\$remote_socket);
				}
			}
			$CONSOLE->Attr($ATTR_NORMAL) if ($config{'colorMode'} && !$sys{'Vx_interface'});
		#skill to you
		}elsif (($skillID==28 || $skillID==29 || $skillID == 34)  && $targetDisplay eq "you" && $config{'AutoThanks'} && %{$players{$sourceID}}){
			print "$players{$sourceID}{'name'} use $skillsID_lut{$skillID} on You\n";
			sysLog("D","** $players{$sourceID}{'name'} use $skillsID_lut{$skillID} on You\n");
			if ($ai_seq[0] eq "attack") {
				shift @ai_seq;
				shift @ai_seq_args;
				ai_setSuspend(0);
				sendAttackStop(\$remote_socket) if ($config{'attackUseWeapon'});
			}
			if ($config{'ChatAuto'} && (!defined($ppllog{'cmd'}{"$players{$sourceID}{'name'}"}{'resp'}) || $ppllog{'cmd'}{"$players{$sourceID}{'name'}"}{'resp'}<$config{'ChatAuto_Max'})) {
				$ai_cmdQue[$ai_cmdQue]{'type'} = "C";
				$ai_cmdQue[$ai_cmdQue]{'ID'} = $sourceID;
				$ai_cmdQue[$ai_cmdQue]{'user'} = $players{$sourceID}{'name'};
				$ai_cmdQue[$ai_cmdQue]{'msg'} = "/thanks";
				$ai_cmdQue[$ai_cmdQue]{'time'} = time;
				$ai_cmdQue++;
			}
		}
#mod Stop

	} elsif ($switch eq "011E") {
		my $fail = unpack("C1", substr($msg, 2, 1));
		if ($fail) {
			print "Memo Failed\n";
		} else {
			print "Memo Succeeded\n";
		}

	} elsif ($switch eq "011F" || $switch eq "01C9") {
		#011f <dst ID>.l <src ID>.l <X>.w <Y>.w <type>.B <fail>.B 
		#01c9 <dst ID>.l <src ID>.l <X>.w <Y>.w <type>.B <fail>.B ?.81b
		#area effect spell
		$ID = substr($msg, 2, 4);
		$SourceID = substr($msg, 6, 4);
		$x = unpack("S1",substr($msg, 10, 2));
		$y = unpack("S1",substr($msg, 12, 2));
		$spells{$ID}{'sourceID'} = $SourceID;
		$spells{$ID}{'pos'}{'x'} = $x;
		$spells{$ID}{'pos'}{'y'} = $y;
		$binID = binAdd(\@spellsID, $ID);
		$spells{$ID}{'binID'} = $binID;

	} elsif ($switch eq "0120") {
		#The area effect spell with ID dissappears
		$ID = substr($msg, 2, 4);
		undef %{$spells{$ID}};
		binRemove(\@spellsID, $ID);

#Cart Parses - chobit andy 20030102
	} elsif ($switch eq "0121") {
		$cart{'items'} = unpack("S1", substr($msg, 2, 2));
		$cart{'items_max'} = unpack("S1", substr($msg, 4, 2));
		$cart{'weight'} = int(unpack("L1", substr($msg, 6, 4)) / 10);
		$cart{'weight_max'} = int(unpack("L1", substr($msg, 10, 4)) / 10);

	} elsif ($switch eq "0122") {
		#"0122" sends non-stackable item info
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4), $config{'encrypt'});
		$msg = substr($msg, 0, 4).$newmsg;
		for($i = 4; $i < $msg_size; $i+=20) {
			$index = unpack("S1", substr($msg, $i, 2));
			$ID = unpack("S1", substr($msg, $i+2, 2));
			$type = unpack("C1",substr($msg, $i+4, 1));
			$display = ($items_lut{$ID} ne "") ? $items_lut{$ID} : "Unknown ".$ID;
			$cart{'inventory'}[$index]{'nameID'} = $ID;
			$cart{'inventory'}[$index]{'amount'} = 1;
			$cart{'inventory'}[$index]{'name'} = $display;
			$cart{'inventory'}[$index]{'identified'} = unpack("C1", substr($msg, $i+5, 1));
			$cart{'inventory'}[$index]{'type_equip'} = unpack("S1", substr($msg, $i + 6, 2));
#mod Start
# parse Card & Elements
			#------------------------------------------------------------------------------------------------------------
			$cart{'inventory'}[$index]{'refined'} = unpack("C1", substr($msg, $i+11, 1));
			if (unpack("S1", substr($msg, $i+12, 2)) == 0x00FF) {
				$cart{'inventory'}[$index]{'elements'} = unpack("C1", substr($msg, $i+14, 1));
				$cart{'inventory'}[$index]{'star'}      = unpack("C1", substr($msg, $i+15, 1))/ 0x05;
			} else {
				$cart{'inventory'}[$index]{'card'}[0]   = unpack("S1", substr($msg, $i+12, 2));
				$cart{'inventory'}[$index]{'card'}[1]   = unpack("S1", substr($msg, $i+14, 2));
				$cart{'inventory'}[$index]{'card'}[2]   = unpack("S1", substr($msg, $i+16, 2));
				$cart{'inventory'}[$index]{'card'}[3]   = unpack("S1", substr($msg, $i+18, 2));
			}
			modifingName(\%{$cart{'inventory'}[$index]});
			#------------------------------------------------------------------------------------------------------------
#mod Stop
			print "Non-Stackable Cart Item: $cart{'inventory'}[$index]{'name'} ($index) x 1\n" if ($config{'debug'} >= 1);
		}

	} elsif ($switch eq "0123" || $switch eq "01EF") {
		#"0123" sends stackable item info
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4), $config{'encrypt'});
		$msg = substr($msg, 0, 4).$newmsg;
		my $psize = ($switch eq "0123") ? 10 : 18;
		for($i = 4; $i < $msg_size; $i+=$psize) {
			$index = unpack("S1", substr($msg, $i, 2));
			$ID = unpack("S1", substr($msg, $i+2, 2));
			$amount = unpack("S1", substr($msg, $i+6, 2));
			if (defined %{$cart{'inventory'}[$index]}) {
				$cart{'inventory'}[$index]{'amount'} += $amount;
			} else {
				$cart{'inventory'}[$index]{'nameID'} = $ID;
				$cart{'inventory'}[$index]{'amount'} = $amount;
				$display = ($items_lut{$ID} ne "") ? $items_lut{$ID} : "Unknown ".$ID;
				$cart{'inventory'}[$index]{'name'} = $display;
			}
			print "Stackable Cart Item: $cart{'inventory'}[$index]{'name'} ($index) x $amount\n" if ($config{'debug'} >= 1);
		}

	} elsif ($switch eq "0124" || $switch eq "01C5") {
		$index = unpack("S1", substr($msg, 2, 2));
		$amount = unpack("L1", substr($msg, 4, 4));
		$ID = unpack("S1", substr($msg, 8, 2));
		if (%{$cart{'inventory'}[$index]}) {
			$cart{'inventory'}[$index]{'amount'} += $amount;
		} else {
			$cart{'inventory'}[$index]{'nameID'} = $ID;
			$cart{'inventory'}[$index]{'amount'} = $amount;
			$display = ($items_lut{$ID} ne "") ? $items_lut{$ID} : "Unknown ".$ID;
			$cart{'inventory'}[$index]{'name'} = $display;
#mod Start
# parse Card & Elements
			#------------------------------------------------------------------------------------------------------------
			#<index>.w <amount>.l <item ID>.w <identify flag>.B <attribute?>.B <refine>.B <card>.4w
			$cart{'inventory'}[$index]{'identify'} = unpack("C1", substr($msg, 10, 1));
			$cart{'inventory'}[$index]{'refined'} = unpack("C1", substr($msg, 12, 1));
			if (unpack("S1", substr($msg, 13, 2)) == 0x00FF) {
				$cart{'inventory'}[$index]{'elements'} = unpack("C1", substr($msg, 15, 1));
				$cart{'inventory'}[$index]{'star'}      = unpack("C1", substr($msg, 16, 1))/ 0x05;
			} else {
				$cart{'inventory'}[$index]{'card'}[0]   = unpack("S1", substr($msg, 13, 2));
				$cart{'inventory'}[$index]{'card'}[1]   = unpack("S1", substr($msg, 15, 2));
				$cart{'inventory'}[$index]{'card'}[2]   = unpack("S1", substr($msg, 17, 2));
				$cart{'inventory'}[$index]{'card'}[3]   = unpack("S1", substr($msg, 19, 2));
			}
			modifingName(\%{$cart{'inventory'}[$index]});
			#------------------------------------------------------------------------------------------------------------
#mod Stop
		}
		print addTag($sys{'Vx_interface'},"cartAdd"),"Cart Item Added: $cart{'inventory'}[$index]{'name'} ($index) x $amount\n";

	} elsif ($switch eq "0125") {
		$index = unpack("S1", substr($msg, 2, 2));
		$amount = unpack("L1", substr($msg, 4, 4));
		$cart{'inventory'}[$index]{'amount'} -= $amount;
		print addTag($sys{'Vx_interface'},"cartRemove"),"Cart Item Removed: $cart{'inventory'}[$index]{'name'} ($index) x $amount\n";
		if ($cart{'inventory'}[$index]{'amount'} <= 0) {
			undef %{$cart{'inventory'}[$index]};
		}

	} elsif ($switch eq "012C") {
		$index = unpack("S1", substr($msg, 3, 2));
		$amount = unpack("L1", substr($msg, 7, 2));
		$ID = unpack("S1", substr($msg, 9, 2));
		if ($items_lut{$ID} ne "") {
			print "Can't Add Cart Item: $items_lut{$ID}\n";
		}

#mod Start
#Solos Vender
	} elsif ($switch eq "012D" ){
		#used vending skill.
		$number = unpack("S1",substr($msg, 2, 2));
		print "You can sell $number items!\n";

	} elsif ($switch eq "0131") {
		#Street stall signboard indication 
		$ID = substr($msg,2,4);
		if (!%{$venderLists{$ID}}) {
			binAdd(\@venderListsID, $ID);
		}
		($venderLists{$ID}{'title'}) = substr($msg,6,36) =~ /(.*?)\000/;

	} elsif ($switch eq "0132") {
		#Street stall signboard elimination
		$ID = substr($msg,2,4);
		binRemove(\@venderListsID, $ID);
		undef %{$venderLists{$ID}};

	} elsif ($switch eq "0133") {
			undef @venderItemList;
			undef $venderID;
			$venderID = substr($msg,4,4);
			$venderItemList = 0;
			print "----------Vender Store List-----------\n";
			print "#  Name                          Type       Amount     Price\n";
			for ($i = 8; $i < $msg_size; $i+=22) {
				$index = unpack("S1", substr($msg, $i + 6, 2));
				$ID = unpack("S1", substr($msg, $i + 9, 2));
				$venderItemList[$index]{'nameID'} = $ID;
				$display = ($items_lut{$ID} ne "") ? $items_lut{$ID} : "Unknown ".$ID;
#mod Start
# parse Card & Elements
				#------------------------------------------------------------------------------------------------------------
				$venderItemList[$index]{'name'} = $display;
				$venderItemList[$index]{'price'} = unpack("L1", substr($msg, $i, 4));
				$venderItemList[$index]{'amount'} = unpack("S1", substr($msg, $i + 4, 2));
				$venderItemList[$index]{'type'} = unpack("C1", substr($msg, $i + 8, 1));
				$venderItemList[$index]{'identified'} = unpack("C1", substr($msg, $i + 11, 1));
				$venderItemList[$index]{'refined'} = unpack("C1", substr($msg, $i + 13, 1));
				if (unpack("S1", substr($msg,$i+14, 2)) == 0x00FF) {
					$venderItemList[$index]{'elements'} = unpack("C1", substr($msg,$i+16, 1));
					$venderItemList[$index]{'star'}      = unpack("C1", substr($msg,$i+17, 1)) / 0x05;
				}else{
					$venderItemList[$index]{'card'}[0] = unpack("S1", substr($msg, $i + 14, 2));
					$venderItemList[$index]{'card'}[1] = unpack("S1", substr($msg, $i + 16, 2));
					$venderItemList[$index]{'card'}[2] = unpack("S1", substr($msg, $i + 18, 2));
					$venderItemList[$index]{'card'}[3] = unpack("S1", substr($msg, $i + 20, 2));
				}
				modifingName(\%{$venderItemList[$index]});
				#------------------------------------------------------------------------------------------------------------
				$venderItemList++;
				print "Item added to Vender Store: $items{$ID}{'name'} - $price z\n" if ($config{'debug'} >= 2);
				print sprintf("%2d %-29s %-10s %6s %8sz\n",$index,$venderItemList[$index]{'name'},$itemTypes_lut{$venderItemList[$index]{'type'}},$venderItemList[$index]{'amount'},$venderItemList[$index]{'price'});
			}
			print "--------------------------------------\n";

	} elsif ($switch eq "0135") {
	#Failure of street stall item purchase.
		my $fail = unpack("C1",substr($msg,6,1));
		if ($fail == 1) {
			print "Your money is not enough\n";
		}elsif ($fail == 2){
			print "It is overweight.\n";
		}

	} elsif ($switch eq "0136") {
		undef %shopItem;
		undef @articles;
		$articles = 0; 
		print "---------- $shop{'shop_title'} -------------\n"; 
		print "#  Name                          Type     Amount      Price\n";
		for ($i = 8; $i < $msg_size; $i+=22) { 
			$index = unpack("S1", substr($msg, $i + 4, 2)); 
			$articles[$index]{'price'} = unpack("L1", substr($msg, $i, 4)); 
			$articles[$index]{'amount'} = unpack("S1", substr($msg, $i + 6, 2)); 
			$articles[$index]{'type'} = unpack("C1", substr($msg, $i + 8, 1));
			$ID = unpack("S1", substr($msg, $i + 9, 2)); 
			$articles[$index]{'identified'} = unpack("C1", substr($msg, $i + 11, 1)); 
			$articles[$index]{'nameID'} = $ID; 
			$display = ($items_lut{$ID} ne "") ? $items_lut{$ID} : "Unknown ".$ID; 
			# parse Card & Elements
			#------------------------------------------------------------------------------------------------------------
			#<value>.l <index>.w <amount>.w <type>.B <item ID>.w <identify flag>.B <attribute?>.B <refine>.B <card>.4w
			$articles[$index]{'name'} = $display;
			$articles[$index]{'refined'} = unpack("C1", substr($msg, $i + 13, 1));
			if (unpack("S1", substr($msg,$i+14, 2)) == 0x00FF) {
				$articles[$index]{'elements'} = unpack("C1", substr($msg,$i+16, 1));
				$articles[$index]{'star'}      = unpack("C1", substr($msg,$i+17, 1)) / 0x05;
			}else{
				$articles[$index]{'card'}[0] = unpack("S1", substr($msg, $i + 14, 2)); 
				$articles[$index]{'card'}[1] = unpack("S1", substr($msg, $i + 16, 2)); 
				$articles[$index]{'card'}[2] = unpack("S1", substr($msg, $i + 18, 2)); 
				$articles[$index]{'card'}[3] = unpack("S1", substr($msg, $i + 20, 2)); 
			}
			modifingName(\%{$articles[$index]});
			#------------------------------------------------------------------------------------------------------------
			$articles++; 
			print sprintf("%2d %-29s %-10s %6s %8sz\n",$index,$articles[$index]{'name'},$itemTypes_lut{$articles[$index]{'type'}},$articles[$index]{'amount'},$articles[$index]{'price'});
		} 
		print "-------------------------","-"x length($shop{'shop_title'}),"\n"; 

	} elsif ($switch eq "0137") {
		$index = unpack("S1",substr($msg, 2, 2));
		$amount = unpack("S1",substr($msg, 4, 2));
		$price = $amount * $articles[$index]{'price'};
		$articles[$index]{'sold'} += $amount;
		$shop{'earned'} += $amount * $articles[$index]{'price'};
		$articles[$index]{'amount'} -= $amount;
		print "sold item : $articles[$index]{'name'} x $amount - $price z\n";
		sysLog("shop","sold item : $articles[$index]{'name'} x $amount - $price z\n");
		if ($articles[$index]{'amount'} < 1) {
			if (!--$articles){
				print "all sold out.^^\n";
				sendcloseShop(\$remote_socket);
				print "Closing Your Shop \n";
				$ai_v{'temp'}{'shopOpen'} = 0;
				quit() if ($config{'dcOnShopClosed'});
			}
		}

	} elsif ($switch eq "0139") {
		$ID = substr($msg, 2, 4);
		$type = unpack("C1",substr($msg, 14, 1));
		$coords1{'x'} = unpack("S1",substr($msg, 6, 2));
		$coords1{'y'} = unpack("S1",substr($msg, 8, 2));
		$coords2{'x'} = unpack("S1",substr($msg, 10, 2));
		$coords2{'y'} = unpack("S1",substr($msg, 12, 2));
		%{$monsters{$ID}{'pos_attack_info'}} = %coords1;
		%{$chars[$config{'char'}]{'pos'}} = %coords2;
		%{$chars[$config{'char'}]{'pos_to'}} = %coords2;
		print "Recieved attack location - $monsters{$ID}{'pos_attack_info'}{'x'}, $monsters{$ID}{'pos_attack_info'}{'y'} - ".getHex($ID)."\n" if ($config{'debug'} >= 2);

# Attack Range from server
	} elsif ($switch eq "013A") {
		my $type = unpack("S1",substr($msg, 2, 2));
		print "Your Real Attack Range is : $type\n" if ($config{'debug'});

# Hambo Arrow Equip
	} elsif ($switch eq "013B") {
		$type = unpack("S1",substr($msg, 2, 2)); 
		if ($type == 0) { 
			print "Please equip arrow first\n";
			undef $chars[$config{'char'}]{'arrow'};
			quit() if ($config{'dcOnEmptyArrow'});
		} elsif ($type == 3) {
			print "Arrow equipped\n" if ($config{'debug'}); 
		} 

	} elsif ($switch eq "013C") {
		$index = unpack("S1", substr($msg, 2, 2)); 
		$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index); 
		if ($invIndex ne "") { 
			$chars[$config{'char'}]{'arrow'}=1 if (!defined($chars[$config{'char'}]{'arrow'}));
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'equipped'} = 32768; 
			print "Arrow equipped: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex)\n";
		} 

	} elsif ($switch eq "013D") {
		$type = unpack("S1",substr($msg, 2, 2));
		$amount = unpack("S1",substr($msg, 4, 2));
		if ($type == 5) {
			calPercent(\%{$chars[$config{'char'}]},"hp",$chars[$config{'char'}]{'hp'}+$amount);
		} elsif ($type == 7) {
			calPercent(\%{$chars[$config{'char'}]},"sp",$chars[$config{'char'}]{'sp'}+$amount);
		}

	} elsif ($switch eq "013E") {
		$conState = 5 if ($conState != 4 && $sys{'Xmode'});
		my $sourceID = substr($msg, 2, 4);
		my $targetID = substr($msg, 6, 4);
		my $x = unpack("S1",substr($msg, 10, 2));
		my $y = unpack("S1",substr($msg, 12, 2));
		my $skillID = unpack("S1",substr($msg, 14, 2));
		my ($sourceDisplay,$targetDisplay,%coords);
		my $dis=0;

		if (%{$monsters{$sourceID}}) {
			$sourceDisplay = "$monsters{$sourceID}{'name'} ($monsters{$sourceID}{'binID'}) is casting";
		} elsif (%{$players{$sourceID}}) {
			$sourceDisplay = "$players{$sourceID}{'name'} ($players{$sourceID}{'binID'}) is casting";
		} elsif ($sourceID eq $accountID) {
			$sourceDisplay = "You are casting";
			$chars[$config{'char'}]{'time_cast'} = time;
		} else {
			$sourceDisplay = "Unknown is casting";
		}

		if (%{$monsters{$targetID}}) {
			$targetDisplay = "$monsters{$targetID}{'name'} ($monsters{$targetID}{'binID'})";
			if ($sourceID eq $accountID) {
				$monsters{$targetID}{'castOnByYou'}++;
			} elsif (%{$players{$sourceID}}) {
				$monsters{$targetID}{'castOnByPlayer'}{$sourceID}++;
			}
		} elsif (%{$players{$targetID}}) {
			$targetDisplay = "$players{$targetID}{'name'} ($players{$targetID}{'binID'})";
		} elsif ($targetID eq $accountID) {
			if ($sourceID eq $accountID) {
				$targetDisplay = "yourself";
			} else {
				$targetDisplay = "you";
			}
		} elsif ($x != 0 || $y != 0) {
			$coords{'x'} = $x;
			$coords{'y'} = $y;
			$dist = judgeSkillArea($skillID) - distance(\%{$chars[$config{'char'}]{'pos_to'}},\%coords);
			$targetDisplay = "location ($x, $y)";
		} else {
			$targetDisplay = "unknown";
		}
		if (!$config{'hideMsg_otherUseSkill'} || ($sourceID eq $accountID || (%{$monsters{$sourceID}} && ($targetID eq $accountID || ($dist>0))))) {
			print addTag($sys{'Vx_interface'},"casting"),"$sourceDisplay $skillsID_lut{$skillID} on $targetDisplay\n";
		}
		#Switch Target immediately
		if (%{$monsters{$sourceID}} && $mon_control{lc($monsters{$sourceID}{'name'})}{'skillcancel_auto'}) {
			if ($targetID eq $accountID || $dist>0 || ($ai_seq[0] eq "attack" && $ai_seq_args[0]{'ID'} ne $sourceID)) {
				print "[Act] Monster Skill - switch Target to : $monsters{$sourceID}{'name'} ($monsters{$sourceID}{'binID'})\n";
				sendAttackStop(\$remote_socket);
				shift @ai_seq;
				shift @ai_seq_args;
				attack($sourceID);
			}
			#skill area casting -> running to monster's back
			if ($dist>0){
				#calculate X axis
				if ($chars[$config{'char'}]{'pos_to'}{'x'}-$monsters{$ai_seq_args[0]{'ID'}}{'pos_to'}{'x'} < 0) {
					$coords{'x'} = $monsters{$ai_seq_args[0]{'ID'}}{'pos_to'}{'x'}+2;
				} else {
					$coords{'x'} = $monsters{$ai_seq_args[0]{'ID'}}{'pos_to'}{'x'}-2;
				}
				#calculate Y axis
				if ($chars[$config{'char'}]{'pos_to'}{'y'}-$monsters{$ai_seq_args[0]{'ID'}}{'pos_to'}{'y'} < 0) {
					$coords{'y'} = $monsters{$ai_seq_args[0]{'ID'}}{'pos_to'}{'y'}+2;
				} else {
					$coords{'y'} = $monsters{$ai_seq_args[0]{'ID'}}{'pos_to'}{'y'}-2;
				}
				getVector(\%{$ai_v{'temp'}{'vec'}}, \%coords, \%{$chars[$config{'char'}]{'pos_to'}});
				moveAlongVector(\%{$ai_v{'temp'}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}}, \%{$ai_v{'temp'}{'vec'}},distance(\%{$chars[$config{'char'}]{'pos_to'}},\%coords));
				ai_route(\%{$ai_seq_args[0]{'ai_route_returnHash'}}, $ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'}, $field{'name'}, $config{'attackMaxRouteDistance'}, $config{'attackMaxRouteTime'}, 0, 0);
				print "[Act] Avoid casting Skill - switch position to : $ai_v{'temp'}{'pos'}{'x'},$ai_v{'temp'}{'pos'}{'y'}\n";
			}
		}

# Detect Warp
		$CONSOLE->Attr($main::FG_RED|$main::BG_BLACK) if ($config{'colorMode'} && !$sys{'Vx_interface'});
		if ($skillID == 27 && ($chars[$config{'char'}]{'pos_to'}{'x'}==$x)
			&& ($chars[$config{'char'}]{'pos_to'}{'y'}==$y) && $currentChatRoom eq "" && !$ai_v{'temp'}{'shopOpen'}){
			print addTag($sys{'Vx_interface'},"danger"),"$players{$sourceID}{'name'} Trying to Warp You \n";
			sysLog("D","** $players{$sourceID}{'name'} Trying to Warp You \n");
			updatepplControl("$def_config/ppl_control.txt",$players{$sourceID}{'name'},unpack("L1",$sourceID)) if (!%{$ppl_control{$players{$sourceID}{'name'}}});
			if ($config{'AntiWarp'} == 1) {
				if ($ai_seq[0] eq "attack") {
					shift @ai_seq;
					shift @ai_seq_args;
					ai_setSuspend(0);
					sendAttackStop(\$remote_socket) if ($config{'attackUseWeapon'});
				}
				if ($config{'ChatAuto'} && (!defined($ppllog{'cmd'}{"$players{$sourceID}{'name'}"}{'resp'}) || $ppllog{'cmd'}{"$players{$sourceID}{'name'}"}{'resp'}<$config{'ChatAuto_Max'})) {
					do { 
						$ai_v{'temp'}{'randX'} = $x + ((int(rand(3))-1)*(int(rand($config{'avoid_walkDistance'}))+1));
						$ai_v{'temp'}{'randY'} = $y + ((int(rand(3))-1)*(int(rand($config{'avoid_walkDistance'}))+1));
					} while ($field{'field'}[$ai_v{'temp'}{'randY'}*$field{'width'} + $ai_v{'temp'}{'randX'}]
						&& $ai_v{'temp'}{'randX'}==$chars[$config{'char'}]{'pos_to'}{'x'}
						&& $ai_v{'temp'}{'randY'}==$chars[$config{'char'}]{'pos_to'}{'y'}
					);
					ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'}, $field{'name'}, 0, $config{'route_randomWalk_maxRouteTime'}, 2);
					$ai_cmdQue[$ai_cmdQue]{'type'} = "C";
					$ai_cmdQue[$ai_cmdQue]{'ID'} = $sourceID;
					$ai_cmdQue[$ai_cmdQue]{'user'} = $players{$sourceID}{'name'};
					$ai_cmdQue[$ai_cmdQue]{'msg'} = "/warp";
					$ai_cmdQue[$ai_cmdQue]{'time'} = time;
					$ai_cmdQue++;
				}elsif (!$config{'ChatAuto'} || $ppllog{'cmd'}{"$players{$sourceID}{'name'}"}{'resp'}>=$config{'ChatAuto_Max'}){
					if ($ppl_control{$players{$sourceID}{'name'}}{'teleport_auto'}) {
						useTeleport($ppl_control{$players{$sourceID}{'name'}}{'teleport_auto'});
						print addTag($sys{'Vx_interface'},"danger"),"Teleport Away by Method : ($ppl_control{$players{$sourceID}{'name'}}{'teleport_auto'}) ...\n";
						sysLog("D","** Teleport Away by Method : ($ppl_control{$players{$sourceID}{'name'}}{'teleport_auto'}) ...\n");
					}elsif ($config{'avoidGM'}<3 && $config{'avoidGM'}>0){
						useTeleport($config{'avoidGM'});
						print addTag($sys{'Vx_interface'},"danger"),"Teleport Away by Method : ($config{'avoidGM'}) ...\n";
						sysLog("D","** Teleport Away by Method : ($config{'avoidGM'}) ...\n");
					}
					if ($ppl_control{$players{$sourceID}{'name'}}{'disconnect_auto'} || $config{'avoidGM'}==3) {
						print "Avoiding $players{$sourceID}{'name'} ($players{$sourceID}{'nameID'}), Disconnect...\n";
						sysLog("D","**Avoiding $players{$sourceID}{'name'} ($players{$sourceID}{'nameID'}), Disconnect...\n");
						$timeout_ex{'master'}{'time'} = time;
						$timeout_ex{'master'}{'timeout'} = $config{'avoid_reConnect'};
						killConnection(\$remote_socket);
					}
				}
			}elsif ($config{'AntiWarp'} == 2) { useTeleport(2); }
		}elsif ($skillID==12 && $monsters{$ai_seq_args[0]{'ID'}}{'pos_to'}{'x'}==$x && $monsters{$ai_seq_args[0]{'ID'}}{'pos_to'}{'y'}==$y) {
			print addTag($sys{'Vx_interface'},"danger"),"$players{$sourceID}{'name'} Trying to use Safety Wall on Your Attack Monster \n";
			sysLog("D","** $players{$sourceID}{'name'} Trying to use Safety Wall on Your Attack Monster \n");
			updatepplControl("$def_config/ppl_control.txt",$players{$sourceID}{'name'},unpack("L1",$sourceID)) if (!%{$ppl_control{$players{$sourceID}{'name'}}});
			if ($config{'AntiSkillonMonster'}) {
				if (!$ppllog{'cmd'}{"$players{$sourceID}{'name'}"}{'resp'} || $ppllog{'cmd'}{"$players{$sourceID}{'name'}"}{'resp'}<$config{'ChatAuto_Max'}) {
					if ($ai_seq[0] eq "attack") {
						shift @ai_seq;
						shift @ai_seq_args;
						sendAttackStop(\$remote_socket) if ($config{'attackUseWeapon'});
					}
					$ai_cmdQue[$ai_cmdQue]{'type'} = "C";
					$ai_cmdQue[$ai_cmdQue]{'ID'} = $sourceID;
					$ai_cmdQue[$ai_cmdQue]{'user'} = $players{$sourceID}{'name'};
					$ai_cmdQue[$ai_cmdQue]{'msg'} = "/antiskill12";
					$ai_cmdQue[$ai_cmdQue]{'time'} = time;
					$ai_cmdQue++;
					do { 
						$ai_v{'temp'}{'randX'} = $x + ((int(rand(3))-1)*(int(rand($config{'avoid_walkDistance'}))+1));
						$ai_v{'temp'}{'randY'} = $y + ((int(rand(3))-1)*(int(rand($config{'avoid_walkDistance'}))+1));
					} while ($field{'field'}[$ai_v{'temp'}{'randY'}*$field{'width'} + $ai_v{'temp'}{'randX'}]
						&& $ai_v{'temp'}{'randX'}==$chars[$config{'char'}]{'pos_to'}{'x'}
						&& $ai_v{'temp'}{'randY'}==$chars[$config{'char'}]{'pos_to'}{'y'}
					);
				}elsif ($ppllog{'cmd'}{"$players{$sourceID}{'name'}"}{'resp'}>=$config{'ChatAuto_Max'}){
					if ($ppl_control{$players{$sourceID}{'name'}}{'teleport_auto'}) {
						useTeleport($ppl_control{$players{$sourceID}{'name'}}{'teleport_auto'});
						print addTag($sys{'Vx_interface'},"danger"),"Teleport Away by Method : ($ppl_control{$players{$sourceID}{'name'}}{'teleport_auto'}) ...\n";
						sysLog("D","** Teleport Away by Method : ($ppl_control{$players{$sourceID}{'name'}}{'teleport_auto'}) ...\n");
					}elsif ($config{'avoidGM'}<3 && $config{'avoidGM'}>0){
						useTeleport($config{'avoidGM'});
						print addTag($sys{'Vx_interface'},"danger"),"Teleport Away by Method : ($config{'avoidGM'}) ...\n";
						sysLog("D","** Teleport Away by Method : ($config{'avoidGM'}) ...\n");
					}
					if ($ppl_control{$players{$sourceID}{'name'}}{'disconnect_auto'} || $config{'avoidGM'}==3) {
						print "Avoiding $players{$sourceID}{'name'} ($players{$sourceID}{'nameID'}), Disconnect...\n";
						sysLog("D","**Avoiding $players{$sourceID}{'name'} ($players{$sourceID}{'nameID'}), Disconnect...\n");
						$timeout_ex{'master'}{'time'} = time;
						$timeout_ex{'master'}{'timeout'} = $config{'avoid_reConnect'};
						killConnection(\$remote_socket);
					}
				}
			}
		}
		$CONSOLE->Attr($ATTR_NORMAL) if ($config{'colorMode'} && !$sys{'Vx_interface'});

	} elsif ($switch eq "0141") {
		$type = unpack("S1",substr($msg, 2, 2));
		$val = unpack("S1",substr($msg, 6, 2));
		$val2 = unpack("S1",substr($msg, 10, 2));
		if ($type == 13) {
			$chars[$config{'char'}]{'str'} = $val;
			$chars[$config{'char'}]{'str_bonus'} = $val2;
			print "Strength: $val + $val2\n" if $config{'debug'};
		} elsif ($type == 14) {
			$chars[$config{'char'}]{'agi'} = $val;
			$chars[$config{'char'}]{'agi_bonus'} = $val2;
			print "Agility: $val + $val2\n" if $config{'debug'};
		} elsif ($type == 15) {
			$chars[$config{'char'}]{'vit'} = $val;
			$chars[$config{'char'}]{'vit_bonus'} = $val2;
			print "Vitality: $val + $val2\n" if $config{'debug'};
		} elsif ($type == 16) {
			$chars[$config{'char'}]{'int'} = $val;
			$chars[$config{'char'}]{'int_bonus'} = $val2;
			print "Intelligence: $val + $val2\n" if $config{'debug'};
		} elsif ($type == 17) {
			$chars[$config{'char'}]{'dex'} = $val;
			$chars[$config{'char'}]{'dex_bonus'} = $val2;
			print "Dexterity: $val + $val2\n" if $config{'debug'};
		} elsif ($type == 18) {
			$chars[$config{'char'}]{'luk'} = $val;
			$chars[$config{'char'}]{'luk_bonus'} = $val2;
			print "Luck: $val + $val2\n" if $config{'debug'};
		}

	#} elsif ($switch eq "0145") {
	#Kapra cut-In indication

	} elsif ($switch eq "0147") { 
		$skillID = unpack("S*",substr($msg, 2, 2)); 
		$skillLv = unpack("S*",substr($msg, 8, 2));
		print "Now using $skillsID_lut{$skillID}, lv $skillLv\n"; 
		sendSkillUse(\$remote_socket, $skillID, $skillLv, $accountID);

	}elsif ($switch eq "0148"){
		#0148 <ID>.l <type>.w
		my $targetID = substr($msg, 2, 4);
		my $type = unpack("S1",substr($msg, 6, 2));
		if ($type) {
			if ($targetID eq $accountID) {
				print "You have been resurrected\n";
				undef $chars[$config{'char'}]{'dead'};
			}elsif (%{$players{$targetID}}) {
				undef $players{$targetID}{'dead'};
			}
		}

	} elsif ($switch eq "0154") {
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4), $config{'encrypt'});
		$msg = substr($msg, 0, 4).$newmsg;
		my $id;
		for(my $i = 4; $i < $msg_size; $i+=104) {
			my $id = substr($msg, $i+4, 4);
			$chars[$config{'char'}]{'guild'}{'members'}{$id}{'accountID'} = substr($msg, $i, 4);
			$chars[$config{'char'}]{'guild'}{'members'}{$id}{'nameID'} = substr($msg, $i+4, 4);
			$chars[$config{'char'}]{'guild'}{'members'}{$id}{'sex'} = unpack("S1",substr($msg, $i+12, 2));
			$chars[$config{'char'}]{'guild'}{'members'}{$id}{'job'} = unpack("S1",substr($msg, $i+14, 2));
			$chars[$config{'char'}]{'guild'}{'members'}{$id}{'lv'} = unpack("S1",substr($msg, $i+16, 2));
			$chars[$config{'char'}]{'guild'}{'members'}{$id}{'exp'} = unpack("L1",substr($msg, $i+18, 4));
			$chars[$config{'char'}]{'guild'}{'members'}{$id}{'online'} = unpack("L1",substr($msg, $i+22, 4));
			$chars[$config{'char'}]{'guild'}{'members'}{$id}{'position'} = unpack("L1",substr($msg, $i+26, 4));
			($chars[$config{'char'}]{'guild'}{'members'}{$id}{'name'}) = substr($msg, $i+80, 24) =~ /([\s\S]*?)\000/;
		}

	} elsif ($switch eq "0160") {
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4), $config{'encrypt'});
		$msg = substr($msg, 0, 4).$newmsg;
		my ($num,$join,$kick);
		for(my $i = 4; $i < $msg_size; $i+=16) {
			$num = unpack("L*",substr($msg, $i, 4));
			$join = (unpack("C1",substr($msg, $i+4, 1)) & 0x01) ? 1 : '';
			$kick = (unpack("C1",substr($msg, $i+4, 1)) & 0x10) ? 1 : '';
			$chars[$config{'char'}]{'guild'}{'positions'}[$num]{'join'} = $join;
			$chars[$config{'char'}]{'guild'}{'positions'}[$num]{'kick'} = $kick;
			$chars[$config{'char'}]{'guild'}{'positions'}[$num]{'feeEXP'} = unpack("L1",substr($msg, $i+12, 4));
		}

	} elsif ($switch eq "0166") {
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4), $config{'encrypt'});
		$msg = substr($msg, 0, 4).$newmsg;
		my ($num,$name);
		for(my $i = 4; $i < $msg_size; $i+=28) {
			$num = unpack("L1",substr($msg, $i, 4));
			($name) = substr($msg, $i+4, 24) =~ /([\s\S]*?)\000/;
			$chars[$config{'char'}]{'guild'}{'positions'}[$num]{'name'} = $name;
		}

	} elsif ($switch eq "016A") {
		# guild request for you
		$ID = substr($msg, 2, 4);
		($name) = substr($msg, 4, 24) =~ /([\s\S]*?)\000/;
		print "Incoming Request to join Guild '$name'\n";
		$incomingGuild{'ID'} = $ID;
		$incomingGuild{'Type'} = 1;
		$timeout{'ai_guildAutoDeny'}{'time'} = time;
		if ($config{'AntiIncoming'}) {
			$ai_cmdQue[$ai_cmdQue]{'type'} = "C";
			$ai_cmdQue[$ai_cmdQue]{'ID'} = $ID;
			$ai_cmdQue[$ai_cmdQue]{'user'} = $players{$ID}{'name'};
			$ai_cmdQue[$ai_cmdQue]{'msg'} = "/guild";
			$ai_cmdQue[$ai_cmdQue]{'time'} = time;
			$ai_cmdQue++;
		}

	} elsif ($switch eq "016C") {
		($chars[$config{'char'}]{'guild'}{'name'}) = substr($msg, 19, 24) =~ /([\s\S]*?)\000/;

	} elsif ($switch eq "016D") { 
		$ID = substr($msg, 2, 4); 
		$TargetID =  substr($msg, 6, 4); 
		$type = unpack("L1", substr($msg, 10, 4)); 
		if ($type) { 
			$isOnline = "Log In"; 
		} else { 
			$isOnline = "Log Out"; 
		}
		sendNameRequest(\$remote_socket, $TargetID); 

	} elsif ($switch eq "016F") {
		my ($address) = substr($msg, 2, 60) =~ /([\s\S]*?)\000/;
		my ($message) = substr($msg, 62, 120) =~ /([\s\S]*?)\000/;
		if (!$config{'hideMsg_guildBulletin'}) {
			$CONSOLE->Attr($main::FG_YELLOW|$main::BG_BLACK) if ($config{'colorMode'} && !$sys{'Vx_interface'});
			print	"---Guild Notice---\n"
				,"$address\n\n"
				,"$message\n"
				,"------------------\n";
			$CONSOLE->Attr($ATTR_NORMAL) if ($config{'colorMode'} && !$sys{'Vx_interface'});
			sendGuildRequest(\$remote_socket, 0); 
			sendGuildRequest(\$remote_socket, 1);
			sendGuildRequest(\$remote_socket, 2);
		}

	} elsif ($switch eq "0171") {
		$ID = substr($msg, 2, 4);
		($name) = substr($msg, 6, 24) =~ /[\s\S]*?\000/;
		print "Incoming Request to Ally Guild '$name'\n";
		$incomingGuild{'ID'} = $ID;
		$incomingGuild{'Type'} = 2;
		$timeout{'ai_guildAutoDeny'}{'time'} = time;
		if ($config{'AntiIncoming'}) {
			$ai_cmdQue[$ai_cmdQue]{'type'} = "C";
			$ai_cmdQue[$ai_cmdQue]{'ID'} = $ID;
			$ai_cmdQue[$ai_cmdQue]{'user'} = $players{$ID}{'name'};
			$ai_cmdQue[$ai_cmdQue]{'msg'} = "/allyGuild";
			$ai_cmdQue[$ai_cmdQue]{'time'} = time;
			$ai_cmdQue++;
		}
#Mod Stop

	} elsif ($switch eq "0177") {
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4), $config{'encrypt'});
		$msg = substr($msg, 0, 4).$newmsg;
		undef @identifyID;
		undef $invIndex;
		for ($i = 4; $i < $msg_size; $i += 2) {
			$index = unpack("S1", substr($msg, $i, 2));
			$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
			binAdd(\@identifyID, $invIndex);
		}
		print "Recieved Possible Identify List - type 'identify'\n";

	} elsif ($switch eq "0179") {
		$index = unpack("S*",substr($msg, 2, 2));
		undef $invIndex;
		$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
		$chars[$config{'char'}]{'inventory'}[$invIndex]{'identified'} = 1;
		print "Item Identified: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'}\n";
		undef @identifyID;

	} elsif ($switch eq "017F") { 
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4), $config{'encrypt'});
		$msg = substr($msg, 0, 4).$newmsg;
		$ID = substr($msg, 4, 4);
		$chat = substr($msg, 4, $msg_size - 4); 
		$chat =~ s/\000$//g;
		($chatMsgUser, $chatMsg) = $chat =~ /([\s\S]*?) : ([\s\S]*)\000/;
		sysLog("g",$chat."\n");
		$ai_cmdQue[$ai_cmdQue]{'type'} = "g"; 
		$ai_cmdQue[$ai_cmdQue]{'ID'} = $ID; 
		$ai_cmdQue[$ai_cmdQue]{'user'} = $chatMsgUser; 
		$ai_cmdQue[$ai_cmdQue]{'msg'} = $chatMsg; 
		$ai_cmdQue[$ai_cmdQue]{'time'} = time; 
		$ai_cmdQue++;
		$CONSOLE->Attr($main::FG_YELLOW|$main::BG_BLACK) if ($config{'colorMode'} && !$sys{'Vx_interface'});
		print addTag($sys{'Vx_interface'},"guild"),"[Guild] $chat\n";
		$CONSOLE->Attr($ATTR_NORMAL) if ($config{'colorMode'} && !$sys{'Vx_interface'});

	} elsif ($switch eq "0188") {
		$type =  unpack("S1",substr($msg, 2, 2));
		$index = unpack("S1",substr($msg, 4, 2));
		$enchant = unpack("S1",substr($msg, 6, 2));
		$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
		$chars[$config{'char'}]{'inventory'}[$invIndex]{'elements'} = $enchant;
		print "Your Weapon Element changed to : $elements_lut{$enchant}\n";


	} elsif ($switch eq "0194") {
		#Parse Guildman Connect
		my $ID = substr($msg, 2, 4); 
		if ($ID ne $accountID) {
			($name) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/;
			$CONSOLE->Attr($main::FG_YELLOW |$main::BG_BLACK) if ($config{'colorMode'} && !$sys{'Vx_interface'});
			print "Guild Member : $name $isOnline\n";
			$CONSOLE->Attr($ATTR_NORMAL) if ($config{'colorMode'} && !$sys{'Vx_interface'});
		}
		sendGuildInfoRequest(\$remote_socket);
		sendGuildRequest(\$remote_socket, 0);
		sendGuildRequest(\$remote_socket, 1);

	} elsif ($switch eq "0195") {
		#0195 < ID >.l < nick >.24b < party name >.24b < guild name >.24b < class name >.24b 
		#player info
		my $ID = substr($msg, 2, 4);
		if (%{$players{$ID}}) {
			($players{$ID}{'name'}) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/;
			($players{$ID}{'party'}{'name'}) = substr($msg, 30, 24) =~ /([\s\S]*?)\000/;
			($players{$ID}{'guild'}{'name'}) = substr($msg, 54, 24) =~ /([\s\S]*?)\000/;
			($players{$ID}{'guild'}{'men'}{$players{$ID}{'name'}}{'title'}) = substr($msg, 78, 24) =~ /([\s\S]*?)\000/;
			print "Player Info: $players{$ID}{'name'} ($players{$ID}{'binID'})\n" if ($config{'debug'} >= 2);
		}

	} elsif ($switch eq "0196") {
		#0196 < type >.w < ID >.l < switch >.b (after the comodo) 
		# Status Parser Kokal improve
		my $type = unpack("S1",substr($msg, 2, 2));
		my $ID = substr($msg, 4, 4);
		my $flag = unpack("C1",substr($msg, 8, 1));
		if ($ID eq $accountID) {
			my $display = (defined($skillsST_lut{$type})) ? $skillsST_lut{$type} : "Unknown".$type;
			if (binFind(\@skillsST, $display) eq "" && $flag) {
				binAdd(\@skillsST, $display);
				print "[Rep] Attach Status : $display\n" if ($config{'debug_packet'});
			} elsif(binFind(\@skillsST, $display) ne "" && !$flag){
				binRemove(\@skillsST, $display);
				print "[Rep] Detach Status : $display\n"if ($config{'debug_packet'});
			}
		}

	} elsif ($switch eq "0199") {
		#0199 < type >.w
		#game mode change
		my $type = unpack("S1",substr($msg, 2, 2));
		if ($type == 1) {
			print "[Rep]You are in pvp mode\n";
		}elsif ($type ==3) {
			print "[Rep]You are in gvg mode\n";
		}

	} elsif ($switch eq "019B") {
		#019b < ID >.l < type >.l
		# lvup packet
		my $ID = substr($msg, 2, 4);
		my $type = unpack("L1",substr($msg, 6, 4));
		my $name;
		if ($ID eq $accountID) {
			$name = "You"
		}elsif (%{$players{$ID}}) {
			$name = $players{$ID}{'name'};
		} else {
			$name = "Unknown";
		}
		if ($type == 0) {
			print "$name gained a level!\n";
		} elsif ($type == 1) {
			print "$name gained a job level!\n";
		} elsif ($type == 2){
			print "$name refined weapon fail !!\n";
		} elsif ($type == 3){
			print "$name refined weapon Success !!\n";
		}

	} elsif ($switch eq "01A2") {
		#01a2 < pet name >.24b < name flag >.B < lv >.w < hungry >.w < friendly >.w < accessory >.w
		# Pet Info
		($chars[$config{'char'}]{'pet'}{'name'}) = substr($msg, 2, 24) =~ /([\s\S]*?)\000/; 
		$chars[$config{'char'}]{'pet'}{'name_flag'} = unpack("C1",substr($msg, 26, 1)); 
		$chars[$config{'char'}]{'pet'}{'level'} = unpack("S1",substr($msg, 27, 2)); 
		$chars[$config{'char'}]{'pet'}{'hungry'} = unpack("S1",substr($msg, 29, 2)); 
		$chars[$config{'char'}]{'pet'}{'friendly'} = unpack("S1",substr($msg, 31, 2)); 
		$chars[$config{'char'}]{'pet'}{'accessory'} = unpack("S1",substr($msg, 33, 2)); 
		$chars[$config{'char'}]{'pet'}{'action'} = 0;

	} elsif ($switch eq "01A3") {
		#01a3 < fail >.B < itemId >.w 
		#give pet food result
		my $success=unpack("C1",substr($msg, 2, 1)); 
		my $ID=unpack("S1",substr($msg, 3, 2));
		if (!$success) {
			print "You can't give a food($items_lut{$ID}), auto return to egg\n";
			sendPetCommand(\$remote_socket, 3);
			undef %{$chars[$config{'char'}]{'pet'}};
		}

	} elsif ($switch eq "01A4") {
		#01a4 < type >.B < ID >.l < val >.l 
		#pet spawn
		my $type = unpack("C1",substr($msg, 2, 1));
		my $ID = substr($msg, 3, 4);
		my $val = unpack("L",substr($msg, 7, 4)); 
		
		if (($type < 3 || $chars[$config{'char'}]{'pet'}{'ID'} eq $ID) && %{$pets{$ID}}) { 
			binRemove(\@petsID, $ID); 
			undef %{$pets{$ID}}; 
		} 
		
		if ($type == 0) { 
			$chars[$config{'char'}]{'pet'}{'ID'} = $ID; 
		} elsif ($type == 1) { 
			$chars[$config{'char'}]{'pet'}{'friendly'} = $val; 
			print "Pet Friendly : $chars[$config{'char'}]{'pet'}{'friendly'}\n" if ($config{'debug'});
		} elsif ($type == 2) {
			if ($val <= $config{'petAutoFeedRate'}){
				$petfood = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{'petAutoFood'});
				if ($petfood ne "") {
					print "Auto-give pet food : ".$config{'petAutoFood'}."\n";
					sendPetCommand(\$remote_socket, 1);
				} else {
					print "Auto-return to Egg\n";
					sendPetCommand(\$remote_socket, 3);
				}
			}
			$chars[$config{'char'}]{'pet'}{'hungry'} = $val;
			print "Pet Hungry : $chars[$config{'char'}]{'pet'}{'hungry'}\n" if ($config{'debug'});
		} else { 
			if ($chars[$config{'char'}]{'pet'}{'ID'} eq $ID) { 
				if ($type == 3) { 
					$chars[$config{'char'}]{'pet'}{'accessory'} = $val; 
				} elsif ($type == 4) { 
					$chars[$config{'char'}]{'pet'}{'action'} = $val; 
				}
			} else { 
				if (!%{$pets{$ID}}) {
					binAdd(\@petsID, $ID); 
					%{$pets{$ID}} = %{$monsters{$ID}}; 
					$pets{$ID}{'name_given'} = "Unknown"; 
					$pets{$ID}{'binID'} = binFind(\@petsID, $ID); 
				} 
				if ($type == 3) { 
					$pets{$ID}{'accessory'} = $val; 
				} elsif ($type == 4) { 
					$pets{$ID}{'action'} = $val;
				} elsif ($type == 5) {
					print "Pet Spawned: $pets{$ID}{'name'} ($pets{$ID}{'binID'})\n" if ($config{'debug'}); 
				} 
			} 
		} 
		if (%{$monsters{$ID}}) {
			if ($sys{'Vx_interface'}) {
				Vx::removeObj($ID);
			}
			binRemove(\@monstersID, $ID);
			undef %{$monsters{$ID}};
		}
		print "Pet Spawned: $pets{$ID}{'name'} ($pets{$ID}{'binID'})\n" if ($config{'debug'});


	} elsif ($switch eq "01AA") {
		#01aa < ID >.l < emotion >.l
		#pet emotion
		my $ID = substr($msg, 2, 4);
		my $type = unpack("L1", substr($msg, 6, 4));
		if ($type < 34) {
			print "[Pet] $pets{$ID}{'name_given'} : $emotions_lut{$type}\n";
		}

	} elsif ($switch eq "01B0"){
		#01b0 <monster id>.l <?>.b <new monster code>.l
		#monster Type Change
		my $ID = substr($msg,2,4);
		my $type = unpack("L1", substr($msg, 7, 4));
		if (!%{$monsters{$ID}}) {
			$monsters{$ID}{'appear_time'} = time;
			binAdd(\@monstersID, $ID);
			$monsters{$ID}{'nameID'} = $type;
			$monsters{$ID}{'name'} = ($monsters_lut{$type} ne "") ? $monsters_lut{$type} : "Unknown ".$type;
			$monsters{$ID}{'binID'} = binFind(\@monstersID, $ID);
		}else{
			$monsters{$ID}{'nameID'} = $type;
			$monsters{$ID}{'name'} = ($monsters_lut{$type} ne "") ? $monsters_lut{$type} : "Unknown ".$type;
		}

	} elsif ($switch eq "01B3") { 
		#NPC image 
		my $npc_image = substr($msg, 2,64); 
		($npc_image) = $npc_image =~ /(\S+)/; 
		print "NPC image: $npc_image\n" if $config{'debug'}; 

	} elsif ($switch eq "01B5") {
		#Airtime remaining
		my $remain = unpack("L1", substr($msg, 2, 4)); 
		my ($day,$hour,$minute);
		if (!$remain) { 
			$remain = unpack("L1", substr($msg, 6, 4)); 
		}
		$day = int($remain / 1440); 
		$remain = $remain % 1440; 
		$hour = int($remain / 60); 
		$remain = $remain % 60; 
		$minute = $remain; 
		print "You have Airtime : $day days, $hour hours and $minute minutes\n";
		$chars[$config{'char'}]{'Airtime'}{'day'}=$day;
		$chars[$config{'char'}]{'Airtime'}{'hour'}=$hour;
		$chars[$config{'char'}]{'Airtime'}{'minute'}=$minute;
		$chars[$config{'char'}]{'Airtime'}{'loginat'}= getFormattedDate(int(time));

	} elsif ($switch eq "01B6") {
		#01b6 < guildId >.l < guildLv >.l < connum >.l < fixed capacity >.l < Avl.lvl >.l < now_exp >.l < next_exp >.l < payment point >.l < propensity F-V >.l < propensity R-W >.l < members >.l < guild name >.24b < guild master >.24b < agit? >.20B 
		#Guild Info 
		$chars[$config{'char'}]{'guild'}{'ID'} = substr($msg, 2, 4);
		$chars[$config{'char'}]{'guild'}{'lv'} = unpack("L1", substr($msg,  6, 4));
		$chars[$config{'char'}]{'guild'}{'conMember'} = unpack("L1", substr($msg, 10, 4));
		$chars[$config{'char'}]{'guild'}{'maxMember'} = unpack("L1", substr($msg, 14, 4));
		$chars[$config{'char'}]{'guild'}{'average'} = unpack("L1", substr($msg, 18, 4));
		$chars[$config{'char'}]{'guild'}{'exp'} = unpack("L1", substr($msg, 22, 4));
		$chars[$config{'char'}]{'guild'}{'next_exp'} = unpack("L1", substr($msg, 26, 4));
		$chars[$config{'char'}]{'guild'}{'offerPoint'} = unpack("L1", substr($msg, 30, 4));
		$chars[$config{'char'}]{'guild'}{'inclination_FtoV'} = unpack("L1", substr($msg, 34, 4));
		$chars[$config{'char'}]{'guild'}{'inclination_RtoW'} = unpack("L1", substr($msg, 38, 4));
		($chars[$config{'char'}]{'guild'}{'name'}) = substr($msg, 46, 24) =~ /([\s\S]*?)\000/;
		($chars[$config{'char'}]{'guild'}{'master'}) = substr($msg, 70, 24) =~ /([\s\S]*?)\000/;
		($chars[$config{'char'}]{'guild'}{'castle'}) = substr($msg, 94, 20) =~ /([\s\S]*?)\000/;

	} elsif ($switch eq "01B9") {
		#01b9 < ID >.I 
		#The permanent residence discontinuance of ID and the like with suffering uselessly
		my $ID = substr($msg, 2, 4); 
		undef $display; 
		if ($ID eq $accountID) { 
			aiRemove("skill_use"); 
			$display = "You"; 
		} elsif (%{$monsters{$ID}}) { 
			$display = "$monsters{$ID}{'name'} ($monsters{$ID}{'binID'})"; 
		} elsif (%{$players{$ID}}) { 
			$display = "$players{$ID}{'name'} ($players{$ID}{'binID'})"; 
		} else { 
			$display = "Unknown"; 
		} 
		print "$display failed to use skill\n"; 

	} elsif ($switch eq "01C4") {
		#01c4 < index >.w < amount >.l < itemId >.w < item data >.12b 
		#Coupler warehouse item 
		my $index = unpack("S1", substr($msg, 2, 2)); 
		my $amount = unpack("L1", substr($msg, 4, 4)); 
		my $ID = unpack("S1", substr($msg, 8, 2)); 
		my $type = unpack("S1", substr($msg, 10, 1));
		#my $identify = unpack("S1", substr($msg, 11, 1));
		if (%{$storage{'inventory'}[$index]}) { 
			$storage{'inventory'}[$index]{'amount'} += $amount; 
		} else { 
			$storage{'inventory'}[$index]{'nameID'} = $ID; 
			$storage{'inventory'}[$index]{'amount'} = $amount; 
			$display = ($items_lut{$ID} ne "") ? $items_lut{$ID} : "Unknown ".$ID; 
			$storage{'inventory'}[$index]{'name'} = $display;
			if ($type>3 && $type !=6 && $type != 10) {
				$storage{'inventory'}[$index]{'refined'} = unpack("C1", substr($msg, 13, 1)); 
				if(unpack("S1", substr($msg,14, 2)) == 0x00FF){ 
					$storage{'inventory'}[$index]{'elements'} = unpack("C1", substr($msg,16, 1)); 
					$storage{'inventory'}[$index]{'star'} = unpack("C1", substr($msg,17, 1)) / 0x05; 
				}else{
					$storage{'inventory'}[$index]{'card'}[0] = unpack("S1", substr($msg,14, 2));
					$storage{'inventory'}[$index]{'card'}[1] = unpack("S1", substr($msg,16, 2)); 
					$storage{'inventory'}[$index]{'card'}[2] = unpack("S1", substr($msg,18, 2)); 
					$storage{'inventory'}[$index]{'card'}[3] = unpack("S1", substr($msg,20, 2)); 
				}
				modifingName(\%{$storage{'inventory'}[$index]}); 
			}
		}
		print "Storage Item Added: $storage{'inventory'}[$index]{'name'} ($index) x $amount\n"; 

	} elsif ($switch eq "01C8") {
		#01c8 < index >.w < item ID >.w < ID >.l < amount left >.w < type >.B 
		#Item use response. (The higher rank version of 00a8? ) 
		my $index = unpack("S1",substr($msg, 2, 2)); 
		my $ID = unpack("S1", substr($msg, 4, 2)); 
		my $sourceID = substr($msg, 6, 4); 
		my $amountleft = unpack("S1",substr($msg, 10, 2)); 
		my $display = ($items_lut{$ID} ne "") ? $items_lut{$ID} : "Unknown ".$ID; 
		my $invIndex; 
		if ($sourceID eq $accountID) { 
			$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index); 
			$amount = $chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} - $amountleft; 
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} -= $amount; 
			print addTag($sys{'Vx_interface'},"useItem"),"You used Item: $display x $amount\n"; 
			if ($chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} <= 0) { 
				undef %{$chars[$config{'char'}]{'inventory'}[$invIndex]}; 
			} 
		} elsif (%{$players{$sourceID}} && !$config{'hideMsg_otherUseItem'}) { 
			print  "$players{$sourceID}{'name'} ($players{$sourceID}{'binID'}) used $display\n"; 
		} elsif (!$config{'hideMsg_otherUseItem'}){ 
			print  "Unknown used $display\n"; 
		}

	} elsif ($switch eq "01CD") {
		undef @autospellID;
		for (my $i = 2; $i < 30; $i += 4) {
			my $ID = unpack("S1",substr($msg, $i, 2));
			binAdd(\@autospellID, $ID);
		}
		#print "Recieved Possible Auto Casting Spell - type 'spell'\n";

#01cf <crusader id>.l <target id>.l <?>.18b
# Unknow

#monk Spirits
	} elsif ($switch eq "01D0" || $switch eq "01E1"){
		my $sourceID = substr($msg, 2, 4); 
		if ($sourceID eq $accountID) {
			$chars[$config{'char'}]{'spirits'} = unpack("S1",substr($msg, 6, 2)); 
			print "You have $chars[$config{'char'}]{'spirits'} spirit(s) now\n";
		}

#01d1 <monk id>.l <target monster id>.l <bool>.l
#Steal Spirit Ball

	} elsif ($switch eq "01D2") {
		# Triple Attack
		$sourceID = substr($msg, 2, 4);
		$wait = unpack("L1",substr($msg, 6, 4));

# Encrypt Key
	} elsif ($switch eq "01DC") { 
		$secureLoginKey = substr($msg, 4, $msg_size);

#unparsed packet
	} elsif (!defined($rpackets{$switch})) {
		print "Unparsed packet - $switch\n";
	}

	$msg = (length($msg) >= $msg_size) ? substr($msg, $msg_size, length($msg) - $msg_size) : "";
	return $msg;
}


sub sendMessage {
	my $r_socket = shift;
	my $type = shift;
	my $msg = shift;
	my $user = shift;
	my $i, $j;
	my @msg;
	my @msgs;
	my $oldmsg;
	my $amount;
	my $space;
	@msgs = split /\\n/,$msg;
	for ($j = 0; $j < @msgs; $j++) {
		@msg = split / /, $msgs[$j];
		undef $msg;
		for ($i = 0; $i < @msg; $i++) {
			if (!length($msg[$i])) {
				$msg[$i] = " ";
				$space = 1;
			}
			if (length($msg[$i]) > $config{'message_length_max'}) {
				while (length($msg[$i]) >= $config{'message_length_max'}) {
					$oldmsg = $msg;
					if (length($msg)) {
						$amount = $config{'message_length_max'};
						if ($amount - length($msg) > 0) {
							$amount = $config{'message_length_max'} - 1;
							$msg .= " " . substr($msg[$i], 0, $amount - length($msg));
						}
					} else {
						$amount = $config{'message_length_max'};
						$msg .= substr($msg[$i], 0, $amount);
					}
					if ($type eq "c") {
						sendChat($r_socket, $msg);
					} elsif ($type eq "g") { 
						sendGuildChat($r_socket, $msg); 
					} elsif ($type eq "p") {
						sendPartyChat($r_socket, $msg);
					} elsif ($type eq "pm") {
						sendPrivateMsg($r_socket, $user, $msg);
						undef %lastpm;
						$lastpm{'msg'} = $msg;
						$lastpm{'user'} = $user;
						push @lastpm, {%lastpm};
					} elsif ($type eq "k" && $sys{'Xmode'}) {
						injectMessage($msg);
 					}
					$msg[$i] = substr($msg[$i], $amount - length($oldmsg), length($msg[$i]) - $amount - length($oldmsg));
					undef $msg;
				}
			}
			if (length($msg[$i]) && length($msg) + length($msg[$i]) <= $config{'message_length_max'}) {
				if (length($msg)) {
					if (!$space) {
						$msg .= " " . $msg[$i];
					} else {
						$space = 0;
						$msg .= $msg[$i];
					}
				} else {
					$msg .= $msg[$i];
				}
			} else {
				if ($type eq "c") {
					sendChat($r_socket, $msg);
				} elsif ($type eq "g") { 
					sendGuildChat($r_socket, $msg); 
				} elsif ($type eq "p") {
					sendPartyChat($r_socket, $msg);
				} elsif ($type eq "pm") {
					sendPrivateMsg($r_socket, $user, $msg);
					undef %lastpm;
					$lastpm{'msg'} = $msg;
					$lastpm{'user'} = $user;
					push @lastpm, {%lastpm};
				} elsif ($type eq "k" && $sys{'Xmode'}) {
					injectMessage($msg);
				}
				$msg = $msg[$i];
			}
			if (length($msg) && $i == @msg - 1) {
				if ($type eq "c") {
					sendChat($r_socket, $msg);
				} elsif ($type eq "g") { 
					sendGuildChat($r_socket, $msg); 
				} elsif ($type eq "p") {
					sendPartyChat($r_socket, $msg);
				} elsif ($type eq "pm") {
					sendPrivateMsg($r_socket, $user, $msg);
					undef %lastpm;
					$lastpm{'msg'} = $msg;
					$lastpm{'user'} = $user;
					push @lastpm, {%lastpm};
				} elsif ($type eq "k" && $sys{'Xmode'}) {
					injectMessage($msg);
				}
			}
		}
	}
}

#######################################
#######################################
#OUTGOING PACKET FUNCTIONS
#######################################
#######################################

sub injectMessage {
	my $message = shift;
	my $name = "X";
	my $msg .= $name . " : " . $message . chr(0);
	encrypt(\$msg, $msg, $config{'encrypt'},$conState);
	$msg = pack("C*",0x09, 0x01) . pack("S*", length($name) + length($message) + 12) . pack("C*",0,0,0,0) . $msg;
	encrypt(\$msg, $msg, $config{'encrypt'},$conState);
	sendToClientByInject(\$remote_socket, $msg);
}

sub injectAdminMessage {
	my $message = shift;
	$msg = pack("C*",0x9A, 0x00) . pack("S*", length($message)+5) . $message .chr(0);
	encrypt(\$msg, $msg, $config{'encrypt'},$conState);
	sendToClientByInject(\$remote_socket, $msg);
}

sub sendAddSkillPoint {
	my $r_socket = shift;
	my $skillID = shift;
	my $msg = pack("C*", 0x12, 0x01) . pack("S*", $skillID);
	sendMsgToServer($r_socket, $msg);
}

sub sendAddStatusPoint {
	my $r_socket = shift;
	my $statusID = shift;
	my $msg = pack("C*", 0xBB, 0) . pack("S*", $statusID) . pack("C*", 0x01);
	sendMsgToServer($r_socket, $msg);
}

sub sendAlignment {
	my $r_socket = shift;
	my $ID = shift;
	my $alignment = shift;
	my $msg = pack("C*", 0x49, 0x01) . $ID . pack("C*", $alignment);
	sendMsgToServer($r_socket, $msg);
	print "Sent Alignment: ".getHex($ID).", $alignment\n" if ($config{'debug'} >= 2);
}

sub sendAttack {
	my $r_socket = shift;
	my $monID = shift;
	my $flag = shift;
	my $msg = pack("C*", 0x89, 0x00) . $monID . pack("C*", $flag);
	sendMsgToServer($r_socket, $msg);
	print "Sent attack: ".getHex($monID)."\n" if ($config{'debug'} >= 2);
}

sub sendAttackStop {
	my $r_socket = shift;
	my $msg = pack("C*", 0x18, 0x01);
	sendMsgToServer($r_socket, $msg);
	print "Sent stop attack\n" if $config{'debug'};
}

sub sendBuy {
	my $r_socket = shift;
	my $ID = shift;
	my $amount = shift;
	my $msg = pack("C*", 0xC8, 0x00, 0x08, 0x00) . pack("S*", $amount, $ID);
	sendMsgToServer($r_socket, $msg);
	print "Sent buy: ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

sub sendCartAddFromInv {  
	my $r_socket = shift;  
	my $index = shift;  
	my $amount = shift;
	my $msg = pack("C*", 0x26, 0x01) . pack("S*", $index) . pack("L*", $amount); 
	sendMsgToServer($r_socket, $msg);  
	print "Sent Cart Add: $index x $amount\n" if ($config{'debug'} >= 2);
}

sub sendCartGetToInv {  
	my $r_socket = shift;  
	my $index = shift;  
	my $amount = shift;
	my $msg = pack("C*", 0x27, 0x01) . pack("S*", $index) . pack("L*", $amount); 
	sendMsgToServer($r_socket, $msg);  
	print "Sent Cart Get: $index x $amount\n" if ($config{'debug'} >= 2);
}

sub sendCharLogin {
	my $r_socket = shift;
	my $char = shift;
	my $msg = pack("C*", 0x66,0) . pack("C*",$char);
	sendMsgToServer($r_socket, $msg);
}

sub sendChat {
	my $r_socket = shift;
	my $message = shift;
	my $msg = pack("C*",0x8C, 0x00) . pack("S*", length($chars[$config{'char'}]{'name'}) + length($message) + 8) . 
		$chars[$config{'char'}]{'name'} . " : " . $message . chr(0);
	sendMsgToServer($r_socket, $msg);
}

sub sendChatRoomBestow {
	my $r_socket = shift;
	my $name = shift;
	$name = substr($name, 0, 24) if (length($name) > 24);
	$name = $name . chr(0) x (24 - length($name));
	my $msg = pack("C*", 0xE0, 0x00, 0x00, 0x00, 0x00, 0x00).$name;
	sendMsgToServer($r_socket, $msg);
	print "Sent Chat Room Bestow: $name\n" if ($config{'debug'} >= 2);
}

sub sendChatRoomChange {
	my $r_socket = shift;
	my $title = shift;
	my $limit = shift;
	my $public = shift;
	my $password = shift;
	$password = substr($password, 0, 8) if (length($password) > 8);
	$password = $password . chr(0) x (8 - length($password));
	my $msg = pack("C*", 0xDE, 0x00).pack("S*", length($title) + 15, $limit).pack("C*",$public).$password.$title;
	sendMsgToServer($r_socket, $msg);
	print "Sent Change Chat Room: $title, $limit, $public, $password\n" if ($config{'debug'} >= 2);
}

sub sendChatRoomCreate {
	my $r_socket = shift;
	my $title = shift;
	my $limit = shift;
	my $public = shift;
	my $password = shift;
	$password = substr($password, 0, 8) if (length($password) > 8);
	$password = $password . chr(0) x (8 - length($password));
	my $msg = pack("C*", 0xD5, 0x00).pack("S*", length($title) + 15, $limit).pack("C*",$public).$password.$title;
	sendMsgToServer($r_socket, $msg);
	print "Sent Create Chat Room: $title, $limit, $public, $password\n" if ($config{'debug'} >= 2);
}

sub sendChatRoomJoin {
	my $r_socket = shift;
	my $ID = shift;
	my $password = shift;
	$password = substr($password, 0, 8) if (length($password) > 8);
	$password = $password . chr(0) x (8 - length($password));
	my $msg = pack("C*", 0xD9, 0x00).$ID.$password;
	sendMsgToServer($r_socket, $msg);
	print "Sent Join Chat Room: ".getHex($ID)." $password\n" if ($config{'debug'} >= 2);
}

sub sendChatRoomKick {
	my $r_socket = shift;
	my $name = shift;
	$name = substr($name, 0, 24) if (length($name) > 24);
	$name = $name . chr(0) x (24 - length($name));
	my $msg = pack("C*", 0xE2, 0x00).$name;
	sendMsgToServer($r_socket, $msg);
	print "Sent Chat Room Kick: $name\n" if ($config{'debug'} >= 2);
}

sub sendChatRoomLeave {
	my $r_socket = shift;
	my $msg = pack("C*", 0xE3, 0x00);
	sendMsgToServer($r_socket, $msg);
	print "Sent Leave Chat Room\n" if ($config{'debug'} >= 2);
}

sub sendCurrentDealCancel {
	my $r_socket = shift;
	my $msg = pack("C*", 0xED, 0x00);
	sendMsgToServer($r_socket, $msg);
	print "Sent Cancel Current Deal\n" if ($config{'debug'} >= 2);
}

sub sendDeal {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0xE4, 0x00) . $ID;
	sendMsgToServer($r_socket, $msg);
	print "Sent Initiate Deal: ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

sub sendDealAccept {
	my $r_socket = shift;
	my $msg = pack("C*", 0xE6, 0x00, 0x03);
	sendMsgToServer($r_socket, $msg);
	print "Sent Accept Deal\n" if ($config{'debug'} >= 2);
}

sub sendDealAddItem {
	my $r_socket = shift;
	my $index = shift;
	my $amount = shift;
	my $msg = pack("C*", 0xE8, 0x00) . pack("S*", $index) . pack("L*",$amount);	
	sendMsgToServer($r_socket, $msg);
	print "Sent Deal Add Item: $index, $amount\n" if ($config{'debug'} >= 2);
}

sub sendDealCancel {
	my $r_socket = shift;
	my $msg = pack("C*", 0xE6, 0x00, 0x04);
	sendMsgToServer($r_socket, $msg);
	print "Sent Cancel Deal\n" if ($config{'debug'} >= 2);
}

sub sendDealFinalize {
	my $r_socket = shift;
	my $msg = pack("C*", 0xEB, 0x00);
	sendMsgToServer($r_socket, $msg);
	print "Sent Deal OK\n" if ($config{'debug'} >= 2);
}

sub sendDealOK {
	my $r_socket = shift;
	my $msg = pack("C*", 0xEB, 0x00);
	sendMsgToServer($r_socket, $msg);
	print "Sent Deal OK\n" if ($config{'debug'} >= 2);
}

sub sendDealTrade {
	my $r_socket = shift;
	my $msg = pack("C*", 0xEF, 0x00);
	sendMsgToServer($r_socket, $msg);
	print "Sent Deal Trade\n" if ($config{'debug'} >= 2);
}

sub sendDrop {
	my $r_socket = shift;
	my $index = shift;
	my $amount = shift;
	my $msg = pack("C*", 0xA2, 0x00) . pack("S*", $index, $amount);
	sendMsgToServer($r_socket, $msg);
	print "Sent drop: $index x $amount\n" if ($config{'debug'} >= 2);
}

sub sendEmotion {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0xBF, 0x00).pack("C1",$ID);
	sendMsgToServer($r_socket, $msg);
	print "Sent Emotion\n" if ($config{'debug'} >= 2);
}

sub sendEquip{
	my $r_socket = shift;
	my $index = shift;
	my $type = shift;
	my $msg = pack("C*", 0xA9, 0x00) . pack("S*", $index) .  pack("S*", $type);
	sendMsgToServer($r_socket, $msg);
	print "Sent Equip: $index\n" if ($config{'debug'} >= 2);
}

sub sendGameLogin {
	my $r_socket = shift;
	my $accountID = shift;
	my $sessionID = shift;
	my $sessionID2 = shift;
	my $sex = shift;
	my $msg = pack("C*", 0x65,0) . $accountID . $sessionID . $sessionID2 . pack("C*", 0,0,$sex);
	sendMsgToServer($r_socket, $msg);
}

sub sendGetPlayerInfo {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0x94, 0x00) . $ID;
	sendMsgToServer($r_socket, $msg);
	print "Sent get player info: ID - ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

sub sendGetStoreList {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0xC5, 0x00) . $ID . pack("C*",0x00);
	sendMsgToServer($r_socket, $msg);
	print "Sent get store list: ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

sub sendGetSellList {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0xC5, 0x00) . $ID . pack("C*",0x01);
	sendMsgToServer($r_socket, $msg);
	print "Sent sell to NPC: ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

sub sendGuildChat { 
	my $r_socket = shift; 
	my $message = shift; 
	my $msg = pack("C*",0x7E, 0x01) . pack("S*",length($chars[$config{'char'}]{'name'}) + length($message) + 8) . 
	$chars[$config{'char'}]{'name'} . " : " . $message . chr(0); 
	sendMsgToServer($r_socket, $msg);
} 

sub sendIdentify {
	my $r_socket = shift;
	my $index = shift;
	my $msg = pack("C*", 0x78, 0x01) . pack("S*", $index);
	sendMsgToServer($r_socket, $msg);
	print "Sent Identify: $index\n" if ($config{'debug'} >= 2);
}

sub sendIgnore {
	my $r_socket = shift;
	my $name = shift;
	my $flag = shift;
	$name = substr($name, 0, 24) if (length($name) > 24);
	$name = $name . chr(0) x (24 - length($name));
	my $msg = pack("C*", 0xCF, 0x00).$name.pack("C*", $flag);
	sendMsgToServer($r_socket, $msg);
	print "Sent Ignore: $name, $flag\n" if ($config{'debug'} >= 2);
}

sub sendIgnoreAll { 
	my $r_socket = shift; 
	my $flag = shift; 
	my $msg = pack("C*", 0xD0, 0x00).pack("C*", $flag); 
	sendMsgToServer($r_socket, $msg); 
	print "Sent Ignore All: $flag\n" if ($config{'debug'} >= 2); 
}

#sendGetIgnoreList - chobit 20021223 
sub sendIgnoreListGet {  
	my $r_socket = shift;  
	my $flag = shift;  
	my $msg = pack("C*", 0xD3, 0x00);  
	sendMsgToServer($r_socket, $msg); 
	print "Sent get Ignore List: $flag\n" if ($config{'debug'} >= 2);
}

sub sendItemUse {
	my $r_socket = shift;
	my $ID = shift;
	my $targetID = shift;
	my $msg = pack("C*", 0xA7, 0x00).pack("S*",$ID).$targetID;
	sendMsgToServer($r_socket, $msg);
	print "Item Use: $ID\n" if ($config{'debug'} >= 2);
}

sub sendLook {
	my $r_socket = shift;
	my $body = shift;
	my $head = shift;
	my $msg = pack("C*", 0x9B, 0x00, $head, 0x00, $body);
	sendMsgToServer($r_socket, $msg);
	print "Sent look: $body $head\n" if ($config{'debug'} >= 2);
	$chars[$config{'char'}]{'look'}{'head'} = $head;
	$chars[$config{'char'}]{'look'}{'body'} = $body;
}

sub sendMapLoaded {
	my $r_socket = shift;
	my $msg = pack("C*", 0x7D,0x00);
	print "Sending Map Loaded\n" if $config{'debug'};
	sendMsgToServer($r_socket, $msg);
}

sub sendMapLogin {
	my $r_socket = shift;
	my $accountID = shift;
	my $charID = shift;
	my $sessionID = shift;
	my $sex = shift;
	my $msg = pack("C*", 0x72,0) . $accountID . $charID . $sessionID . pack("L1", getTickCount()) . pack("C*",$sex);
	sendMsgToServer($r_socket, $msg);
}

sub sendMasterLogin {
	my $r_socket = shift;
	my $username = shift;
	my $password = shift;
	my $msg = pack("C*", 0x64,0,$config{'version'},0,0,0) . $username . chr(0) x (24 - length($username)) . 
			$password . chr(0) x (24 - length($password)) . pack("C*", $config{"master_version_$config{'master'}"});
	sendMsgToServer($r_socket, $msg);
}

sub sendMemo {
	my $r_socket = shift;
	my $msg = pack("C*", 0x1D, 0x01);
	sendMsgToServer($r_socket, $msg);
	print "Sent Memo\n" if ($config{'debug'} >= 2);
}

sub sendMove {
	my $r_socket = shift;
	my $x = shift;
	my $y = shift;
	my $msg = pack("C*", 0x85, 0x00) . getCoordString($x, $y);
	sendMsgToServer($r_socket, $msg);
	print "Sent move to: $x, $y\n" if ($config{'debug'} >= 2);
}

sub sendPartyChat {
	my $r_socket = shift;
	my $message = shift;
	my $msg = pack("C*",0x08, 0x01) . pack("S*",length($chars[$config{'char'}]{'name'}) + length($message) + 8) . 
		$chars[$config{'char'}]{'name'} . " : " . $message . chr(0);
	sendMsgToServer($r_socket, $msg);
}

sub sendPartyJoin {
	my $r_socket = shift;
	my $ID = shift;
	my $flag = shift;
	my $msg = pack("C*", 0xFF, 0x00).$ID.pack("L", $flag);
	sendMsgToServer($r_socket, $msg);
	print "Sent Join Party: ".getHex($ID).", $flag\n" if ($config{'debug'} >= 2);
}

sub sendPartyJoinRequest {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0xFC, 0x00).$ID;
	sendMsgToServer($r_socket, $msg);
	print "Sent Request Join Party: ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

sub sendPartyKick {
	my $r_socket = shift;
	my $ID = shift;
	my $name = shift;
	$name = substr($name, 0, 24) if (length($name) > 24);
	$name = $name . chr(0) x (24 - length($name));
	my $msg = pack("C*", 0x03, 0x01).$ID.$name;
	sendMsgToServer($r_socket, $msg);
	print "Sent Kick Party: ".getHex($ID).", $name\n" if ($config{'debug'} >= 2);
}

sub sendPartyLeave {
	my $r_socket = shift;
	my $msg = pack("C*", 0x00, 0x01);
	sendMsgToServer($r_socket, $msg);
	print "Sent Leave Party: $name\n" if ($config{'debug'} >= 2);
}

sub sendPartyOrganize {
	my $r_socket = shift;
	my $name = shift;
	$name = substr($name, 0, 24) if (length($name) > 24);
	$name = $name . chr(0) x (24 - length($name));
	my $msg = pack("C*", 0xF9, 0x00).$name;
	sendMsgToServer($r_socket, $msg);
	print "Sent Organize Party: $name\n" if ($config{'debug'} >= 2);
}

sub sendPartyShareEXP {
	my $r_socket = shift;
	my $flag = shift;
	my $msg = pack("C*", 0x02, 0x01).pack("L", $flag);
	sendMsgToServer($r_socket, $msg);
	print "Sent Party Share: $flag\n" if ($config{'debug'} >= 2);
}

sub sendRaw {
	my $r_socket = shift;
	my $raw = shift;
	my @raw;
	my $msg;
	@raw = split / /, $raw;
	foreach (@raw) {
		$msg .= pack("C", hex($_));
	}
	sendMsgToServer($r_socket, $msg);
	print "Sent Raw Packet: @raw\n" if ($config{'debug'} >= 2);
}

sub sendRespawn {
	my $r_socket = shift;
	my $msg = pack("C*", 0xB2, 0x00, 0x00);
	sendMsgToServer($r_socket, $msg);
	print "Sent Respawn\n" if ($config{'debug'} >= 2);
}

sub sendPrivateMsg {
	my $r_socket = shift;
	my $user = shift;
	my $message = shift;
	my $msg = pack("C*",0x96, 0x00) . pack("S*",length($message) + 29) . $user . chr(0) x (24 - length($user)) .
			$message . chr(0);
	sendMsgToServer($r_socket, $msg);
}

sub sendSell {
	my $r_socket = shift;
	my $index = shift;
	my $amount = shift;
	my $msg = pack("C*", 0xC9, 0x00, 0x08, 0x00) . pack("S*", $index, $amount);
	sendMsgToServer($r_socket, $msg);
	print "Sent sell: $index x $amount\n" if ($config{'debug'} >= 2);
	
}

sub sendSit {
	my $r_socket = shift;
	my $msg = pack("C*", 0x89,0x00, 0x00, 0x00, 0x00, 0x00, 0x02);
	sendMsgToServer($r_socket, $msg);
	print "Sitting\n" if ($config{'debug'} >= 2);
}

sub sendSkillUse {
	my $r_socket = shift;
	my $ID = shift;
	my $lv = shift;
	my $targetID = shift;
	my $msg = pack("C*", 0x13, 0x01).pack("S*",$lv,$ID).$targetID;
	sendMsgToServer($r_socket, $msg);
	print "Skill Use: $ID\n" if ($config{'debug'} >= 2);
}

sub sendSkillUseLoc {
	my $r_socket = shift;
	my $ID = shift;
	my $lv = shift;
	my $x = shift;
	my $y = shift;
	my $msg = pack("C*", 0x16, 0x01).pack("S*",$lv,$ID,$x,$y);
	sendMsgToServer($r_socket, $msg);
	print "Skill Use Loc: $ID\n" if ($config{'debug'} >= 2);
}

sub sendStorageAddFromInv {
	my $r_socket = shift;
	my $index = shift;
	my $amount = shift;
	my $msg = pack("C*", 0xF3, 0x00) . pack("S*", $index) . pack("L*", $amount);
	sendMsgToServer($r_socket, $msg);
	print "Sent Storage Add: $index x $amount\n" if ($config{'debug'} >= 2);	
}

sub sendStorageAddFromCart {
	my $r_socket = shift;
	my $index = shift;
	my $amount = shift;
	my $msg = pack("C*", 0x29, 0x01) . pack("S*", $index) . pack("L*", $amount);
	sendMsgToServer($r_socket, $msg);
	print "Sent Storage Add from Cart: $index x $amount\n" if ($config{'debug'} >= 2); 
}

sub sendStorageGetToCart {
	my $r_socket = shift;
	my $index = shift;
	my $amount = shift;
	my $msg = pack("C*", 0x28, 0x01) . pack("S*", $index) . pack("L*", $amount);
	sendMsgToServer($r_socket, $msg);
	print "Sent Storage Get to Cart: $index x $amount\n" if ($config{'debug'} >= 2); 
} 

sub sendStorageGetToInv {
	my $r_socket = shift;
	my $index = shift;
	my $amount = shift;
	my $msg = pack("C*", 0xF5, 0x00) . pack("S*", $index) . pack("L*", $amount);
	sendMsgToServer($r_socket, $msg);
	print "Sent Storage Get: $index x $amount\n" if ($config{'debug'} >= 2);	
}

sub sendStorageClose {
	my $r_socket = shift;
	my $msg = pack("C*", 0xF7, 0x00);
	sendMsgToServer($r_socket, $msg);
	print "Sent Storage Done\n" if ($config{'debug'} >= 2);
}

sub sendStand {
	my $r_socket = shift;
	my $msg = pack("C*", 0x89,0x00, 0x00, 0x00, 0x00, 0x00, 0x03);
	sendMsgToServer($r_socket, $msg);
	print "Standing\n" if ($config{'debug'} >= 2);
}

sub sendSync {
	my $r_socket = shift;
	my $time = shift;
	my $msg = pack("C*", 0x7E, 0x00) . pack("L1", $time);
	sendMsgToServer($r_socket, $msg);
	print "Sent Sync: $time\n" if ($config{'debug'} >= 2);
}

sub sendSyncInject {
	my $r_socket = shift;
	$$r_socket->send("K".pack("S", 0)) if $$r_socket && $$r_socket->connected();
}

sub sendTake {
	my $r_socket = shift;
	my $itemID = shift;
	my $msg = pack("C*", 0x9F, 0x00) . $itemID;
	sendMsgToServer($r_socket, $msg);
	print "Sent take\n" if ($config{'debug'} >= 2);
}

sub sendTalk {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0x90, 0x00) . $ID . pack("C*",0x01);
	sendMsgToServer($r_socket, $msg);
	print "Sent talk: ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

sub sendTalkCancel {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0x46, 0x01) . $ID;
	sendMsgToServer($r_socket, $msg);
	print "Sent talk cancel: ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

sub sendTalkContinue {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0xB9, 0x00) . $ID;
	sendMsgToServer($r_socket, $msg);
	print "Sent talk continue: ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

sub sendTalkResponse {
	my $r_socket = shift;
	my $ID = shift;
	my $response = shift;
	my $msg = pack("C*", 0xB8, 0x00) . $ID. pack("C1",$response);
	sendMsgToServer($r_socket, $msg);
	print "Sent talk respond: ".getHex($ID).", $response\n" if ($config{'debug'} >= 2);
}

sub sendTeleport {
	my $r_socket = shift;
	my $location = shift;
	$location = substr($location, 0, 16) if (length($location) > 16);
	$location .= chr(0) x (16 - length($location));
	my $msg = pack("C*", 0x1B, 0x01, 0x1A, 0x00) . $location;
	sendMsgToServer($r_socket, $msg);
	print "Sent Teleport: $location\n" if ($config{'debug'} >= 2);
}

sub sendToClientByInject {
	my $r_socket = shift;
	my $msg = shift;
	$$r_socket->send("R".pack("S", length($msg)).$msg) if $$r_socket && $$r_socket->connected();
}

sub sendToServerByInject {
	my $r_socket = shift;
	my $msg = shift;
	$$r_socket->send("S".pack("S", length($msg)).$msg) if $$r_socket && $$r_socket->connected();
}

sub sendMsgToServer {
	my $r_socket = shift;
	my $msg = shift;
	return if (!$$r_socket || !$$r_socket->connected());
	encrypt(\$msg, $msg, $config{'encrypt'},$conState);
	if ($sys{'Xmode'}) {
		sendToServerByInject(\$remote_socket, $msg);
	} else {
		$$r_socket->send($msg) if ($$r_socket && $$r_socket->connected());
	}
}

sub sendUnequip{
	my $r_socket = shift;
	my $index = shift;
	my $msg = pack("C*", 0xAB, 0x00) . pack("S*", $index);
	sendMsgToServer($r_socket, $msg);
	print "Sent Unequip: $index\n" if ($config{'debug'} >= 2);
}

sub sendWho {
	my $r_socket = shift;
	my $msg = pack("C*", 0xC1, 0x00);
	sendMsgToServer($r_socket, $msg);
	print "Sent Who\n" if ($config{'debug'} >= 2);
}

# Pet Command
sub sendPetCommand{
	my $r_socket = shift;
	my $flag = shift;
	my $msg = pack("C*", 0xA1, 0x01).pack("C1",$flag);
	sendMsgToServer($r_socket, $msg);
	print "Sent Pet Command : $flag\n" if ($config{'debug'});
}

# Secure Login
sub sendMasterSecureLogin{
	my $r_socket = shift;
	my $username = shift;
	my $password = shift; 
	my $salt = shift;
	my $md5 = Digest::MD5->new;
	my ($msg,$number);
	if ($config{'SecureLogin'} % 2 == 1) {
		$salt = $salt . $password;
	} else {
		$salt = $password . $salt;
	}
	$md5->add($salt);
	if ($config{'SecureLogin'} < 3 ) {
		$msg = pack("C*", 0xDD, 0x01) . pack("L1", $config{'version'}) . $username . chr(0) x (24 - length($username)) .
					 $md5->digest . pack("C*", $config{"master_version_$config{'master'}"});
	}else{
		$number = ($config{'SecureLogin_Account'}>0) ? $config{'SecureLogin_Account'} -1 : 0;
		$msg = pack("C*", 0xFA, 0x01) . pack("L1", $config{'version'}) . $username . chr(0) x (24 - length($username)) .
					 $md5->digest . pack("C*", $config{"master_version_$config{'master'}"}). pack("C1", $number);
	}
	sendMsgToServer($r_socket, $msg);
}

sub sendMasterEncryptKeyRequest{
	my $r_socket = shift;
	my $type = shift;
	my $msg = "";
	if ($type == 1) {
		 $msg = pack("C*", 0x04, 0x02, 0x7B, 0x8A, 0xA8, 0x90, 0x2F, 0xD8, 0xE8, 0x30, 0xF8, 0xA5, 0x25, 0x7A, 0x0D, 0x3B, 0xCE, 0x52);
	} elsif ($type == 2) {
		 $msg = pack("C*", 0x04, 0x02, 0x27, 0x6A, 0x2C, 0xCE, 0xAF, 0x88, 0x01, 0x87, 0xCB, 0xB1, 0xFC, 0xD5, 0x90, 0xC4, 0xED, 0xD2);
	}
	$msg .= pack("C*", 0xDB, 0x01);
	sendMsgToServer($r_socket, $msg);
}

sub sendEnteringVender {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0x30, 0x01) . $ID;
	sendMsgToServer($r_socket, $msg);
	print "Sent Entering Vender: ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

sub sendBuyVender {
	my $r_socket = shift;
	my $ID = shift;
	my $amount = shift;
	my $msg = pack("C*", 0x34, 0x01, 0x0C, 0x00) . $venderID . pack("S*", $amount, $ID);
	sendMsgToServer($r_socket, $msg);
	print "Sent Vender Buy: ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

sub sendGuildInfoRequest {
	my $r_socket = shift;
	my $msg = pack("C*", 0x4d, 0x01);
	sendMsgToServer($r_socket, $msg);
	print "Sent Guild Information Request\n" if ($config{'debug'});
}

sub sendGuildRequest {
	my $r_socket = shift;
	my $page = shift;
	my $msg = pack("C*", 0x4f, 0x01).pack("L1", $page);
	sendMsgToServer($r_socket, $msg);
	print "Sent Guild Request Page : ".$page."\n" if ($config{'debug'});
}

sub sendGuildJoin{
	my $r_socket = shift;
	my $ID = shift;
	my $flag = shift;
	my $msg = pack("C*", 0x6B, 0x01).$ID.pack("L1", $flag);
	sendMsgToServer($r_socket, $msg);
	print "Sent Join Guild : ".getHex($ID).", $flag\n" if ($config{'debug'});
}

sub sendGuildAlly{
	my $r_socket = shift;
	my $ID = shift;
	my $flag = shift;
	my $msg = pack("C*", 0x72, 0x01).$ID.pack("L1", $flag);
	sendMsgToServer($r_socket, $msg);
	print "Sent Ally Guild : ".getHex($ID).", $flag\n" if ($config{'debug'});
}

sub sendcloseShop {
	my $r_socket = shift;
	my $msg = pack("C*", 0x2E, 0x01);
	sendMsgToServer($r_socket, $msg);
	print "Sent Close Shop\n" if ($config{'debug'});
}

sub sendQuit { 
	my $r_socket = shift; 
	my $msg = pack("C*", 0x8A, 0x01, 0x00, 0x00); 
	sendMsgToServer($r_socket, $msg); 
	print "Sent Quit\n" if ($config{'debug'} >= 2); 
}

sub sendUneqCart{
	my $r_socket = shift; 
	my $msg = pack("C*", 0x2a, 0x01); 
	sendMsgToServer($r_socket, $msg); 
	print "Sent Unequip Cart\n" if ($config{'debug'} >= 2); 
}

# Make arrow
sub sendArrowMake {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0xAE, 0x01).pack("S1", $ID);
	sendMsgToServer($r_socket, $msg); 
	print "Sent Arrow Make : $ID\n" if ($config{'debug'} >= 2);
}

# Auto spell
sub sendAutospell {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0xCE, 0x01) . pack("S*", $ID) . chr(0) x 2;
	sendMsgToServer($r_socket, $msg); 
	print "Sent Autospell: $index\n" if ($config{'debug'} >= 2);
}

# Guild Member Name Request
sub sendNameRequest { 
	my $r_socket = shift; 
	my $ID = shift; 
	my $msg = pack("C*", 0x93, 0x01) . $ID; 
	sendMsgToServer($r_socket, $msg);
	print "Sent Name Request : ".getHex($ID)."\n" if ($config{'debug'} >= 2); 
}

1;