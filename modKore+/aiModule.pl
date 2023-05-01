#########################################################################
#  modKore - Hybrid :: Ai module
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
#######################################
#AI
#######################################
#######################################

sub AI {
	
	my $i, $j;
	my %cmd = %{(shift)};

	return if (!$AI);

	Plugins::callHook('AI_pre');

	if (!$accountID) {
		$AI = 0;
		injectAdminMessage("Kore does not have enough account information, so AI has been disabled. Relog to enable AI.") if ($config{'verbose'} && $System::xMode);
		return;
	}

	if (%cmd) {
		$responseVars{'cmd_user'} = $cmd{'user'};
		if ($cmd{'user'} eq $chars[$config{'char'}]{'name'}) {
			return;
		}
 		if ($cmd{'type'} eq "pm" || $cmd{'type'} eq "p" || $cmd{'type'} eq "g") {
			$ai_v{'temp'}{'qm'} = quotemeta $config{'adminPassword'};
			if ($cmd{'msg'} =~ /^$ai_v{'temp'}{'qm'}\b/) {
				if ($overallAuth{$cmd{'user'}} == 1) {
					sendMessage(\$System::remote_socket, "pm", getResponse("authF"), $cmd{'user'});
				} else {
					auth($cmd{'user'}, 1);
					sendMessage(\$System::remote_socket, "pm", getResponse("authS"),$cmd{'user'});
				}
			}
		}
		$ai_v{'temp'}{'qm'} = quotemeta $config{'callSign'};
		if ($overallAuth{$cmd{'user'}} >= 1 
			&& ($cmd{'msg'} =~ /\b$ai_v{'temp'}{'qm'}\b/i || $cmd{'type'} eq "pm")) {
			if ($cmd{'msg'} =~ /\bsit\b/i) {
				$ai_v{'sitAuto_forceStop'} = 0;
				$ai_v{'attackAuto_old'} = $config{'attackAuto'};
				$ai_v{'route_randomWalk_old'} = $config{'route_randomWalk'};
				configModify("attackAuto", 1);
				configModify("route_randomWalk", 0);
				aiRemove("move");
				aiRemove("route");
				aiRemove("route_getRoute");
				aiRemove("route_getMapRoute");
				sit();
				sendMessage(\$System::remote_socket, $cmd{'type'}, getResponse("sitS"), $cmd{'user'}) if $config{'verbose'};
				$timeout{'ai_thanks_set'}{'time'} = time;

			} elsif ($cmd{'msg'} =~ /\bstand\b/i) {
				$ai_v{'sitAuto_forceStop'} = 1;
				if ($ai_v{'attackAuto_old'} ne "") {
					configModify("attackAuto", $ai_v{'attackAuto_old'});
					configModify("route_randomWalk", $ai_v{'route_randomWalk_old'});
				}
				stand();
				sendMessage(\$System::remote_socket, $cmd{'type'}, getResponse("standS"), $cmd{'user'}) if $config{'verbose'};
				$timeout{'ai_thanks_set'}{'time'} = time;

			} elsif ($cmd{'msg'} =~ /\brelog\b/i) {
				relog();
				sendMessage(\$System::remote_socket, $cmd{'type'}, getResponse("relogS"), $cmd{'user'}) if $config{'verbose'};
				$timeout{'ai_thanks_set'}{'time'} = time;

			} elsif ($cmd{'msg'} =~ /\blogout\b/i) {
				quit();
				sendMessage(\$System::remote_socket, $cmd{'type'}, getResponse("quitS"), $cmd{'user'}) if $config{'verbose'};
				$timeout{'ai_thanks_set'}{'time'} = time;

			} elsif ($cmd{'msg'} =~ /\breload\b/i) {
				FileParser::parseReload($');
				sendMessage(\$System::remote_socket, $cmd{'type'}, getResponse("reloadS"), $cmd{'user'}) if $config{'verbose'};
				$timeout{'ai_thanks_set'}{'time'} = time;

			} elsif ($cmd{'msg'} =~ /\bstatus\b/i) {
				$responseVars{'char_sp'} = $chars[$config{'char'}]{'sp'};
				$responseVars{'char_hp'} = $chars[$config{'char'}]{'hp'};
				$responseVars{'char_sp_max'} = $chars[$config{'char'}]{'sp_max'};
				$responseVars{'char_hp_max'} = $chars[$config{'char'}]{'hp_max'};
				$responseVars{'char_lv'} = $chars[$config{'char'}]{'lv'};
				$responseVars{'char_lv_job'} = $chars[$config{'char'}]{'lv_job'};
				$responseVars{'char_exp'} = $chars[$config{'char'}]{'exp'};
				$responseVars{'char_exp_max'} = $chars[$config{'char'}]{'exp_max'};
				$responseVars{'char_exp_job'} = $chars[$config{'char'}]{'exp_job'};
				$responseVars{'char_exp_job_max'} = $chars[$config{'char'}]{'exp_job_max'};
				$responseVars{'char_weight'} = $chars[$config{'char'}]{'weight'};
				$responseVars{'char_weight_max'} = $chars[$config{'char'}]{'weight_max'};
				$responseVars{'zenny'} = $chars[$config{'char'}]{'zenny'};
				sendMessage(\$System::remote_socket, $cmd{'type'}, getResponse("statusS"), $cmd{'user'}) if $config{'verbose'};
				$timeout{'ai_thanks_set'}{'time'} = time;

			} elsif ($cmd{'msg'} =~ /\bconf\b/i) {
				$ai_v{'temp'}{'after'} = $';
				($ai_v{'temp'}{'arg1'}, $ai_v{'temp'}{'arg2'}) = $ai_v{'temp'}{'after'} =~ /(\w+) (\w+)/;
				@{$ai_v{'temp'}{'conf'}} = keys %config;
				if ($ai_v{'temp'}{'arg1'} eq "") {
					sendMessage(\$System::remote_socket, $cmd{'type'}, getResponse("confF1"), $cmd{'user'}) if $config{'verbose'};
				} elsif (binFind(\@{$ai_v{'temp'}{'conf'}}, $ai_v{'temp'}{'arg1'}) eq "") {
					sendMessage(\$System::remote_socket, $cmd{'type'}, getResponse("confF2"), $cmd{'user'}) if $config{'verbose'};
				} elsif ($ai_v{'temp'}{'arg2'} eq "value") {
					if ($ai_v{'temp'}{'arg1'} =~ /username/i || $ai_v{'temp'}{'arg1'} =~ /password/i) {
						sendMessage(\$System::remote_socket, $cmd{'type'}, getResponse("confF3"), $cmd{'user'}) if $config{'verbose'};
					} else {
						$responseVars{'key'} = $ai_v{'temp'}{'arg1'};
						$responseVars{'value'} = $config{$ai_v{'temp'}{'arg1'}};
						sendMessage(\$System::remote_socket, $cmd{'type'}, getResponse("confS1"), $cmd{'user'}) if $config{'verbose'};
						$timeout{'ai_thanks_set'}{'time'} = time;
					}
				} else {
					configModify($ai_v{'temp'}{'arg1'}, $ai_v{'temp'}{'arg2'});
					sendMessage(\$System::remote_socket, $cmd{'type'}, getResponse("confS2"), $cmd{'user'}) if $config{'verbose'};
					$timeout{'ai_thanks_set'}{'time'} = time;
				}

			} elsif ($cmd{'msg'} =~ /\btimeout\b/i) {
				$ai_v{'temp'}{'after'} = $';
				($ai_v{'temp'}{'arg1'}, $ai_v{'temp'}{'arg2'}) = $ai_v{'temp'}{'after'} =~ /([\s\S]+) (\w+)/;
				if ($ai_v{'temp'}{'arg1'} eq "") {
					sendMessage(\$System::remote_socket, $cmd{'type'}, getResponse("timeoutF1"), $cmd{'user'}) if $config{'verbose'};
				} elsif ($timeout{$ai_v{'temp'}{'arg1'}} eq "") {
					sendMessage(\$System::remote_socket, $cmd{'type'}, getResponse("timeoutF2"), $cmd{'user'}) if $config{'verbose'};
				} elsif ($ai_v{'temp'}{'arg2'} eq "") {
					$responseVars{'key'} = $ai_v{'temp'}{'arg1'};
					$responseVars{'value'} = $timeout{$ai_v{'temp'}{'arg1'}};
					sendMessage(\$System::remote_socket, $cmd{'type'}, getResponse("timeoutS1"), $cmd{'user'}) if $config{'verbose'};
					$timeout{'ai_thanks_set'}{'time'} = time;
				} else {
					setTimeout($ai_v{'temp'}{'arg1'}, $ai_v{'temp'}{'arg2'});
					sendMessage(\$System::remote_socket, $cmd{'type'}, getResponse("timeoutS2"), $cmd{'user'}) if $config{'verbose'};
					$timeout{'ai_thanks_set'}{'time'} = time;
				}

			} elsif ($cmd{'msg'} =~ /\bshut[\s\S]*up\b/i) {
				if ($config{'verbose'}) {
					configModify("verbose", 0);
					sendMessage(\$System::remote_socket, $cmd{'type'}, getResponse("verboseOffS"), $cmd{'user'});
					$timeout{'ai_thanks_set'}{'time'} = time;
				} else {
					sendMessage(\$System::remote_socket, $cmd{'type'}, getResponse("verboseOffF"), $cmd{'user'});
				}

			} elsif ($cmd{'msg'} =~ /\bspeak\b/i) {
				if (!$config{'verbose'}) {
					configModify("verbose", 1);
					sendMessage(\$System::remote_socket, $cmd{'type'}, getResponse("verboseOnS"), $cmd{'user'});
					$timeout{'ai_thanks_set'}{'time'} = time;
				} else {
					sendMessage(\$System::remote_socket, $cmd{'type'}, getResponse("verboseOnF"), $cmd{'user'});
				}

			} elsif ($cmd{'msg'} =~ /\bdate\b/i) {
				$responseVars{'date'} = getFormattedDate(int(time));
				sendMessage(\$System::remote_socket, $cmd{'type'}, getResponse("dateS"), $cmd{'user'}) if $config{'verbose'};
				$timeout{'ai_thanks_set'}{'time'} = time;

			} elsif ($cmd{'msg'} =~ /\bmove\b/i && $cmd{'msg'} =~ /\bstop\b/i) {
				aiRemove("move");
				aiRemove("route");
				aiRemove("route_getRoute");
				aiRemove("route_getMapRoute");
				sendMessage(\$System::remote_socket, $cmd{'type'}, getResponse("moveS"), $cmd{'user'}) if $config{'verbose'};
				$timeout{'ai_thanks_set'}{'time'} = time;

			} elsif ($cmd{'msg'} =~ /\bmove\b/i) {
				$ai_v{'temp'}{'after'} = $';
				$ai_v{'temp'}{'after'} =~ s/^\s+//;
				$ai_v{'temp'}{'after'} =~ s/\s+$//;
				($ai_v{'temp'}{'arg1'}, $ai_v{'temp'}{'arg2'}, $ai_v{'temp'}{'arg3'}) = $ai_v{'temp'}{'after'} =~ /(\d+)\D+(\d+)(.*?)$/;
				undef $ai_v{'temp'}{'map'};
				if ($ai_v{'temp'}{'arg1'} eq "") {
					($ai_v{'temp'}{'map'}) = $ai_v{'temp'}{'after'} =~ /(.*?)$/;
				} else {
					$ai_v{'temp'}{'map'} = $ai_v{'temp'}{'arg3'};
				}
				$ai_v{'temp'}{'map'} =~ s/\s//g;
				if (($ai_v{'temp'}{'arg1'} eq "" || $ai_v{'temp'}{'arg2'} eq "") && !$ai_v{'temp'}{'map'}) {
					sendMessage(\$System::remote_socket, $cmd{'type'}, getResponse("moveF"), $cmd{'user'}) if $config{'verbose'};
				} else {
					$ai_v{'temp'}{'map'} = $field{'name'} if ($ai_v{'temp'}{'map'} eq "");
					if ($maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}) {
						if ($ai_v{'temp'}{'arg2'} ne "") {
							System::message "Calculating route to: $maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}($ai_v{'temp'}{'map'}): $ai_v{'temp'}{'arg1'}, $ai_v{'temp'}{'arg2'}\n","route",1;
							injectMessage("Calculating route to: $maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}($ai_v{'temp'}{'map'}): $ai_v{'temp'}{'arg1'}, $ai_v{'temp'}{'arg2'}\n") if ($config{'verbose'} && $System::xMode);
							$ai_v{'temp'}{'x'} = $ai_v{'temp'}{'arg1'};
							$ai_v{'temp'}{'y'} = $ai_v{'temp'}{'arg2'};
						} else {
							System::message "Calculating route to: $maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}($ai_v{'temp'}{'map'})\n","route",1;
							injectMessage("Calculating route to: $maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}($ai_v{'temp'}{'map'})\n") if ($config{'verbose'} && $System::xMode);
							undef $ai_v{'temp'}{'x'};
							undef $ai_v{'temp'}{'y'};
						}
						sendMessage(\$System::remote_socket, $cmd{'type'}, getResponse("moveS"), $cmd{'user'}) if $config{'verbose'};
						ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'x'}, $ai_v{'temp'}{'y'}, $ai_v{'temp'}{'map'}, 0, 0, 1, 0, 0, 1);
						$timeout{'ai_thanks_set'}{'time'} = time;
					} else {
						System::message "Map $ai_v{'temp'}{'map'} does not exist\n";
						injectMessage("Map $ai_v{'temp'}{'map'} does not exist\n") if ($config{'verbose'} && $System::xMode);
						sendMessage(\$System::remote_socket, $cmd{'type'}, getResponse("moveF"), $cmd{'user'}) if $config{'verbose'};
					}
				}

			} elsif ($cmd{'msg'} =~ /\blook\b/i) {
				($ai_v{'temp'}{'body'}) = $cmd{'msg'} =~ /(\d+)/;
				($ai_v{'temp'}{'head'}) = $cmd{'msg'} =~ /\d+ (\d+)/;
				if ($ai_v{'temp'}{'body'} ne "") {
					look($ai_v{'temp'}{'body'}, $ai_v{'temp'}{'head'});
					sendMessage(\$System::remote_socket, $cmd{'type'}, getResponse("lookS"), $cmd{'user'}) if $config{'verbose'};
					$timeout{'ai_thanks_set'}{'time'} = time;
				} else {
					sendMessage(\$System::remote_socket, $cmd{'type'}, getResponse("lookF"), $cmd{'user'}) if $config{'verbose'};
				}	

			} elsif ($cmd{'msg'} =~ /\bfollow/i
				&& $cmd{'msg'} =~ /\bstop\b/i) {
				if ($config{'follow'}) {
					aiRemove("follow");
					configModify("follow", 0);
					sendMessage(\$System::remote_socket, $cmd{'type'}, getResponse("followStopS"), $cmd{'user'}) if $config{'verbose'};
					$timeout{'ai_thanks_set'}{'time'} = time;
				} else {
					sendMessage(\$System::remote_socket, $cmd{'type'}, getResponse("followStopF"), $cmd{'user'}) if $config{'verbose'};
				}

			} elsif ($cmd{'msg'} =~ /\bfollow\b/i) {
				$ai_v{'temp'}{'after'} = $';
				$ai_v{'temp'}{'after'} =~ s/^\s+//;
				$ai_v{'temp'}{'after'} =~ s/\s+$//;
				$ai_v{'temp'}{'targetID'} = ai_getIDFromChat(\%players, $cmd{'user'}, $ai_v{'temp'}{'after'});
				if ($ai_v{'temp'}{'targetID'} ne "") {
					aiRemove("follow");
					ai_follow($players{$ai_v{'temp'}{'targetID'}}{'name'});
					configModify("follow", 1);
					configModify("followTarget", $players{$ai_v{'temp'}{'targetID'}}{'name'});
					sendMessage(\$System::remote_socket, $cmd{'type'}, getResponse("followS"), $cmd{'user'}) if $config{'verbose'};
					$timeout{'ai_thanks_set'}{'time'} = time;
				} else {
					sendMessage(\$System::remote_socket, $cmd{'type'}, getResponse("followF"), $cmd{'user'}) if $config{'verbose'};
				}

			} elsif ($cmd{'msg'} =~ /\bst\b/i) {
				$responseVars{'char_str'} = $chars[$config{'char'}]{'str'};
				$responseVars{'char_agi'} = $chars[$config{'char'}]{'agi'};
				$responseVars{'char_vit'} = $chars[$config{'char'}]{'vit'};
				$responseVars{'char_int'} = $chars[$config{'char'}]{'int'};
				$responseVars{'char_dex'} = $chars[$config{'char'}]{'dex'};
				$responseVars{'char_luk'} = $chars[$config{'char'}]{'luk'};
				$responseVars{'char_point'} = $chars[$config{'char'}]{'points_free'};
				sendMessage(\$System::remote_socket, $cmd{'type'}, getResponse("statS"), $cmd{'user'}) if $config{'verbose'};
				$timeout{'ai_thanks_set'}{'time'} = time;

			} elsif ($cmd{'msg'} =~ /\btank/i
				&& $cmd{'msg'} =~ /\bstop\b/i) {
				if (!$config{'tankMode'}) {
					sendMessage(\$System::remote_socket, $cmd{'type'}, getResponse("tankStopF"), $cmd{'user'}) if $config{'verbose'};
				} elsif ($config{'tankMode'}) {
					sendMessage(\$System::remote_socket, $cmd{'type'}, getResponse("tankStopS"), $cmd{'user'}) if $config{'verbose'};
					configModify("tankMode", 0);
					$timeout{'ai_thanks_set'}{'time'} = time;
				}
			} elsif ($cmd{'msg'} =~ /\btank/i) {
				$ai_v{'temp'}{'after'} = $';
				$ai_v{'temp'}{'after'} =~ s/^\s+//;
				$ai_v{'temp'}{'after'} =~ s/\s+$//;
				$ai_v{'temp'}{'targetID'} = ai_getIDFromChat(\%players, $cmd{'user'}, $ai_v{'temp'}{'after'});
				if ($ai_v{'temp'}{'targetID'} ne "") {
					sendMessage(\$System::remote_socket, $cmd{'type'}, getResponse("tankS"), $cmd{'user'}) if $config{'verbose'};
					configModify("tankMode", 1);
					configModify("tankModeTarget", $players{$ai_v{'temp'}{'targetID'}}{'name'});
					$timeout{'ai_thanks_set'}{'time'} = time;
				} else {
					sendMessage(\$System::remote_socket, $cmd{'type'}, getResponse("tankF"), $cmd{'user'}) if $config{'verbose'};
				}
			} elsif ($cmd{'msg'} =~ /\btown/i) {
				sendMessage(\$System::remote_socket, $cmd{'type'}, getResponse("moveS"), $cmd{'user'}) if $config{'verbose'};
				useTeleport(2);
				$timeout{'ai_thanks_set'}{'time'} = time;

			} elsif ($cmd{'msg'} =~ /\bwhere\b/i) {
				$responseVars{'x'} = $chars[$config{'char'}]{'pos_to'}{'x'};
				$responseVars{'y'} = $chars[$config{'char'}]{'pos_to'}{'y'};
				$responseVars{'map'} = qq~$maps_lut{$field{'name'}.'.rsw'} ($field{'name'})~;
				$timeout{'ai_thanks_set'}{'time'} = time;
				sendMessage(\$System::remote_socket, $cmd{'type'}, getResponse("whereS"), $cmd{'user'}) if $config{'verbose'};

			}
			if ($cmd{'msg'} =~ /\bheal\b/i){
				$ai_v{'temp'}{'after'} = $';
				($ai_v{'temp'}{'amount'}) = $ai_v{'temp'}{'after'} =~ /(\d+)/;
				$ai_v{'temp'}{'after'} =~ s/\d+//;
				$ai_v{'temp'}{'after'} =~ s/^\s+//;
				$ai_v{'temp'}{'after'} =~ s/\s+$//;
				$ai_v{'temp'}{'targetID'} = ai_getIDFromChat(\%players, $cmd{'user'}, $ai_v{'temp'}{'after'});
				if ($ai_v{'temp'}{'targetID'} eq "") {
					sendMessage(\$System::remote_socket, $cmd{'type'}, getResponse("healF1"), $cmd{'user'}) if $config{'verbose'};
				} elsif ($chars[$config{'char'}]{'skills'}{'AL_HEAL'}{'lv'} > 0) {
					undef $ai_v{'temp'}{'amount_healed'};
					undef $ai_v{'temp'}{'sp_needed'};
					undef $ai_v{'temp'}{'sp_used'};
					undef $ai_v{'temp'}{'failed'};
					undef @{$ai_v{'temp'}{'skillCasts'}};
					while ($ai_v{'temp'}{'amount_healed'} < $ai_v{'temp'}{'amount'}) {
						for ($i = 1; $i <= $chars[$config{'char'}]{'skills'}{'AL_HEAL'}{'lv'}; $i++) {
							$ai_v{'temp'}{'sp'} = 10 + ($i * 3);
							$ai_v{'temp'}{'amount_this'} = int(($chars[$config{'char'}]{'lv'} + $chars[$config{'char'}]{'int'}) / 8)
									* (4 + $i * 8);
							last if ($ai_v{'temp'}{'amount_healed'} + $ai_v{'temp'}{'amount_this'} >= $ai_v{'temp'}{'amount'});
						}
						$ai_v{'temp'}{'sp_needed'} += $ai_v{'temp'}{'sp'};
						$ai_v{'temp'}{'amount_healed'} += $ai_v{'temp'}{'amount_this'};
					}
					while ($ai_v{'temp'}{'sp_used'} < $ai_v{'temp'}{'sp_needed'} && !$ai_v{'temp'}{'failed'}) {
						for ($i = 1; $i <= $chars[$config{'char'}]{'skills'}{'AL_HEAL'}{'lv'}; $i++) {
							$ai_v{'temp'}{'lv'} = $i;
							$ai_v{'temp'}{'sp'} = 10 + ($i * 3);
							if ($ai_v{'temp'}{'sp_used'} + $ai_v{'temp'}{'sp'} > $chars[$config{'char'}]{'sp'}) {
								$ai_v{'temp'}{'lv'}--;
								$ai_v{'temp'}{'sp'} = 10 + ($ai_v{'temp'}{'lv'} * 3);
								last;
							}
							last if ($ai_v{'temp'}{'sp_used'} + $ai_v{'temp'}{'sp'} >= $ai_v{'temp'}{'sp_needed'});
						}
						if ($ai_v{'temp'}{'lv'} > 0) {
							$ai_v{'temp'}{'sp_used'} += $ai_v{'temp'}{'sp'};
							$ai_v{'temp'}{'skillCast'}{'skill'} = 28;
							$ai_v{'temp'}{'skillCast'}{'lv'} = $ai_v{'temp'}{'lv'};
							$ai_v{'temp'}{'skillCast'}{'maxCastTime'} = 0;
							$ai_v{'temp'}{'skillCast'}{'minCastTime'} = 0;
							$ai_v{'temp'}{'skillCast'}{'ID'} = $ai_v{'temp'}{'targetID'};
							unshift @{$ai_v{'temp'}{'skillCasts'}}, {%{$ai_v{'temp'}{'skillCast'}}};
						} else {
							$responseVars{'char_sp'} = $chars[$config{'char'}]{'sp'} - $ai_v{'temp'}{'sp_used'};
							sendMessage(\$System::remote_socket, $cmd{'type'}, getResponse("healF2"), $cmd{'user'}) if $config{'verbose'};
							$ai_v{'temp'}{'failed'} = 1;
						}
					}
					if (!$ai_v{'temp'}{'failed'}) {
						sendMessage(\$System::remote_socket, $cmd{'type'}, getResponse("healS"), $cmd{'user'}) if $config{'verbose'};
						$timeout{'ai_thanks_set'}{'time'} = time;
					}
					foreach (@{$ai_v{'temp'}{'skillCasts'}}) {
						ai_skillUse($$_{'skill'}, $$_{'lv'}, $$_{'maxCastTime'}, $$_{'minCastTime'}, $$_{'ID'});
					}
				} else {
					sendMessage(\$System::remote_socket, $cmd{'type'}, getResponse("healF3"), $cmd{'user'}) if $config{'verbose'};
				}
			}
			if ($cmd{'msg'} =~ /\bagi\b/i){
				$ai_v{'temp'}{'after'} = $';
				($ai_v{'temp'}{'amount'}) = $ai_v{'temp'}{'after'} =~ /(\d+)/;
				$ai_v{'temp'}{'after'} =~ s/\d+//;
				$ai_v{'temp'}{'after'} =~ s/^\s+//;
				$ai_v{'temp'}{'after'} =~ s/\s+$//;
				$ai_v{'temp'}{'targetID'} = ai_getIDFromChat(\%players, $cmd{'user'}, $ai_v{'temp'}{'after'});
				if ($ai_v{'temp'}{'targetID'} eq "") {
					sendMessage(\$System::remote_socket, $cmd{'type'}, getResponse("healF1"), $cmd{'user'}) if $config{'verbose'};
				} elsif ($chars[$config{'char'}]{'skills'}{'AL_INCAGI'}{'lv'} > 0) {
					undef $ai_v{'temp'}{'failed'};
					$ai_v{'temp'}{'failed'} = 1;
					for ($i = $chars[$config{'char'}]{'skills'}{'AL_INCAGI'}{'lv'}; $i >=1; $i--) {
						if ($chars[$config{'char'}]{'sp'} >= $skillsSP_lut{$skills_rlut{lc("Increase AGI")}}{$i}) {
							ai_skillUse(29,$i,0,0,$ai_v{'temp'}{'targetID'});
							$ai_v{'temp'}{'failed'} = 0;
							last;
						}
					}
					if (!$ai_v{'temp'}{'failed'}) {
						sendMessage(\$System::remote_socket, $cmd{'type'}, getResponse("healS"), $cmd{'user'}) if $config{'verbose'};
					}else{
						sendMessage(\$System::remote_socket, $cmd{'type'}, getResponse("healF2"), $cmd{'user'}) if $config{'verbose'};
					}
				} else {
					sendMessage(\$System::remote_socket, $cmd{'type'}, getResponse("healF3"), $cmd{'user'}) if $config{'verbose'};
				}
				$timeout{'ai_thanks_set'}{'time'} = time;
			}
			if ($cmd{'msg'} =~ /\bbless\b/i || $cmd{'msg'} =~ /\bblessing\b/i){
				$ai_v{'temp'}{'after'} = $';
				($ai_v{'temp'}{'amount'}) = $ai_v{'temp'}{'after'} =~ /(\d+)/;
				$ai_v{'temp'}{'after'} =~ s/\d+//;
				$ai_v{'temp'}{'after'} =~ s/^\s+//;
				$ai_v{'temp'}{'after'} =~ s/\s+$//;
				$ai_v{'temp'}{'targetID'} = ai_getIDFromChat(\%players, $cmd{'user'}, $ai_v{'temp'}{'after'});
				if ($ai_v{'temp'}{'targetID'} eq "") {
					sendMessage(\$System::remote_socket, $cmd{'type'}, getResponse("healF1"), $cmd{'user'}) if $config{'verbose'};
				} elsif ($chars[$config{'char'}]{'skills'}{'AL_BLESSING'}{'lv'} > 0) {
					undef $ai_v{'temp'}{'failed'};
					$ai_v{'temp'}{'failed'} = 1;
					for ($i = $chars[$config{'char'}]{'skills'}{'AL_BLESSING'}{'lv'}; $i >=1; $i--) {
						if ($chars[$config{'char'}]{'sp'} >= $skillsSP_lut{$skills_rlut{lc("Blessing")}}{$i}) {
							ai_skillUse(34,$i,0,0,$ai_v{'temp'}{'targetID'});
							$ai_v{'temp'}{'failed'} = 0;
							last;
						}
					}
					if (!$ai_v{'temp'}{'failed'}) {
						sendMessage(\$System::remote_socket, $cmd{'type'}, getResponse("healS"), $cmd{'user'}) if $config{'verbose'};
					}else{
						sendMessage(\$System::remote_socket, $cmd{'type'}, getResponse("healF2"), $cmd{'user'}) if $config{'verbose'};
					}
				} else {
					sendMessage(\$System::remote_socket, $cmd{'type'}, getResponse("healF3"), $cmd{'user'}) if $config{'verbose'};
				}
				$timeout{'ai_thanks_set'}{'time'} = time;
			}
			if ($cmd{'msg'} =~ /\bkyrie\b/i){
				$ai_v{'temp'}{'after'} = $';
				($ai_v{'temp'}{'amount'}) = $ai_v{'temp'}{'after'} =~ /(\d+)/;
				$ai_v{'temp'}{'after'} =~ s/\d+//;
				$ai_v{'temp'}{'after'} =~ s/^\s+//;
				$ai_v{'temp'}{'after'} =~ s/\s+$//;
				$ai_v{'temp'}{'targetID'} = ai_getIDFromChat(\%players, $cmd{'user'}, $ai_v{'temp'}{'after'});
				if ($ai_v{'temp'}{'targetID'} eq "") {
					sendMessage(\$System::remote_socket, $cmd{'type'}, getResponse("healF1"), $cmd{'user'}) if $config{'verbose'};
				} elsif ($chars[$config{'char'}]{'skills'}{'PR_KYRIE'}{'lv'} > 0) {
					undef $ai_v{'temp'}{'failed'};
					$ai_v{'temp'}{'failed'} = 1;
					for ($i = $chars[$config{'char'}]{'skills'}{'PR_KYRIE'}{'lv'}; $i >=1; $i--) {
						if ($chars[$config{'char'}]{'sp'} >= $skillsSP_lut{$skills_rlut{lc("Kyrie Eleison")}}{$i}) {
							ai_skillUse(73,$i,0,0,$ai_v{'temp'}{'targetID'});
							$ai_v{'temp'}{'failed'} = 0;
							last;
						}
					}
					if (!$ai_v{'temp'}{'failed'}) {
						sendMessage(\$System::remote_socket, $cmd{'type'}, getResponse("healS"), $cmd{'user'}) if $config{'verbose'};
					}else{
						sendMessage(\$System::remote_socket, $cmd{'type'}, getResponse("healF2"), $cmd{'user'}) if $config{'verbose'};
					}
				} else {
					sendMessage(\$System::remote_socket, $cmd{'type'}, getResponse("healF3"), $cmd{'user'}) if $config{'verbose'};
				}
				$timeout{'ai_thanks_set'}{'time'} = time;
			}

			if ($cmd{'msg'} =~ /\bthank/i || $cmd{'msg'} =~ /\bthn/i) {
				if (!timeOut(\%{$timeout{'ai_thanks_set'}})) {
					$timeout{'ai_thanks_set'}{'time'} -= $timeout{'ai_thanks_set'}{'timeout'};
					sendMessage(\$System::remote_socket, $cmd{'type'}, getResponse("thankS"), $cmd{'user'}) if $config{'verbose'};
				}
			}
		}

