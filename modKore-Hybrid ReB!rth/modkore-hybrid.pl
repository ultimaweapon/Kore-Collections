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
sub __start {
#writing error to error.txt

#Standard Class module
use Digest::MD5;
use Time::HiRes qw(time usleep);
use IO::Socket;

#search module at root directory first
use lib '.';
use lib './inc';
use lib './inc/modules';

#Use-Defined Class module
use aiMath;
use fileParser;
use Input;
use Modules;
use ROcrypt;
use Settings;
use Globals;
use Utils;


#register module for dynamic loading
Modules::register(qw(Globals Modules aiMath Utils fileParser ROcrypt Settings));

#Seperate File
require 'aiModule.pl';
require 'packetParser.pl';
require 'miscFunctions.pl';

srand(time());

# Parsing Command Line Argument
Settings::parseArguments();

# versioning text
print $versionText;

#away from crash -- user stupid buggy prove.
if (-e "$def_config/option.txt") {
	print "Loading $def_config/option.txt...\n";
	parseDataFile2("$def_config/option.txt",\%sys);
}

#open input server if  using non-Vx
Input::start() if (!$sys{'Vx_interface'});

# control folder
addParseFiles(\@parseFiles,"$def_config/config.txt", \%config, \&parseDataFile2);
addParseFiles(\@parseFiles,"$def_config/items_control.txt", \%items_control, \&parseItemsControl);
addParseFiles(\@parseFiles,"$def_config/mon_control.txt", \%mon_control, \&parseMonControl);
addParseFiles(\@parseFiles,"$def_config/ppl_control.txt", \%ppl_control, \&parsePplControl);
addParseFiles(\@parseFiles,"$def_config/gid_control.txt", \%gid_control, \&parseGIDControl);
addParseFiles(\@parseFiles,"$def_config/pickupitems.txt", \%itemsPickup, \&parseDataFile_lc);
addParseFiles(\@parseFiles,"$def_config/timeouts.txt", \%timeout, \&parseTimeouts);
addParseFiles(\@parseFiles,"$def_config/chatauto.txt", \%qmsg, \&parseChatMsg);
addParseFiles(\@parseFiles,"$def_config/responses.txt", \%responses, \&parseResponses);
addParseFiles(\@parseFiles,"$def_config/overallauth.txt", \%overallAuth, \&parseDataFile);
addParseFiles(\@parseFiles,"$def_config/cart_control.txt", \%cart_control, \&parseCartControl);
addParseFiles(\@parseFiles,"$def_config/shop.txt", \%shop, \&parseDataFile2);
# table folder 
addParseFiles(\@parseFiles,"$def_table/cities.txt", \%cities_lut, \&parseROLUT);
addParseFiles(\@parseFiles,"$def_table/emotions.txt", \%emotions_lut, \&parseDataFile2);
addParseFiles(\@parseFiles,"$def_table/equiptypes.txt", \%equipTypes_lut, \&parseDataFile2);
addParseFiles(\@parseFiles,"$def_table/items.txt", \%items_lut, \&parseROLUT);
addParseFiles(\@parseFiles,"$def_table/itemtypes.txt", \%itemTypes_lut, \&parseDataFile2);
addParseFiles(\@parseFiles,"$def_table/maps.txt", \%maps_lut, \&parseROLUT);
addParseFiles(\@parseFiles,"$def_table/monsters.txt", \%monsters_lut, \&parseDataFile2);
addParseFiles(\@parseFiles,"$def_table/npcs.txt", \%npcs_lut, \&parseNPCs);
addParseFiles(\@parseFiles,"$def_table/portals.txt", \%portals_lut, \&parsePortals);
addParseFiles(\@parseFiles,"$def_table/portalsLOS.txt", \%portals_los, \&parsePortalsLOS);
addParseFiles(\@parseFiles,"$def_table/skills.txt", \%skills_lut, \&parseSkillsLUT);
addParseFiles(\@parseFiles,"$def_table/skills.txt", \%skillsID_lut, \&parseSkillsIDLUT);
addParseFiles(\@parseFiles,"$def_table/skills.txt", \%skills_rlut, \&parseSkillsReverseLUT_lc);
addParseFiles(\@parseFiles,"$def_table/skillssp.txt", \%skillsSP_lut, \&parseSkillsSPLUT);
addParseFiles(\@parseFiles,"$def_table/recvpackets.txt", \%rpackets, \&parseDataFile2);
addParseFiles(\@parseFiles,"$def_table/skillsst.txt", \%skillsST_lut, \&parseDataFile2);
addParseFiles(\@parseFiles,"$def_table/cards.txt", \%cards_lut, \&parseROLUT);
addParseFiles(\@parseFiles,"$def_table/elements.txt", \%elements_lut, \&parseROLUT);
addParseFiles(\@parseFiles,"$def_table/aids.txt", \%GameMasters, \&parseDataFile3);
addParseFiles(\@parseFiles,"$def_table/modifiedWalk.txt", \%modifiedWalk, \&parseDataFile2);

#parse loader
load(\@parseFiles);

#Platform Specified module
#openkore re-init cygwin
if ($^O eq 'MSWin32' || $^O eq 'cygwin') {
	require Win32::API;	import Win32::API;
	require Win32::Sound;	import Win32::Sound;
	require Win32::Console;	import Win32::Console;
	#eval "use Win32::Console";
	die if ($@);
	if (!$sys{'Vx_interface'}) {
		$CONSOLE = new Win32::Console(&STD_OUTPUT_HANDLE()) || die "Could not init Console Attribute";
	}else{
		Win32::Console->new(&STD_OUTPUT_HANDLE())->Free or warn "could not free console: $!\n";
		require Vx; import Vx;
		no strict;
		no warnings;
		tie *STDOUT,"Vx";
		#parse color for Vx
		addParseFiles(\@parseFiles,"$def_config/colors.txt", \%color, \&Vx::parseColorFile);
		parseReload(\@parseFiles,"color");
	}
	$CalcPath_init = new Win32::API("Tools", "CalcPath_init", "PPPNNPPN", "N") || die "Could not locate Tools.dll";
	$CalcPath_pathStep = new Win32::API("Tools", "CalcPath_pathStep", "N", "N") || die "Could not locate Tools.dll";
	$CalcPath_destroy = new Win32::API("Tools", "CalcPath_destroy", "N", "V") || die "Could not locate Tools.dll";

} else{
	#support linux by VCL
	require Tools;	import Tools;
	require LinuxConsole;	import LinuxConsole;
	#non Vx for Linux
	if (!$sys{'Vx_interface'}) {
		import LinuxConsole;
		$CONSOLE = new LinuxConsole;
	} else {
		require Vx; import Vx;
		no strict;
		no warnings;
		tie *STDOUT,"Vx";
		addParseFiles(\@parseFiles,"$def_config/colors.txt", \%color, \&Vx::parseColorFile);
		parseReload(\@parseFiles,"color");
	}
}

### ADMIN PASSWORD GENERATOR ###
if ($config{'adminPassword'} eq 'x' x 10) {
	print "\nAuto-generating Admin Password\n";
	configModify("adminPassword", vocalString(8));
# This is where we protect the stupid from having a blank admin password
}elsif ($config{'adminPassword'} eq '') {
	print "\nAuto-generating Admin Password due to blank...\n";
	configModify("adminPassword", vocalString(8));
}

print "\n";

$proto = getprotobyname('tcp');

#Create Socket to comunicate with RO Server
our $remote_socket = IO::Socket::INET->new();

#Create InjectSocket to comunicate with RO Client ( Xmode )
if ($sys{'Xmode'} && $^O eq 'MSWin32') {
	#add send packet explorer
	if ($config{'debug_sendPacket'}) {
		addParseFiles(\@parseFiles,"$def_table/sendpackets.txt", \%spackets,\&parseDataFile2);
		parseReload("sendpackets");
	}
	our $welcomeText = "modKore - Hybrid  ~  http://modkore.sf.net";
	our $injectServer_socket = IO::Socket::INET->new(
			Listen		=> 5,
			LocalAddr	=> 'localhost',
			LocalPort	=> 2350,
			Proto		=> 'tcp') || die "Error creating local inject server: $!";
	 print "Local inject server started (".$injectServer_socket->sockhost().":2350)\n";

	our $cwd = Win32::GetCwd();
	our $injectDLL_file = $cwd."\\Inject.dll";
	our $GetProcByName = new Win32::API("Tools", "GetProcByName", "P", "N") || die "Could not locate Tools.dll";
}


###COMPILE PORTALS###

print "\nChecking for new portals...";

if (compilePortals_check()) {
	print "found new portals!\n";
	print "Compile portals now? (y/n)\n";
	print "Auto-compile in $timeout{'compilePortals_auto'}{'timeout'} seconds...";
	$timeout{'compilePortals_auto'}{'time'} = time;
	undef $msg;
	while (!timeOut(\%{$timeout{'compilePortals_auto'}})) {
		if (Input::canRead()) {
			$msg = Input::readLine();
		}elsif ($sys{'Vx_interface'}){
			Vx::update();
			$msg = Vx::getInput();
		}
		last if ($msg ne "");
	}
	if ($msg =~ /y/ || $msg eq "") {
		print "compiling portals\n\n";
		compilePortals();
	} else {
		print "skipping compile\n\n";
	}
} else {
	print "none found\n";
}

if (!$sys{'Xmode'}) {
	if (!$config{'username'}) {
		print "Enter Username:\n";
		if (!$sys{'Vx_interface'}) {
			$msg = Input::readLine();
		}else{
			undef $msg;
			until ($msg ne "") {
				Vx::update();
				$msg = Vx::getInput();
			}
		}
		$config{'username'} = $msg;
		writeDataFileIntact("$def_config/config.txt", \%config);
	}
	if (!$config{'password'}) {
		print "Enter Password:\n";
		if (!$sys{'Vx_interface'}) {
			$msg = Input::readLine();
		}else{
			undef $msg;
			until ($msg ne "") {
				Vx::update();
				$msg = Vx::getInput();
			}
		}
		$config{'password'} = $msg;
		writeDataFileIntact("$def_config/config.txt", \%config);
	}
	if ($config{'master'} eq "") {
		$i = 0;
		print "--------- Master Servers ----------\n";
		print "#         Name\n";
		while ($config{"master_name_$i"} ne "") {
			print sprintf("%-3d %-43s\n",$i,$config{"master_name_$i"});
			$i++;
		}
		print "-----------------------------------\n";
		print "Choose your master server:\n";
		undef $msg;
		if (!$sys{'Vx_interface'}) {
			$msg = Input::readLine();
		}else{
			until ($msg ne "") {
				Vx::update();
				$msg = Vx::getInput();
			}
		}
		print $msg,"\n";
		$config{'master'} = $msg;
		writeDataFileIntact("$def_config/config.txt", \%config);
	}
}else{
	$timeout{'injectSync'}{'time'} = time;
}

our $conState = 1;
our $AI = 1;
undef $msg;
our $KoreStartTime = time;
# exp report
our $bExpSwitch = 2; 
our $jExpSwitch = 2; 
our $totalBaseExp = 0; 
our $totalJobExp = 0; 
our $startTime_EXP = time; 

#checkAuthorized();

#main loop
while ($quit != 1) {
	usleep($config{'sleepTime'});
	Vx::update() if($sys{'Vx_interface'});
	if ($sys{'Xmode'}) {
		if (timeOut(\%{$timeout{'injectKeepAlive'}})) {
			$conState = 1;
			my $printed = 0;
			my $procID = 0;
			do {
				$procID = $GetProcByName->Call($sys{'Xmode_exeName'});
				if (!$procID) {
					print "Error: Could not locate process $sys{'Xmode_exeName'}.\nWaiting for you to start the process..." if (!$printed);
					$printed = 1;
					Vx::update() if($sys{'Vx_interface'});
				}
				sleep 2;
			} while (!$procID && !$quit);

			if ($printed == 1) {
				print "Process found\n";
			}
			my $InjectDLL = new Win32::API("Tools", "InjectDLL", "NP", "I");
			my $retVal = $InjectDLL->Call($procID, $injectDLL_file) || die "Could not inject DLL";

			print "Waiting for InjectDLL to connect...\n";
			$remote_socket = $injectServer_socket->accept();
			(inet_aton($remote_socket->peerhost()) == inet_aton('localhost')) || die "Inject Socket must be connected from localhost";
			print "InjectDLL Socket connected - Ready to start botting\n";
			$timeout{'injectKeepAlive'}{'time'} = time;
		}
		if (timeOut(\%{$timeout{'injectSync'}})) {
			sendSyncInject(\$remote_socket);
			$timeout{'injectSync'}{'time'} = time;
		}
	}
	if($sys{'Vx_interface'} && Vx::getInputNum()>0){
		$inputp = Vx::getInput();
		parseInput($inputp);
		#checkAuthorized();
	}elsif (!$sys{'Vx_interface'} && Input::canRead) {
		$input = Input::readLine();
		parseInput($input);
		#checkAuthorized();
	} elsif (!$sys{'Xmode'} && dataWaiting(\$remote_socket)) {
		$remote_socket->recv($new, $MAX_READ);
		$msg .= $new;
		$msg_length = length($msg);
		while ($msg ne "") {
			$msg = parseMsg($msg);
			last if ($msg_length == length($msg));
			$msg_length = length($msg);
		}
	} elsif ($sys{'Xmode'} && dataWaiting(\$remote_socket)) {
		my $injectMsg;
		$remote_socket->recv($injectMsg, $MAX_READ);
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
	$ai_cmdQue_shift = 0;
	do {
		AI(\%{$ai_cmdQue[$ai_cmdQue_shift]}) if ($conState == 5 && timeOut(\%{$timeout{'ai'}}) && $remote_socket && $remote_socket->connected());
		undef %{$ai_cmdQue[$ai_cmdQue_shift++]};
		$ai_cmdQue-- if ($ai_cmdQue > 0);
	} while ($ai_cmdQue > 0);
	checkConnection();
}

#Terminate X mode
if ($sys{'Xmode'}){
	close($server_socket);
	unlink('buffer');
}

#Close Connection
close($remote_socket);
killConnection(\$remote_socket);

#Bye Bye Message
print "Bye!\n";
print $versionText;
sleep(5);

#Terminate Input
if (!$sys{'Vx_interface'}) {
	close($input_socket);
	kill 9, $input_pid;
	exit;
}else{
	Vx::Terminate();
}
#end main.

}

__start() unless defined $ENV{INTERPRETER};