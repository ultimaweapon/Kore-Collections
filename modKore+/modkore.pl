#!/usr/bin/env perl
#########################################################################
#  modKore - Hybrid :: main program
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

srand;
#writing error to error.txt
BEGIN {
	open "STDERR", "> errors_log.txt" or die "Could not write to errors.txt: $!\n";
}

##### SETUP SIGNAL #####
$SIG{__DIE__} = sub {
	return unless (defined $^S && $^S == 0);

	# Extract file and line number from the die message 
	my ($file, $line) = $_[0] =~ / at (.+?) line (\d+)\.$/; 

	# Get rid of the annoying "@INC contains:" 
	my $dieMsg = $_[0]; 
	$dieMsg =~ s/ \(\@INC contains: .*\)//;

	my $log = '';
	$log .= "\@ai_seq = @Globals::ai_seq\n\n" if (defined @Globals::ai_seq);
	if (defined &Carp::longmess) {
		$log .= Carp::longmess(@_);
	} else {
		$log .= $dieMsg;
	}
	# Find out which line died
	if (-f $file && open(F, "< $file")) {
		my @lines = <F>;
		close F;

		my $msg;
		$msg =  "  $lines[$line-2]" if ($line - 2 >= 0);
		$msg .= "* $lines[$line-1]";
		$msg .= "  $lines[$line]" if (@lines > $line);
		$msg .= "\n" unless $msg =~ /\n$/s;
		$log .= "\n\nDied at this line:\n$msg\n";
	}

	open(F, "> errors.txt");
	print F $log;
	close F;
	exit 9;
};


#Standard Class module
use Digest::MD5;
use Time::HiRes qw(time usleep);
use IO::Socket;
use Config;
use HTTP::Lite;

#search module at root directory first
use lib './src';

#Use-Defined Class module
use FileParser;
use ROcrypt;
use Globals;
use Utils;
use System;
use Plugins;
#use IPC;

#Seperate File
require 'miscFunctions.pl';
require 'aiModule.pl';
require 'packetParser.pl';

System::init();
Plugins::loadAll();

###################    LOADING DATA    ########################
# control folder
FileParser::addParseFiles("$System::def_config/config.txt", \%config, \&FileParser::parseDataFile2);
FileParser::addParseFiles("$System::def_config/items_control.txt", \%items_control, \&FileParser::parseItemsControl);
FileParser::addParseFiles("$System::def_config/mon_control.txt", \%mon_control, \&FileParser::parseMonControl);
FileParser::addParseFiles("$System::def_config/ppl_control.txt", \%ppl_control, \&FileParser::parsePplControl);
FileParser::addParseFiles("$System::def_config/gid_control.txt", \%gid_control, \&FileParser::parseGIDControl);
FileParser::addParseFiles("$System::def_config/pickupitems.txt", \%itemsPickup, \&FileParser::parseDataFile_lc);
FileParser::addParseFiles("$System::def_config/timeouts.txt", \%timeout, \&FileParser::parseTimeouts);
FileParser::addParseFiles("$System::def_config/chatauto.txt", \%qmsg, \&FileParser::parseChatMsg);
FileParser::addParseFiles("$System::def_config/responses.txt", \%responses, \&FileParser::parseResponses);
FileParser::addParseFiles("$System::def_config/overallauth.txt", \%overallAuth, \&FileParser::parseDataFile);
FileParser::addParseFiles("$System::def_config/cart_control.txt", \%cart_control, \&FileParser::parseCartControl);
FileParser::addParseFiles("$System::def_config/shop.txt", \%shop, \&FileParser::parseDataFile2);
FileParser::addParseFiles("$System::def_config/colors_${System::def_interface}.txt", \%consoleColors, \&FileParser::parseSectionedFile);

#control XML
FileParser::addParseFiles("$System::def_config/slot_attackskill.txt", \%config, \&FileParser::parseDataFile2);
FileParser::addParseFiles("$System::def_config/slot_autoswitch.txt", \%config, \&FileParser::parseDataFile2);
FileParser::addParseFiles("$System::def_config/slot_buyauto.txt", \%config, \&FileParser::parseDataFile2);
FileParser::addParseFiles("$System::def_config/slot_equipauto.txt", \%config, \&FileParser::parseDataFile2);
FileParser::addParseFiles("$System::def_config/slot_getauto.txt", \%config, \&FileParser::parseDataFile2);
FileParser::addParseFiles("$System::def_config/slot_locationskill.txt", \%config, \&FileParser::parseDataFile2);
FileParser::addParseFiles("$System::def_config/slot_partyskill.txt", \%config, \&FileParser::parseDataFile2);
FileParser::addParseFiles("$System::def_config/slot_selfitem.txt", \%config, \&FileParser::parseDataFile2);
FileParser::addParseFiles("$System::def_config/slot_selfskill.txt", \%config, \&FileParser::parseDataFile2);