#mod Start
# Chatauto part 1
		if ($config{'ChatAuto'} && $ai_seq[0] ne "chatauto"
			&& (!$config{"ChatAuto_inLockOnly"} || ($config{"ChatAuto_inLockOnly"} && $field{'name'} eq $config{"lockMap_$ai_v{'lockMapIndex'}"}))
			&& (!%{$ppllog{'cmd'}{"$cmd{'user'}"}} || $cmd{'msg'} ne $ppllog{'cmd'}{"$cmd{'user'}"}{'last'} && $cmd{'msg'} ne $ppllog{'emotion'}{'last'})
			&& ( ($cmd{'type'} eq "c" && distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$players{$cmd{'ID'}}{'pos_to'}}) <= $config{'ChatAuto_Distance'})
			|| $cmd{'type'} eq "pm" || $cmd{'type'} eq "e" || $cmd{'type'} eq "C")
		){
			my $ans = getResMsg(lc($cmd{'msg'}));
			if ($ans ne "" && (($ppllog{'cmd'}{"$cmd{'user'}"}{'resp'}<=$config{'ChatAuto_Max'}) || $cmd{'user'} eq "")){
				my %args;
				$args{'ans'} = $ans;
				$args{'timeout'} = ($ans =~ /^e \d+/) ? $config{'ChatAuto_Emotime'} : $config{'ChatAuto_Cps'}*length($ans);
				$args{'time'}=time;
				if ($cmd{'user'} ne ""){
					$args{'name'} = $cmd{'user'};
					$ppllog{'cmd'}{"$cmd{'user'}"}{'resp'}++;
				}
				$args{'type'} = $cmd{'type'};
				if ($cmd{'type'} ne "e") {
					$ppllog{'cmd'}{"$cmd{'user'}"}{'last'} = $cmd{'msg'};
					alertsound($config{'alertSound_name'},$config{'alertSound_volume'}) if ($config{'alertSound'} && $type eq "c" && !$ppllog{'cmd'}{"$cmd{'user'}"}{'resp'} && $^O eq 'MSWin32');
				}else{
					$ppllog{'emotion'}{'last'} = $cmd{'msg'};
				}
				unshift @ai_seq, "chatauto";
				unshift @ai_seq_args, {%args};
			}
		}elsif ($ppllog{'cmd'}{"$cmd{'user'}"}{'resp'}>$config{'ChatAuto_Max'} && $config{'ChatAuto_Autoignored'} && $cmd{'type'} eq "pm"){
			sendIgnore(\$System::remote_socket,$cmd{'user'}, 0);
		}
#mod Stop
	}


	##### MISC 2 #####

	if ($ai_seq[0] eq "look" && timeOut(\%{$timeout{'ai_look'}})) {
		$timeout{'ai_look'}{'time'} = time;
		sendLook(\$System::remote_socket, $ai_seq_args[0]{'look_body'}, $ai_seq_args[0]{'look_head'});
		shift @ai_seq;
		shift @ai_seq_args;
	}

	if ($ai_seq[0] ne "deal" && %currentDeal) {
		unshift @ai_seq, "deal";
		unshift @ai_seq_args, "";
	} elsif ($ai_seq[0] eq "deal" && %currentDeal && !$currentDeal{'you_finalize'} && timeOut(\%{$timeout{'ai_dealAuto'}}) && $config{'dealAuto'}==2) {
		sendDealFinalize(\$System::remote_socket);
		$timeout{'ai_dealAuto'}{'time'} = time;
	} elsif ($ai_seq[0] eq "deal" && %currentDeal && $currentDeal{'other_finalize'} && $currentDeal{'you_finalize'} &&timeOut(\%{$timeout{'ai_dealAuto'}}) && $config{'dealAuto'}==2) {
		sendDealTrade(\$System::remote_socket);
		$timeout{'ai_dealAuto'}{'time'} = time;
	} elsif ($ai_seq[0] eq "deal" && !%currentDeal) {
		shift @ai_seq;
		shift @ai_seq_args;
	}

	#dealAuto 1=refuse 2=accept
	if ($config{'dealAuto'} && %incomingDeal && timeOut(\%{$timeout{'ai_dealAuto'}})) {
		if ($config{'dealAuto'}==1) {
			sendDealCancel(\$System::remote_socket);
		}elsif ($config{'dealAuto'}==2) {
			sendDealAccept(\$System::remote_socket);
		}
		$timeout{'ai_dealAuto'}{'time'} = time;
	}

	#partyAuto 1=refuse 2=accept
	if ($config{'partyAuto'} && %incomingParty && timeOut(\%{$timeout{'ai_partyAuto'}})) {
		sendPartyJoin(\$System::remote_socket, $incomingParty{'ID'}, $config{'partyAuto'} - 1);
		$timeout{'ai_partyAuto'}{'time'} = time;
		undef %incomingParty;
	}

	 if ($config{'guildAutoDeny'} && %incomingGuild && timeOut(\%{$timeout{'ai_guildAutoDeny'}})) {
		sendGuildJoin(\$System::remote_socket, $incomingGuild{'ID'}, 0) if ($incomingGuild{'Type'}==1);
		sendGuildAlly(\$System::remote_socket, $incomingGuild{'ID'}, 0) if ($incomingGuild{'Type'}==2);
		$timeout{'ai_guildAutoDeny'}{'time'} = time;
		undef %incomingGuild;
	}

	if ($ai_v{'portalTrace_mapChanged'}) {
		undef $ai_v{'portalTrace_mapChanged'};
		$ai_v{'temp'}{'first'} = 1;
		undef $ai_v{'temp'}{'foundID'};
		undef $ai_v{'temp'}{'smallDist'};
		
		foreach (@portalsID_old) {
			$ai_v{'temp'}{'dist'} = distance(\%{$chars_old[$config{'char'}]{'pos_to'}}, \%{$portals_old{$_}{'pos'}});
			if ($ai_v{'temp'}{'dist'} <= 7 && ($ai_v{'temp'}{'first'} || $ai_v{'temp'}{'dist'} < $ai_v{'temp'}{'smallDist'})) {
				$ai_v{'temp'}{'smallDist'} = $ai_v{'temp'}{'dist'};
				$ai_v{'temp'}{'foundID'} = $_;
				undef $ai_v{'temp'}{'first'};
			}
		}
		if ($ai_v{'temp'}{'foundID'}) {
			$ai_v{'portalTrace'}{'source'}{'map'} = $portals_old{$ai_v{'temp'}{'foundID'}}{'source'}{'map'};
			$ai_v{'portalTrace'}{'source'}{'ID'} = $portals_old{$ai_v{'temp'}{'foundID'}}{'nameID'};
			%{$ai_v{'portalTrace'}{'source'}{'pos'}} = %{$portals_old{$ai_v{'temp'}{'foundID'}}{'pos'}};
		}
	}

	if (%{$ai_v{'portalTrace'}} && portalExists(\%portals_lut , $ai_v{'portalTrace'}{'source'}{'map'}, \%{$ai_v{'portalTrace'}{'source'}{'pos'}}) ne "") {
		undef %{$ai_v{'portalTrace'}};
	} elsif (%{$ai_v{'portalTrace'}} && $field{'name'}) {
		$ai_v{'temp'}{'first'} = 1;
		undef $ai_v{'temp'}{'foundID'};
		undef $ai_v{'temp'}{'smallDist'};
		
		foreach (@portalsID) {
			$ai_v{'temp'}{'dist'} = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$portals{$_}{'pos'}});
			if ($ai_v{'temp'}{'first'} || $ai_v{'temp'}{'dist'} < $ai_v{'temp'}{'smallDist'}) {
				$ai_v{'temp'}{'smallDist'} = $ai_v{'temp'}{'dist'};
				$ai_v{'temp'}{'foundID'} = $_;
				undef $ai_v{'temp'}{'first'};
			}
		}
		
		if (%{$portals{$ai_v{'temp'}{'foundID'}}}) {
			if (portalExists(\%portals_lut, $field{'name'}, \%{$portals{$ai_v{'temp'}{'foundID'}}{'pos'}}) eq ""
				&& $ai_v{'portalTrace'}{'source'}{'map'} && $ai_v{'portalTrace'}{'source'}{'pos'}{'x'} ne "" && $ai_v{'portalTrace'}{'source'}{'pos'}{'y'} ne ""
				&& $field{'name'} && $portals{$ai_v{'temp'}{'foundID'}}{'pos'}{'x'} ne "" && $portals{$ai_v{'temp'}{'foundID'}}{'pos'}{'y'} ne "") {

				
				$portals{$ai_v{'temp'}{'foundID'}}{'name'} = "$field{'name'} -> $ai_v{'portalTrace'}{'source'}{'map'}";
				$portals{pack("L",$ai_v{'portalTrace'}{'source'}{'ID'})}{'name'} = "$ai_v{'portalTrace'}{'source'}{'map'} -> $field{'name'}";

				$ai_v{'temp'}{'ID'} = "$ai_v{'portalTrace'}{'source'}{'map'} $ai_v{'portalTrace'}{'source'}{'pos'}{'x'} $ai_v{'portalTrace'}{'source'}{'pos'}{'y'}";
				$portals_lut{$ai_v{'temp'}{'ID'}}{'source'}{'map'} = $ai_v{'portalTrace'}{'source'}{'map'};
				%{$portals_lut{$ai_v{'temp'}{'ID'}}{'source'}{'pos'}} = %{$ai_v{'portalTrace'}{'source'}{'pos'}};
				$portals_lut{$ai_v{'temp'}{'ID'}}{'dest'}{'map'} = $field{'name'};
				%{$portals_lut{$ai_v{'temp'}{'ID'}}{'dest'}{'pos'}} = %{$portals{$ai_v{'temp'}{'foundID'}}{'pos'}};

				FileParser::updatePortalLUT("$System::def_table/portals.txt",
					$ai_v{'portalTrace'}{'source'}{'map'}, $ai_v{'portalTrace'}{'source'}{'pos'}{'x'}, $ai_v{'portalTrace'}{'source'}{'pos'}{'y'},
					$field{'name'}, $portals{$ai_v{'temp'}{'foundID'}}{'pos'}{'x'}, $portals{$ai_v{'temp'}{'foundID'}}{'pos'}{'y'});

				$ai_v{'temp'}{'ID2'} = "$field{'name'} $portals{$ai_v{'temp'}{'foundID'}}{'pos'}{'x'} $portals{$ai_v{'temp'}{'foundID'}}{'pos'}{'y'}";
				$portals_lut{$ai_v{'temp'}{'ID2'}}{'source'}{'map'} = $field{'name'};
				%{$portals_lut{$ai_v{'temp'}{'ID2'}}{'source'}{'pos'}} = %{$portals{$ai_v{'temp'}{'foundID'}}{'pos'}};
				$portals_lut{$ai_v{'temp'}{'ID2'}}{'dest'}{'map'} = $ai_v{'portalTrace'}{'source'}{'map'};
				%{$portals_lut{$ai_v{'temp'}{'ID2'}}{'dest'}{'pos'}} = %{$ai_v{'portalTrace'}{'source'}{'pos'}};

				FileParser::updatePortalLUT("$System::def_table/portals.txt",
					$field{'name'}, $portals{$ai_v{'temp'}{'foundID'}}{'pos'}{'x'}, $portals{$ai_v{'temp'}{'foundID'}}{'pos'}{'y'},
					$ai_v{'portalTrace'}{'source'}{'map'}, $ai_v{'portalTrace'}{'source'}{'pos'}{'x'}, $ai_v{'portalTrace'}{'source'}{'pos'}{'y'});
			}
			undef %{$ai_v{'portalTrace'}};
		}
	}


	if ($System::xMode && !$sentWelcomeMessage && timeOut(\%{$timeout{'welcomeText'}})) {
		injectAdminMessage($welcomeText) if ($config{'verbose'} && $System::xMode);
		$sentWelcomeMessage = 1;
	}


	##### CLIENT SUSPEND #####

	if ($ai_seq[0] eq "clientSuspend" && timeOut(\%{$ai_seq_args[0]})) {
		shift @ai_seq;
		shift @ai_seq_args;
	} elsif ($ai_seq[0] eq "clientSuspend" && $System::xMode) {
		if ($ai_seq_args[0]{'type'} eq "0089") {
			if ($ai_seq_args[0]{'args'}[0] == 2) {
				if ($chars[$config{'char'}]{'sitting'}) {
					$ai_seq_args[0]{'time'} = time;
				}
			} elsif ($ai_seq_args[0]{'args'}[0] == 3) {
				$ai_seq_args[0]{'timeout'} = 6;
			} else {
				if (!$ai_seq_args[0]{'forceGiveup'}{'timeout'}) {
					$ai_seq_args[0]{'forceGiveup'}{'timeout'} = 6;
					$ai_seq_args[0]{'forceGiveup'}{'time'} = time;
				}
				if ($ai_seq_args[0]{'dmgFromYou_last'} != $monsters{$ai_seq_args[0]{'args'}[1]}{'dmgFromYou'}) {
					$ai_seq_args[0]{'forceGiveup'}{'time'} = time;
				}
				$ai_seq_args[0]{'dmgFromYou_last'} = $monsters{$ai_seq_args[0]{'args'}[1]}{'dmgFromYou'};
				$ai_seq_args[0]{'missedFromYou_last'} = $monsters{$ai_seq_args[0]{'args'}[1]}{'missedFromYou'};
				if (%{$monsters{$ai_seq_args[0]{'args'}[1]}}) {
					$ai_seq_args[0]{'time'} = time;
				} else {
					$ai_seq_args[0]{'time'} -= $ai_seq_args[0]{'timeout'};
				}
				if (timeOut(\%{$ai_seq_args[0]{'forceGiveup'}})) {
					$ai_seq_args[0]{'time'} -= $ai_seq_args[0]{'timeout'};
				}
			}
		} elsif ($switch eq "009F") {
			if (!$ai_seq_args[0]{'forceGiveup'}{'timeout'}) {
				$ai_seq_args[0]{'forceGiveup'}{'timeout'} = 4;
				$ai_seq_args[0]{'forceGiveup'}{'time'} = time;
			}
			if (%{$items{$ai_seq_args[0]{'args'}[0]}}) {
				$ai_seq_args[0]{'time'} = time;
			} else {
				$ai_seq_args[0]{'time'} -= $ai_seq_args[0]{'timeout'};
			}
			if (timeOut(\%{$ai_seq_args[0]{'forceGiveup'}})) {
				$ai_seq_args[0]{'time'} -= $ai_seq_args[0]{'timeout'};
			}
		}
	}

	#storageAuto - chobit aska 20030128
	#####AUTO STORAGE ( GET & KEEP )#####

	AUTOSTORAGE: {

	if (($ai_seq[0] eq "" || $ai_seq[0] eq "route") && $config{'storageAuto'} && $config{'storageAuto_npc'} ne "" && $chars[$config{'char'}]{'percent_weight'} >= $config{'itemsMaxWeight'}) {
		$ai_v{'temp'}{'ai_route_index'} = binFind(\@ai_seq, "route");
		if ($ai_v{'temp'}{'ai_route_index'} ne "") {
			$ai_v{'temp'}{'ai_route_attackOnRoute'} = $ai_seq_args[$ai_v{'temp'}{'ai_route_index'}]{'attackOnRoute'};
		}
		if (!($ai_v{'temp'}{'ai_route_index'} ne "" && $ai_v{'temp'}{'ai_route_attackOnRoute'} <= 1) && ai_storageAutoCheck()) {
			unshift @ai_seq, "storageAuto";
			unshift @ai_seq_args, {};
		}
# getAuto Part I
	}elsif (($ai_seq[0] eq "" || $ai_seq[0] eq "route" || $ai_seq[0] eq "attack") && $config{'storageAuto'} && $config{'storageAuto_npc'} ne "" && timeOut(\%{$timeout{'ai_storagegetAuto'}})) {
		undef $ai_v{'temp'}{'found'};
		my $i = 0; 
		while (defined($config{"getAuto_$i"})) {
			$ai_v{'temp'}{'invIndex'} = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{"getAuto_$i"}); 
			if ($config{"getAuto_$i"."_minAmount"} ne "" && $config{"getAuto_$i"."_maxAmount"} ne "" && !$stockVoid[$i] 
				&& !$config{"getAuto_$i"."_passive"} && ($ai_v{'temp'}{'invIndex'} eq "" 
				|| ($chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'amount'} <= $config{"getAuto_$i"."_minAmount"}
				&& $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'amount'} < $config{"getAuto_$i"."_maxAmount"}))) { 
				$ai_v{'temp'}{'found'} = 1;
			}
			$i++;
		}
		$ai_v{'temp'}{'ai_route_index'} = binFind(\@ai_seq, "route");
		if ($ai_v{'temp'}{'ai_route_index'} ne "") {
			$ai_v{'temp'}{'ai_route_attackOnRoute'} = $ai_seq_args[$ai_v{'temp'}{'ai_route_index'}]{'attackOnRoute'};
		}
		if (!($ai_v{'temp'}{'ai_route_index'} ne "" && $ai_v{'temp'}{'ai_route_attackOnRoute'} <= 1) && $ai_v{'temp'}{'found'}) {
			unshift @ai_seq, "storageAuto";
			unshift @ai_seq_args, {};
		}
		$timeout{'ai_storagegetAuto'}{'time'} = time;
	}

	if ($ai_seq[0] eq "storageAuto" && $ai_seq_args[0]{'done'}) {
		#equip arrow when auto-storage done
		if ($ai_v{'temp'}{'arrow'}){
			sendEquip(\$System::remote_socket, $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'arrow'}]{'index'},0); 
			undef $ai_v{'temp'}{'arrow'};
		}
		undef %{$ai_v{'temp'}{'ai'}};
		%{$ai_v{'temp'}{'ai'}{'completedAI'}} = %{$ai_seq_args[0]{'completedAI'}};
		shift @ai_seq;
		shift @ai_seq_args;
		if (!$ai_v{'temp'}{'ai'}{'completedAI'}{'sellAuto'}) {
			$ai_v{'temp'}{'ai'}{'completedAI'}{'storageAuto'} = 1;
			unshift @ai_seq, "sellAuto";
			unshift @ai_seq_args, {%{$ai_v{'temp'}{'ai'}}};
		}
	} elsif ($ai_seq[0] eq "storageAuto" && timeOut(\%{$timeout{'ai_storageAuto'}})) {
#		if (!$config{'storageAuto'} || !%{$npcs_lut{$config{'storageAuto_npc'}}}) {
#			print "[Warn] autoStorage aborted: no information known about NPC $config{'storageAuto_npc'}\n";
#			print "[Hint] Checking your npcs.txt first\n";
#			configModify("storageAuto",0);
#			$ai_seq_args[0]{'done'} = 1;
#			last AUTOSTORAGE;
#		}elsif ($config{'storageAuto'} && $storage{'items'} == $storage{'items_max'} && $storage{'items_max'} > 0) {
#			print "[Warn] Storage is maximum size\n";
#			sysLog("warn","Storage is maximum size turn off autostorage\n");
#			configModify("storageAuto",0);
#			$ai_seq_args[0]{'done'} = 1;
#			last AUTOSTORAGE;
#		}

		undef $ai_v{'temp'}{'do_route'};
		if ($field{'name'} ne $npcs_lut{$config{'storageAuto_npc'}}{'map'}) {
			$ai_v{'temp'}{'do_route'} = 1;
		} else {
			$ai_v{'temp'}{'distance'} = distance(\%{$npcs_lut{$config{'storageAuto_npc'}}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
			#Hayashi Fixed
			if ($ai_v{'temp'}{'distance'} > $config{'storageAuto_distance'}) {
				$ai_v{'temp'}{'do_route'} = 1;
			}
		}
		if ($ai_v{'temp'}{'do_route'}) {
			if ($ai_seq_args[0]{'warpedToSave'} && !$ai_seq_args[0]{'mapChanged'}) {
				undef $ai_seq_args[0]{'warpedToSave'};
			}
			if ($config{'saveMap'} ne "" && $field{'name'} ne $config{'saveMap'} && $config{'saveMap_warpToBuyOrSell'} && !$ai_seq_args[0]{'warpedToSave'} && !$cities_lut{$field{'name'}.'.rsw'}) {
				$ai_seq_args[0]{'warpedToSave'} = 1;
				useTeleport(2);
				$timeout{'ai_storageAuto'}{'time'} = time;
			} else {
				System::message "Calculating auto-storage route to: $maps_lut{$npcs_lut{$config{'storageAuto_npc'}}{'map'}.'.rsw'}($npcs_lut{$config{'storageAuto_npc'}}{'map'}): $npcs_lut{$config{'storageAuto_npc'}}{'pos'}{'x'}, $npcs_lut{$config{'storageAuto_npc'}}{'pos'}{'y'}\n";
				injectMessage("Calculating auto-storage route to: $maps_lut{$npcs_lut{$config{'storageAuto_npc'}}{'map'}.'.rsw'}($npcs_lut{$config{'storageAuto_npc'}}{'map'}): $npcs_lut{$config{'storageAuto_npc'}}{'pos'}{'x'}, $npcs_lut{$config{'storageAuto_npc'}}{'pos'}{'y'}\n") if ($config{'verbose'} && $System::xMode);
				ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $npcs_lut{$config{'storageAuto_npc'}}{'pos'}{'x'}, $npcs_lut{$config{'storageAuto_npc'}}{'pos'}{'y'}, $npcs_lut{$config{'storageAuto_npc'}}{'map'}, 0, 0, 1, 0,$config{'storageAuto_distance'},1);
			}
		} else {
#mod Start
#npc Step
			if (!$ai_seq_args[0]{'sentTalk'}) {
				#unequip current arrow when got storage
				$ai_v{'temp'}{'arrow'} = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "equipped",32768);
				if ($ai_v{'temp'}{'arrow'} ne "") {
					sendUnequip(\$System::remote_socket,$chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'arrow'}]{'index'});
				}
				#checking npc id by position
				checkNPC("storageAuto_npc") if ($config{'autoUpdateNPC'});
				sendTalk(\$System::remote_socket, pack("L1",$config{'storageAuto_npc'}));
				@{$ai_seq_args[0]{'steps'}} = split(/ /, $config{'storageAuto_npc_steps'});
				$ai_seq_args[0]{'sentTalk'} = 1;
				$timeout{'ai_storageAuto'}{'time'} = time; 
				last AUTOSTORAGE;
			} elsif (@{$ai_seq_args[0]{'steps'}}) {
				if ($ai_seq_args[0]{'steps'}[0] =~ /c/i) {
					sendTalkContinue(\$System::remote_socket, pack("L1",$config{'storageAuto_npc'})); 
				} elsif ($ai_seq_args[0]{'steps'}[0] =~ /n/i) {
					sendTalkCancel(\$System::remote_socket, pack("L1",$config{'storageAuto_npc'}));
				} elsif (($ai_v{'temp'}{'arg'}) = $ai_seq_args[0]{'steps'}[$ai_seq_args[0]{'step'}] =~ /r(\d+)/i){
					$ai_v{'temp'}{'arg'}++;
					sendTalkResponse(\$System::remote_socket, pack("L1",$config{'storageAuto_npc'}), $ai_v{'temp'}{'arg'});
				}
				shift @{$ai_seq_args[0]{'steps'}};
				$timeout{'ai_storageAuto'}{'time'} = time;
				last AUTOSTORAGE; 
			}
			$ai_seq_args[0]{'done'} = 1;

#getAuto Part II
			if (!$ai_seq_args[0]{'getStart'}) {
				for (my $i = 0; $i < @{$chars[$config{'char'}]{'inventory'}};$i++) {
					next if (!%{$chars[$config{'char'}]{'inventory'}[$i]} || $chars[$config{'char'}]{'inventory'}[$i]{'equipped'});
					if (($items_control{'all'}{'storage'} && $chars[$config{'char'}]{'inventory'}[$i]{'amount'} > $items_control{'all'}{'keep'} && !%{$items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}})
						|| ($items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'storage'} && $chars[$config{'char'}]{'inventory'}[$i]{'amount'} > $items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'keep'})
						) {
						if ($ai_seq_args[0]{'lastIndex'} ne "" && $ai_seq_args[0]{'lastIndex'} == $chars[$config{'char'}]{'inventory'}[$i]{'index'}
							&& timeOut(\%{$timeout{'ai_storageAuto_giveup'}})) {
							last AUTOSTORAGE;
						} elsif ($ai_seq_args[0]{'lastIndex'} eq "" || $ai_seq_args[0]{'lastIndex'} != $chars[$config{'char'}]{'inventory'}[$i]{'index'}) {
							$timeout{'ai_storageAuto_giveup'}{'time'} = time;
						}
						undef $ai_seq_args[0]{'done'};
						$ai_seq_args[0]{'lastIndex'} = $chars[$config{'char'}]{'inventory'}[$i]{'index'};
						sendStorageAddFromInv(\$System::remote_socket, $chars[$config{'char'}]{'inventory'}[$i]{'index'}, $chars[$config{'char'}]{'inventory'}[$i]{'amount'} - $items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'keep'});
						$timeout{'ai_storageAuto'}{'time'} = time;
						last AUTOSTORAGE;
					}
				}
			}
			
			if (!$ai_seq_args[0]{'getStart'} && $ai_seq_args[0]{'done'} == 1) {
				$ai_seq_args[0]{'getStart'} = 1;
				undef $ai_seq_args[0]{'done'};
				last AUTOSTORAGE; 
			}
			$i = 0;
			undef $ai_seq_args[0]{'index'};
			while (defined($config{"getAuto_$i"})) {
				#last if (!$config{"getAuto_$i"});
				$ai_seq_args[0]{'invIndex'} = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{"getAuto_$i"});
				if (!$ai_seq_args[0]{'index_failed'}{$i} && $config{"getAuto_$i"."_maxAmount"} ne "" && !$stockVoid[$i] && ($ai_seq_args[0]{'invIndex'} eq ""
				|| $chars[$config{'char'}]{'inventory'}[$ai_seq_args[0]{'invIndex'}]{'amount'} < $config{"getAuto_$i"."_maxAmount"})) {
					$ai_seq_args[0]{'index'} = $i;
					last;
				}
				$i++;
			}
			if ($ai_seq_args[0]{'index'} eq ""
				|| ($ai_seq_args[0]{'lastIndex'} ne "" && $ai_seq_args[0]{'lastIndex'} == $ai_seq_args[0]{'index'}
				&& timeOut(\%{$timeout{'ai_storageAuto_giveup'}}))) {
					$ai_seq_args[0]{'done'} = 1;
					sendStorageClose(\$System::remote_socket);
					last AUTOSTORAGE;
			} elsif ($ai_seq_args[0]{'lastIndex'} eq "" || $ai_seq_args[0]{'lastIndex'} != $ai_seq_args[0]{'index'}) {
				$timeout{'ai_storageAuto_giveup'}{'time'} = time;
			}
			undef $ai_seq_args[0]{'done'};
			undef $ai_seq_args[0]{'storageInvID'};
			$ai_seq_args[0]{'lastIndex'} = $ai_seq_args[0]{'index'}; 
			$ai_seq_args[0]{'storageInvIndex'} = findIndexString_lc(\@{$storage{'inventory'}}, "name", $config{"getAuto_$ai_seq_args[0]{'index'}"}); 
			if ($ai_seq_args[0]{'storageInvIndex'} eq "") { 
				$stockVoid[$ai_seq_args[0]{'index'}] = 1; 
				last AUTOSTORAGE; 
			} elsif ($ai_seq_args[0]{'invIndex'} ne "") { 
				if ($config{"getAuto_$ai_seq_args[0]{'index'}"."_maxAmount"} - $chars[$config{'char'}]{'inventory'}[$ai_seq_args[0]{'invIndex'}]{'amount'} > $storage{'inventory'}[$ai_seq_args[0]{'storageInvIndex'}]{'amount'}) { 
					$getAmount = $storage{'inventory'}[$ai_seq_args[0]{'storageInvIndex'}]{'amount'}; 
					$stockVoid[$ai_seq_args[0]{'index'}] = 1; 
				} else {
					$getAmount = $config{"getAuto_$ai_seq_args[0]{'index'}"."_maxAmount"} - $chars[$config{'char'}]{'inventory'}[$ai_seq_args[0]{'invIndex'}]{'amount'}; 
				}
			} else { 
				if ($config{"getAuto_$ai_seq_args[0]{'index'}"."_maxAmount"} > $storage{'inventory'}[$ai_seq_args[0]{'storageInvIndex'}]{'amount'}) { 
					$getAmount = $storage{'inventory'}[$ai_seq_args[0]{'storageInvIndex'}]{'amount'}; 
					$stockVoid[$ai_seq_args[0]{'index'}] = 1; 
				} else { 
					$getAmount = $config{"getAuto_$ai_seq_args[0]{'index'}"."_maxAmount"}; 
				}
			} 
			sendStorageGetToInv(\$System::remote_socket, $ai_seq_args[0]{'storageInvIndex'}, $getAmount); 
			$timeout{'ai_storageAuto'}{'time'} = time;
#mod Stop
		}
	}

	} #END OF BLOCK AUTOSTORAGE


	#####AUTO SELL#####

	AUTOSELL: {

	if (($ai_seq[0] eq "" || $ai_seq[0] eq "route") && $config{'sellAuto'} && $config{'sellAuto_npc'} ne "" && $chars[$config{'char'}]{'percent_weight'} >= $config{'itemsMaxWeight'}) {
		$ai_v{'temp'}{'ai_route_index'} = binFind(\@ai_seq, "route");
		if ($ai_v{'temp'}{'ai_route_index'} ne "") {
			$ai_v{'temp'}{'ai_route_attackOnRoute'} = $ai_seq_args[$ai_v{'temp'}{'ai_route_index'}]{'attackOnRoute'};
		}
		if (!($ai_v{'temp'}{'ai_route_index'} ne "" && $ai_v{'temp'}{'ai_route_attackOnRoute'} <= 1) && ai_sellAutoCheck()) {
			unshift @ai_seq, "sellAuto";
			unshift @ai_seq_args, {};
		}
	}

	if ($ai_seq[0] eq "sellAuto" && $ai_seq_args[0]{'done'}) {
		undef %{$ai_v{'temp'}{'ai'}};
		%{$ai_v{'temp'}{'ai'}{'completedAI'}} = %{$ai_seq_args[0]{'completedAI'}};
		shift @ai_seq;
		shift @ai_seq_args;
		if (!$ai_v{'temp'}{'ai'}{'completedAI'}{'buyAuto'}) {
			$ai_v{'temp'}{'ai'}{'completedAI'}{'sellAuto'} = 1;
			unshift @ai_seq, "buyAuto";
			unshift @ai_seq_args, {%{$ai_v{'temp'}{'ai'}}};
		}
	} elsif ($ai_seq[0] eq "sellAuto" && timeOut(\%{$timeout{'ai_sellAuto'}})) {
		if (!$config{'sellAuto'} || !%{$npcs_lut{$config{'sellAuto_npc'}}}) {
			$ai_seq_args[0]{'done'} = 1;
			last AUTOSELL;
		}

		undef $ai_v{'temp'}{'do_route'};
		if ($field{'name'} ne $npcs_lut{$config{'sellAuto_npc'}}{'map'}) {
			$ai_v{'temp'}{'do_route'} = 1;
		} else {
			$ai_v{'temp'}{'distance'} = distance(\%{$npcs_lut{$config{'sellAuto_npc'}}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
			#Hayashi Fixed
			if ($ai_v{'temp'}{'distance'} > $config{'sellAuto_distance'}) {
				$ai_v{'temp'}{'do_route'} = 1;
			}
		}
		if ($ai_v{'temp'}{'do_route'}) {
			if ($ai_seq_args[0]{'warpedToSave'} && !$ai_seq_args[0]{'mapChanged'}) {
				undef $ai_seq_args[0]{'warpedToSave'};
			}
			if ($config{'saveMap'} ne "" && $field{'name'} ne $config{'saveMap'} && $config{'saveMap_warpToBuyOrSell'} && !$ai_seq_args[0]{'warpedToSave'} && !$cities_lut{$field{'name'}.'.rsw'}) {
				$ai_seq_args[0]{'warpedToSave'} = 1;
				useTeleport(2);
				$timeout{'ai_sellAuto'}{'time'} = time;
			} else {
				System::message "Calculating auto-sell route to: $maps_lut{$npcs_lut{$config{'sellAuto_npc'}}{'map'}.'.rsw'}($npcs_lut{$config{'sellAuto_npc'}}{'map'}): $npcs_lut{$config{'sellAuto_npc'}}{'pos'}{'x'}, $npcs_lut{$config{'sellAuto_npc'}}{'pos'}{'y'}\n";
				injectMessage("Calculating auto-sell route to: $maps_lut{$npcs_lut{$config{'sellAuto_npc'}}{'map'}.'.rsw'}($npcs_lut{$config{'sellAuto_npc'}}{'map'}): $npcs_lut{$config{'sellAuto_npc'}}{'pos'}{'x'}, $npcs_lut{$config{'sellAuto_npc'}}{'pos'}{'y'}\n") if ($config{'verbose'} && $System::xMode);
				ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $npcs_lut{$config{'sellAuto_npc'}}{'pos'}{'x'}, $npcs_lut{$config{'sellAuto_npc'}}{'pos'}{'y'}, $npcs_lut{$config{'sellAuto_npc'}}{'map'}, 0, 0, 1, 0, $config{'sellAuto_distance'}, 1);
			}
		} else {
			if ($ai_seq_args[0]{'sentSell'} <= 1) {
				checkNPC("sellAuto_npc") if ($config{'autoUpdateNPC'});
				sendTalk(\$System::remote_socket, pack("L1",$config{'sellAuto_npc'})) if !$ai_seq_args[0]{'sentSell'};
				sendGetSellList(\$System::remote_socket, pack("L1",$config{'sellAuto_npc'})) if $ai_seq_args[0]{'sentSell'};
				$ai_seq_args[0]{'sentSell'}++;
				$timeout{'ai_sellAuto'}{'time'} = time;
				last AUTOSELL;
			}
			$ai_seq_args[0]{'done'} = 1;
			for ($i = 0; $i < @{$chars[$config{'char'}]{'inventory'}};$i++) {
				next if (!%{$chars[$config{'char'}]{'inventory'}[$i]} || $chars[$config{'char'}]{'inventory'}[$i]{'equipped'});
				if (($items_control{'all'}{'sell'} && $chars[$config{'char'}]{'inventory'}[$i]{'amount'} > $items_control{'all'}{'keep'} && !%{$items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}})
					|| ($items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'sell'} && $chars[$config{'char'}]{'inventory'}[$i]{'amount'} > $items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'keep'})
					) {
					if ($ai_seq_args[0]{'lastIndex'} ne "" && $ai_seq_args[0]{'lastIndex'} == $chars[$config{'char'}]{'inventory'}[$i]{'index'}
						&& timeOut(\%{$timeout{'ai_sellAuto_giveup'}})) {
						last AUTOSELL;
					} elsif ($ai_seq_args[0]{'lastIndex'} eq "" || $ai_seq_args[0]{'lastIndex'} != $chars[$config{'char'}]{'inventory'}[$i]{'index'}) {
						$timeout{'ai_sellAuto_giveup'}{'time'} = time;
					}
					undef $ai_seq_args[0]{'done'};
					$ai_seq_args[0]{'lastIndex'} = $chars[$config{'char'}]{'inventory'}[$i]{'index'};
					sendSell(\$System::remote_socket, $chars[$config{'char'}]{'inventory'}[$i]{'index'}, $chars[$config{'char'}]{'inventory'}[$i]{'amount'} - $items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'keep'});
					$timeout{'ai_sellAuto'}{'time'} = time;
					last AUTOSELL;
				}
			}
		}
	}

	} #END OF BLOCK AUTOSELL



	#####AUTO BUY#####

	AUTOBUY: {

	if (($ai_seq[0] eq "" || $ai_seq[0] eq "route" || $ai_seq[0] eq "attack") && timeOut(\%{$timeout{'ai_buyAuto'}})) {
		undef $ai_v{'temp'}{'found'};
		$i = 0;
		while (defined($config{"buyAuto_$i"}) && defined($config{"buyAuto_$i"."_npc"})) {
			#last if (!$config{"buyAuto_$i"} || !$config{"buyAuto_$i"."_npc"});
			$ai_v{'temp'}{'invIndex'} = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{"buyAuto_$i"});
			if ($config{"buyAuto_$i"."_minAmount"} ne "" && $config{"buyAuto_$i"."_maxAmount"} ne ""
				&& ($ai_v{'temp'}{'invIndex'} eq ""
				|| ($chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'amount'} <= $config{"buyAuto_$i"."_minAmount"}
				&& $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'amount'} < $config{"buyAuto_$i"."_maxAmount"}))) {
				$ai_v{'temp'}{'found'} = 1;
			}
			$i++;
		}
		$ai_v{'temp'}{'ai_route_index'} = binFind(\@ai_seq, "route");
		if ($ai_v{'temp'}{'ai_route_index'} ne "") {
			$ai_v{'temp'}{'ai_route_attackOnRoute'} = $ai_seq_args[$ai_v{'temp'}{'ai_route_index'}]{'attackOnRoute'};
		}
		if (!($ai_v{'temp'}{'ai_route_index'} ne "" && $ai_v{'temp'}{'ai_route_attackOnRoute'} <= 1) && $ai_v{'temp'}{'found'}) {
			unshift @ai_seq, "buyAuto";
			unshift @ai_seq_args, {};
		}
		$timeout{'ai_buyAuto'}{'time'} = time;
	}

	if ($ai_seq[0] eq "buyAuto" && $ai_seq_args[0]{'done'}) {
		undef %{$ai_v{'temp'}{'ai'}};
		%{$ai_v{'temp'}{'ai'}{'completedAI'}} = %{$ai_seq_args[0]{'completedAI'}};
		shift @ai_seq;
		shift @ai_seq_args;
		if (!$ai_v{'temp'}{'ai'}{'completedAI'}{'storageAuto'}) {
			$ai_v{'temp'}{'ai'}{'completedAI'}{'buyAuto'} = 1;
			unshift @ai_seq, "storageAuto";
			unshift @ai_seq_args, {%{$ai_v{'temp'}{'ai'}}};
		}
	} elsif ($ai_seq[0] eq "buyAuto" && timeOut(\%{$timeout{'ai_buyAuto_wait'}}) && timeOut(\%{$timeout{'ai_buyAuto_wait_buy'}})) {
		$i = 0;
		undef $ai_seq_args[0]{'index'};
		
		while (defined($config{"buyAuto_$i"}) && defined(%{$npcs_lut{$config{"buyAuto_$i"."_npc"}}})) {
			#last if (!$config{"buyAuto_$i"} || !%{$npcs_lut{$config{"buyAuto_$i"."_npc"}}});
			$ai_seq_args[0]{'invIndex'} = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{"buyAuto_$i"});
			if (!$ai_seq_args[0]{'index_failed'}{$i} && $config{"buyAuto_$i"."_maxAmount"} ne "" && ($ai_seq_args[0]{'invIndex'} eq "" 
				|| $chars[$config{'char'}]{'inventory'}[$ai_seq_args[0]{'invIndex'}]{'amount'} < $config{"buyAuto_$i"."_maxAmount"})) {
				$ai_seq_args[0]{'index'} = $i;
				last;
			}
			$i++;
		}
		if ($ai_seq_args[0]{'index'} eq ""
			|| ($ai_seq_args[0]{'lastIndex'} ne "" && $ai_seq_args[0]{'lastIndex'} == $ai_seq_args[0]{'index'}
			&& timeOut(\%{$timeout{'ai_buyAuto_giveup'}}))) {
			$ai_seq_args[0]{'done'} = 1;
			last AUTOBUY;
		}
		undef $ai_v{'temp'}{'do_route'};
		if ($field{'name'} ne $npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'map'}) {
			$ai_v{'temp'}{'do_route'} = 1;
		} else {
			$ai_v{'temp'}{'distance'} = distance(\%{$npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
			#Hayashi Fixed
			if ($ai_v{'temp'}{'distance'} > $config{"buyAuto_$ai_seq_args[0]{'index'}"."_distance"}) {
				$ai_v{'temp'}{'do_route'} = 1;
			}
		}
		if ($ai_v{'temp'}{'do_route'}) {
			if ($ai_seq_args[0]{'warpedToSave'} && !$ai_seq_args[0]{'mapChanged'}) {
				undef $ai_seq_args[0]{'warpedToSave'};
			}
			if ($config{'saveMap'} ne "" && $field{'name'} ne $config{'saveMap'} && $config{'saveMap_warpToBuyOrSell'} && !$ai_seq_args[0]{'warpedToSave'} && !$cities_lut{$field{'name'}.'.rsw'}) {
				$ai_seq_args[0]{'warpedToSave'} = 1;
				useTeleport(2);
				$timeout{'ai_buyAuto_wait'}{'time'} = time;
			} else {
				System::message qq~Calculating auto-buy route to: $maps_lut{$npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'map'}.'.rsw'}($npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'map'}): $npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'pos'}{'x'}, $npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'pos'}{'y'}\n~;
				injectMessage(qq~Calculating auto-buy route to: $maps_lut{$npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'map'}.'.rsw'}($npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'map'}): $npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'pos'}{'x'}, $npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'pos'}{'y'}~) if ($config{'verbose'} && $System::xMode);
				ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'pos'}{'x'}, $npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'pos'}{'y'}, $npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'map'}, 0, 0, 1, 0, $config{"buyAuto_$ai_seq_args[0]{'index'}"."_distance"}, 1);
			}
		} else {
			if ($ai_seq_args[0]{'lastIndex'} eq "" || $ai_seq_args[0]{'lastIndex'} != $ai_seq_args[0]{'index'}) {
				undef $ai_seq_args[0]{'itemID'};
				if ($config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"} != $config{"buyAuto_$ai_seq_args[0]{'lastIndex'}"."_npc"}) {
					undef $ai_seq_args[0]{'sentBuy'};
				}
				$timeout{'ai_buyAuto_giveup'}{'time'} = time;
			}
			$ai_seq_args[0]{'lastIndex'} = $ai_seq_args[0]{'index'};
			if ($ai_seq_args[0]{'itemID'} eq "") {
				foreach (keys %items_lut) {
					if (lc($items_lut{$_}) eq lc($config{"buyAuto_$ai_seq_args[0]{'index'}"})) {
						$ai_seq_args[0]{'itemID'} = $_;
					}
				}
				if ($ai_seq_args[0]{'itemID'} eq "") {
					$ai_seq_args[0]{'index_failed'}{$ai_seq_args[0]{'index'}} = 1;
					System::message "autoBuy index $ai_seq_args[0]{'index'} failed\n" if $config{'debug'};
					last AUTOBUY;
				}
			}

			if ($ai_seq_args[0]{'sentBuy'} <= 1) {
				checkNPC("buyAuto_$ai_seq_args[0]{'index'}"."_npc") if ($config{'autoUpdateNPC'});
				sendTalk(\$System::remote_socket, pack("L1",$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"})) if !$ai_seq_args[0]{'sentBuy'};
				sendGetStoreList(\$System::remote_socket, pack("L1",$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"})) if $ai_seq_args[0]{'sentBuy'};
				$ai_seq_args[0]{'sentBuy'}++;
				$timeout{'ai_buyAuto_wait'}{'time'} = time;
				last AUTOBUY;
			}	
			if ($ai_seq_args[0]{'invIndex'} ne "") {
				sendBuy(\$System::remote_socket, $ai_seq_args[0]{'itemID'}, $config{"buyAuto_$ai_seq_args[0]{'index'}"."_maxAmount"} - $chars[$config{'char'}]{'inventory'}[$ai_seq_args[0]{'invIndex'}]{'amount'});
			} else {
				sendBuy(\$System::remote_socket, $ai_seq_args[0]{'itemID'}, $config{"buyAuto_$ai_seq_args[0]{'index'}"."_maxAmount"});
			}
			$timeout{'ai_buyAuto_wait_buy'}{'time'} = time;
		}
	}

	} #END OF BLOCK AUTOBUY

	##### LOCKMAP #####

	if (($ai_seq[0] eq "" || $ai_seq[0] eq "move" || $ai_seq[0] eq "route" || $ai_seq[0] eq "route_getRoute" || $ai_seq[0] eq "route_getMapRoute" )
		&& $field{'name'} && $config{"allowableMap"} ne ""
		&& !(existsInList($config{"allowableMap"},$field{'name'}))) {
		System::message "You are out of allowable map : $field{'name'} \n","danger",1,"D";
		ai_setSuspend(5);
		if ($config{'reactallowableMap'} == 1) {
			System::message "Respawn to save map\n","danger",1,"D";
			useTeleport(2);
		} elsif ($config{'reactallowableMap'} == 2) {
			System::message "Disconnect for the first place\n","danger",1,"D";
			quit();
		}
	}

	if ($ai_seq[0] eq "" && $config{'lockMap_0'} && $field{'name'}) {
	# Calculate lockMap Slot
		$ai_v{'lockMapIndex'} = 0 if (!defined $ai_v{'lockMapIndex'});
		#setup time when entry lockMap
		if ($field{'name'} eq $config{"lockMap_$ai_v{'lockMapIndex'}"} && $config{"lockMap_$ai_v{'lockMapIndex'}"."_timeout"} 
			&& !defined $timeout{'lockMap'}{'time'}) {
			$timeout{'lockMap'}{'time'} = time;
			$timeout{'lockMap'}{'timeout'} = $config{"lockMap_$ai_v{'lockMapIndex'}"."_timeout"} if (!defined $timeout{'lockMap'}{'timeout'});
		#wrap around lockMap
		}elsif ($field{'name'} eq $config{"lockMap_$ai_v{'lockMapIndex'}"} && $config{"lockMap_$ai_v{'lockMapIndex'}"."_timeout"}
					&& defined $timeout{'lockMap'}{'time'} && timeOut(\%{$timeout{'lockMap'}})){
			if (defined $config{"lockMap_".($ai_v{'lockMapIndex'}+1)}){
				$ai_v{'lockMapIndex'}++;
			}else{
				$ai_v{'lockMapIndex'} = 0;
			}
			System::message "lockMap timeOut switch map to :".$config{"lockMap_$ai_v{'lockMapIndex'}"}."\n";
			undef $timeout{'lockMap'}{'time'};
			undef $timeout{'lockMap'}{'timeout'};
		}
	# normal LockMap
		if ($field{'name'} ne $config{"lockMap_$ai_v{'lockMapIndex'}"} || ($config{"lockMap_$ai_v{'lockMapIndex'}"."_x"} ne ""
			&& ($chars[$config{'char'}]{'pos_to'}{'x'} != $ai_v{'temp'}{'randX'} || $chars[$config{'char'}]{'pos_to'}{'y'} != $ai_v{'temp'}{'randY'}))
			){
			if ($maps_lut{$config{"lockMap_$ai_v{'lockMapIndex'}"}.'.rsw'} eq "") {
				System::message "Invalid map specified for lockMap - map".$config{"lockMap_$ai_v{'lockMapIndex'}"}."doesn't exist\n";
				injectMessage("Invalid map specified for lockMap - map ".$config{"lockMap_$ai_v{'lockMapIndex'}"}."doesn't exist") if ($config{'verbose'} && $System::xMode);
			} elsif (!$ai_v{'temp'}{'shopOpen'}) {
				if ($config{"lockMap_$ai_v{'lockMapIndex'}"."_x"} ne "" || $config{"lockMap_$ai_v{'lockMapIndex'}"."_y"} ne "") {
					if ($config{"lockMap_$ai_v{'lockMapIndex'}"."_randx"} || $config{"lockMap_$ai_v{'lockMapIndex'}"."_randy"}) {
						do { 
							$ai_v{'temp'}{'randX'} = $config{"lockMap_$ai_v{'lockMapIndex'}"."_x"} + ((int(rand(3))-1)*(int(rand($config{"lockMap_$ai_v{'lockMapIndex'}"."_randx"}))+1));
							$ai_v{'temp'}{'randY'} = $config{"lockMap_$ai_v{'lockMapIndex'}"."_y"} + ((int(rand(3))-1)*(int(rand($config{"lockMap_$ai_v{'lockMapIndex'}"."_randy"}))+1));
						} while ($field{'field'}[$ai_v{'temp'}{'randY'}*$field{'width'} + $ai_v{'temp'}{'randX'}]);
					}elsif($ai_v{'temp'}{'randX'}!=$config{"lockMap_$ai_v{'lockMapIndex'}"."_x"} && $ai_v{'temp'}{'randY'}!=$config{"lockMap_$ai_v{'lockMapIndex'}"."_y"}){
						$ai_v{'temp'}{'randX'} = $config{"lockMap_$ai_v{'lockMapIndex'}"."_x"};
						$ai_v{'temp'}{'randY'} = $config{"lockMap_$ai_v{'lockMapIndex'}"."_y"};
					}
					System::message qq~Calculating lockMap route to: $maps_lut{$config{"lockMap_$ai_v{'lockMapIndex'}"}.'.rsw'}($config{"lockMap_$ai_v{'lockMapIndex'}"}): $ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'}\n~,"route",1;
					injectMessage("Calculating lockMap route to: ".$maps_lut{$config{"lockMap_$ai_v{'lockMapIndex'}"}.'.rsw'}."(".$config{"lockMap_$ai_v{'lockMapIndex'}"}."): $ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'}") if ($config{'verbose'} && $System::xMode);
				} else {
					if ($ai_v{'temp'}{'randX'} ne "") {
						undef $ai_v{'temp'}{'randX'};
						undef $ai_v{'temp'}{'randY'};
					}
					System::message qq~Calculating lockMap route to: $maps_lut{$config{"lockMap_$ai_v{'lockMapIndex'}"}.'.rsw'}($config{"lockMap_$ai_v{'lockMapIndex'}"})\n~,"route",1;
					injectMessage("Calculating lockMap route to: ".$maps_lut{$config{"lockMap_$ai_v{'lockMapIndex'}"}.'.rsw'}."(".$config{"lockMap_$ai_v{'lockMapIndex'}"}.")") if ($config{'verbose'} && $System::xMode);
				}
				#$r_ret, $x, $y, $map, $maxRouteDistance, $maxRouteTime, $attackOnRoute, $avoidPortals, $distFromGoal, $checkInnerPortals,$attackID;
				ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'},$config{"lockMap_$ai_v{'lockMapIndex'}"}, 0, 0,!$config{'attackAuto_inLockOnly'}, 0, 0, 1);
			}
		}
	}


	##### Shop AutoStart #####

	if ($ai_seq[0] eq "" && $shop{'shop_autoStart'} && !$ai_v{'temp'}{'shop'}{'time'} && !$ai_v{'temp'}{'shopOpen'}) {
		configModify("route_randomWalk",0) if ($config{'route_randomWalk'});
		configModify("makeChatwhenSit",0) if ($config{'makeChatwhenSit'});
		configModify("attackAuto",0) if ($config{'attackAuto'}>=1);
		unshift @ai_seq, "shopauto";
		unshift @ai_seq_args, {};
	}elsif ($ai_seq[0] eq "shopauto" && !$ai_v{'temp'}{'shop'}{'time'} && !$ai_v{'temp'}{'shopOpen'}){
		if ($chars[$config{'char'}]{'sitting'}) {
			sendStand(\$System::remote_socket); 
			sleep(0.5); 
		}
		$ai_v{'temp'}{'shop'}{'time'} = time;
	}elsif ($ai_seq[0] eq "shopauto" && !$ai_v{'temp'}{'shopOpen'} && $shop{'shop_autoStart'} && timeOut($ai_v{'temp'}{'shop'}{'time'},$shop{'shop_startTimeDelay'})){
		openShop(\$System::remote_socket);
		undef $ai_v{'temp'}{'shop'}{'time'};
	}
	
	##### Waypoint #####

	if ($config{'useLockPoint'} && $ai_seq[0] eq "" && @{$field{'field'}} > 1 && !$cities_lut{$field{'name'}.'.rsw'} && !$ai_v{'temp'}{'shopOpen'}) {
		if (!%route || $route{'name'} ne $field{'name'}) {
			if (!FileParser::getRoutePoint("wap/$field{'name'}.wap",\%route)) {
				configModify("useLockPoint",0);
			}else{
				#sticky to waypoint
				$route{'count'} = 0;
				for ($i=0;$i<$route{'max'};$i++) {
					if (distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$route{"$route{'count'}"}}) > distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$route{"$i"}})) {
						$route{'count'} = $i;
					}
				}
			}
		}
		if ($config{'useLockPoint'}) {
			System::message "move to (".$route{"$route{'count'}"}{'x'}.",".$route{"$route{'count'}"}{'y'}.")\n";
			$ai_v{'temp'}{'randX'} = $route{"$route{'count'}"}{'x'};
			$ai_v{'temp'}{'randY'} = $route{"$route{'count'}"}{'y'};
			ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'}, $field{'name'}, 0, $config{'route_randomWalk_maxRouteTime'}, 2);
			$route{'count'}++;
			#wrap around
			if($route{'count'} == $route{'max'}) {
				$route{'count'} = 0;
			}
		}
	}
#mod Stop

	##### RANDOM WALK #####
	#1if ($config{'route_randomWalk'} && $ai_seq[0] eq "" && @{$field{'field'}} > 1) {
	if ($config{'route_randomWalk'} && $ai_seq[0] eq "" && @{$field{'field'}} > 1 && !$cities_lut{$field{'name'}.'.rsw'}) {
		do { 
			$ai_v{'temp'}{'randX'} = int(rand() * ($field{'width'} - 1));
			$ai_v{'temp'}{'randY'} = int(rand() * ($field{'height'} - 1));
		} while ($field{'field'}[$ai_v{'temp'}{'randY'}*$field{'width'} + $ai_v{'temp'}{'randX'}]);
		System::message "Calculating random route to: $maps_lut{$field{'name'}.'.rsw'}($field{'name'}): $ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'}\n","route",1;
		injectMessage("Calculating random route to: $maps_lut{$field{'name'}.'.rsw'}($field{'name'}): $ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'}") if ($config{'verbose'} && $System::xMode);
		ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'}, $field{'name'}, 0, $config{'route_randomWalk_maxRouteTime'}, 2, undef, undef, 1);
		#ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'}, $field{'name'}, 0, $config{'route_randomWalk_maxRouteTime'}, 2);
	}

	##### DEAD #####

	if ($ai_seq[0] eq "dead" && !$chars[$config{'char'}]{'dead'}) {
		shift @ai_seq;
		shift @ai_seq_args;

		#force storageAuto or sellAuto
		if ($config{'deadAuto_forceStorageOrSell'}) {
			if ($config{'storageAuto'}) {
				unshift @ai_seq, "storageAuto";
				unshift @ai_seq_args, {};
			}elsif ($config{'sellAuto'}){
				unshift @ai_seq, "sellAuto";
				unshift @ai_seq_args, {};
			}
		}
		if ($config{'deadAuto_waitForUseItem'}) {
			unshift @ai_seq, "item_use";
			unshift @ai_seq_args, {};
		}

	} elsif ($ai_seq[0] ne "dead" && $chars[$config{'char'}]{'dead'}) {
		undef @ai_seq;
		undef @ai_seq_args;
		unshift @ai_seq, "dead";
		unshift @ai_seq_args, {};
	}
	
	if ($ai_seq[0] eq "dead" && $config{'deadAuto_respawn'}
		&& timeOut($chars[$config{'char'}]{'dead_time'},$timeout{'ai_dead_respawn'}{'timeout'})){
		sendRespawn(\$System::remote_socket);
		$chars[$config{'char'}]{'dead_time'} = time;
	}elsif ($ai_seq[0] eq "dead" && $config{'dcOnDeath'}){
		System::message "Disconnecting on death!\n";
		injectMessage("Disconnecting on death!") if ($config{'verbose'} && $System::xMode);
		quit();
	}


	##### AUTO-ITEM USE #####


	if (($ai_seq[0] eq "" || $ai_seq[0] eq "route" || $ai_seq[0] eq "route_getRoute" || $ai_seq[0] eq "route_getMapRoute" 
		|| $ai_seq[0] eq "follow" || $ai_seq[0] eq "sitAuto" || $ai_seq[0] eq "take" || $ai_seq[0] eq "items_gather" 
		|| $ai_seq[0] eq "items_take" || $ai_seq[0] eq "attack" || $ai_seq[0] eq "item_use")
		&& timeOut(\%{$timeout{'ai_item_use_auto'}}) && !$chars[$config{'char'}]{'ban_period'}) { 
		my $i = 0;
		my $isDo = 0;
		while (defined($config{"useSelf_item_$i"})) {
			#last if (!$config{"useSelf_item_$i"});
			if (checkSelfCondition("useSelf_item_$i")) {
				undef $ai_v{'temp'}{'invIndex'};
				$ai_v{'temp'}{'invIndex'} = findIndexStringList_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{"useSelf_item_$i"});
				if ($ai_v{'temp'}{'invIndex'} ne "") {
					$isDo = 1;
					sendItemUse(\$System::remote_socket, $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'index'}, $accountID);
					$ai_v{"useSelf_item_$i"."_time"} = time;
					$timeout{'ai_item_use_auto'}{'time'} = time;
					System::message qq~Auto-item use: $items_lut{$chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'nameID'}}\n~ if $config{'debug'};
					last;
				}
			}
			$i++;
		}
		if (!$isDo  && $ai_seq[0] eq "item_use") {
			shift @ai_seq;
			shift @ai_seq_args;
		}
	}