# table folder
FileParser::addParseFiles("$System::def_table/cities.txt", \%cities_lut, \&FileParser::parseROLUT);
FileParser::addParseFiles("$System::def_table/emotions.txt", \%emotions_lut, \&FileParser::parseDataFile2);
FileParser::addParseFiles("$System::def_table/equiptypes.txt", \%equipTypes_lut, \&FileParser::parseDataFile2);
FileParser::addParseFiles("$System::def_table/items.txt", \%items_lut, \&FileParser::parseROLUT);
FileParser::addParseFiles("$System::def_table/itemtypes.txt", \%itemTypes_lut, \&FileParser::parseDataFile2);
FileParser::addParseFiles("$System::def_table/maps.txt", \%maps_lut, \&FileParser::parseROLUT);
FileParser::addParseFiles("$System::def_table/monsters.txt", \%monsters_lut, \&FileParser::parseDataFile2);
FileParser::addParseFiles("$System::def_table/npcs.txt", \%npcs_lut, \&FileParser::parseNPCs);
FileParser::addParseFiles("$System::def_table/portals.txt", \%portals_lut, \&FileParser::parsePortals);
FileParser::addParseFiles("$System::def_table/portalsLOS.txt", \%portals_los, \&FileParser::parsePortalsLOS);
FileParser::addParseFiles("$System::def_table/skills.txt", \%skills_lut, \&FileParser::parseSkillsLUT);
FileParser::addParseFiles("$System::def_table/skills.txt", \%skillsID_lut, \&FileParser::parseSkillsIDLUT);
FileParser::addParseFiles("$System::def_table/skills.txt", \%skills_rlut, \&FileParser::parseSkillsReverseLUT_lc);
FileParser::addParseFiles("$System::def_table/skillssp.txt", \%skillsSP_lut, \&FileParser::parseSkillsSPLUT);
FileParser::addParseFiles("$System::def_table/recvpackets.txt", \%rpackets, \&FileParser::parseDataFile2);
FileParser::addParseFiles("$System::def_table/skillsst.txt", \%skillsST_lut, \&FileParser::parseDataFile2);
FileParser::addParseFiles("$System::def_table/cards.txt", \%cards_lut, \&FileParser::parseROLUT);
FileParser::addParseFiles("$System::def_table/elements.txt", \%elements_lut, \&FileParser::parseROLUT);
FileParser::addParseFiles("$System::def_table/aids.txt", \%GameMasters, \&FileParser::parseGameMaster);
########################################################

FileParser::load();
Plugins::callHook('postloadfiles');

#Platform Specified module
#openkore re-init cygwin
if ($^O eq 'MSWin32' || $^O eq 'cygwin') {
	require Win32::API; import Win32::API;

	System::error("Unable to load the Win32::API module. Please install this Perl module first.","critical") if ($@);
	$CalcPath_init = new Win32::API("Tools", "CalcPath_init", "PPPNNPPN", "N") || System::error "Could not locate Tools.dll -- CalcPath_init Function\n","critical";
	$CalcPath_pathStep = new Win32::API("Tools", "CalcPath_pathStep", "N", "N") || System::error "Could not locate Tools.dll -- CalcPath_pathStep Function\n","critical";
	$CalcPath_destroy = new Win32::API("Tools", "CalcPath_destroy", "N", "V") || System::error "Could not locate Tools.dll -- CalcPath_destroy Function\n","critical";

	if ($System::xMode) {
		$injectDLL_file = Win32::GetCwd()."\\Inject.dll";
		$GetProcByName = new Win32::API("Tools", "GetProcByName", "P", "N") || System::error "Could not locate Tools.dll -- GetProcByName Function\n","critical";
	}

} else{
	#linux ?
}

### ADMIN PASSWORD GENERATOR ###
if ($config{'adminPassword'} eq 'x' x 10) {
	System::message "\nAuto-generating Admin Password\n";
	configModify("adminPassword", vocalString(8));
# This is where we protect the stupid from having a blank admin password
}elsif ($config{'adminPassword'} eq '') {
	System::message "\nAuto-generating Admin Password due to blank...\n";
	configModify("adminPassword", vocalString(8));
}

System::message("\n");

###COMPILE PORTALS###

System::message "\nChecking for new portals...";