#Auto Equip - Kaldi Update 12/03/2004
	##### AUTO-EQUIP #####
	if (($ai_seq[0] eq "" || $ai_seq[0] eq "route" || $ai_seq[0] eq "route_getRoute" || 
		 $ai_seq[0] eq "route_getMapRoute" || $ai_seq[0] eq "follow" || $ai_seq[0] eq "sitAuto" || 
		 $ai_seq[0] eq "take" || $ai_seq[0] eq "items_gather" || $ai_seq[0] eq "items_take" || 
		 $ai_seq[0] eq "attack")&& timeOut(\%{$timeout{'ai_equip_auto'}}) 
		){
		my $i = 0;
		my $ai_index_attack = binFind(\@ai_seq, "attack");
		my $ai_index_skill_use = binFind(\@ai_seq, "skill_use");
		while ($config{"equipAuto_$i"}) {
			#last if (!$config{"equipAuto_$i"});
			if ($chars[$config{'char'}]{'percent_hp'} <= $config{"equipAuto_$i" . "_hp_upper"}
				&& $chars[$config{'char'}]{'percent_hp'} >= $config{"equipAuto_$i" . "_hp_lower"}
				&& $chars[$config{'char'}]{'percent_sp'} <= $config{"equipAuto_$i" . "_sp_upper"}
				&& $chars[$config{'char'}]{'percent_sp'} >= $config{"equipAuto_$i" . "_sp_lower"}
				&& $config{"equipAuto_$i" . "_minAggressives"} <= ai_getAggressives()
				&& (!$config{"equipAuto_$i" . "_maxAggressives"} || $config{"equipAuto_$i" . "_maxAggressives"} >= ai_getAggressives())
				&& (!$config{"equipAuto_$i" . "_monsters"} || existsInList($config{"equipAuto_$i" . "_monsters"}, $monsters{$ai_seq_args[0]{'ID'}}{'name'}))
				&& (!$config{"equipAuto_$i" . "_weight"} || $chars[$config{'char'}]{'percent_weight'} >= $config{"equipAuto_$i" . "_weight"})
				&& ($config{"equipAuto_$i"."_whileSitting"} || !$chars[$config{'char'}]{'sitting'})
				&& (!$config{"equipAuto_$i" . "_skills"} || $ai_index_skill_use ne "" && existsInList($config{"equipAuto_$i" . "_skills"},$skillsID_lut{$ai_seq_args[$ai_index_skill_use]{'skill_use_id'}}))
			) {
				undef $ai_v{'temp'}{'invIndex'};
				$ai_v{'temp'}{'invIndex'} = findIndexString_lc_not_equip(\@{$chars[$config{'char'}]{'inventory'}},"name", $config{"equipAuto_$i"});
				if ($ai_v{'temp'}{'invIndex'} ne "") {
					sendEquip(\$System::remote_socket,$chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'index'},$chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'type_equip'});
					$timeout{'ai_item_equip_auto'}{'time'} = time;
					System::message qq~Auto-equip: $items_lut{$chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'nameID'}}\n~ if $config{'debug'};
					last;
				}
			} elsif ($config{"equipAuto_$i" . "_def"} && !$chars[$config{'char'}]{'sitting'}) {
				undef $ai_v{'temp'}{'invIndex'};
				$ai_v{'temp'}{'invIndex'} = findIndexString_lc_not_equip(\@{$chars[$config{'char'}]{'inventory'}},"name", $config{"equipAuto_$i" . "_def"});
				if ($ai_v{'temp'}{'invIndex'} ne "") {
					sendEquip(\$System::remote_socket, $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'index'},$chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'type_equip'});
					$timeout{'ai_item_equip_auto'}{'time'} = time;
					System::message qq~Auto-equip: $items_lut{$chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'nameID'}}\n~ if $config{'debug'};
				}
			}
			$i++;
		}
	}


	##### AUTO-SKILL USE #####


	if ($ai_seq[0] eq "" || $ai_seq[0] eq "route" || $ai_seq[0] eq "route_getRoute" || $ai_seq[0] eq "route_getMapRoute" 
		|| $ai_seq[0] eq "follow" || $ai_seq[0] eq "take" || $ai_seq[0] eq "items_gather"
		|| $ai_seq[0] eq "items_take" || $ai_seq[0] eq "attack") {
		######################################################
		$i = 0;
		undef $ai_v{'useSelf_skill'};
		undef $ai_v{'useSelf_skill_lvl'};
		while (defined($config{"useSelf_skill_$i"}) && %{$chars[$config{'char'}]{'skills'}{$skills_rlut{lc($config{"useSelf_skill_$i"})}}}) {
		#Auto useself skill
			if (checkSelfCondition("useSelf_skill_$i")
				&& (!$config{"useSelf_skill_$i"."_monsters"} || existsInList($config{"useSelf_skill_$i"."_monsters"}, $monsters{$ai_seq_args[0]{'ID'}}{'name'}))
				) {
				$ai_v{"useSelf_skill_$i"."_time"} = time;
				$ai_v{'useSelf_skill'} = $config{"useSelf_skill_$i"};
				$ai_v{'useSelf_skill_lvl'} = $config{"useSelf_skill_$i"."_lvl"};
				$ai_v{'useSelf_skill_maxCastTime'} = $config{"useSelf_skill_$i"."_maxCastTime"};
				$ai_v{'useSelf_skill_minCastTime'} = $config{"useSelf_skill_$i"."_minCastTime"};
				last;
			}
			$i++;
		}
		if ($config{'useSelf_skill_smartHeal'} && $skills_rlut{lc($ai_v{'useSelf_skill'})} eq "AL_HEAL") {
			undef $ai_v{'useSelf_skill_smartHeal_lvl'};
			$ai_v{'useSelf_skill_smartHeal_hp_dif'} = $chars[$config{'char'}]{'hp_max'} - $chars[$config{'char'}]{'hp'};
			for ($i = 1; $i <= $chars[$config{'char'}]{'skills'}{$skills_rlut{lc($ai_v{'useSelf_skill'})}}{'lv'}; $i++) {
				$ai_v{'useSelf_skill_smartHeal_lvl'} = $i;
				$ai_v{'useSelf_skill_smartHeal_sp'} = 10 + ($i * 3);
				$ai_v{'useSelf_skill_smartHeal_amount'} = int(($chars[$config{'char'}]{'lv'} + $chars[$config{'char'}]{'int'}) / 8)
						* (4 + $i * 8);
				if ($chars[$config{'char'}]{'sp'} < $ai_v{'useSelf_skill_smartHeal_sp'}) {
					$ai_v{'useSelf_skill_smartHeal_lvl'}--;
					last;
				}
				last if ($ai_v{'useSelf_skill_smartHeal_amount'} >= $ai_v{'useSelf_skill_smartHeal_hp_dif'});
			}
			$ai_v{'useSelf_skill_lvl'} = $ai_v{'useSelf_skill_smartHeal_lvl'};
		}
		if ($ai_v{'useSelf_skill_lvl'} > 0) {
			System::message qq~Auto-skill on self: $skills_lut{$skills_rlut{lc($ai_v{'useSelf_skill'})}} (lvl $ai_v{'useSelf_skill_lvl'})\n~ if $config{'debug'};
			if (!ai_getSkillUseType($skills_rlut{lc($ai_v{'useSelf_skill'})})) {
				ai_skillUse($chars[$config{'char'}]{'skills'}{$skills_rlut{lc($ai_v{'useSelf_skill'})}}{'ID'}, $ai_v{'useSelf_skill_lvl'}, $ai_v{'useSelf_skill_maxCastTime'}, $ai_v{'useSelf_skill_minCastTime'}, $accountID);
			} else {
				ai_skillUse($chars[$config{'char'}]{'skills'}{$skills_rlut{lc($ai_v{'useSelf_skill'})}}{'ID'}, $ai_v{'useSelf_skill_lvl'}, $ai_v{'useSelf_skill_maxCastTime'}, $ai_v{'useSelf_skill_minCastTime'}, $chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'});
			}
		}
		######################################################
		$i = 0;
		undef $ai_v{'useLocation_skill'};
		undef $ai_v{'useLocation_skill_lvl'};
		while (defined($config{"useLocation_skill_$i"})) {
		#Auto useLocation skill
			if (checkSelfCondition("useLocation_skill_$i")
				&& (defined($config{"useLocation_skill_$i"."_posX"}) && defined($config{"useLocation_skill_$i"."_posY"}))
				) {
				$ai_v{"useLocation_skill_$i"."_time"} = time;
				$ai_v{'useLocation_skill'} = $config{"useLocation_skill_$i"};
				$ai_v{'useLocation_skill_lvl'} = $config{"useLocation_skill_$i"."_lvl"};
				$ai_v{'useLocation_skill_maxCastTime'} = $config{"useLocation_skill_$i"."_maxCastTime"};
				$ai_v{'useLocation_skill_minCastTime'} = $config{"useLocation_skill_$i"."_minCastTime"};
				$ai_v{'useLocation_skill_posX'} = $config{"useLocation_skill_$i"."_posX"};
				$ai_v{'useLocation_skill_posY'} = $config{"useLocation_skill_$i"."_posY"};
				last;
			}
			$i++;
		}
		if ($ai_v{'useLocation_skill_lvl'} > 0) {
			#print qq~Auto-skill on Location : $skills_lut{$skills_rlut{lc($ai_v{'useLocation_skill'})}} (lvl $ai_v{'useLocation_skill_lvl'}) [$i]\n~;
			System::message qq~Auto-skill on Location : $skills_lut{$skills_rlut{lc($ai_v{'useLocation_skill'})}} (lvl $ai_v{'useLocation_skill_lvl'}) [$i]\n~ if ($debug);
			if (ai_getSkillUseType($skills_rlut{lc($ai_v{'useLocation_skill'})})) {
				ai_skillUse($chars[$config{'char'}]{'skills'}{$skills_rlut{lc($ai_v{'useLocation_skill'})}}{'ID'}, $ai_v{'useLocation_skill_lvl'}, $ai_v{'useLocation_skill_maxCastTime'}, $ai_v{'useLocation_skill_minCastTime'}, $ai_v{'useLocation_skill_posX'}, $ai_v{'useLocation_skill_posY'});
			}
		}
		######################################################
	}


	##### PARTY-SKILL USE ##### 


	#will doing this event if set only one config
	if ( $config{'partySkill_0'} && %{$chars[$config{'char'}]{'party'}} && ($ai_seq[0] eq "" || $ai_seq[0] eq "route" || $ai_seq[0] eq "route_getRoute" || $ai_seq[0] eq "route_getMapRoute"
		|| $ai_seq[0] eq "follow" || $ai_seq[0] eq "sitAuto" || $ai_seq[0] eq "take" || $ai_seq[0] eq "items_gather" 
		|| $ai_seq[0] eq "items_take" || $ai_seq[0] eq "attack") ){
		my $i = 0;
		undef $ai_v{'partySkill'};
		undef $ai_v{'partySkill_lvl'};
		my $partyTargetID;
		my $partyTarget_HP_Percent;
		while (defined($config{"partySkill_$i"})) {
			undef $partyTargetID;
			undef $partyTarget_HP_Percent;
			for (my $j = 0; $j < @partyUsersID; $j++) {
				next if ($partyUsersID[$j] eq "");
				if ($config{"partySkill_$i"."_target"} eq $chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$j]}{'name'}
					&& $chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$j]}{'online'}){
					$partyTargetID = $partyUsersID[$j];
					$partyTarget_HP_Percent = $chars[$config{'char'}]{'party'}{'users'}{$partyTargetID}{'percent_hp'};
					last if (defined($partyTargetID) && defined($partyTarget_HP_Percent));
				}
			}
			#if defined $partyTarget_HP_Percent mean that player is in the screen. else skip to  do think.
			if (defined($partyTargetID) && defined($partyTarget_HP_Percent) && $partyTarget_HP_Percent <= $config{"partySkill_$i"."_targetHp_upper"} && $partyTarget_HP_Percent >= $config{"partySkill_$i"."_targetHp_lower"}
			&& $chars[$config{'char'}]{'percent_sp'} <= $config{"partySkill_$i"."_sp_upper"} && $chars[$config{'char'}]{'percent_sp'} >= $config{"partySkill_$i"."_sp_lower"}
			&& $chars[$config{'char'}]{'sp'} >= $skillsSP_lut{$skills_rlut{lc($config{"partySkill_$i"})}}{$config{"partySkill_$i"."_lvl"}}
			&& timeOut($ai_v{"partySkill_$i"."_time"},$config{"partySkill_$i"."_timeout"})
			&& !($config{"partySkill_$i"."_stopWhenHit"} && ai_getMonstersWhoHitMe())
			&& (!$config{"partySkill_$i"."_onSit"} || ($config{"partySkill_$i"."_onSit"} && $ai_seq[0] eq "sitAuto"))) {
				$ai_v{"partySkill_$i"."_time"} = time;
				$ai_v{'partySkill'} = $config{"partySkill_$i"};
				$ai_v{'partySkill_target'} = $config{"partySkill_$i"."_target"};
				$ai_v{'partySkill_lvl'} = $config{"partySkill_$i"."_lvl"};
				$ai_v{'partySkill_maxCastTime'} = $config{"partySkill_$i"."_maxCastTime"};
				$ai_v{'partySkill_minCastTime'} = $config{"partySkill_$i"."_minCastTime"};
				last; 
			}
			$i++;
		}
		if ($partyTargetID && $config{'useSelf_skill_smartHeal'} && $skills_rlut{lc($ai_v{'partySkill'})} eq "AL_HEAL") {
			undef $ai_v{'partySkill_smartHeal_lvl'};
			$ai_v{'partySkill_smartHeal_hp_dif'} = $chars[$config{'char'}]{'party'}{'users'}{$partyTargetID}{'hp_max'} - $chars[$config{'char'}]{'party'}{'users'}{$partyTargetID}{'hp'};
			for ($i = 1; $i <= $chars[$config{'char'}]{'skills'}{$skills_rlut{lc($ai_v{'partySkill'})}}{'lv'}; $i++) {
				$ai_v{'partySkill_smartHeal_lvl'} = $i;
				$ai_v{'partySkill_smartHeal_sp'} = 10 + ($i * 3);
				$ai_v{'partySkill_smartHeal_amount'} = int(($chars[$config{'char'}]{'lv'} + $chars[$config{'char'}]{'int'}) / 8) * (4 + $i * 8);
				if ($chars[$config{'char'}]{'sp'} < $ai_v{'partySkill_smartHeal_sp'}) {
					$ai_v{'partySkill_smartHeal_lvl'}--;
					last;
				}
				last if ($ai_v{'partySkill_smartHeal_amount'} >= $ai_v{'partySkill_smartHeal_hp_dif'});
			}
			$ai_v{'partySkill_lvl'} = $ai_v{'partySkill_smartHeal_lvl'};
		}
		if ($ai_v{'partySkill_lvl'} > 0 && $partyTargetID) {
			System::message qq~Party Skill used ($chars[$config{'char'}]{'party'}{'users'}{$partyTargetID}{'name'})Skills Used: $skills_lut{$skills_rlut{lc($ai_v{'follow_skill'})}} (lvl $ai_v{'follow_skill_lvl'})\n~ if $config{'debug'};
			if (!ai_getSkillUseType($skills_rlut{lc($ai_v{'partySkill'})})) {
				ai_skillUse($chars[$config{'char'}]{'skills'}{$skills_rlut{lc($ai_v{'partySkill'})}}{'ID'}, $ai_v{'partySkill_lvl'}, $ai_v{'partySkill_maxCastTime'}, $ai_v{'partySkill_minCastTime'}, $partyTargetID);
			} else {
				ai_skillUse($chars[$config{'char'}]{'skills'}{$skills_rlut{lc($ai_v{'partySkill'})}}{'ID'}, $ai_v{'partySkill_lvl'}, $ai_v{'partySkill_maxCastTime'}, $ai_v{'partySkill_minCastTime'}, $chars[$config{'char'}]{'party'}{'users'}{$partyTargetID}{'pos'}{'x'}, $chars[$config{'char'}]{'party'}{'users'}{$partyTargetID}{'pos'}{'y'});
			}
		}
	}


##### Hit and Run ##### 
# by SnT2k
	if ($ai_seq[0] eq "attack" && $config{'hitAndRun'} && timeOut(\%{$timeout{'hitAndRun'}}) && 
	$config{'minDistance'} >= distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$ai_v{'ai_attack_ID'}}{'pos_to'}})) {
		my ($flee_x, $flee_y);		
		if (($chars[$config{'char'}]{'pos'}{'x'}) - ($monsters{$ai_v{'ai_attack_ID'}}{'pos_to'}{'x'}) < 0) {
			$flee_x = $config{'runDistance'} * -1;
		} elsif (($chars[$config{'char'}]{'pos'}{'x'}) - ($monsters{$ai_v{'ai_attack_ID'}}{'pos_to'}{'x'}) > 0) {
			$flee_x = $config{'runDistance'};
		} else {
			$flee_x = 0;
		}
		if (($chars[$config{'char'}]{'pos'}{'y'}) - ($monsters{$ai_v{'ai_attack_ID'}}{'pos_to'}{'y'}) < 0) {
			$flee_y = $config{'runDistance'} * -1;
		} elsif (($chars[$config{'char'}]{'pos'}{'y'}) - ($monsters{$ai_v{'ai_attack_ID'}}{'pos_to'}{'y'}) > 0) {
			$flee_y = $config{'runDistance'};
		} else {
			$flee_y = 0;
		}
		$flee_x = ($chars[$config{'char'}]{'pos'}{'x'}) + $flee_x;
		$flee_y = ($chars[$config{'char'}]{'pos'}{'y'}) + $flee_y;
		$flee_x = 2 if ($flee_x == 0);
		$flee_x = $field{'width'} if ($flee_x > $field{'width'});
		$flee_y = 2 if ($flee_y == 0);
		$flee_y = $field{'height'} if ($flee_y > $field{'height'});
		if (($flee_x && $flee_y) eq 0) {
			$flee_x = int(rand() * ($field{'width'} - 2));
			$flee_y = int(rand() * ($field{'height'} - 2));
		} elsif ($flee_x eq $field{'width'} && $flee_y eq $field{'height'}) {
			$flee_x = int(rand() * ($field{'width'} - 2));
			$flee_y = int(rand() * ($field{'height'} - 2));
		}
		move($flee_x, $flee_y);
		$timeout{'hitAndRun'}{'time'} = time;
		System::message "Fleeing from target\n";
		injectMessage("Fleeing from target") if ($config{'verbose'} && $System::xMode);
	}


#KE Code Improvement
##### FOLLOW ##### 


	if ($ai_seq[0] eq "" && $config{'follow'}) {
		ai_follow($config{'followTarget'}); 
	}
	if ($ai_seq[0] eq "follow" && $ai_seq_args[0]{'suspended'}) {
		if ($ai_seq_args[0]{'ai_follow_lost'}) {
			$ai_seq_args[0]{'ai_follow_lost_end'}{'time'} += time - $ai_seq_args[0]{'suspended'}; 
		}
		undef $ai_seq_args[0]{'suspended'}; 
	}
	if ($ai_seq[0] eq "follow" && !$ai_seq_args[0]{'ai_follow_lost'}) {
		if (!$ai_seq_args[0]{'following'}) { 
			foreach (keys %players) { 
				if ($players{$_}{'name'} eq $ai_seq_args[0]{'name'} && !$players{$_}{'dead'}) { 
					$ai_seq_args[0]{'ID'} = $_; 
					$ai_seq_args[0]{'following'} = 1; 
					last;
				}
			} 
		}
		#KE Code Improvement
		if (!$ai_seq_args[0]{'ID'}) {
			for ($i = 0; $i < @partyUsersID; $i++) { 
				next if ($partyUsersID[$i] eq ""); 
				if ($chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'name'} eq $config{'followTarget'}) { 
					$ai_seq_args[0]{'ID'} = $partyUsersID[$i]; 
					$ai_seq_args[0]{'following'} = 1 if (%{$players{$ai_seq_args[0]{'ID'}}}); 
					last; 
				} 
			} 
		} 
		#end KE Code 
		if ($ai_seq_args[0]{'following'} && $players{$ai_seq_args[0]{'ID'}}{'pos_to'}) { 
			$ai_v{'temp'}{'dist'} = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$players{$ai_seq_args[0]{'ID'}}{'pos_to'}});
			#$ai_v{'temp'}{'dist'} = $players{$ai_seq_args[0]{'ID'}}{'distance'}; 
			if ($ai_v{'temp'}{'dist'} > $config{'followDistanceMax'}) {
				if ($ai_v{'temp'}{'dist'} > 15) {
					ai_route(\%{$ai_seq_args[0]{'ai_route_returnHash'}}, $players{$ai_seq_args[0]{'ID'}}{'pos_to'}{'x'}, $players{$ai_seq_args[0]{'ID'}}{'pos_to'}{'y'}, $field{'name'}, 0, 0, 1, 0, $config{'followDistanceMin'}); 
				} else {
					my $dist = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$players{$ai_seq_args[0]{'ID'}}{'pos_to'}});
					my (%vec, %pos);
					getVector(\%vec, \%{$players{$ai_seq_args[0]{'ID'}}{'pos_to'}}, \%{$chars[$config{'char'}]{'pos_to'}});
					moveAlongVector(\%pos, \%{$chars[$config{'char'}]{'pos_to'}}, \%vec, $dist - $config{'followDistanceMin'});
					move($pos{'x'}, $pos{'y'});
				}
			}
		}
		if ($ai_seq_args[0]{'following'} && $players{$ai_seq_args[0]{'ID'}}{'sitting'} == 1 && $chars[$config{'char'}]{'sitting'} == 0) {
			sit(); 
		}
	} 
	if ($ai_seq[0] eq "follow" && $ai_seq_args[0]{'following'} && ($players{$ai_seq_args[0]{'ID'}}{'dead'} || $players_old{$ai_seq_args[0]{'ID'}}{'dead'})) {
		System::message "Master died.  I'll wait here.\n";
		injectMessage("Master died.  I'll wait here.") if ($config{'verbose'} && $System::xMode);
		undef $ai_seq_args[0]{'following'};
	} elsif ($ai_seq[0] eq "follow" && $ai_seq_args[0]{'following'} && !%{$players{$ai_seq_args[0]{'ID'}}}) {
		System::message "I lost my master\n";
		injectMessage("I lost my master") if ($config{'verbose'} && $System::xMode);
		undef $ai_seq_args[0]{'following'};
		if ($players_old{$ai_seq_args[0]{'ID'}}{'disconnected'}) {
			System::message "My master disconnected\n";
			injectMessage("My master disconnected") if ($config{'verbose'} && $System::xMode);
		} elsif ($players_old{$ai_seq_args[0]{'ID'}}{'disappeared'}) {
			System::message "Trying to find lost master\n";
			injectMessage("Trying to find lost master") if ($config{'verbose'} && $System::xMode);
			undef $ai_seq_args[0]{'ai_follow_lost_char_last_pos'};
			undef $ai_seq_args[0]{'follow_lost_portal_tried'};
			$ai_seq_args[0]{'ai_follow_lost'} = 1;
			$ai_seq_args[0]{'ai_follow_lost_end'}{'timeout'} = $timeout{'ai_follow_lost_end'}{'timeout'};
			$ai_seq_args[0]{'ai_follow_lost_end'}{'time'} = time; 
			getVector(\%{$ai_seq_args[0]{'ai_follow_lost_vec'}}, \%{$players_old{$ai_seq_args[0]{'ID'}}{'pos_to'}}, \%{$chars[$config{'char'}]{'pos_to'}});
			#check if player went through portal 
			if (!$players_old{$ai_seq_args[0]{'ID'}}{'teleported'}) { 
				$ai_v{'temp'}{'first'} = 1; 
				undef $ai_v{'temp'}{'foundID'}; 
				undef $ai_v{'temp'}{'smallDist'}; 
				foreach (@portalsID) { 
					$ai_v{'temp'}{'dist'} = distance(\%{$players_old{$ai_seq_args[0]{'ID'}}{'pos_to'}}, \%{$portals{$_}{'pos'}}); 
					if ($ai_v{'temp'}{'dist'} <= 7 && ($ai_v{'temp'}{'first'} || $ai_v{'temp'}{'dist'} < $ai_v{'temp'}{'smallDist'})) { 
						$ai_v{'temp'}{'smallDist'} = $ai_v{'temp'}{'dist'}; 
						$ai_v{'temp'}{'foundID'} = $_; 
						undef $ai_v{'temp'}{'first'}; 
					} 
				}
				$ai_seq_args[0]{'follow_lost_portalID'} = $ai_v{'temp'}{'foundID'}; 
			}
		} else {
			System::message "Don't know what happened to Master\n"; 
			injectMessage("Don't know what happened to Master") if ($config{'verbose'} && $System::xMode);
			undef $ai_seq_args[0]{'following'}; 
			undef $ai_seq_args[0]{'follow_lost_portalID'}; 
			undef $players{$ai_seq_args[0]{'ID'}}{'dead'}; 
			undef $players_old{$ai_seq_args[0]{'ID'}}{'dead'};
		}
	}

	if ($ai_seq[0] eq "follow" && !$ai_seq_args[0]{'following'} && !$ai_seq_args[0]{'follow_lost_portalID'} &&  !$players{$ai_seq_args[0]{'ID'}}{'dead'}) {
		if ($chars[$config{'char'}]{'party'}{'users'}{$ai_seq_args[0]{'ID'}} ne "" && $chars[$config{'char'}]{'party'}{'users'}{$ai_seq_args[0]{'ID'}}{'online'} && $chars[$config{'char'}]{'party'}{'users'}{$ai_seq_args[0]{'ID'}}{'map'} ne "") {
			($map_string) = $chars[$config{'char'}]{'party'}{'users'}{$ai_seq_args[0]{'ID'}}{'map'} =~ /([\s\S]*)\.gat/;
			if ($chars[$config{'char'}]{'party'}{'users'}{$ai_seq_args[0]{'ID'}}{'pos'}{'x'} > 0) {
				$ai_seq_args[0]{'follow_lost_char'}{'map'} = $map_string;
				$ai_seq_args[0]{'follow_lost_char'}{'pos'}{'x'} = $chars[$config{'char'}]{'party'}{'users'}{$ai_seq_args[0]{'ID'}}{'pos'}{'x'} + int(rand(4)- 2);
				$ai_seq_args[0]{'follow_lost_char'}{'pos'}{'y'} = $chars[$config{'char'}]{'party'}{'users'}{$ai_seq_args[0]{'ID'}}{'pos'}{'y'} + int(rand(4)- 2); 
				System::message "Calculating Route: $maps_lut{$ai_seq_args[0]{'follow_lost_char'}{'map'}.'.rsw'}($ai_seq_args[0]{'follow_lost_char'}{'map'}): $ai_seq_args[0]{'follow_lost_char'}{'pos'}{'x'}, $ai_seq_args[0]{'follow_lost_char'}{'pos'}{'y'}\n","route",1;
				ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_seq_args[0]{'follow_lost_char'}{'pos'}{'x'}, $ai_seq_args[0]{'follow_lost_char'}{'pos'}{'y'}, $ai_seq_args[0]{'follow_lost_char'}{'map'}, 0, 0, 1, 0, 0, 1);
			} elsif ($field{'name'} ne $map_string) {
				$ai_seq_args[0]{'follow_lost_char'}{'map'} = $map_string;
				undef $ai_seq_args[0]{'follow_lost_char'}{'pos'}{'x'};
				undef $ai_seq_args[0]{'follow_lost_char'}{'pos'}{'y'};
				System::message "Calculating Route: $maps_lut{$ai_seq_args[0]{'follow_lost_char'}{'map'}.'.rsw'}($ai_seq_args[0]{'follow_lost_char'}{'map'})\n","route",1;
				ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_seq_args[0]{'follow_lost_char'}{'pos'}{'x'}, $ai_seq_args[0]{'follow_lost_char'}{'pos'}{'y'}, $ai_seq_args[0]{'follow_lost_char'}{'map'}, 0, 0, 1, 0, 0, 1);
			}
		}
	}

	if ($ai_seq[0] eq "route" && binFind(\@ai_seq, "follow") && !$ai_seq_args[binFind(\@ai_seq, "follow")]{'following'} && !$ai_seq_args[binFind(\@ai_seq, "follow")]{'follow_lost_portalID'} && $ai_seq_args[binFind(\@ai_seq, "follow")]{'ID'} ne "" && !$ai_seq_args[0]{'npc'}{'step'} && timeOut(\%{$timeout{'ai_smart_follow'}})) {
		$ai_v{'temp'}{'index'} = binFind(\@ai_seq, "follow"); 
		$ai_v{'temp'}{'ID'} = $ai_seq_args[$ai_v{'temp'}{'index'}]{'ID'}; 
		($map_string) = $chars[$config{'char'}]{'party'}{'users'}{$ai_v{'temp'}{'ID'}}{'map'} =~ /([\s\S]*)\.gat/; 
		if ($chars[$config{'char'}]{'party'}{'users'}{$ai_v{'temp'}{'ID'}}{'pos'}{'x'} > 0 && $field{'name'} eq $map_string && distance(\%{$chars[$config{'char'}]{'party'}{'users'}{$ai_v{'temp'}{'ID'}}{'pos'}}, \%{$ai_seq_args[$ai_v{'temp'}{'index'}]{'follow_lost_char'}{'pos'}}) > 40) {
			undef @ai_seq; 
			undef @ai_seq_args; 
			ai_follow($config{'followTarget'}); 
		} elsif ($map_string ne $ai_seq_args[$ai_v{'temp'}{'index'}]{'follow_lost_char'}{'map'} && !$indoors_lut{$map_string.'.rsw'}) { 
			undef @ai_seq; 
			undef @ai_seq_args; 
			ai_follow($config{'followTarget'}); 
		} else { 
			for ($i = 0; $i < @playersID; $i++) { 
				next if ($playersID[$i] eq ""); 
				if ($playersID[$i] eq $ai_seq_args[binFind(\@ai_seq, "follow")]{'ID'}) { 
					undef @ai_seq; 
					undef @ai_seq_args; 
					ai_follow($config{'followTarget'}); 
					last; 
				} 
			} 
		}
		$timeout{'ai_smart_follow'}{'time'} = time; 
	}




##### FOLLOW-LOST ##### 


	if ($ai_seq[0] eq "follow" && $ai_seq_args[0]{'ai_follow_lost'}) { 
		if ($ai_seq_args[0]{'ai_follow_lost_char_last_pos'}{'x'} == $chars[$config{'char'}]{'pos_to'}{'x'} && $ai_seq_args[0]{'ai_follow_lost_char_last_pos'}{'y'} == $chars[$config{'char'}]{'pos_to'}{'y'}) { 
			$ai_seq_args[0]{'lost_stuck'}++; 
		} else { 
			undef $ai_seq_args[0]{'lost_stuck'}; 
		} 
		%{$ai_seq_args[0]{'ai_follow_lost_char_last_pos'}} = %{$chars[$config{'char'}]{'pos_to'}}; 
		if (timeOut(\%{$ai_seq_args[0]{'ai_follow_lost_end'}})) {
			undef $ai_seq_args[0]{'ai_follow_lost'}; 
			undef $ai_seq_args[0]{'follow_lost_portalID'}; 
			System::message "Couldn't find master, giving up\n"; 
			injectMessage("Couldn't find master, giving up") if ($config{'verbose'} && $System::xMode);
		} elsif ($players_old{$ai_seq_args[0]{'ID'}}{'disconnected'}) { 
			undef $ai_seq_args[0]{'ai_follow_lost'}; 
			injectMessage("My master disconnected") if ($config{'verbose'} && $System::xMode);
		} elsif (%{$players{$ai_seq_args[0]{'ID'}}}) { 
			$ai_seq_args[0]{'following'} = 1; 
			undef $ai_seq_args[0]{'ai_follow_lost'}; 
			System::message "Found my master!\n"; 
			injectMessage("Found my master!") if ($config{'verbose'} && $System::xMode);
		} elsif ($ai_seq_args[0]{'lost_stuck'}) { 
			if ($ai_seq_args[0]{'follow_lost_portalID'} eq "") { 
				moveAlongVector(\%{$ai_v{'temp'}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}}, \%{$ai_seq_args[0]{'ai_follow_lost_vec'}}, $config{'followLostStep'} / ($ai_seq_args[0]{'lost_stuck'} + 1)); 
				move($ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'}); 
			}
		} else {
			if ($ai_seq_args[0]{'follow_lost_portalID'} ne "") { 
				if (%{$portals{$ai_seq_args[0]{'follow_lost_portalID'}}} && !$ai_seq_args[0]{'follow_lost_portal_tried'}) { 
				$ai_seq_args[0]{'follow_lost_portal_tried'} = 1; 
				%{$ai_v{'temp'}{'pos'}} = %{$portals{$ai_seq_args[0]{'follow_lost_portalID'}}{'pos'}}; 
				ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'}, $field{'name'}, 0, 0, 1); 
				undef $ai_seq_args[0]{'follow_lost_portalID'}; 
				}
			} else {
				moveAlongVector(\%{$ai_v{'temp'}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}}, \%{$ai_seq_args[0]{'ai_follow_lost_vec'}}, $config{'followLostStep'});
				move($ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'});
			}
		}
	}


	##### AUTO-SIT/SIT/STAND #####


	if ($config{'sitAuto_idle'} && ($ai_seq[0] ne "" && $ai_seq[0] ne "follow")) {
		$timeout{'ai_sit_idle'}{'time'} = time;
	}
	if (($ai_seq[0] eq "" || $ai_seq[0] eq "follow") && $config{'sitAuto_idle'} && !$chars[$config{'char'}]{'sitting'} && timeOut(\%{$timeout{'ai_sit_idle'}})) {
		sit();
	}
	if ($ai_seq[0] eq "sitting" && ($chars[$config{'char'}]{'sitting'} || $chars[$config{'char'}]{'skills'}{'NV_BASIC'}{'lv'} < 3)) {
		shift @ai_seq;
		shift @ai_seq_args;
		$timeout{'ai_sit'}{'time'} -= $timeout{'ai_sit'}{'timeout'};
	} elsif ($ai_seq[0] eq "sitting" && !$chars[$config{'char'}]{'sitting'} && timeOut(\%{$timeout{'ai_sit'}}) && timeOut(\%{$timeout{'ai_sit_wait'}})) {
		sendSit(\$System::remote_socket);
		$timeout{'ai_sit'}{'time'} = time;
	}
#mod Start
# Make Chat after sit
	if ($chars[$config{'char'}]{'sitting'} && !defined($timeout{'ai_makechatAuto'}{'time'}) && $config{'makeChatwhenSit'}) {
		$timeout{'ai_makechatAuto'}{'time'} = time;
	}elsif (!$chars[$config{'char'}]{'sitting'} && timeOut(\%{$timeout{'ai_makechatAuto'}}) && $config{'makeChatwhenSit'}) {
		undef $timeout{'ai_makechatAuto'}{'time'};
	}elsif ($chars[$config{'char'}]{'sitting'} && timeOut(\%{$timeout{'ai_makechatAuto'}}) && $config{'makeChatwhenSit'} && $currentChatRoom eq "") {
		#sendLook(\$System::remote_socket,int(rand(8)),0);
		$title = getResMsg("/chatroom");
		if ($title ne "") {
			sendChatRoomCreate(\$System::remote_socket, $title,20,0,vocalString(4));
			$createdChatRoom{'title'} = $title;
			$createdChatRoom{'ownerID'} = $accountID;
			$createdChatRoom{'limit'} = 20;
			$createdChatRoom{'public'} = 0;
			$createdChatRoom{'num_users'} = 1;
			$createdChatRoom{'users'}{$chars[$config{'char'}]{'name'}} = 2;
		}
	}elsif ($ai_seq[0] eq "standing" && $currentChatRoom ne "" ){
		sendChatRoomLeave(\$System::remote_socket);
		undef $timeout{'ai_makechatAuto'}{'time'};
	}
#mod Stop
	if ($ai_seq[0] eq "standing" && !$chars[$config{'char'}]{'sitting'} && !$timeout{'ai_stand_wait'}{'time'}) {
		$timeout{'ai_stand_wait'}{'time'} = time;
	} elsif ($ai_seq[0] eq "standing" && !$chars[$config{'char'}]{'sitting'} && timeOut(\%{$timeout{'ai_stand_wait'}})) {
		shift @ai_seq;
		shift @ai_seq_args;
		undef $timeout{'ai_stand_wait'}{'time'};
		$timeout{'ai_sit'}{'time'} -= $timeout{'ai_sit'}{'timeout'};
	} elsif ($ai_seq[0] eq "standing" && $chars[$config{'char'}]{'sitting'} && timeOut(\%{$timeout{'ai_sit'}})) {
		sendStand(\$System::remote_socket);
		$timeout{'ai_sit'}{'time'} = time;
	}

	if ($ai_v{'sitAuto_forceStop'} && $chars[$config{'char'}]{'percent_hp'} >= $config{'sitAuto_hp_lower'} && $chars[$config{'char'}]{'percent_sp'} >= $config{'sitAuto_sp_lower'}) {
		$ai_v{'sitAuto_forceStop'} = 0;
	}

# storage or sell before sit
	if (!$ai_v{'sitAuto_forceStop'} && ($ai_seq[0] eq "" || $ai_seq[0] eq "follow" || $ai_seq[0] eq "route" || $ai_seq[0] eq "route_getRoute" || $ai_seq[0] eq "route_getMapRoute") && binFind(\@ai_seq, "attack") eq "" && !ai_getAggressives()
		&& ($chars[$config{'char'}]{'percent_hp'} < $config{'sitAuto_hp_lower'} || $chars[$config{'char'}]{'percent_sp'} < $config{'sitAuto_sp_lower'})
		&& $chars[$config{'char'}]{'percent_weight'} < 50
		&& binFind(\@ai_seq, "storageAuto") eq "" && binFind(\@ai_seq, "sellAuto") eq "") {
		unshift @ai_seq, "sitAuto";
		unshift @ai_seq_args, {};
		System::message "Auto-sitting\n" if $config{'debug'};
	}

	if ($ai_seq[0] eq "sitAuto" && !$chars[$config{'char'}]{'sitting'} && $chars[$config{'char'}]{'skills'}{'NV_BASIC'}{'lv'} >= 3 && !ai_getAggressives()) {
		sit();
	}
	if ($ai_seq[0] eq "sitAuto" && ($ai_v{'sitAuto_forceStop'}
		|| ($chars[$config{'char'}]{'percent_hp'} >= $config{'sitAuto_hp_upper'} && $chars[$config{'char'}]{'percent_sp'} >= $config{'sitAuto_sp_upper'}))) {
		shift @ai_seq;
		shift @ai_seq_args;
		if (!$config{'sitAuto_idle'} && $chars[$config{'char'}]{'sitting'}) {
			stand();
		}
	}


	##### AUTO-ATTACK #####


	if (($ai_seq[0] eq "" || $ai_seq[0] eq "route" || $ai_seq[0] eq "route_getRoute" || $ai_seq[0] eq "route_getMapRoute" || $ai_seq[0] eq "follow" 
		|| $ai_seq[0] eq "sitAuto" || $ai_seq[0] eq "take" || $ai_seq[0] eq "items_gather" || $ai_seq[0] eq "items_take")
		&& !($config{'itemsTakeAuto'} >= 2 && ($ai_seq[0] eq "take" || $ai_seq[0] eq "items_take"))
		&& !($config{'itemsGatherAuto'} >= 2 && ($ai_seq[0] eq "take" || $ai_seq[0] eq "items_gather"))
		&& timeOut(\%{$timeout{'ai_attack_auto'}})) {
		undef @{$ai_v{'ai_attack_agMonsters'}};
		undef @{$ai_v{'ai_attack_cleanMonsters'}};
		undef @{$ai_v{'ai_attack_partyMonsters'}};
		undef $ai_v{'temp'}{'foundID'};
		if ($config{'tankMode'}) {
			undef $ai_v{'temp'}{'found'};
			foreach (@playersID) {	
				next if ($_ eq "");
				if ($config{'tankModeTarget'} eq $players{$_}{'name'}) {
					$ai_v{'temp'}{'found'} = 1;
					last;
				}
			}
		}
		if (!$config{'tankMode'} || ($config{'tankMode'} && $ai_v{'temp'}{'found'})) {
			$ai_v{'temp'}{'ai_follow_index'} = binFind(\@ai_seq, "follow");
			if ($ai_v{'temp'}{'ai_follow_index'} ne "") {
				$ai_v{'temp'}{'ai_follow_following'} = $ai_seq_args[$ai_v{'temp'}{'ai_follow_index'}]{'following'};
				$ai_v{'temp'}{'ai_follow_ID'} = $ai_seq_args[$ai_v{'temp'}{'ai_follow_index'}]{'ID'};
			} else {
				undef $ai_v{'temp'}{'ai_follow_following'};
			}
			$ai_v{'temp'}{'ai_route_index'} = binFind(\@ai_seq, "route");
			if ($ai_v{'temp'}{'ai_route_index'} ne "") {
				$ai_v{'temp'}{'ai_route_attackOnRoute'} = $ai_seq_args[$ai_v{'temp'}{'ai_route_index'}]{'attackOnRoute'};
			}
			# List aggressive monsters
			#@{$ai_v{'ai_attack_agMonsters'}} = ai_getAggressives() if ($config{'attackAuto'} && !($ai_v{'temp'}{'ai_route_index'} ne "" && !$ai_v{'temp'}{'ai_route_attackOnRoute'}));
			if ($config{'attackAuto'} && !($ai_v{'temp'}{'ai_route_index'} ne "" && !$ai_v{'temp'}{'ai_route_attackOnRoute'})){
				@{$ai_v{'ai_attack_agMonsters'}} = ai_getAggressives(1);
			}

			# There are two types of non-aggressive monsters. We generate two lists:
			foreach (@monstersID) {
				next if ($_ eq "");

# Detect Frozen & Trap Monster
				if (!$monsters{$ID}{'state'}) {

					if ((($config{'attackAuto_party'}
						&& $ai_seq[0] ne "take" && $ai_seq[0] ne "items_take"
						&& ($monsters{$_}{'dmgToParty'} > 0 || $monsters{$_}{'dmgFromParty'} > 0))
						|| ($config{'attackAuto_followTarget'} && $ai_v{'temp'}{'ai_follow_following'} 
						&& ($monsters{$_}{'dmgToPlayer'}{$ai_v{'temp'}{'ai_follow_ID'}} > 0 || $monsters{$_}{'missedToPlayer'}{$ai_v{'temp'}{'ai_follow_ID'}} > 0 || $monsters{$_}{'dmgFromPlayer'}{$ai_v{'temp'}{'ai_follow_ID'}} > 0)))
						&& !($ai_v{'temp'}{'ai_route_index'} ne "" && !$ai_v{'temp'}{'ai_route_attackOnRoute'})
						&& $monsters{$_}{'attack_failed'} == 0 && ($mon_control{lc($monsters{$_}{'name'})}{'attack_auto'} >= 1 || $mon_control{lc($monsters{$_}{'name'})}{'attack_auto'} eq "")) {
						push @{$ai_v{'ai_attack_partyMonsters'}}, $_;

					# Begin the attack only when noone else is on screen.
					} elsif ($config{'attackAuto_onlyWhenSafe'}
						&& $config{'attackAuto'} >= 1
						&& binSize(\@playersID) == 0
						&& $ai_seq[0] ne "sitAuto" && $ai_seq[0] ne "take" && $ai_seq[0] ne "items_gather" && $ai_seq[0] ne "items_take"
						&& !($monsters{$_}{'dmgFromYou'} == 0 && ($monsters{$_}{'dmgTo'} > 0 || $monsters{$_}{'dmgFrom'} > 0 || %{$monsters{$_}{'missedFromPlayer'}} || %{$monsters{$_}{'missedToPlayer'}} || %{$monsters{$_}{'castOnByPlayer'}})) 
						&& !($ai_v{'temp'}{'ai_route_index'} ne "" && $ai_v{'temp'}{'ai_route_attackOnRoute'} <= 1)
						&& $monsters{$_}{'attack_failed'} == 0
						&& ($mon_control{lc($monsters{$_}{'name'})}{'attack_auto'} >= 1 || $mon_control{lc($monsters{$_}{'name'})}{'attack_auto'} eq "")) {
						push @{$ai_v{'ai_attack_cleanMonsters'}}, $_;

					# List monsters that nobody's attacking
					} elsif ($config{'attackAuto'} >= 2
						&& !$config{'attackAuto_onlyWhenSafe'}
						&& $ai_seq[0] ne "sitAuto" && $ai_seq[0] ne "take" && $ai_seq[0] ne "items_gather" && $ai_seq[0] ne "items_take"
						&& !($monsters{$_}{'dmgFromYou'} == 0 && ($monsters{$_}{'dmgTo'} > 0 || $monsters{$_}{'dmgFrom'} > 0 || %{$monsters{$_}{'missedFromPlayer'}} || %{$monsters{$_}{'missedToPlayer'}} || %{$monsters{$_}{'castOnByPlayer'}})) && $monsters{$_}{'attack_failed'} == 0
						&& !($ai_v{'temp'}{'ai_route_index'} ne "" && $ai_v{'temp'}{'ai_route_attackOnRoute'} <= 1)
						&& ($mon_control{lc($monsters{$_}{'name'})}{'attack_auto'} >= 1 || $mon_control{lc($monsters{$_}{'name'})}{'attack_auto'} eq "")) {
#Avoid KSing
						undef $m_plDist_small;
						my $judgeFirst = 1;
						my $Ankled = 0;
						my $m_cDist = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$_}{'pos_to'}});
						for ($i = 0; $i < @playersID; $i++) {
							next if ($playersID[$i] eq "");
							$m_plDist = distance(\%{$players{$playersID[$i]}{'pos_to'}}, \%{$monsters{$_}{'pos_to'}});
							if ($judgeFirst || $m_plDist < $m_plDist_small) {
								$m_plDist_small = $m_plDist;
								$judgeFirst = 0;
							}
						}
						for ($i = 0; $i < @spellsID; $i++) {
							next if ($spellsID[$i] eq "" || $spells{$spellsID[$i]}{'type'} != 91);
							$Ankled = 1 if (distance(\%{$spells{$spellsID[$i]}{'pos'}}, \%{$monsters{$_}{'pos_to'}}) <= 1);
						}
						if (!$Ankled) {
							$config{'notAttackDistance'} = 3 if ($config{'notAttackDistance'} < 3);
							if((!$m_plDist_small || $m_plDist_small >= $config{'notAttackDistance'}|| $m_cDist <= $m_plDist_small)
								&&(($config{'attackAuto'}==2 && $mon_control{lc($monsters{$_}{'name'})}{'attack_auto'})||$config{'attackAuto'}>2)){
								push @{$ai_v{'ai_attack_cleanMonsters'}}, $_;
							}
						}
					}
				}
			}