if (compilePortals_check()) {
	System::message "found new portals!\n";
	System::message "Compile portals now? (y/n)\n";
	System::message "Auto-compile in $timeout{'compilePortals_auto'}{'timeout'} seconds...";
	$timeout{'compilePortals_auto'}{'time'} = time;
	undef $msg;
	while (!timeOut(\%{$timeout{'compilePortals_auto'}})) {
		$msg = System::getInput($timeout{'compilePortals_auto'}{'timeout'});
		last if ($msg ne "");
	}
	if ($msg =~ /y/ || $msg eq "") {
		System::message "compiling portals\n\n";
		compilePortals();
	} else {
		System::message "skipping compile\n\n";
	}
} else {
	System::message "none found\n";
}

## Contribute Control 
checkUpdate();
checkExpired();


############# input DATA 
if (!$System::xMode) {
	if (!$config{'username'}) {
		System::message "Enter Username:\n";
		$config{'username'} = System::getInput(-1);
		FileParser::writeDataFileIntact("$System::def_config/config.txt", \%config);
	}
	if (!$config{'password'}) {
		System::message "Enter Password:\n";
		$config{'password'} = System::getInput(-1);
		FileParser::writeDataFileIntact("$System::def_config/config.txt", \%config);
	}
	if ($config{'master'} eq "") {
		$i = 0;
		System::message "--------- Master Servers ----------\n","connection";
		System::message "#         Name\n","connection";
		while ($config{"master_name_$i"} ne "") {
			System::message sprintf("%-3d %-43s\n",$i,$config{"master_name_$i"}) ,"connection";
			$i++;
		}
		System::message "-----------------------------------\n","connection";
		System::message "Choose your master server:\n", "connection";
		undef $msg;
		$msg = System::getInput(-1);
		System::message $msg,"\n";
		$config{'master'} = $msg;
		FileParser::writeDataFileIntact("$System::def_config/config.txt", \%config);
	}
}else{
	$timeout{'injectSync'}{'time'} = time;
}

our $conState = 1;
our $AI = 1;
undef $msg;
our $KoreStartTime = time;
our $printed = 0;
our $welcomeText = "modKore - Plus  ~  http://modkore.sf.net";
# exp report
our $bExpSwitch = 2; 
our $jExpSwitch = 2; 
our $totalBaseExp = 0; 
our $totalJobExp = 0; 
our $startTime_EXP = time; 
#IPC::start();

if (System::noCriticalError()) {
	#main loop
	Plugins::callHook('initialized');
	while ($quit != 1) {
		my $input;
		usleep($config{'sleepTime'});

		if(defined($input = System::getInput(0))) {
			parseInput($input);
		}

		#Data waiting @ socket
		if (System::haveIncomingData()) {
			if (!$System::xMode) {
				my $new = System::recvIncomingData();
				$msg .= $new;
				$msg_length = length($msg);
				while ($msg ne "") {
					$msg = parseMsg($msg);
					last if ($msg_length == length($msg));
					$msg_length = length($msg);
				}
			}else{
				my $injectMsg = System::recvIncomingData();
				while ($injectMsg ne "") {
					if (length($injectMsg) < 3) {
						undef $injectMsg;
						break;
					}
					my $type = substr($injectMsg, 0, 1);
					my $len = unpack("S",substr($injectMsg, 1, 2));
					my $newMsg = substr($injectMsg, 3, $len);
					$injectMsg = (length($injectMsg) >= $len+3) ? substr($injectMsg, $len+3, length($injectMsg) - $len - 3) : "";
					if ($type eq "R") {
						$msg .= $newMsg;
						$msg_length = length($msg);
						while ($msg ne "") {
							$msg = parseMsg($msg);
							last if ($msg_length == length($msg));
							$msg_length = length($msg);
						}
					} elsif ($type eq "S") {
						parseSendMsg($newMsg);
					}
					$timeout{'injectKeepAlive'}{'time'} = time;
				}
			}
		}

		#Running Ai
		if ($conState==5) {
			if ($AI) {
				my $i = 0;
				do {
					AI(\%{$ai_cmdQue[$i]}) if (timeOut(\%{$timeout{'ai'}}) && $System::remote_socket && $System::remote_socket->connected());
					undef %{$ai_cmdQue[$i]};
					$ai_cmdQue-- if ($ai_cmdQue > 0);
					$i++;
				} while ($ai_cmdQue > 0);
			}
			wipeCheck();
		}

		#IPC::iterate();
		#checkConnection ;  xmode = checkSynchronized
		if ($System::xMode) {
			checkSynchronized();
		}else{
			checkConnection();
		}
		mainLoop();
	}
}else{
	System::getInput(-1);
}

Plugins::unloadAll();

#Bye Bye Message
System::message "Bye!\n";
System::terminate();
#IPC::stop();
exit;
#end main.