#Reduce code size &  fix monster Priority
			undef $ai_v{'temp'}{'foundID'};
			$ai_v{'temp'}{'foundID'} = selectTarget(@{$ai_v{'ai_attack_agMonsters'}}) if (@{$ai_v{'ai_attack_agMonsters'}});
			$ai_v{'temp'}{'foundID'} = selectTarget(@{$ai_v{'ai_attack_partyMonsters'}}) if (!defined($ai_v{'temp'}{'foundID'}) && @{$ai_v{'ai_attack_partyMonsters'}});
			$ai_v{'temp'}{'foundID'} = selectTarget(@{$ai_v{'ai_attack_cleanMonsters'}}) if (!defined($ai_v{'temp'}{'foundID'}) && @{$ai_v{'ai_attack_cleanMonsters'}});

		}
		if ($ai_v{'temp'}{'foundID'}) {
			ai_setSuspend(0);
			attack($ai_v{'temp'}{'foundID'});
		} else {
			$timeout{'ai_attack_auto'}{'time'} = time;
		}
	}




	##### ATTACK #####


	if ($ai_seq[0] eq "attack" && $ai_seq_args[0]{'suspended'}) {
		$ai_seq_args[0]{'ai_attack_giveup'}{'time'} += time - $ai_seq_args[0]{'suspended'};
		undef $ai_seq_args[0]{'suspended'};
	}
	if ($ai_seq[0] eq "attack" && timeOut(\%{$ai_seq_args[0]{'ai_attack_giveup'}})) {
		$monsters{$ai_seq_args[0]{'ID'}}{'attack_failed'}++;
		shift @ai_seq;
		shift @ai_seq_args;
		System::message "Can't reach or damage target, dropping target\n";
		injectMessage("Can't reach or damage target, dropping target") if ($config{'verbose'} && $System::xMode);

	} elsif ($ai_seq[0] eq "attack" && !%{$monsters{$ai_seq_args[0]{'ID'}}}) {
		$timeout{'ai_attack'}{'time'} -= $timeout{'ai_attack'}{'timeout'};
		$ai_v{'ai_attack_ID_old'} = $ai_seq_args[0]{'ID'};
		shift @ai_seq;
		shift @ai_seq_args;
		if ($monsters_old{$ai_v{'ai_attack_ID_old'}}{'dead'}) {
			System::message "Target died\n","targetDie";
# exp report 
			if (%{$monstersKilled{$monsters_old{$ai_v{'ai_attack_ID_old'}}{'nameID'}}}) { 
				$monstersKilled{$monsters_old{$ai_v{'ai_attack_ID_old'}}{'nameID'}}{'count'} ++; 
			} else {
				binAdd(\@monstersKilledID, $monsters_old{$ai_v{'ai_attack_ID_old'}}{'nameID'}); 
				$monstersKilled{$monsters_old{$ai_v{'ai_attack_ID_old'}}{'nameID'}}{'name'} = $monsters_old{$ai_v{'ai_attack_ID_old'}}{'name'}; 
				$monstersKilled{$monsters_old{$ai_v{'ai_attack_ID_old'}}{'nameID'}}{'count'} = 1; 
			}
	#Add Data to Monster Report
			System::sysLog("m","$monsters_old{$ai_v{'ai_attack_ID_old'}}{'name'}\n") if ($monsters_old{$ai_v{'ai_attack_ID_old'}}{'name'} ne "" && $config{'sysLog_monster'});
			if ($config{'itemsTakeAuto'} && $monsters_old{$ai_v{'ai_attack_ID_old'}}{'dmgFromYou'} > 0) {
				ai_items_take($monsters_old{$ai_v{'ai_attack_ID_old'}}{'pos'}{'x'}, $monsters_old{$ai_v{'ai_attack_ID_old'}}{'pos'}{'y'}, $monsters_old{$ai_v{'ai_attack_ID_old'}}{'pos_to'}{'x'}, $monsters_old{$ai_v{'ai_attack_ID_old'}}{'pos_to'}{'y'});
			} elsif (!ai_getAggressives()) {
				ai_clientSuspend(0, $timeout{'ai_attack_waitAfterKill'}{'timeout'});
			}
		} else {
			System::message "Target lost\n";
			injectMessage("Target lost") if ($config{'verbose'} && $System::xMode);
		}

	} elsif ($ai_seq[0] eq "attack") {

		$ai_v{'temp'}{'ai_follow_index'} = binFind(\@ai_seq, "follow");
		if ($ai_v{'temp'}{'ai_follow_index'} ne "") {
			$ai_v{'temp'}{'ai_follow_following'} = $ai_seq_args[$ai_v{'temp'}{'ai_follow_index'}]{'following'};
			$ai_v{'temp'}{'ai_follow_ID'} = $ai_seq_args[$ai_v{'temp'}{'ai_follow_index'}]{'ID'};
		} else {
			undef $ai_v{'temp'}{'ai_follow_following'};
		}
		$ai_v{'ai_attack_monsterDist'} = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$ai_seq_args[0]{'ID'}}{'pos_to'}});


		$ai_v{'ai_attack_cleanMonster'} = (!($monsters{$ai_seq_args[0]{'ID'}}{'dmgFromYou'} == 0 && ($monsters{$ai_seq_args[0]{'ID'}}{'dmgTo'} > 0 || $monsters{$ai_seq_args[0]{'ID'}}{'dmgFrom'} > 0 || %{$monsters{$ai_seq_args[0]{'ID'}}{'missedFromPlayer'}} || %{$monsters{$ai_seq_args[0]{'ID'}}{'missedToPlayer'}} || %{$monsters{$ai_seq_args[0]{'ID'}}{'castOnByPlayer'}}))
			|| ($config{'attackAuto_party'} && ($monsters{$ai_seq_args[0]{'ID'}}{'dmgFromParty'} > 0 || $monsters{$ai_seq_args[0]{'ID'}}{'dmgToParty'} > 0))
			|| ($config{'attackAuto_followTarget'} && $ai_v{'temp'}{'ai_follow_following'} && ($monsters{$ai_seq_args[0]{'ID'}}{'dmgToPlayer'}{$ai_v{'temp'}{'ai_follow_ID'}} > 0 || $monsters{$ai_seq_args[0]{'ID'}}{'dmgFromPlayer'}{$ai_v{'temp'}{'ai_follow_ID'}} > 0))
			|| ($monsters{$ai_seq_args[0]{'ID'}}{'dmgToYou'} > 0 || $monsters{$ai_seq_args[0]{'ID'}}{'missedYou'} > 0));




		if ($ai_seq_args[0]{'dmgToYou_last'} != $monsters{$ai_seq_args[0]{'ID'}}{'dmgToYou'}
			|| $ai_seq_args[0]{'missedYou_last'} != $monsters{$ai_seq_args[0]{'ID'}}{'missedYou'}
			|| $ai_seq_args[0]{'dmgFromYou_last'} != $monsters{$ai_seq_args[0]{'ID'}}{'dmgFromYou'}) {
				$ai_seq_args[0]{'ai_attack_giveup'}{'time'} = time;
		}

		$ai_seq_args[0]{'dmgToYou_last'} = $monsters{$ai_seq_args[0]{'ID'}}{'dmgToYou'};
		$ai_seq_args[0]{'missedYou_last'} = $monsters{$ai_seq_args[0]{'ID'}}{'missedYou'};
		$ai_seq_args[0]{'dmgFromYou_last'} = $monsters{$ai_seq_args[0]{'ID'}}{'dmgFromYou'};
		$ai_seq_args[0]{'missedFromYou_last'} = $monsters{$ai_seq_args[0]{'ID'}}{'missedFromYou'};
		if (!%{$ai_seq_args[0]{'attackMethod'}}) {
			if ($config{'attackUseWeapon'}) {
				$ai_seq_args[0]{'attackMethod'}{'distance'} = $config{'attackDistance'};
				$ai_seq_args[0]{'attackMethod'}{'type'} = "weapon";
			} else {
				$ai_seq_args[0]{'attackMethod'}{'distance'} = 30;
				undef $ai_seq_args[0]{'attackMethod'}{'type'};
			}
			$i = 0;
			while (defined($config{"attackSkillSlot_$i"}) && %{$chars[$config{'char'}]{'skills'}{$skills_rlut{lc($config{"attackSkillSlot_$i"})}}}) {
				if (checkSelfCondition("attackSkillSlot_$i")
					&& !($config{"attackSkillSlot_$i" . "_stopWhenFrozen"} && $monsters{$ai_seq_args[0]{'ID'}}{'state'})
					&& (!$config{"attackSkillSlot_$i"."_maxUses"} || $ai_seq_args[0]{'attackSkillSlot_uses'}{$i} < $config{"attackSkillSlot_$i"."_maxUses"})
					&& (!$config{"attackSkillSlot_$i"."_monsters"} || existsInList($config{"attackSkillSlot_$i"."_monsters"}, $monsters{$ai_seq_args[0]{'ID'}}{'name'}))) {
					$ai_seq_args[0]{'attackSkillSlot_uses'}{$i}++;
					$ai_seq_args[0]{'attackSkillSlot_index'} = $i;
					$ai_seq_args[0]{'attackMethod'}{'distance'} = $config{"attackSkillSlot_$i"."_dist"};
					$ai_seq_args[0]{'attackMethod'}{'type'} = "skill";
					$ai_seq_args[0]{'attackMethod'}{'skillSlot'} = $i;
					# Looping skills support 
					if ($config{"attackSkillSlot_$i"."_loopSlot"} ne "") { 
						undef $ai_v{qq~attackSkillSlot_$config{"attackSkillSlot_$i"."_loopSlot"}~."_time"}; 
						undef $ai_seq_args[0]{'attackSkillSlot_uses'}{$config{"attackSkillSlot_$i"."_loopSlot"}}; 
					}
					last;
				}
				$i++;
			}
		}
		if ($chars[$config{'char'}]{'sitting'}) {
			ai_setSuspend(0);
			stand();
		} elsif (!$ai_v{'ai_attack_cleanMonster'}) {
			# Drop target if it's already attacked by someone else
			System::message "Dropping target - no kill steal\n"; 
			injectMessage("Dropping target - no kill steal") if ($config{'verbose'} && $System::xMode);
			$monsters{$ai_seq_args[0]{'ID'}}{'attack_failed'}++;
			sendAttackStop(\$System::remote_socket);
			shift @ai_seq;
			shift @ai_seq_args;

		} elsif ($ai_v{'ai_attack_monsterDist'} > $ai_seq_args[0]{'attackMethod'}{'distance'}) {
			if (%{$ai_seq_args[0]{'char_pos_last'}} && %{$ai_seq_args[0]{'attackMethod_last'}}
				&& $ai_seq_args[0]{'attackMethod_last'}{'distance'} == $ai_seq_args[0]{'attackMethod'}{'distance'}
				&& $ai_seq_args[0]{'char_pos_last'}{'x'} == $chars[$config{'char'}]{'pos_to'}{'x'}
				&& $ai_seq_args[0]{'char_pos_last'}{'y'} == $chars[$config{'char'}]{'pos_to'}{'y'}) {
				$ai_seq_args[0]{'distanceDivide'}++;
			} else {
				$ai_seq_args[0]{'distanceDivide'} = 1;
			}
			if (int($ai_seq_args[0]{'attackMethod'}{'distance'} / $ai_seq_args[0]{'distanceDivide'}) == 0
				|| ($config{'attackMaxRouteDistance'} && $ai_seq_args[0]{'ai_route_returnHash'}{'solutionLength'} > $config{'attackMaxRouteDistance'})
				|| ($config{'attackMaxRouteTime'} && $ai_seq_args[0]{'ai_route_returnHash'}{'solutionTime'} > $config{'attackMaxRouteTime'})) {
				$monsters{$ai_seq_args[0]{'ID'}}{'attack_failed'}++;
				shift @ai_seq;
				shift @ai_seq_args;
				System::message "Dropping target - couldn't reach target\n";
				injectMessage("Dropping target - couldn't reach target") if ($config{'verbose'} && $System::xMode);
			} else {
				getVector(\%{$ai_v{'temp'}{'vec'}}, \%{$monsters{$ai_seq_args[0]{'ID'}}{'pos_to'}}, \%{$chars[$config{'char'}]{'pos_to'}});
				moveAlongVector(\%{$ai_v{'temp'}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}}, \%{$ai_v{'temp'}{'vec'}}, $ai_v{'ai_attack_monsterDist'} - ($ai_seq_args[0]{'attackMethod'}{'distance'} / $ai_seq_args[0]{'distanceDivide'}) + 1);

				%{$ai_seq_args[0]{'char_pos_last'}} = %{$chars[$config{'char'}]{'pos_to'}};
				%{$ai_seq_args[0]{'attackMethod_last'}} = %{$ai_seq_args[0]{'attackMethod'}};

				if (@{$field{'field'}} > 1) {
					# $r_ret, $x, $y, $map, $maxRouteDistance, $maxRouteTime, $attackOnRoute, $avoidPortals, $distFromGoal, $checkInnerPortals
					#ai_route(\%{$ai_seq_args[0]{'ai_route_returnHash'}}, $ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'}, $field{'name'}, $config{'attackMaxRouteDistance'}, $config{'attackMaxRouteTime'}, 0, 0);
					ai_route(\%{$ai_seq_args[0]{'ai_route_returnHash'}}, $ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'}, $field{'name'}, $config{'attackMaxRouteDistance'}, $config{'attackMaxRouteTime'}, 0,0,0, 0, $ai_seq_args[0]{'ID'});
				} else {
					#move($ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'});
					move($ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'}, 0, $ai_seq_args[0]{'ID'});
				}
			}
		} elsif ((($config{'tankMode'} && $monsters{$ai_seq_args[0]{'ID'}}{'dmgFromYou'} == 0)
			|| !$config{'tankMode'})) {

			if ($ai_seq_args[0]{'attackMethod'}{'type'} eq "weapon" && timeOut(\%{$timeout{'ai_attack'}})) {
				if ($config{'tankMode'}) {
					sendAttack(\$System::remote_socket, $ai_seq_args[0]{'ID'}, 0);
				} else {
					sendAttack(\$System::remote_socket, $ai_seq_args[0]{'ID'}, 7);
				}
				$timeout{'ai_attack'}{'time'} = time;
				undef %{$ai_seq_args[0]{'attackMethod'}};
			} elsif ($ai_seq_args[0]{'attackMethod'}{'type'} eq "skill") {
				$ai_v{'ai_attack_method_skillSlot'} = $ai_seq_args[0]{'attackMethod'}{'skillSlot'};
				$ai_v{'ai_attack_ID'} = $ai_seq_args[0]{'ID'};
				undef %{$ai_seq_args[0]{'attackMethod'}};
				ai_setSuspend(0);
				if (!ai_getSkillUseType($skills_rlut{lc($config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"})})) {
					ai_skillUse($chars[$config{'char'}]{'skills'}{$skills_rlut{lc($config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"})}}{'ID'}, $config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_lvl"}, $config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_maxCastTime"}, $config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_minCastTime"}, $ai_v{'ai_attack_ID'},"");
				} else {
					ai_skillUse($chars[$config{'char'}]{'skills'}{$skills_rlut{lc($config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"})}}{'ID'}, $config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_lvl"}, $config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_maxCastTime"}, $config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_minCastTime"}, $monsters{$ai_v{'ai_attack_ID'}}{'pos_to'}{'x'}, $monsters{$ai_v{'ai_attack_ID'}}{'pos_to'}{'y'});
				}
				System::message qq~Auto-skill on monster: $skills_lut{$skills_rlut{lc($config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"})}} (lvl $config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_lvl"})\n~ if $config{'debug'};
			}
		} elsif ($config{'tankMode'}) {
			if ($ai_seq_args[0]{'dmgTo_last'} != $monsters{$ai_seq_args[0]{'ID'}}{'dmgTo'}) {
				$ai_seq_args[0]{'ai_attack_giveup'}{'time'} = time;
			}
			$ai_seq_args[0]{'dmgTo_last'} = $monsters{$ai_seq_args[0]{'ID'}}{'dmgTo'};
		}
	}

	##### SKILL USE #####


	if ($ai_seq[0] eq "skill_use" && $ai_seq_args[0]{'suspended'} && !$chars[$config{'char'}]{'ban_period'}) {
		$ai_seq_args[0]{'ai_skill_use_giveup'}{'time'} += time - $ai_seq_args[0]{'suspended'};
		$ai_seq_args[0]{'ai_skill_use_minCastTime'}{'time'} += time - $ai_seq_args[0]{'suspended'};
		$ai_seq_args[0]{'ai_skill_use_maxCastTime'}{'time'} += time - $ai_seq_args[0]{'suspended'};
		undef $ai_seq_args[0]{'suspended'};
	}
	if ($ai_seq[0] eq "skill_use") {
		if ($chars[$config{'char'}]{'sitting'}) {
			ai_setSuspend(0);
			stand();
		} elsif (!$ai_seq_args[0]{'skill_used'}) {
			$ai_seq_args[0]{'skill_used'} = 1;
			$ai_seq_args[0]{'ai_skill_use_giveup'}{'time'} = time;
			if ($ai_seq_args[0]{'skill_use_target_x'} ne "") {
				sendSkillUseLoc(\$System::remote_socket, $ai_seq_args[0]{'skill_use_id'}, $ai_seq_args[0]{'skill_use_lv'}, $ai_seq_args[0]{'skill_use_target_x'}, $ai_seq_args[0]{'skill_use_target_y'});
			} else {
				sendSkillUse(\$System::remote_socket, $ai_seq_args[0]{'skill_use_id'}, $ai_seq_args[0]{'skill_use_lv'}, $ai_seq_args[0]{'skill_use_target'});
			}
			$ai_seq_args[0]{'skill_use_last'} = $chars[$config{'char'}]{'skills'}{$skills_rlut{lc($skillsID_lut{$ai_seq_args[0]{'skill_use_id'}})}}{'time_used'};

		} elsif (($ai_seq_args[0]{'skill_use_last'} != $chars[$config{'char'}]{'skills'}{$skills_rlut{lc($skillsID_lut{$ai_seq_args[0]{'skill_use_id'}})}}{'time_used'}
			|| (timeOut(\%{$ai_seq_args[0]{'ai_skill_use_giveup'}}) && (!$chars[$config{'char'}]{'time_cast'} || !$ai_seq_args[0]{'skill_use_maxCastTime'}{'timeout'}))
			|| ($ai_seq_args[0]{'skill_use_maxCastTime'}{'timeout'} && timeOut(\%{$ai_seq_args[0]{'skill_use_maxCastTime'}})))
			&& timeOut(\%{$ai_seq_args[0]{'skill_use_minCastTime'}})) {
			shift @ai_seq;
			shift @ai_seq_args;
		}
	}

	
	##### ROUTE #####
	#There are three important things that need to be done here:
	#
	#First, calculate the map route to the desired map using the map router (a Perl function that uses 
	#A* pathfinding on the portals), and step through the map solution to get to the map.  The map router returns
	#just an array of portals, so that alone won't do the job.
	#
	#Second, for each portal step we need to use the position router (a C function that uses 
	#A* on the map XY data) to get the position solution to the next portal, then step through that
	#
	#Third, if we are in the desired map and the way is clear, calculate the final route using the position router
	#and step through it.
	#
	#Sometimes we may be in the desired map, but the way to the desired position is blocked by water.
	#If we're in the desired map and the position routing fails, kore calculates a map route to an entrance
	#that can reach the desired location - the map routing function makes sure chosen portals are reachable
	#from our current and desired positions.
	#
	#See also: http://www.gamedev.net/reference/programming/features/motionplanning/

	ROUTE: {

	#The position solution array is an array of XY positions from the current position to the desired position.
	#It's filled by the position router
	#
	#The solution ready flag indicates that we are on the desired map, and the way to the desired position is clear,
	#so the current position solution array is the final solution to be stepped through
	#
	#If we have a solution, and our stepping index is at the end of the solution, and the solution ready flag is set,
	#then we are done
	if ($ai_seq[0] eq "route" && @{$ai_seq_args[0]{'solution'}} && $ai_seq_args[0]{'index'} == @{$ai_seq_args[0]{'solution'}} - 1 && $ai_seq_args[0]{'solutionReady'}) {
		System::message "Route success\n" if $config{'debug'};
		shift @ai_seq;
		shift @ai_seq_args;
	} elsif ($ai_seq[0] eq "route" && $ai_seq_args[0]{'failed'}) {
		System::message "Route failed\n" if $config{'debug'};
		shift @ai_seq;
		shift @ai_seq_args;
		aiRemove("move");
		aiRemove("route");
		aiRemove("route_getRoute");
		aiRemove("route_getMapRoute");

	#We're about to enter the main function, but first we gotta check a timeout.
	#If we're talking to an NPC, we do one NPC talk-step each time this function runs, then wait a second or so.
	#Its not safe to flood the NPC with requests.  Here we check that npc talk timeout, if all is good, then enter
	} elsif ($ai_seq[0] eq "route" && timeOut(\%{$timeout{'ai_route_npcTalk'}})) {
		#if we don't know the current map name, bail out and try again later.
		last ROUTE if (!$field{'name'});
		#When we request a map solution, we give a reference to our array to the map router, exit the function
		#and by the time we get back the map solution should be ready (due to the AI queue).
		#
		#If we requested a map solution and the solution came back empty, we've failed.
		#That "NPC talk - route failed" is a mistake I think, it should just be "route failed"
		if ($ai_seq_args[0]{'waitingForMapSolution'}) {
			undef $ai_seq_args[0]{'waitingForMapSolution'};
			if (!@{$ai_seq_args[0]{'mapSolution'}}) {
				System::message "NPC talk - route failed\n" if $config{'debug'};
				$ai_seq_args[0]{'failed'} = 1;
				last ROUTE;
			}
			$ai_seq_args[0]{'mapIndex'} = -1;
		}
		#If we were waiting for a position solution (not map solution) last time we exited the function...
		if ($ai_seq_args[0]{'waitingForSolution'}) {
			undef $ai_seq_args[0]{'waitingForSolution'};

			#The distFromGoal is a feature so that Kore will stay a certain distance from the
			#desired position.  If you set Kore to follow, you don't want Kore to follow directly behind you
			#but rather stay a certain distance back

			#Here we are checking if the current position solution is the final solution, we don't want to
			#"follow behind" when the position solution is to get from portal A to portal B (from a map
			#solution)
			#
			#We are at a final solution if the current map name is the destination map, and there is either no
			#map solution or we're at the last step of the map solution.
			if ($ai_seq_args[0]{'distFromGoal'} && $field{'name'} && $ai_seq_args[0]{'dest_map'} eq $field{'name'} 
			    && (!@{$ai_seq_args[0]{'mapSolution'}} || $ai_seq_args[0]{'mapIndex'} == @{$ai_seq_args[0]{'mapSolution'}} - 1)) {
				#We achieve this follow behind thing by popping off the last steps from the position solution
				for ($i = 0; $i < $ai_seq_args[0]{'distFromGoal'}; $i++) {
					pop @{$ai_seq_args[0]{'solution'}};
				}

				#Store the REAL desired position values, and replace them with the "follow behind" desired
				#position.  This is to satisfy some "are we done?" checks
				if (@{$ai_seq_args[0]{'solution'}}) {
					$ai_seq_args[0]{'dest_x_original'} = $ai_seq_args[0]{'dest_x'};
					$ai_seq_args[0]{'dest_y_original'} = $ai_seq_args[0]{'dest_y'};
					$ai_seq_args[0]{'dest_x'} = $ai_seq_args[0]{'solution'}[@{$ai_seq_args[0]{'solution'}}-1]{'x'};
					$ai_seq_args[0]{'dest_y'} = $ai_seq_args[0]{'solution'}[@{$ai_seq_args[0]{'solution'}}-1]{'y'};
				}
			}

			#Get length and time it took to get this position solution.  This is stored in a return hash,
			#and returned to functions that call ai_route.  This should really be a += not =, cuz there can
			#be multiple position solutions calculated before we come to the final solution.
			$ai_seq_args[0]{'returnHash'}{'solutionLength'} = @{$ai_seq_args[0]{'solution'}};
			$ai_seq_args[0]{'returnHash'}{'solutionTime'} = time - $ai_seq_args[0]{'time_getRoute'};

			#check if the solution length exceeds some user set length
			if ($ai_seq_args[0]{'maxRouteDistance'} && @{$ai_seq_args[0]{'solution'}} > $ai_seq_args[0]{'maxRouteDistance'}) {
				System::message "Solution length - route failed\n" if $config{'debug'};
				$ai_seq_args[0]{'failed'} = 1;
				last ROUTE;
			}

			#If we're on the desired map, and the solution failed, there may be water or a wall blocking the
			#way.  So we may have to either use portals in this map to get to the position (ie. prontera
			#sewers), or take some long route from map to map to get there. We need to do a more extensive
			#search.
			#
			#This extensive search "checkInnerPortals" means "consult the map router", it should actually
			#be the only type of search, but at the time of writing (before the DLL) it was slow, so it's 
			#a variable set by the caller.
			#
			#So, if we require a more extensive search, and we haven't already tried....
			if (!@{$ai_seq_args[0]{'solution'}} && !@{$ai_seq_args[0]{'mapSolution'}} && $ai_seq_args[0]{'dest_map'} eq $field{'name'} && $ai_seq_args[0]{'checkInnerPortals'} && !$ai_seq_args[0]{'checkInnerPortals_done'}) {
				$ai_seq_args[0]{'checkInnerPortals_done'} = 1;
				System::message "Route Logic - check inner portals done\n" if $config{'debug'};
				undef $ai_seq_args[0]{'solutionReady'};

				#Fill some vars, call the map router, and exit the function. We are now waiting for a
				#map solution
				$ai_seq_args[0]{'temp'}{'pos'}{'x'} = $ai_seq_args[0]{'dest_x'};
				$ai_seq_args[0]{'temp'}{'pos'}{'y'} = $ai_seq_args[0]{'dest_y'};
				$ai_seq_args[0]{'waitingForMapSolution'} = 1;
				ai_mapRoute_getRoute(\@{$ai_seq_args[0]{'mapSolution'}}, \%field, \%{$chars[$config{'char'}]{'pos_to'}}, \%field, \%{$ai_seq_args[0]{'temp'}{'pos'}}, $ai_seq_args[0]{'maxRouteTime'});
				last ROUTE;

			#If we already did an extensive search, and there's no solution, then we've failed
			} elsif (!@{$ai_seq_args[0]{'solution'}}) {
				System::message "No solution - route failed\n" if $config{'debug'};
				$ai_seq_args[0]{'failed'} = 1;
				last ROUTE;
			}
		}

		#If we have a map solution, and the map changed to correct next map, then clear the position solution
		#so we can calculate the next position solution (ie. from portal A to portal B) of the map solution
		#We increase the map
		if (@{$ai_seq_args[0]{'mapSolution'}} && $ai_seq_args[0]{'mapChanged'} && $field{'name'} eq $ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'dest'}{'map'}) {
			System::message "Route logic - map changed\n" if $config{'debug'};
			undef $ai_seq_args[0]{'mapChanged'};
			undef @{$ai_seq_args[0]{'solution'}};
			undef %{$ai_seq_args[0]{'last_pos'}};
			undef $ai_seq_args[0]{'index'};
			undef $ai_seq_args[0]{'npc'};
			undef $ai_seq_args[0]{'divideIndex'};
		}

		#If there's no position solution currently calculated...
		if (!@{$ai_seq_args[0]{'solution'}}) {
			#Check if we are on the final position solution - we're on the desired map, and there is either 
			#no map solution, or we're at the last step of the map solution.
			#
			#This sets the solution ready flag, which is checked at the beginning of the function
			if ($ai_seq_args[0]{'dest_map'} eq $field{'name'}
				&& (!@{$ai_seq_args[0]{'mapSolution'}} || $ai_seq_args[0]{'mapIndex'} == @{$ai_seq_args[0]{'mapSolution'}} - 1)) {
				$ai_seq_args[0]{'temp'}{'dest'}{'x'} = $ai_seq_args[0]{'dest_x'};
				$ai_seq_args[0]{'temp'}{'dest'}{'y'} = $ai_seq_args[0]{'dest_y'};
				$ai_seq_args[0]{'solutionReady'} = 1;
				undef @{$ai_seq_args[0]{'mapSolution'}};
				undef $ai_seq_args[0]{'mapIndex'};
				System::message "Route logic - solution ready\n" if $config{'debug'};
			} else {
				#We're not on the final solution, that means we need a map solution to step through.
				#If we don't have a map solution...
				if (!(@{$ai_seq_args[0]{'mapSolution'}})) {
					#Get the field data if we don't have it
					if (!%{$ai_seq_args[0]{'dest_field'}}) {
						FileParser::getField("$System::def_field/$ai_seq_args[0]{'dest_map'}.fld", \%{$ai_seq_args[0]{'dest_field'}});
					}
					#Fill some vars, call the map router, and exit this function
					$ai_seq_args[0]{'temp'}{'pos'}{'x'} = $ai_seq_args[0]{'dest_x'};
					$ai_seq_args[0]{'temp'}{'pos'}{'y'} = $ai_seq_args[0]{'dest_y'};
					$ai_seq_args[0]{'waitingForMapSolution'} = 1;
					System::message "Route logic - waiting for map solution\n" if $config{'debug'};
					ai_mapRoute_getRoute(\@{$ai_seq_args[0]{'mapSolution'}}, \%field, \%{$chars[$config{'char'}]{'pos_to'}}, \%{$ai_seq_args[0]{'dest_field'}}, \%{$ai_seq_args[0]{'temp'}{'pos'}}, $ai_seq_args[0]{'maxRouteTime'});
					last ROUTE;
				}

				#If we're here then we have a map solution ready.  The position solution is clear, that
				#usually means the map changed.
				#
				#If the current map is the next map in the map solution...
				if ($field{'name'} eq $ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'} + 1]{'source'}{'map'}) {
					#Take a step in the map solution
					$ai_seq_args[0]{'mapIndex'}++;
					#Fill our destination position for the position router
					%{$ai_seq_args[0]{'temp'}{'dest'}} = %{$ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'source'}{'pos'}};
				} else {
					#We're not at the next map, so don't take a step in the map solution.
					#This should only happen the first time we get the map solution.
					#Fill our destination for the position router
					%{$ai_seq_args[0]{'temp'}{'dest'}} = %{$ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'source'}{'pos'}};
				}
			}

			#Safety check, something is screwed up?
			if ($ai_seq_args[0]{'temp'}{'dest'}{'x'} eq "") {
				System::message "No destination - route failed\n" if $config{'debug'};
				$ai_seq_args[0]{'failed'} = 1;
				last ROUTE;
			}

			#Call the position router, exit the function.  We're now waiting for a position solution
			$ai_seq_args[0]{'waitingForSolution'} = 1;
			$ai_seq_args[0]{'time_getRoute'} = time;
			System::message "Route logic - waiting for solution\n" if $config{'debug'};
			ai_route_getRoute(\@{$ai_seq_args[0]{'solution'}}, \%field, \%{$chars[$config{'char'}]{'pos_to'}}, \%{$ai_seq_args[0]{'temp'}{'dest'}}, $ai_seq_args[0]{'maxRouteTime'});
			last ROUTE;
		}

		#If we have a map solution, are currently at the end of a position solution, and an NPC is specified
		#in the map step...
		#
		#Note that when we've completed the NPC talk steps, we do nothing until the map changes,
		#that clears the position solution, and thus we can move on to the next map step.
		if (@{$ai_seq_args[0]{'mapSolution'}} && @{$ai_seq_args[0]{'solution'}} && $ai_seq_args[0]{'index'} == @{$ai_seq_args[0]{'solution'}} - 1
		    && %{$ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}}) {
			#safety check
			if ($ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] ne "") {
				#Do one of the following, increase the talk step, exit the function and wait a few seconds
				#We'll come right back to this block after those seconds are up.
				#
				#Talk to the NPC if we haven't already
				if (!$ai_seq_args[0]{'npc'}{'sentTalk'}) {
					sendTalk(\$System::remote_socket, pack("L1",$ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}{'ID'}));
					$ai_seq_args[0]{'npc'}{'sentTalk'} = 1;
				#If the next step is a "continue" command, execute it
				} elsif ($ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /c/i) {
					sendTalkContinue(\$System::remote_socket, pack("L1",$ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}{'ID'}));
					$ai_seq_args[0]{'npc'}{'step'}++;
				#If the next step is a "cancel" command, execute it
				} elsif ($ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /n/i) {
					sendTalkCancel(\$System::remote_socket, pack("L1",$ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}{'ID'}));
					$ai_seq_args[0]{'npc'}{'step'}++;
				#If the next step is a "response" command, execute it
				} else {
					($ai_v{'temp'}{'arg'}) = $ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /r(\d+)/i;
					if ($ai_v{'temp'}{'arg'} ne "") {
						$ai_v{'temp'}{'arg'}++;
						sendTalkResponse(\$System::remote_socket, pack("L1",$ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}{'ID'}), $ai_v{'temp'}{'arg'});
					}
					$ai_seq_args[0]{'npc'}{'step'}++;
				}
				$timeout{'ai_route_npcTalk'}{'time'} = time;
				last ROUTE;
			}
		}

		#If the map has changed, and the event wasn't caught (and cleared) by any of the preceeding functions,
		#then the map change was a bad thing.  Just give up.
		if ($ai_seq_args[0]{'mapChanged'}) {
			System::message "Map changed - route failed\n" if $config{'debug'};
			$ai_seq_args[0]{'failed'} = 1;
			last ROUTE;

		#Here we check if we've changed positions, and we're off course
		#
		#If we've tried to move (almost always yes)...
		} elsif (%{$ai_seq_args[0]{'last_pos'}}
			#and our current position is not the required position by the step
			&& $chars[$config{'char'}]{'pos_to'}{'x'} != $ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'x'}
			&& $chars[$config{'char'}]{'pos_to'}{'y'} != $ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'y'}
			#and our current position has changed from the last time we were here
			&& $ai_seq_args[0]{'last_pos'}{'x'} != $chars[$config{'char'}]{'pos_to'}{'x'}
			&& $ai_seq_args[0]{'last_pos'}{'y'} != $chars[$config{'char'}]{'pos_to'}{'y'}) {

			#Then something has taken us off course, the solution is no good anymore.
			#Reset the solution, it will be recalculated next time we enter the function
			#
			#The "follow behind" feature may have altered our destination, if it did, get back the original
			if ($ai_seq_args[0]{'dest_x_original'} ne "") {
				$ai_seq_args[0]{'dest_x'} = $ai_seq_args[0]{'dest_x_original'};
				$ai_seq_args[0]{'dest_y'} = $ai_seq_args[0]{'dest_y_original'};
			}
			System::message "Route logic - last pos\n" if $config{'debug'};
			undef @{$ai_seq_args[0]{'solution'}};
			undef %{$ai_seq_args[0]{'last_pos'}};
			undef $ai_seq_args[0]{'index'};
			undef $ai_seq_args[0]{'npc'};
			undef $ai_seq_args[0]{'divideIndex'};
	
		} else {
			#We're set to take a step in the current position solution
			#We actually skip several steps at a time since the server does its own pathfinding.
			#Sometimes we may skip too many steps, and the server says "thats too far, i won't move u"
			#So we decrease the number of steps skipped until the server finally moves us.
			#
			#If we've tried to move and our position still isn't at the next step
			if ($ai_seq_args[0]{'divideIndex'} && $chars[$config{'char'}]{'pos_to'}{'x'} != $ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'x'}
				&& $chars[$config{'char'}]{'pos_to'}{'y'} != $ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'y'}) {

				#we're stuck!
				System::message "Route logic - stuck\n" if $config{'debug'};
				$ai_v{'temp'}{'index_old'} = $ai_seq_args[0]{'index'};
				$ai_seq_args[0]{'index'} -= int($config{'route_step'} / $ai_seq_args[0]{'divideIndex'});
				$ai_seq_args[0]{'index'} = 0 if ($ai_seq_args[0]{'index'} < 0);
				$ai_v{'temp'}{'index'} = $ai_seq_args[0]{'index'};
				undef $ai_v{'temp'}{'done'};

				#decrease the skip amount by a factor, make sure the new skip amount isn't the same as the
				#skip amount that didn't work
				do {
					$ai_seq_args[0]{'divideIndex'}++;
					$ai_v{'temp'}{'index'} = $ai_seq_args[0]{'index'};
					$ai_v{'temp'}{'index'} += int($config{'route_step'} / $ai_seq_args[0]{'divideIndex'});
					$ai_v{'temp'}{'index'} = @{$ai_seq_args[0]{'solution'}} - 1 if ($ai_v{'temp'}{'index'} >= @{$ai_seq_args[0]{'solution'}});
					$ai_v{'temp'}{'done'} = 1 if (int($config{'route_step'} / $ai_seq_args[0]{'divideIndex'}) == 0);
				} while ($ai_v{'temp'}{'index'} >= $ai_v{'temp'}{'index_old'} && !$ai_v{'temp'}{'done'});
			} else {
				$ai_seq_args[0]{'divideIndex'} = 1;
				System::message "Route logic - divide index = 1\n" if $config{'debug'};
				$pos_x = int($chars[$config{'char'}]{'pos_to'}{'x'}) if ($chars[$config{'char'}]{'pos_to'}{'x'} ne "");
				$pos_y = int($chars[$config{'char'}]{'pos_to'}{'y'}) if ($chars[$config{'char'}]{'pos_to'}{'y'} ne "");
				#if kore is stuck
				if (($old_pos_x == $pos_x) && ($old_pos_y == $pos_y)) {
					$route_stuck++;
				} else {
					$route_stuck = 0;
					$old_pos_x = $pos_x;
					$old_pos_y = $pos_y;
				}
				if ($route_stuck >= 50) {
					ClearRouteAI("Route failed, clearing route AI to unstuck ...\n");
					last ROUTE;
				}
				if ($route_stuck >= 80) {
					$route_stuck = 0;
					Unstuck("Route failed, trying to unstuck ...\n");
					last ROUTE;
				}	
				if ($totalStuckCount >= 10) {
					RespawnUnstuck();
					last ROUTE;
				}		
			}

			#We've tried all possible skip amounts, and the server won't move us.  Fail.
			if (int($config{'route_step'} / $ai_seq_args[0]{'divideIndex'}) == 0) {
				System::message "Route step - route failed\n" if $config{'debug'};
				$ai_seq_args[0]{'failed'} = 1;
				last ROUTE;
			}

			#Save current position for the next time we enter this function
			%{$ai_seq_args[0]{'last_pos'}} = %{$chars[$config{'char'}]{'pos_to'}};

			#Increase the step by the skip amount, and make sure that the position at the step is
			#different from our current position (should never happen really)
			do {
				$ai_seq_args[0]{'index'} += int($config{'route_step'} / $ai_seq_args[0]{'divideIndex'});
				$ai_seq_args[0]{'index'} = @{$ai_seq_args[0]{'solution'}} - 1 if ($ai_seq_args[0]{'index'} >= @{$ai_seq_args[0]{'solution'}});
			} while ($ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'x'} == $chars[$config{'char'}]{'pos_to'}{'x'}
				&& $ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'y'} == $chars[$config{'char'}]{'pos_to'}{'y'}
				&& $ai_seq_args[0]{'index'} != @{$ai_seq_args[0]{'solution'}} - 1);

			#If the avoid portals flag is set, don't move to any position that is within a distance of a portal
			#If a portal is within distance, the route will fail.
			#This is an ugly hack.  The map data should be dynamic and have an array of portals "painted" out
			#BEFORE doing A*
			if ($ai_seq_args[0]{'avoidPortals'}) {
				$ai_v{'temp'}{'first'} = 1;
				undef $ai_v{'temp'}{'foundID'};
				undef $ai_v{'temp'}{'smallDist'};
				foreach (@portalsID) {
					$ai_v{'temp'}{'dist'} = distance(\%{$ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]}, \%{$portals{$_}{'pos'}});
					if ($ai_v{'temp'}{'dist'} <= 7 && ($ai_v{'temp'}{'first'} || $ai_v{'temp'}{'dist'} < $ai_v{'temp'}{'smallDist'})) {
						$ai_v{'temp'}{'smallDist'} = $ai_v{'temp'}{'dist'};
						$ai_v{'temp'}{'foundID'} = $_;
						undef $ai_v{'temp'}{'first'};
						System::message "Route logic - portal found\n" if $config{'debug'};
					}
				}
				if ($ai_v{'temp'}{'foundID'}) {
					System::message "A portal is near - route failed\n" if $config{'debug'};
					$ai_seq_args[0]{'failed'} = 1;
					last ROUTE;
				}
			}
			#if the step position doesn't equal our current position, then move there
			if ($ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'x'} != $chars[$config{'char'}]{'pos_to'}{'x'}
				|| $ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'y'} != $chars[$config{'char'}]{'pos_to'}{'y'}) {
				move($ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'x'}, $ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'y'}, 1, $ai_seq_args[0]{'attackID'});
			}
		}
	}
	} #END OF ROUTE BLOCK



	##### ROUTE_GETROUTE #####

	if ($ai_seq[0] eq "route_getRoute" && $ai_seq_args[0]{'suspended'}) {
		$ai_seq_args[0]{'time_giveup'}{'time'} += time - $ai_seq_args[0]{'suspended'};
		undef $ai_seq_args[0]{'suspended'};
	}
	if ($ai_seq[0] eq "route_getRoute" && ($ai_seq_args[0]{'done'} || $ai_seq_args[0]{'mapChanged'}
		|| ($ai_seq_args[0]{'time_giveup'}{'timeout'} && timeOut(\%{$ai_seq_args[0]{'time_giveup'}})))) {
		$timeout{'ai_route_calcRoute_cont'}{'time'} -= $timeout{'ai_route_calcRoute_cont'}{'timeout'};
		ai_route_getRoute_destroy(\%{$ai_seq_args[0]});
		shift @ai_seq;
		shift @ai_seq_args;

	} elsif ($ai_seq[0] eq "route_getRoute" && timeOut(\%{$timeout{'ai_route_calcRoute_cont'}})) {
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
			$ai_seq_args[0]{'timeout'} = $timeout{'ai_route_calcRoute'}{'timeout'}*1000;
		}
		$ai_seq_args[0]{'init'} = 1;
		ai_route_searchStep(\%{$ai_seq_args[0]});
		$timeout{'ai_route_calcRoute_cont'}{'time'} = time;
		ai_setSuspend(0);
	}

	##### ROUTE_GETMAPROUTE #####

	ROUTE_GETMAPROUTE: {

	if ($ai_seq[0] eq "route_getMapRoute" && $ai_seq_args[0]{'suspended'}) {
		$ai_seq_args[0]{'time_giveup'}{'time'} += time - $ai_seq_args[0]{'suspended'};
		undef $ai_seq_args[0]{'suspended'};
	}
	if ($ai_seq[0] eq "route_getMapRoute" && ($ai_seq_args[0]{'done'} || $ai_seq_args[0]{'mapChanged'}
		|| ($ai_seq_args[0]{'time_giveup'}{'timeout'} && timeOut(\%{$ai_seq_args[0]{'time_giveup'}})))) {
		$timeout{'ai_route_calcRoute_cont'}{'time'} -= $timeout{'ai_route_calcRoute_cont'}{'timeout'};
		shift @ai_seq;
		shift @ai_seq_args;

	} elsif ($ai_seq[0] eq "route_getMapRoute" && timeOut(\%{$timeout{'ai_route_calcRoute_cont'}})) {
		if (!%{$ai_seq_args[0]{'start'}}) {
			%{$ai_seq_args[0]{'start'}{'dest'}{'pos'}} = %{$ai_seq_args[0]{'r_start_pos'}};
			$ai_seq_args[0]{'start'}{'dest'}{'map'} = $ai_seq_args[0]{'r_start_field'}{'name'};
			$ai_seq_args[0]{'start'}{'dest'}{'field'} = $ai_seq_args[0]{'r_start_field'};
			%{$ai_seq_args[0]{'dest'}{'source'}{'pos'}} = %{$ai_seq_args[0]{'r_dest_pos'}};
			$ai_seq_args[0]{'dest'}{'source'}{'map'} = $ai_seq_args[0]{'r_dest_field'}{'name'};
			$ai_seq_args[0]{'dest'}{'source'}{'field'} = $ai_seq_args[0]{'r_dest_field'};
			push @{$ai_seq_args[0]{'openList'}}, \%{$ai_seq_args[0]{'start'}};
		}
		$timeout{'ai_route_calcRoute'}{'time'} = time;
		while (!$ai_seq_args[0]{'done'} && !timeOut(\%{$timeout{'ai_route_calcRoute'}})) {
			ai_mapRoute_searchStep(\%{$ai_seq_args[0]});
			last ROUTE_GETMAPROUTE if ($ai_seq[0] ne "route_getMapRoute");
		}

		if ($ai_seq_args[0]{'done'}) {
			@{$ai_seq_args[0]{'returnArray'}} = @{$ai_seq_args[0]{'solutionList'}};
		}
		$timeout{'ai_route_calcRoute_cont'}{'time'} = time;
		ai_setSuspend(0);
	}

	} #End of block ROUTE_GETMAPROUTE


	##### ITEMS TAKE #####


	if ($ai_seq[0] eq "items_take" && $ai_seq_args[0]{'suspended'}) {
		$ai_seq_args[0]{'ai_items_take_start'}{'time'} += time - $ai_seq_args[0]{'suspended'};
		$ai_seq_args[0]{'ai_items_take_end'}{'time'} += time - $ai_seq_args[0]{'suspended'};
		undef $ai_seq_args[0]{'suspended'};
	}
#mod Start
# on route storageAuto occur attack aggressive monster -> take it item !!
	if ($ai_seq[0] eq "items_take"
		&& ($chars[$config{'char'}]{'percent_weight'} >= $config{'itemsMaxWeight'} || $chars[$config{'char'}]{'percent_weight'} >=89)
		&& !$config{'itemsGreedyMode'}
		){
#mod Stop
		shift @ai_seq;
		shift @ai_seq_args;
		ai_clientSuspend(0, $timeout{'ai_attack_waitAfterKill'}{'timeout'}) if (!ai_getAggressives());
	}
	if ($config{'itemsTakeAuto'} && $ai_seq[0] eq "items_take" && timeOut(\%{$ai_seq_args[0]{'ai_items_take_start'}})) {
		undef $ai_v{'temp'}{'foundID'};
		foreach (@itemsID) {
			next if ($_ eq "" || $itemsPickup{lc($items{$_}{name})} eq "0"
						|| $itemsPickup{lc($items{$_}{name})} == -1
						|| (!$itemsPickup{all} && !$itemsPickup{lc($items{$_}{name})})
						);
			$ai_v{'temp'}{'dist'} = distance(\%{$items{$_}{'pos'}}, \%{$ai_seq_args[0]{'pos'}});
			$ai_v{'temp'}{'dist_to'} = distance(\%{$items{$_}{'pos'}}, \%{$ai_seq_args[0]{'pos_to'}});
			if (($ai_v{'temp'}{'dist'} <= 4 || $ai_v{'temp'}{'dist_to'} <= 4) && $items{$_}{'take_failed'} == 0) {
				$ai_v{'temp'}{'foundID'} = $_;
				last;
			}
		}
		if ($ai_v{'temp'}{'foundID'}) {
			$ai_seq_args[0]{'ai_items_take_end'}{'time'} = time;
			$ai_seq_args[0]{'started'} = 1;
			take($ai_v{'temp'}{'foundID'});
		} elsif ($ai_seq_args[0]{'started'} || $ai_seq_args[0]{'notFound'}>=2 || timeOut(\%{$ai_seq_args[0]{'ai_items_take_end'}})) {
			shift @ai_seq;
			shift @ai_seq_args;
			ai_clientSuspend(0, $timeout{'ai_attack_waitAfterKill'}{'timeout'}) if (!ai_getAggressives());
		} else {
			$ai_seq_args[0]{'notFound'}++;
		}
	}



	##### ITEMS AUTO-GATHER #####


	if (($ai_seq[0] eq "" || $ai_seq[0] eq "follow" || $ai_seq[0] eq "route" || $ai_seq[0] eq "route_getRoute" || $ai_seq[0] eq "route_getMapRoute") && $config{'itemsGatherAuto'} && !($chars[$config{'char'}]{'percent_weight'} >= $config{'itemsMaxWeight'}) && timeOut(\%{$timeout{'ai_items_gather_auto'}})) {
		undef @{$ai_v{'ai_items_gather_foundIDs'}};
		foreach (@playersID) {
			next if ($_ eq "");
			if (!%{$chars[$config{'char'}]{'party'}} || !%{$chars[$config{'char'}]{'party'}{'users'}{$_}}) {
				push @{$ai_v{'ai_items_gather_foundIDs'}}, $_;
			}
		}
		foreach $item (@itemsID) {
			next if ($item eq ""
				|| time - $items{$item}{appear_time} < $timeout{ai_items_gather_start}{timeout}
				|| $items{$item}{take_failed} >= 1
				|| $itemsPickup{lc($items{$item}{name})} eq "0" || $itemsPickup{lc($items{$item}{name})} == -1 || (!$itemsPickup{all} && !$itemsPickup{lc($items{$item}{name})}));
			undef $ai_v{'temp'}{'dist'};
			undef $ai_v{'temp'}{'found'};
			foreach (@{$ai_v{'ai_items_gather_foundIDs'}}) {
				$ai_v{'temp'}{'dist'} = distance(\%{$items{$item}{'pos'}}, \%{$players{$_}{'pos_to'}});
				if ($ai_v{'temp'}{'dist'} < 9) {
					$ai_v{'temp'}{'found'} = 1;
					last;
				}
			}
			if ($ai_v{'temp'}{'found'} == 0) {
				gather($item);
				last;
			}
		}
		$timeout{'ai_items_gather_auto'}{'time'} = time;
	}



	##### ITEMS GATHER #####


	if ($ai_seq[0] eq "items_gather" && $ai_seq_args[0]{'suspended'}) {
		$ai_seq_args[0]{'ai_items_gather_giveup'}{'time'} += time - $ai_seq_args[0]{'suspended'};
		undef $ai_seq_args[0]{'suspended'};
	}
	if ($ai_seq[0] eq "items_gather" && !%{$items{$ai_seq_args[0]{'ID'}}}) {
		System::message "Failed to gather $items_old{$ai_seq_args[0]{'ID'}}{'name'} ($items_old{$ai_seq_args[0]{'ID'}}{'binID'}) : Lost target\n";
		injectMessage("Failed to gather $items_old{$ai_seq_args[0]{'ID'}}{'name'} ($items_old{$ai_seq_args[0]{'ID'}}{'binID'}) : Lost target") if ($config{'verbose'} && $System::xMode);
		shift @ai_seq;
		shift @ai_seq_args;
	} elsif ($ai_seq[0] eq "items_gather") {
		undef $ai_v{'temp'}{'dist'};
		undef @{$ai_v{'ai_items_gather_foundIDs'}};
		undef $ai_v{'temp'}{'found'};
		foreach (@playersID) {
			next if ($_ eq "");
			if (%{$chars[$config{'char'}]{'party'}} && !%{$chars[$config{'char'}]{'party'}{'users'}{$_}}) {
				push @{$ai_v{'ai_items_gather_foundIDs'}}, $_;
			}
		}
		foreach (@{$ai_v{'ai_items_gather_foundIDs'}}) {
			$ai_v{'temp'}{'dist'} = distance(\%{$items{$ai_seq_args[0]{'ID'}}{'pos'}}, \%{$players{$_}{'pos'}});
			if ($ai_v{'temp'}{'dist'} < 9) {
				$ai_v{'temp'}{'found'}++;
			}
		}
		$ai_v{'temp'}{'dist'} = distance(\%{$items{$ai_seq_args[0]{'ID'}}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
		if (timeOut(\%{$ai_seq_args[0]{'ai_items_gather_giveup'}})) {
			System::message "Failed to gather $items{$ai_seq_args[0]{'ID'}}{'name'} ($items{$ai_seq_args[0]{'ID'}}{'binID'}) : Timeout\n";
			injectMessage("Failed to gather $items{$ai_seq_args[0]{'ID'}}{'name'} ($items{$ai_seq_args[0]{'ID'}}{'binID'}) : Timeout") if ($config{'verbose'} && $System::xMode);
			$items{$ai_seq_args[0]{'ID'}}{'take_failed'}++;
			shift @ai_seq;
			shift @ai_seq_args;
		} elsif ($chars[$config{'char'}]{'sitting'}) {
			ai_setSuspend(0);
			stand();
		} elsif ($ai_v{'temp'}{'found'} == 0 && $ai_v{'temp'}{'dist'} > 2) {
			getVector(\%{$ai_v{'temp'}{'vec'}}, \%{$items{$ai_seq_args[0]{'ID'}}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
			moveAlongVector(\%{$ai_v{'temp'}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}}, \%{$ai_v{'temp'}{'vec'}}, $ai_v{'temp'}{'dist'} - 1);
			move($ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'});
		} elsif ($ai_v{'temp'}{'found'} == 0) {
			$ai_v{'ai_items_gather_ID'} = $ai_seq_args[0]{'ID'};
			shift @ai_seq;
			shift @ai_seq_args;
			take($ai_v{'ai_items_gather_ID'});
		} elsif ($ai_v{'temp'}{'found'} > 0) {
			if ($System::xMode) {
				System::message "Failed to gather $items{$ai_seq_args[0]{'ID'}}{'name'} ($items{$ai_seq_args[0]{'ID'}}{'binID'}) : No looting!\n";
			} else {
				injectMessage("Failed to gather $items{$ai_seq_args[0]{'ID'}}{'name'} ($items{$ai_seq_args[0]{'ID'}}{'binID'}) : No looting!") if ($config{'verbose'} && $System::xMode);
			}
			shift @ai_seq;
			shift @ai_seq_args;
		}
	}



	##### TAKE #####


	if ($ai_seq[0] eq "take" && $ai_seq_args[0]{'suspended'}) {
		$ai_seq_args[0]{'ai_take_giveup'}{'time'} += time - $ai_seq_args[0]{'suspended'};
		undef $ai_seq_args[0]{'suspended'};
	}
	if ($ai_seq[0] eq "take" && !%{$items{$ai_seq_args[0]{'ID'}}}) {
		shift @ai_seq;
		shift @ai_seq_args;
	} elsif ($ai_seq[0] eq "take" && timeOut(\%{$ai_seq_args[0]{'ai_take_giveup'}})) {
		System::message "Failed to take $items{$ai_seq_args[0]{'ID'}}{'name'} ($items{$ai_seq_args[0]{'ID'}}{'binID'})\n";
		injectMessage("Failed to take $items{$ai_seq_args[0]{'ID'}}{'name'} ($items{$ai_seq_args[0]{'ID'}}{'binID'})") if ($config{'verbose'} && $System::xMode);
		$items{$ai_seq_args[0]{'ID'}}{'take_failed'}++;
		shift @ai_seq;
		shift @ai_seq_args;
	} elsif ($ai_seq[0] eq "take") {

		$ai_v{'temp'}{'dist'} = distance(\%{$items{$ai_seq_args[0]{'ID'}}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
		if ($chars[$config{'char'}]{'sitting'}) {
			stand();
		} elsif ($ai_v{'temp'}{'dist'} > 2) {
			getVector(\%{$ai_v{'temp'}{'vec'}}, \%{$items{$ai_seq_args[0]{'ID'}}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
			moveAlongVector(\%{$ai_v{'temp'}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}}, \%{$ai_v{'temp'}{'vec'}}, $ai_v{'temp'}{'dist'} - 1);
			move($ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'});
		} elsif (timeOut(\%{$timeout{'ai_take'}})) {
			changeDirection(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$items{$ai_seq_args[0]{'ID'}}{'pos'}});
			sendTake(\$System::remote_socket, $ai_seq_args[0]{'ID'});
			$timeout{'ai_take'}{'time'} = time;
		}
	}

	
	##### MOVE #####


	if ($ai_seq[0] eq "move" && $ai_seq_args[0]{'suspended'}) {
		$ai_seq_args[0]{'ai_move_giveup'}{'time'} += time - $ai_seq_args[0]{'suspended'};
		undef $ai_seq_args[0]{'suspended'};
	}
	if ($ai_seq[0] eq "move") {
		if (!$ai_seq_args[0]{'ai_moved'} && $ai_seq_args[0]{'ai_moved_tried'} && $ai_seq_args[0]{'ai_move_time_last'} != $chars[$config{'char'}]{'time_move'}) {
			$ai_seq_args[0]{'ai_moved'} = 1;
		}
		if ($chars[$config{'char'}]{'sitting'}) {
			ai_setSuspend(0);
			stand();
		} elsif (!$ai_seq_args[0]{'ai_moved'} && timeOut(\%{$ai_seq_args[0]{'ai_move_giveup'}})) {
			shift @ai_seq;
			shift @ai_seq_args;
		} elsif (!$ai_seq_args[0]{'ai_moved_tried'}) {
			sendMove(\$System::remote_socket, int($ai_seq_args[0]{'move_to'}{'x'}), int($ai_seq_args[0]{'move_to'}{'y'}));
			$ai_seq_args[0]{'ai_move_giveup'}{'time'} = time;
			$ai_seq_args[0]{'ai_move_time_last'} = $chars[$config{'char'}]{'time_move'};
			$ai_seq_args[0]{'ai_moved_tried'} = 1;
		} elsif ($ai_seq_args[0]{'ai_moved'} && time - $chars[$config{'char'}]{'time_move'} >= $chars[$config{'char'}]{'time_move_calc'}) {
			shift @ai_seq;
			shift @ai_seq_args;
		}
	}



	##### AUTO-TELEPORT #####

	($ai_v{'map_name_lu'}) = $map_name =~ /([\s\S]*)\./;
	$ai_v{'map_name_lu'} .= ".rsw";
	if ($config{'teleportAuto_onlyWhenSafe'} && binSize(\@playersID)) {
		undef $ai_v{'ai_teleport_safe'};
		if (!$cities_lut{$ai_v{'map_name_lu'}} && timeOut(\%{$timeout{'ai_teleport_safe_force'}})) {
			$ai_v{'ai_teleport_safe'} = 1;
		}
	} elsif (!$cities_lut{$ai_v{'map_name_lu'}}) {
		$ai_v{'ai_teleport_safe'} = 1;
		$timeout{'ai_teleport_safe_force'}{'time'} = time;
	} else {
		undef $ai_v{'ai_teleport_safe'};
	}

	if (timeOut(\%{$timeout{'ai_teleport_away'}}) && $ai_v{'ai_teleport_safe'}) {
		foreach (@monstersID) {
			next if ($_ eq "");
			if ($mon_control{lc($monsters{$_}{'name'})}{'monitor_auto'} 
				&& ($monsters{$_}{'monitor_pos'}{'x'} != $monsters{$_}{'pos'}{'x'})
				&& ($monsters{$_}{'monitor_pos'}{'y'} != $monsters{$_}{'pos'}{'y'})
				) {
				my $text = "Found Monster $monsters{$_}{'name'} at ($monsters{$_}{'pos'}{'x'},$monsters{$_}{'pos'}{'y'})";
				$monsters{$_}{'monitor_pos'}{'x'} = $monsters{$_}{'pos'}{'x'};
				$monsters{$_}{'monitor_pos'}{'y'} = $monsters{$_}{'pos'}{'y'};
				System::message "[Alert] $text\n";
				sendMessage(\$System::remote_socket, "p", $text) if (%{$chars[$config{'char'}]{'party'}});
				foreach (keys %overallAuth) {
					sendMessage(\$System::remote_socket, "pm", $text,$_);
				}
			}
			my $found = 0;
			if ($mon_control{lc($monsters{$_}{'name'})}{'teleport_auto'}==1) {
				$found = 1;
				System::message "[Act] Avoiding monster : $monsters{$_}{'name'}\n";
			}elsif ($mon_control{lc($monsters{$_}{'name'})}{'teleport_auto'} =~ /^d/){
				my ($avoid_dist) = $mon_control{lc($monsters{$_}{'name'})}{'teleport_auto'} =~ /^d(\d+)/;
				my $dist = int(distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$_}{'pos_to'}}));
				$found = 1 if ($dist <= $avoid_dist);
				System::message "[Act] Avoiding monster : $monsters{$_}{'name'} to close than $avoid_dist ($dist)\n";
			}
			if ($found) {
				useTeleport(1);
				$ai_v{'temp'}{'search'} = 1;
				last;
			}
		}
		$timeout{'ai_teleport_away'}{'time'} = time;
	}

	if ((($config{'teleportAuto_hp'} && $chars[$config{'char'}]{'percent_hp'} <= $config{'teleportAuto_hp'} && ai_getAggressives())
		|| ($config{'teleportAuto_minAggressives'} && scalar(ai_getAggressives()) >= $config{'teleportAuto_minAggressives'})
		)&& $ai_v{'ai_teleport_safe'} && timeOut(\%{$timeout{'ai_teleport_hp'}})
		){
		if ($config{'teleportAuto_hp'} && $chars[$config{'char'}]{'percent_hp'} <= $config{'teleportAuto_hp'}) {
			System::message "[Act] Teleport : Hp is lower than $config{'teleportAuto_hp'} ($chars[$config{'char'}]{'percent_hp'})\n";
		}else{
			System::message "[Act] Teleport : Aggressive is more than $config{'teleportAuto_minAggressives'} (".scalar(ai_getAggressives()).")\n";
		}
		useTeleport(1);
		$ai_v{'clear_aiQueue'} = 1;
		$timeout{'ai_teleport_hp'}{'time'} = time;
	}

#teleport Search - Kladi improve
	if ($config{'teleportAuto_search'} && !$ai_v{'useSelf_skill'} && $ai_v{'ai_teleport_safe'} && timeOut(\%{$timeout{'ai_teleport_search'}}) 
		&& binFind(\@ai_seq, "attack") eq "" && binFind(\@ai_seq, "items_take") eq "" && binFind(\@ai_seq, "sitAuto") eq "" 
		&& binFind(\@ai_seq, "storageAuto") eq "" && binFind(\@ai_seq, "sellAuto") eq "" && binFind(\@ai_seq, "buyAuto") eq "" 
		&& ($field{'name'} eq $config{"lockMap_$ai_v{'lockMapIndex'}"} || $config{"lockMap_$ai_v{'lockMapIndex'}"} eq "")
		&& $ai_v{'ai_teleport_safe'}
		){
		undef $ai_v{'temp'}{'search'};
		foreach (keys %mon_control) {
			if ($mon_control{$_}{'teleport_search'}) {
				$ai_v{'temp'}{'search'} = 1;
				last;
			}
		}
		if ($ai_v{'temp'}{'search'}) {
			undef $ai_v{'temp'}{'found'};
			foreach (@monstersID) {
				next if ($_ eq "");
				if ($mon_control{lc($monsters{$_}{'name'})}{'teleport_search'} && !$monsters{$_}{'attack_failed'}) {
					$ai_v{'temp'}{'found'} = 1;
					last;
				}
			}

			# Teleport Search
			if (!$ai_v{'temp'}{'found'}) {
				useTeleport(1);
				$ai_v{'clear_aiQueue'} = 1;
			}

		}
		$timeout{'ai_teleport_search'}{'time'} = time;
	}

	if ($config{'teleportAuto_idle'} && $ai_seq[0] ne "") {
		$timeout{'ai_teleport_idle'}{'time'} = time;
	}

	if ($config{'teleportAuto_idle'} && timeOut(\%{$timeout{'ai_teleport_idle'}}) && $ai_v{'ai_teleport_safe'}) {
		useTeleport($config{'teleportAuto_idle'});
		$ai_v{'clear_aiQueue'} = 1;
		$timeout{'ai_teleport_idle'}{'time'} = time;
	}

	# avoid portal in lockMap
	if ($config{'teleportAuto_portal'} && timeOut(\%{$timeout{'ai_teleport_portal'}}) && $ai_v{'ai_teleport_safe'}
	   &&($field{'name'} eq $config{"lockMap_$ai_v{'lockMapIndex'}"} || $config{"lockMap_$ai_v{'lockMapIndex'}"} eq "")) {
		if (binSize(\@portalsID)) {
			useTeleport(1);
			$ai_v{'clear_aiQueue'} = 1;
		}
		$timeout{'ai_teleport_portal'}{'time'} = time;
	}


	##### RESPONSE-AUTO #####

	if ($ai_seq[0] eq "chatauto" && timeOut(\%{$ai_seq_args[0]})){
		if ($ai_seq_args[0]{'ans'} =~ /^e \d+/) {
			($arg1) = $ai_seq_args[0]{'ans'} =~ /[\s\S+] (\d+)/;
			sendEmotion(\$System::remote_socket, $arg1);
		}elsif ($ai_seq_args[0]{'type'} eq "pm") {
			sendMessage(\$System::remote_socket, "pm", $ai_seq_args[0]{'ans'},$ai_seq_args[0]{'name'});
		}else {
			sendMessage(\$System::remote_socket, "c", $ai_seq_args[0]{'ans'});
		}
		shift @ai_seq;
		shift @ai_seq_args;
	}

	##### Q' pet ####

	if (%{$chars[$config{'char'}]{'pet'}}){
		if (!$timeout{'ai_petPlay'}{'time'} && $config{'petAutoPlay'}){
			$timeout{'ai_petPlay'}{'time'}=time;
		}elsif (timeOut(\%{$timeout{'ai_petPlay'}}) && $config{'petAutoPlay'}){
			sendPetCommand(\$System::remote_socket,2);
			$timeout{'ai_petPlay'}{'time'}=time;
			System::message "Auto Play pet\n";
		}
	}
	

	##### AUTO-CART #####

	if ($chars[$config{'char'}]{'cart'} && timeOut(\%{$timeout{'ai_cartAuto'}})) {
		foreach my $key (keys %cart_control) {
			my $invIndex = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $key);
			next if ($invIndex eq "" && !$cart_control{$key}{'getAuto'} && !$cart_control{$key}{'keep'});
			my $cartIndex = findIndexString_lc(\@{$cart{'inventory'}}, "name", $key);
			if ($cartIndex ne "") {
				my $amount;
				if ($invIndex ne "" && $chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} < $cart_control{$key}{'keep'}) {
					$amount = $cart_control{$key}{'keep'} - $chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'};
				}elsif ($invIndex eq ""){
					$amount = $cart_control{$key}{'keep'};
				}
				if ($amount > $cart{'inventory'}[$cartIndex]{'amount'}) {
					$amount = $cart{'inventory'}[$cartIndex]{'amount'};
				}
				sendCartGetToInv(\$System::remote_socket, $cartIndex, $amount);
			}
		}
		$timeout{'ai_cartAuto'}{'time'} = time;
	}

	##### Auto-Speak #####

	if (!$timeout{'ai_AutoSpeak'}{'time'} && $config{'autoSpeak'}) {
		
	}elsif (timeOut(\%{$timeout{'ai_AutoSpeak'}}) && $config{'autoSpeak'}) {
		if (!$config{'autoSpeak_inLockOnly'} || ($config{'autoSpeak_inLockOnly'} && $field{'name'} eq $config{"lockMap_$ai_v{'lockMapIndex'}"})){
			$arg = getResMsg("/autospeak");
			if ($arg ne "") {
				if ($arg =~ /^e \d+/) {
					($arg1) = $arg =~ /[\s\S+] (\d+)/;
					sendEmotion(\$System::remote_socket, $arg1);
				}else {
					sendMessage(\$System::remote_socket, "c", $arg);
				}
			}
			undef $timeout{'ai_AutoSpeak'}{'time'};
		}else{
			$timeout{'ai_AutoSpeak'}{'time'} = time;
		}
	}

	##### Avoid State #####

	if ($ai_seq[0] eq "avoid") {
		if (!defined($ai_seq_args[0]{'type'})) {
			my $is_found = 0;
			foreach (@playersID) {
				if (existsInPatternList($config{'avoid_namePattern'},$players{$_}{'name'}) || $GameMasters{$_}) {
					$is_found = 1;
					last;
				}
			}
			if (!$is_found) {
				shift @ai_seq;
				shift @ai_seq_args;
			}
		}elsif (defined($ai_seq_args[0]{'type'}) && ($ai_seq_args[0]{'map'} ne $field{'name'}  || $field{'name'} eq $config{'saveMap'})){
			System::message "[Act] Teleport/Respawn Success .. Quit ..\n","danger",1,"D";
			$timeout_ex{'master'}{'time'} = time;
			$timeout_ex{'master'}{'timeout'} = $config{'avoid_reConnect'};
			killConnection(\$System::remote_socket,1);
		}
	}

	if (timeOut(\%{$timeout{'ai_avoidcheck'}})) {
#avoiding players
		foreach (@playersID) {
			next if ($_ eq "");
			#ACT - teleport
			if ($ppl_control{$players{$_}{'name'}}{'teleport_auto'} || $gid_control{$_}{'teleport_auto'}
				|| ((existsInPatternList($config{'avoid_namePattern'},$players{$_}{'name'})|| $GameMasters{$_}) && $config{'avoidGM'})
				 && timeOut(\%{$timeout{'ai_teleport_away'}}) && $ai_v{'ai_teleport_safe'} && binFind(\@ai_seq, "avoid") eq "") {
				my $dis = (defined(%{$players{$_}{'pos_to'}})) ? int(distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$players{$_}{'pos_to'}})) : int(distance(\%{$chars[$config{'char'}]{'pos'}}, \%{$players{$_}{'pos'}}));
				my %args;
				#teleport by ppl 
				if ($ppl_control{$players{$_}{'name'}}{'teleport_auto'}){
					useTeleport($ppl_control{$players{$_}{'name'}}{'teleport_auto'});
					#argument for shifting state to avoid State
					if ($ppl_control{$players{$_}{'name'}}{'disconnect_auto'}) {
						$args{'type'} = $ppl_control{$players{$_}{'name'}}{'teleport_auto'};
						$args{'map'} = ($args{'type'}==2) ? $field{'name'}:"";
					}
				#teleport by gid 
				}elsif ($gid_control{$_}{'teleport_auto'}) {
					useTeleport($gid_control{$_}{'teleport_auto'});
					#argument for shifting state to avoid State
					if ($gid_control{$_}{'disconnect_auto'}) {
						$args{'type'} = $ppl_control{$players{$_}{'name'}}{'teleport_auto'};
						$args{'map'} = ($args{'type'}==2) ? $field{'name'}:"";
					}
				#teleport by avoidGM
				}elsif ($config{'avoidGM'}<3) {
					useTeleport($config{'avoidGM'});
					#argument for shifting state to avoid State
					$args{'type'} = $config{'avoidGM'};
					$args{'map'} = ($args{'type'}==2) ? $field{'name'}:"";
				}
				$timeout{'ai_teleport_away'}{'time'} = time;
				#when want teleport & disconnect , for disconnect combo -> shift to avoid state
				if ($ppl_control{$players{$_}{'name'}}{'disconnect_auto'} || $gid_control{$_}{'disconnect_auto'} || $config{'avoidGM'}){
					undef $ai_v{'clear_aiQueue'};
					undef @ai_seq;
					undef @ai_seq_args;
					unshift @ai_seq, "avoid";
					unshift @ai_seq_args, {%args};
				}
				System::message "[Act] Avoiding $players{$_}{'name'} ($players{$_}{'nameID'}) Distance: $dis , use teleport lv $args{'type'}\n","danger",1,"D";
				last if ((%{$ppl_control{$players{$_}{'name'}}} && !$ppl_control{$players{$_}{'name'}}{'disconnect_auto'})
							||(%{$gid_control{$_}} && !$gid_control{$_}{'disconnect_auto'}));
			}
			#ACT - disconnect
			if ($ppl_control{$players{$_}{'name'}}{'disconnect_auto'} || $gid_control{$_}{'disconnect_auto'}
				||((existsInPatternList($config{'avoid_namePattern'},$players{$_}{'name'}) || $GameMasters{$_}) && $config{'avoidGM'}==3)
				&& binFind(\@ai_seq, "avoid") eq "") {
				my $dis = int(distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$players{$_}{'pos_to'}}));
				System::message "[Act] Avoiding $players{$_}{'name'} ($players{$_}{'nameID'}) Distance: $dis , Disconnect...\n","danger",1,"D";
				$timeout_ex{'master'}{'time'} = time;
				$timeout_ex{'master'}{'timeout'} = $config{'avoid_reConnect'};
				killConnection(\$System::remote_socket,1);
				last;
			}
			#ACT - Stand Still
			if ($config{'avoidGM'}==4 && (existsInPatternList($config{'avoid_namePattern'},$players{$_}{'name'})|| $GameMasters{$_}) &&  binFind(\@ai_seq, "avoid") eq "") {
				my $dis = int(distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$players{$_}{'pos_to'}}));
				System::message "[Act] Avoiding $players{$_}{'name'} ($players{$_}{'nameID'}) Distance: $dist , Stand Still ...\n","danger",1,"D";
				unshift @ai_seq, "avoid";
				unshift @ai_seq_args, {};
			}
			#Exclusive Avoid
			if ($config{'exclusive_Avoid'}==1 && !$cities_lut{$field{'name'}.'.rsw'} && ($field{'name'} eq $config{"lockMap_$ai_v{'lockMapIndex'}"} || $config{"lockMap_$ai_v{'lockMapIndex'}"} eq "")
				&& ($players{$_}{'jobID'}==4 || $players{$_}{'jobID'}==8 || $players{$_}{'jobID'}==15)) {
				System::message "[Act] Force Exclusive Avoid : $players{$_}{'name'} ($players{$_}{'nameID'}) [$jobs_lut[$players{$_}{'jobID'}]]\n","danger",1,"D";
				useTeleport(1);
				$ai_v{'clear_aiQueue'} = 1;
				last;
			}elsif ($config{'exclusive_Avoid'}==2 && !$cities_lut{$field{'name'}.'.rsw'} && ($field{'name'} eq $config{"lockMap_$ai_v{'lockMapIndex'}"} || $config{"lockMap_$ai_v{'lockMapIndex'}"} eq "")){
				useTeleport(1);
				$ai_v{'clear_aiQueue'} = 1;
				last;
			}
		}
		$timeout{'ai_avoidcheck'}{'time'} = time;
	}

	if ($config{'cureAuto'} && timeOut(\%{$timeout{'ai_autocure'}})) {
		if ($chars[$config{'char'}]{'status'} == 1) {
			if ($chars[$config{'char'}]{'skills'}{'TF_DETOXIFY'}{'lv'}) {
				System::message "Auto-Cure Poison use Skill : Detoxify\n";
				ai_skillUse($chars[$config{'char'}]{'skills'}{'TF_DETOXIFY'}{'ID'}, 1, 0,0, $accountID);
			}else{
				undef $ai_v{'temp'}{'invIndex'}; 
				$ai_v{'temp'}{'invIndex'} = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "nameID", 511);
				$ai_v{'temp'}{'invIndex'} = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "nameID", 506) if ($ai_v{'temp'}{'invIndex'} eq "");
				$ai_v{'temp'}{'invIndex'} = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "nameID", 525) if ($ai_v{'temp'}{'invIndex'} eq "");
				if ($ai_v{'temp'}{'invIndex'} ne "") { 
					System::message "Auto-Cure Poison use item : $items_lut{$chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'nameID'}}\n";
					sendItemUse(\$System::remote_socket, $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'index'}, $accountID); 
				}else{
					System::message "No item to Auto-Cure Poison\n";
				}
			}
		}elsif ($chars[$config{'char'}]{'status'} == 4 || $chars[$config{'char'}]{'status'} == 16){
			my $text = ($chars[$config{'char'}]{'status'}==4) ? "Slept" : "Blind";
			undef $ai_v{'temp'}{'invIndex'}; 
			$ai_v{'temp'}{'invIndex'} = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "nameID", 506);
			if ($ai_v{'temp'}{'invIndex'} ne "") {
				System::message "Auto-Cure $text use item : $items_lut{$chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'nameID'}}\n";
				sendItemUse(\$System::remote_socket, $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'index'}, $accountID); 
			}else{
				System::message "No item to Auto-Cure $text\n";
			}
		}
		$timeout{'ai_autocure'}{'time'} = time;
	}

	##########

	#DEBUG CODE
	if (time - $ai_v{'time'} > 2 && $config{'debug_ai'}) {
		$stuff = @ai_seq_args;
		System::message "AI: @ai_seq | $stuff\n";
		$ai_v{'time'} = time;
	}


	if ($ai_v{'clear_aiQueue'}) {
		undef $ai_v{'clear_aiQueue'};
		undef @ai_seq;
		undef @ai_seq_args;
	}
	
}


#######################################
#######################################
#AI FUNCTIONS
#######################################
#######################################

sub ai_clientSuspend {
	my ($type,$initTimeout,@args) = @_;
	my %args;
	$args{'type'} = $type;
	$args{'time'} = time;
	$args{'timeout'} = $initTimeout;
	@{$args{'args'}} = @args;
	unshift @ai_seq, "clientSuspend";
	unshift @ai_seq_args, \%args;
}

sub ai_follow {
	my $name = shift;
	my %args;
	$args{'name'} = $name; 
	unshift @ai_seq, "follow";
	unshift @ai_seq_args, \%args;
}

sub ai_getAggressives {
	my $type = shift;
	my @agMonsters;
	foreach (@monstersID) {
		next if ($_ eq "");
		if ((($type && $mon_control{lc($monsters{$_}{'name'})}{'aggressive_auto'}) 
			|| ($monsters{$_}{'dmgToYou'} > 0 || $monsters{$_}{'missedYou'} > 0))
			 && $monsters{$_}{'attack_failed'} <= 1) {
			push @agMonsters, $_;
		}
	}
	return @agMonsters;
}

sub ai_getIDFromChat {
	my $r_hash = shift;
	my $msg_user = shift;
	my $match_text = shift;
	my $qm;
	if ($match_text !~ /\w+/ || $match_text eq "me") {
		foreach (keys %{$r_hash}) {
			next if ($_ eq "");
			if ($msg_user eq $$r_hash{$_}{'name'}) {
				return $_;
			}
		}
	} else {
		foreach (keys %{$r_hash}) {
			next if ($_ eq "");
			$qm = quotemeta $match_text;
			if ($$r_hash{$_}{'name'} =~ /$qm/i) {
				return $_;
			}
		}
	}
}

sub ai_getMonstersWhoHitMe {
	my @agMonsters;
	foreach (@monstersID) {
		next if ($_ eq "");
		if ($monsters{$_}{'dmgToYou'} > 0 && $monsters{$_}{'attack_failed'} <= 1) {
			push @agMonsters, $_;
		}
	}
	return @agMonsters;
}

# Skill Type Fix
sub ai_getSkillUseType {
	my $skill = shift;
	if ($skill eq "WZ_FIREPILLAR" || $skill eq "WZ_METEOR"
		|| $skill eq "WZ_VERMILION" || $skill eq "WZ_STORMGUST"
		|| $skill eq "WZ_HEAVENDRIVE" || $skill eq "WZ_QUAGMIRE" 
		|| $skill eq "MG_SAFETYWALL" || $skill eq "MG_FIREWALL"
		|| $skill eq "MG_THUNDERSTORM" || $skill eq "AL_PNEUMA"
		|| $skill eq "AL_WARP" || $skill eq "PR_SANCTUARY"
		|| $skill eq "PR_MAGNUS"|| $skill eq "BS_HAMMERFALL"
		|| $skill eq "HT_SKIDTRAP" || $skill eq "HT_LANDMINE"
		|| $skill eq "HT_ANKLESNARE" || $skill eq "HT_SHOCKWAVE"
		|| $skill eq "HT_SANDMAN" || $skill eq "HT_FLASHER"
		|| $skill eq "HT_FREEZINGTRAP" || $skill eq "HT_BLASTMINE" 
		|| $skill eq "HT_CLAYMORETRAP" || $skill eq "AS_VENOMDUST") {
		return 1;
	} else {
		return 0;
	}
}


sub ai_mapRoute_getRoute {
	my %args;
	##VARS
	$args{'g_normal'} = 1;
	###
	my ($returnArray, $r_start_field, $r_start_pos, $r_dest_field, $r_dest_pos, $time_giveup) = @_;
	$args{'returnArray'} = $returnArray;
	$args{'r_start_field'} = $r_start_field;
	$args{'r_start_pos'} = $r_start_pos;
	$args{'r_dest_field'} = $r_dest_field;
	$args{'r_dest_pos'} = $r_dest_pos;
	$args{'time_giveup'}{'timeout'} = $time_giveup;
	$args{'time_giveup'}{'time'} = time;
	unshift @ai_seq, "route_getMapRoute";
	unshift @ai_seq_args, \%args;
}

sub ai_mapRoute_getSuccessors {
	my ($r_args, $r_array, $r_cur) = @_;
	my $ok;
	foreach (keys %portals_lut) {
		if ($portals_lut{$_}{'source'}{'map'} eq $$r_cur{'dest'}{'map'}

			&& !($$r_cur{'source'}{'map'} eq $portals_lut{$_}{'dest'}{'map'}
			&& $$r_cur{'source'}{'pos'}{'x'} == $portals_lut{$_}{'dest'}{'pos'}{'x'}
			&& $$r_cur{'source'}{'pos'}{'y'} == $portals_lut{$_}{'dest'}{'pos'}{'y'})

			&& !(%{$$r_cur{'parent'}} && $$r_cur{'parent'}{'source'}{'map'} eq $portals_lut{$_}{'dest'}{'map'}
			&& $$r_cur{'parent'}{'source'}{'pos'}{'x'} == $portals_lut{$_}{'dest'}{'pos'}{'x'}
			&& $$r_cur{'parent'}{'source'}{'pos'}{'y'} == $portals_lut{$_}{'dest'}{'pos'}{'y'})) {
			undef $ok;
			if (!%{$$r_cur{'parent'}}) {
				if (!$$r_args{'solutions'}{$$r_args{'start'}{'dest'}{'field'}.\%{$$r_args{'start'}{'dest'}{'pos'}}.\%{$portals_lut{$_}{'source'}{'pos'}}}{'solutionTried'}) {
					$$r_args{'solutions'}{$$r_args{'start'}{'dest'}{'field'}.\%{$$r_args{'start'}{'dest'}{'pos'}}.\%{$portals_lut{$_}{'source'}{'pos'}}}{'solutionTried'} = 1;
					$timeout{'ai_route_calcRoute'}{'time'} -= $timeout{'ai_route_calcRoute'}{'timeout'};
					$$r_args{'waitingForSolution'} = 1;
					ai_route_getRoute(\@{$$r_args{'solutions'}{$$r_args{'start'}{'dest'}{'field'}.\%{$$r_args{'start'}{'dest'}{'pos'}}.\%{$portals_lut{$_}{'source'}{'pos'}}}{'solution'}}, 
							$$r_args{'start'}{'dest'}{'field'}, \%{$$r_args{'start'}{'dest'}{'pos'}}, \%{$portals_lut{$_}{'source'}{'pos'}});
					last;
				}
				$ok = 1 if (@{$$r_args{'solutions'}{$$r_args{'start'}{'dest'}{'field'}.\%{$$r_args{'start'}{'dest'}{'pos'}}.\%{$portals_lut{$_}{'source'}{'pos'}}}{'solution'}});
			} elsif ($portals_los{$$r_cur{'dest'}{'ID'}}{$portals_lut{$_}{'source'}{'ID'}} ne "0"
				&& $portals_los{$portals_lut{$_}{'source'}{'ID'}}{$$r_cur{'dest'}{'ID'}} ne "0") {
				$ok = 1;
			}
			if ($$r_args{'dest'}{'source'}{'pos'}{'x'} ne "" && $portals_lut{$_}{'dest'}{'map'} eq $$r_args{'dest'}{'source'}{'map'}) {
				if (!$$r_args{'solutions'}{$$r_args{'dest'}{'source'}{'field'}.\%{$portals_lut{$_}{'dest'}{'pos'}}.\%{$$r_args{'dest'}{'source'}{'pos'}}}{'solutionTried'}) {
					$$r_args{'solutions'}{$$r_args{'dest'}{'source'}{'field'}.\%{$portals_lut{$_}{'dest'}{'pos'}}.\%{$$r_args{'dest'}{'source'}{'pos'}}}{'solutionTried'} = 1;
					$timeout{'ai_route_calcRoute'}{'time'} -= $timeout{'ai_route_calcRoute'}{'timeout'};
					$$r_args{'waitingForSolution'} = 1;
					ai_route_getRoute(\@{$$r_args{'solutions'}{$$r_args{'dest'}{'source'}{'field'}.\%{$portals_lut{$_}{'dest'}{'pos'}}.\%{$$r_args{'dest'}{'source'}{'pos'}}}{'solution'}}, 
							$$r_args{'dest'}{'source'}{'field'}, \%{$portals_lut{$_}{'dest'}{'pos'}}, \%{$$r_args{'dest'}{'source'}{'pos'}});
					last;
				}
			}
			push @{$r_array}, \%{$portals_lut{$_}} if $ok;
		}
	}
}

sub ai_mapRoute_searchStep {
	my $r_args = shift;
	my @successors;
	my $r_cur, $r_suc;
	my $i;

	###check if failed
	if (!@{$$r_args{'openList'}}) {
		#failed!
		$$r_args{'done'} = 1;
		return;
	}
	
	$r_cur = shift @{$$r_args{'openList'}};

	###check if finished
	if ($$r_args{'dest'}{'source'}{'map'} eq $$r_cur{'dest'}{'map'}
		&& (@{$$r_args{'solutions'}{$$r_args{'dest'}{'source'}{'field'}.\%{$$r_cur{'dest'}{'pos'}}.\%{$$r_args{'dest'}{'source'}{'pos'}}}{'solution'}}
		|| $$r_args{'dest'}{'source'}{'pos'}{'x'} eq "")) {
		do {
			unshift @{$$r_args{'solutionList'}}, {%{$r_cur}};
			$r_cur = $$r_cur{'parent'} if (%{$$r_cur{'parent'}});
		} while ($r_cur != \%{$$r_args{'start'}});
		$$r_args{'done'} = 1;
		return;
	}

	ai_mapRoute_getSuccessors($r_args, \@successors, $r_cur);
	if ($$r_args{'waitingForSolution'}) {
		undef $$r_args{'waitingForSolution'};
		unshift @{$$r_args{'openList'}}, $r_cur;
		return;
	}

	$newg = $$r_cur{'g'} + $$r_args{'g_normal'};
	foreach $r_suc (@successors) {
		undef $found;
		undef $openFound;
		undef $closedFound;
		for($i = 0; $i < @{$$r_args{'openList'}}; $i++) {
			if ($$r_suc{'dest'}{'map'} eq $$r_args{'openList'}[$i]{'dest'}{'map'}
				&& $$r_suc{'dest'}{'pos'}{'x'} == $$r_args{'openList'}[$i]{'dest'}{'pos'}{'x'}
				&& $$r_suc{'dest'}{'pos'}{'y'} == $$r_args{'openList'}[$i]{'dest'}{'pos'}{'y'}) {
				if ($newg >= $$r_args{'openList'}[$i]{'g'}) {
					$found = 1;
					}
				$openFound = $i;
				last;
			}
		}
		next if ($found);
		
		undef $found;
		for($i = 0; $i < @{$$r_args{'closedList'}}; $i++) {
			if ($$r_suc{'dest'}{'map'} eq $$r_args{'closedList'}[$i]{'dest'}{'map'}
				&& $$r_suc{'dest'}{'pos'}{'x'} == $$r_args{'closedList'}[$i]{'dest'}{'pos'}{'x'}
				&& $$r_suc{'dest'}{'pos'}{'y'} == $$r_args{'closedList'}[$i]{'dest'}{'pos'}{'y'}) {
				if ($newg >= $$r_args{'closedList'}[$i]{'g'}) {
					$found = 1;
				}
				$closedFound = $i;
				last;
			}
		}
		next if ($found);
		if ($openFound ne "") {
			binRemoveAndShiftByIndex(\@{$$r_args{'openList'}}, $openFound);
		}
		if ($closedFound ne "") {
			binRemoveAndShiftByIndex(\@{$$r_args{'closedList'}}, $closedFound);
		}
		$$r_suc{'g'} = $newg;
		$$r_suc{'h'} = 0;
		$$r_suc{'f'} = $$r_suc{'g'} + $$r_suc{'h'};
		$$r_suc{'parent'} = $r_cur;
		minHeapAdd(\@{$$r_args{'openList'}}, $r_suc, "f");
	}
	push @{$$r_args{'closedList'}}, $r_cur;
}

sub ai_items_take {
	my ($x1, $y1, $x2, $y2) = @_;
	my %args;
	$args{'pos'}{'x'} = $x1;
	$args{'pos'}{'y'} = $y1;
	$args{'pos_to'}{'x'} = $x2;
	$args{'pos_to'}{'y'} = $y2;
	$args{'ai_items_take_end'}{'time'} = time;
	$args{'ai_items_take_end'}{'timeout'} = $timeout{'ai_items_take_end'}{'timeout'};
	$args{'ai_items_take_start'}{'time'} = time;
	$args{'ai_items_take_start'}{'timeout'} = $timeout{'ai_items_take_start'}{'timeout'};
	unshift @ai_seq, "items_take";
	unshift @ai_seq_args, \%args;
}

sub ai_route {
	my ($r_ret, $x, $y, $map, $maxRouteDistance, $maxRouteTime, $attackOnRoute, $avoidPortals, $distFromGoal, $checkInnerPortals,$attackID) = @_;
	my %args;	
#mod Start
	my $pos_x;
	my $pos_y;
	$pos_x = int($chars[$config{'char'}]{'pos_to'}{'x'}) if ($chars[$config{'char'}]{'pos_to'}{'x'} ne "");
	$pos_y = int($chars[$config{'char'}]{'pos_to'}{'y'}) if ($chars[$config{'char'}]{'pos_to'}{'y'} ne "");
#mod Stop
	$x = int($x) if ($x ne "");
	$y = int($y) if ($y ne "");
	$args{'returnHash'} = $r_ret;
	$args{'dest_x'} = $x;
	$args{'dest_y'} = $y;
	$args{'dest_map'} = $map;
	$args{'maxRouteDistance'} = $maxRouteDistance;
	$args{'maxRouteTime'} = $maxRouteTime;
	$args{'attackOnRoute'} = $attackOnRoute;
	$args{'avoidPortals'} = $avoidPortals;
	$args{'distFromGoal'} = $distFromGoal;
	$args{'checkInnerPortals'} = $checkInnerPortals;
	$args{'attackID'} = $attackID;
	undef %{$args{'returnHash'}};
	unshift @ai_seq, "route";
	unshift @ai_seq_args, \%args;
	System::message "On route to: $maps_lut{$map.'.rsw'}($map): $x, $y\n" if $config{'debug'};
#mod Start
#if kore is stuck
	if (($old_x || $old_y) && ($old_x == $x) && ($old_y == $y)) {
		$calcTo_SameSpot++;
	} else {
		$calcTo_SameSpot = 0;
		$old_x = $x;
		$old_y = $y;
	}
	if ($calcTo_SameSpot >= 10) {
		$calcTo_SameSpot = 0;
		Unstuck("Cannot find destination, trying to unstuck ...\n");
	}
	
	if (($old_pos_x || $old_pos_y) && ($old_pos_x == $pos_x) && ($old_pos_y == $pos_y)) {
		$calcFrom_SameSpot++;
	} else {
		$calcFrom_SameSpot = 0;
		$old_pos_x = $pos_x;
		$old_pos_y = $pos_y;
	}
	if ($calcFrom_SameSpot >= 10) {
		$calcFrom_SameSpot = 0;
		Unstuck("Invalid original position, trying to unstuck ...\n");
	}	

	if ($totalStuckCount >= 10) {
		RespawnUnstuck();
	}	
#mod Stop
}

sub ai_route_getDiagSuccessors {
	my $r_args = shift;
	my $r_pos = shift;
	my $r_array = shift;
	my $type = shift;
	my %pos;

	if (ai_route_getMap($r_args, $$r_pos{'x'}-1, $$r_pos{'y'}-1) == $type
		&& !($$r_pos{'parent'} && $$r_pos{'parent'}{'x'} == $$r_pos{'x'}-1 && $$r_pos{'parent'}{'y'} == $$r_pos{'y'}-1)) {
		$pos{'x'} = $$r_pos{'x'}-1;
		$pos{'y'} = $$r_pos{'y'}-1;
		push @{$r_array}, {%pos};
	}

	if (ai_route_getMap($r_args, $$r_pos{'x'}+1, $$r_pos{'y'}-1) == $type
		&& !($$r_pos{'parent'} && $$r_pos{'parent'}{'x'} == $$r_pos{'x'}+1 && $$r_pos{'parent'}{'y'} == $$r_pos{'y'}-1)) {
		$pos{'x'} = $$r_pos{'x'}+1;
		$pos{'y'} = $$r_pos{'y'}-1;
		push @{$r_array}, {%pos};
	}	

	if (ai_route_getMap($r_args, $$r_pos{'x'}+1, $$r_pos{'y'}+1) == $type
		&& !($$r_pos{'parent'} && $$r_pos{'parent'}{'x'} == $$r_pos{'x'}+1 && $$r_pos{'parent'}{'y'} == $$r_pos{'y'}+1)) {
		$pos{'x'} = $$r_pos{'x'}+1;
		$pos{'y'} = $$r_pos{'y'}+1;
		push @{$r_array}, {%pos};
	}	

		
	if (ai_route_getMap($r_args, $$r_pos{'x'}-1, $$r_pos{'y'}+1) == $type
		&& !($$r_pos{'parent'} && $$r_pos{'parent'}{'x'} == $$r_pos{'x'}-1 && $$r_pos{'parent'}{'y'} == $$r_pos{'y'}+1)) {
		$pos{'x'} = $$r_pos{'x'}-1;
		$pos{'y'} = $$r_pos{'y'}+1;
		push @{$r_array}, {%pos};
	}	
}

sub ai_route_getMap {
	my $r_args = shift;
	my $x = shift;
	my $y = shift;
	if($x < 0 || $x >= $$r_args{'field'}{'width'} || $y < 0 || $y >= $$r_args{'field'}{'height'}) {
		return 1;	 
	}
	return $$r_args{'field'}{'field'}[($y*$$r_args{'field'}{'width'})+$x];
}

sub ai_route_getRoute {
	my %args;
	my ($returnArray, $r_field, $r_start, $r_dest, $time_giveup) = @_;
	$args{'returnArray'} = $returnArray;
	$args{'field'} = $r_field;
	%{$args{'start'}} = %{$r_start};
	%{$args{'dest'}} = %{$r_dest};
	$args{'time_giveup'}{'timeout'} = $time_giveup;
	$args{'time_giveup'}{'time'} = time;
	$args{'destroyFunction'} = \&ai_route_getRoute_destroy;
	undef @{$args{'returnArray'}};
	unshift @ai_seq, "route_getRoute";
	unshift @ai_seq_args, \%args;
}

sub ai_route_getRoute_destroy {
	my $r_args = shift;
	if ($^O eq 'MSWin32') {
		$CalcPath_destroy->Call($$r_args{'session'}) if ($$r_args{'session'} ne "");
	} else {
		Tools::CalcPath_destroy($$r_args{'session'}) if ($$r_args{'session'} ne "");
	}
}
sub ai_route_searchStep {
	my $r_args = shift;
	my $ret;

	if (!$$r_args{'initialized'}) {
		#####
		my $SOLUTION_MAX = 5000;
		$$r_args{'solution'} = "\0" x ($SOLUTION_MAX*4+4);
		my $weights = join '', map chr $_, (255, 8, 7, 6, 5, 4, 3, 2, 1);
		$weights .= chr(1) x (256 - length($weights)); 
		#####
		if ($^O eq 'MSWin32') {
			$$r_args{'session'} = $CalcPath_init->Call($$r_args{'solution'},
				$$r_args{'field'}{'dstMap'}, $weights, $$r_args{'field'}{'width'}, $$r_args{'field'}{'height'},
				pack("S*",$$r_args{'start'}{'x'}, $$r_args{'start'}{'y'}), pack("S*",$$r_args{'dest'}{'x'}, $$r_args{'dest'}{'y'}), $$r_args{'timeout'});
		} else {
			$$r_args{'session'} = Tools::CalcPath_init(
				$$r_args{'solution'},
				$$r_args{'field'}{'dstMap'},
				$$r_args{'field'}{'width'},
				$weights,
				$$r_args{'field'}{'height'}, 
				pack("S*",$$r_args{'start'}{'x'}, $$r_args{'start'}{'y'}), 
				pack("S*",$$r_args{'dest'}{'x'}, $$r_args{'dest'}{'y'}),
				$$r_args{'timeout'});
		}
	}
	if ($$r_args{'session'} < 0) {
		$$r_args{'done'} = 1;
		return;
	}
	$$r_args{'initialized'} = 1;
	if ($^O eq 'MSWin32') {
		$ret = $CalcPath_pathStep->Call($$r_args{'session'});
	} else {
		$ret = Tools::CalcPath_pathStep($$r_args{'session'});
	}
	if (!$ret) {
		my $size = unpack("L",substr($$r_args{'solution'},0,4));
		my $j = 0;
		my $i;
		for ($i = ($size-1)*4+4; $i >= 4;$i-=4) {
			$$r_args{'returnArray'}[$j]{'x'} = unpack("S",substr($$r_args{'solution'}, $i, 2));
			$$r_args{'returnArray'}[$j]{'y'} = unpack("S",substr($$r_args{'solution'}, $i+2, 2));
			$j++;
		}
		$$r_args{'done'} = 1;
	}
}

sub ai_route_getSuccessors {
	my $r_args = shift;
	my $r_pos = shift;
	my $r_array = shift;
	my $type = shift;
	my %pos;
	
	if (ai_route_getMap($r_args, $$r_pos{'x'}-1, $$r_pos{'y'}) == $type
		&& !($$r_pos{'parent'} && $$r_pos{'parent'}{'x'} == $$r_pos{'x'}-1 && $$r_pos{'parent'}{'y'} == $$r_pos{'y'})) {
		$pos{'x'} = $$r_pos{'x'}-1;
		$pos{'y'} = $$r_pos{'y'};
		push @{$r_array}, {%pos};
	}

	if (ai_route_getMap($r_args, $$r_pos{'x'}, $$r_pos{'y'}-1) == $type
		&& !($$r_pos{'parent'} && $$r_pos{'parent'}{'x'} == $$r_pos{'x'} && $$r_pos{'parent'}{'y'} == $$r_pos{'y'}-1)) {
		$pos{'x'} = $$r_pos{'x'};
		$pos{'y'} = $$r_pos{'y'}-1;
		push @{$r_array}, {%pos};
	}	

	if (ai_route_getMap($r_args, $$r_pos{'x'}+1, $$r_pos{'y'}) == $type
		&& !($$r_pos{'parent'} && $$r_pos{'parent'}{'x'} == $$r_pos{'x'}+1 && $$r_pos{'parent'}{'y'} == $$r_pos{'y'})) {
		$pos{'x'} = $$r_pos{'x'}+1;
		$pos{'y'} = $$r_pos{'y'};
		push @{$r_array}, {%pos};
	}	

		
	if (ai_route_getMap($r_args, $$r_pos{'x'}, $$r_pos{'y'}+1) == $type
		&& !($$r_pos{'parent'} && $$r_pos{'parent'}{'x'} == $$r_pos{'x'} && $$r_pos{'parent'}{'y'} == $$r_pos{'y'}+1)) {
		$pos{'x'} = $$r_pos{'x'};
		$pos{'y'} = $$r_pos{'y'}+1;
		push @{$r_array}, {%pos};
	}	
}

#sellAuto for items_control - chobit andy 20030210
sub ai_sellAutoCheck {
	for ($i = 0; $i < @{$chars[$config{'char'}]{'inventory'}};$i++) {
		next if (!%{$chars[$config{'char'}]{'inventory'}[$i]} || $chars[$config{'char'}]{'inventory'}[$i]{'equipped'});
		if (($items_control{'all'}{'sell'} && $chars[$config{'char'}]{'inventory'}[$i]{'amount'} > $items_control{'all'}{'keep'} && !%{$items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}})
			|| ($items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'sell'} && $chars[$config{'char'}]{'inventory'}[$i]{'amount'} > $items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'keep'})
			) {
			return 1;
		}
	}
}

sub ai_setMapChanged {
	my $index = shift;
	$index = 0 if ($index eq "");
	if ($index < @ai_seq_args) {
		$ai_seq_args[$index]{'mapChanged'} = time;
	}
	$ai_v{'portalTrace_mapChanged'} = 1;
}

sub ai_setSuspend {
	my $index = shift;
	$index = 0 if ($index eq "");
	if ($index < @ai_seq_args) {
		$ai_seq_args[$index]{'suspended'} = time;
	}
}

sub ai_skillUse {
	my $ID = shift;
	my $lv = shift;
	my $maxCastTime = shift;
	my $minCastTime = shift;
	my $target = shift;
	my $y = shift;
	my %args;
	$args{'ai_skill_use_giveup'}{'time'} = time;
	$args{'ai_skill_use_giveup'}{'timeout'} = $timeout{'ai_skill_use_giveup'}{'timeout'};
	$args{'skill_use_id'} = $ID;
	$args{'skill_use_lv'} = $lv;
	$args{'skill_use_maxCastTime'}{'time'} = time;
	$args{'skill_use_maxCastTime'}{'timeout'} = $maxCastTime;
	$args{'skill_use_minCastTime'}{'time'} = time;
	$args{'skill_use_minCastTime'}{'timeout'} = $minCastTime;
	if ($y eq "") {
		$args{'skill_use_target'} = $target;
	} else {
		$args{'skill_use_target_x'} = $target;
		$args{'skill_use_target_y'} = $y;
	}
	unshift @ai_seq, "skill_use";
	unshift @ai_seq_args, \%args;
}

#storageAuto for items_control - chobit andy 20030210
sub ai_storageAutoCheck {
	for ($i = 0; $i < @{$chars[$config{'char'}]{'inventory'}};$i++) {
		next if (!%{$chars[$config{'char'}]{'inventory'}[$i]} || $chars[$config{'char'}]{'inventory'}[$i]{'equipped'});
		if (($items_control{'all'}{'storage'} && $chars[$config{'char'}]{'inventory'}[$i]{'amount'} > $items_control{'all'}{'keep'} && !%{$items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}})
			|| ($items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'storage'} && $chars[$config{'char'}]{'inventory'}[$i]{'amount'} > $items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'keep'})
			){
			return 1;
		}
	}
}

sub aiRemove {
	my $ai_type = shift;
	my $index;
	while (1) {
		$index = binFind(\@ai_seq, $ai_type);
		if ($index ne "") {
			if ($ai_seq_args[$index]{'destroyFunction'}) {
				&{$ai_seq_args[$index]{'destroyFunction'}}(\%{$ai_seq_args[$index]});
			}
			binRemoveAndShiftByIndex(\@ai_seq, $index);
			binRemoveAndShiftByIndex(\@ai_seq_args, $index);
		} else {
			last;
		}
	}
}

sub checkSelfCondition {
	$prefix = shift;

	#return 0 if ($config{$prefix . "_disabled"} > 0);

	if ($config{$prefix . "_hp"}) { 
		return 0 unless (inRange($chars[$config{'char'}]{'percent_hp'}, $config{$prefix . "_hp"}));
	} elsif ($config{$prefix . "_hp_upper"}) { # backward compatibility with old config format
		return 0 unless ($chars[$config{'char'}]{'percent_hp'} <= $config{$prefix . "_hp_upper"} && $chars[$config{'char'}]{'percent_hp'} >= $config{$prefix . "_hp_lower"});
	}

	if ($config{$prefix . "_sp"}) { 
		return 0 unless (inRange($chars[$config{'char'}]{'percent_sp'}, $config{$prefix . "_sp"}));
	} elsif ($config{$prefix . "_sp_upper"}) { # backward compatibility with old config format
		return 0 unless ($chars[$config{'char'}]{'percent_sp'} <= $config{$prefix . "_sp_upper"} && $chars[$config{'char'}]{'percent_sp'} >= $config{$prefix . "_sp_lower"});
	}

	if ($config{$prefix . "_spirits"}) { 
		return 0 unless (inRange($chars[$config{'char'}]{'spirits'}, $config{$prefix . "_spirits"}));
	} elsif ($config{$prefix . "_spirits_upper"}) { # backward compatibility with old config format
		return 0 unless ($chars[$config{'char'}]{'spirits'} <= $config{$prefix . "_spirits_upper"} && $chars[$config{'char'}]{'spirits'} >= $config{$prefix . "_spirits_lower"});
	}

	# check skill use SP if this is a 'use skill' condition
	if ($prefix =~ /skill/i) {
		return 0 unless ($chars[$config{'char'}]{'sp'} >= $skillsSP_lut{$skills_rlut{lc($config{$prefix})}}{$config{$prefix . "_lvl"}})
	}

	if ($config{$prefix . "_aggressives"}) {
		return 0 unless (inRange(scalar ai_getAggressives(), $config{$prefix . "_aggressives"}));
	} elsif ($config{$prefix . "_maxAggressives"}) { # backward compatibility with old config format
		return 0 unless ($config{$prefix . "_minAggressives"} <= ai_getAggressives());
		return 0 unless ($config{$prefix . "_maxAggressives"} >= ai_getAggressives());
	}
	if ($config{$prefix . "_stopWhenHit"}) { return 0 if (ai_getMonstersWhoHitMe()); }

#	if ($config{$prefix . "_whenFollowing"} && $config{follow}) {
#		return 0 if (!checkFollowMode());
#	}

	if ($config{$prefix . "_inStatus"}) { return 0 unless (binFind(\@skillsST, $skillsST_lut{$config{$prefix."_inStatus"}}) ne ""); }
	if ($config{$prefix . "_outStatus"}) { return 0 unless (binFind(\@skillsST, $skillsST_lut{$config{$prefix."_outStatus"}}) eq "");}
	#if ($config{$prefix . "_onAction"}) { return 0 unless (existsInList($config{$prefix . "_onAction"}, AI::action)); }

	if ($config{$prefix . "_timeout"}) { return 0 unless timeOut($ai_v{$prefix . "_time"}, $config{$prefix . "_timeout"}) }
	if ($config{$prefix . "_inLockOnly"}) { return 0 unless ($field{name} eq $config{"lockMap_$ai_v{'lockMapIndex'}"}); }
	if ($config{$prefix . "_whileSitting"}) { return 0 if ($chars[$config{char}]{'sitting'}); }
	if ($config{$prefix . "_notInTown"}) { return 0 if ($cities_lut{$field{name}.'.rsw'}); }

#	if ($config{$prefix . "_monsters"} && !($prefix =~ /skillSlot/i)) {
#		my $exists;
#		foreach (ai_getAggressives()) {
#			if (existsInList($config{$prefix . "_monsters"}, $monsters{$_}{name})) {
#				$exists = 1;
#				last;
#			}
#		}
#		return 0 unless $exists;
#	}

#	if ($config{$prefix . "_inInventory_name"}) {
#		my @arrN = split / *, */, $config{$prefix . "_inInventory_name"};
#		my @arrQ = split / *, */, $config{$prefix . "_inInventory_qty"};
#		my $found = 0;
#
#		my $i = 0;
#		foreach (@arrN) {
#			my $index = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $_);
#			if ($index ne "") {
#				$found = 1;
#				return 0 unless inRange($chars[$config{'char'}]{'inventory'}[$index]{amount},$arrQ[$i]);
#			}
#			$i++;
#		}
#		return 0 unless $found;
#	}

	return 1;
}

sub inRange {
	my $value = shift;
	my $param = shift;

	return 1 if (!defined $param);
	my ($min, $max) = getRange($param);

	if (defined $min && defined $max) {
		return 1 if ($value >= $min && $value <= $max);
	} elsif (defined $min) {
		return 1 if ($value >= $min);
	} elsif (defined $max) {
		return 1 if ($value <= $max);
	}
	
	return 0;
}

sub getRange {
	my $param = shift;
	return if (!defined $param);

	if (($param =~ /(\d+)\s*-\s*(\d+)/) || ($param =~ /(\d+)\s*\.\.\s*(\d+)/)) {
		return ($1, $2);
	} elsif ($param =~ />\s*(\d+)/) {
		return ($1+1, undef);
	} elsif ($param =~ />=\s*(\d+)/) {
		return ($1, undef);
	} elsif ($param =~ /<\s*(\d+)/) {
		return (undef, $1-1);
	} elsif ($param =~ /<=\s*(\d+)/) {
		return (undef, $1);
	} elsif ($param =~/^(\d+)/) {
		return ($1, $1);
	}
}
1;