#########################################################################
#  modKore :: System Framework
#  http://modkore.sf.net
#
#  This software is open source, licensed under the GNU General Public
#  License, version 2.
#  Basically, this means that you're allowed to modify and distribute
#  this software. However, if you distribute modified versions, you MUST
#  also distribute the source code.
#  See http://www.gnu.org/licenses/gpl.html for the full license.
#########################################################################

package System;

#errors detection
use strict;
no warnings;

use Getopt::Long;
use Digest::MD5;
use Time::HiRes qw(time usleep);
use IO::Socket;
use Win32::Sound;

use Interface;
use Globals;
use Utils;

#export function from this module
use Exporter;
our @ISA = ("Exporter");
our @EXPORT_OK = qw(
	init
	terminate
	message
	error
	getInput
	setProfile
	showVersion
	recvIncomingData
	haveIncomingData
);

#constant
our $NAME = "modKore-Plus!";
our $VERSION = getupdateDay();
our $CVS = "";
our $WEBSITE = "http://modkore.sf.net";
our $versionText = "***   $NAME ${VERSION} ${CVS} ***\n***   $WEBSITE   ***\n";
our $MAX_READ = 30000;

#DATA Management
our $def_config;
our $def_table;
our $def_field;
our $def_interface;
our $xMode;
our $seedMode = 0;
our %error;
our %logFile;
our $interface;
our $plugins_folder;

#Socket Port
our $remote_socket;
our $injectServer_socket;


######################################################
sub init {
	parseArguments();
	if (!$seedMode) {
		$interface = new Interface;
		$interface = $interface->switchInterface($def_interface,1);
	}else{
		require Win32::Console; import Win32::Console;
		Win32::Console->new(&STD_OUTPUT_HANDLE())->Free or sub{$seedMode=0; error("could not free console: $!\n");};
	}
	showVersion();
	if ($xMode) {
		message("---[ Xmode ]------------------------------------------\n");
		$injectServer_socket = IO::Socket::INET->new(
			Listen		=> 5,
			LocalAddr	=> 'localhost',
			LocalPort	=> 2350,
			Proto		=> 'tcp') || error("Error creating local inject server: $!","critical");
		message("Local inject server started (".$injectServer_socket->sockhost().":2350)\n");
		message("------------------------------------------------------\n");
	}#else{
		#$remote_socket = IO::Socket::INET->new();
	#}
}

######################################################

sub terminate {
	if ($xMode && $remote_socket && $remote_socket->connected()) {
		$remote_socket->send("Z".pack("S", 0));
	}
	close($remote_socket) if (defined $remote_socket);
	close($injectServer_socket) if (defined $injectServer_socket);
	message($versionText."\n","version");
	getInput(3);
}

######################################################
sub parseArguments {
	my $help_option;
	$def_config = "control";
	$def_table = "tables";
	$def_field = "fields";
	$def_interface = "Console";
	$plugins_folder = "plugins";
	# init Command Line
	&GetOptions(
					'control=s',\$def_config,
					'fields=s',\$def_field,
					'tables=s',\$def_table,
					'xmode=s',\$xMode,
					'seed',\$seedMode,
					'interface=s',\$def_interface,
					'help',\$help_option
					);
	if ($help_option) { 
		print "Usage: .exe name [options...]\n";
		print "The supported options are:\n";
		print "--help\t\tDisplays this help message.\n";
		print "--control=path\tWhere config folder to use.\n";
		print "--fields=path\tWhere fields folder to use.\n";
		print "--tables=path\tWhere tables folder to use.\n";
		print "--xmode=process name\tStarting xMode.\n";
		print "--interface=interface name\tinitial Interface.\n";
		print "--seed\tStarting Hide Console Mode (Win32).\n";
		exit();
	}

	if (! -d "logs") {
		if (!mkdir("logs")) {
			print "Error: unable to create folder ($!)\n";
			exit 1;
		}
		
	}
}


######################################################

sub debug {
}

######################################################

sub error {
	return if ($seedMode);
	my $text = shift;
	my $type = shift;
	$error{$type}++;
	return processMsg("error",	# type
		$text,						# message
		$type,						# domain
		$1,						# level
		$config{'verbose'},			# currentVerbosity
		);
}

######################################################

sub message {
	return if ($seedMode);
	if (defined $_[3]) {
		sysLog($_[3],$_[0]);
	}
	return processMsg("message",	# type
		$_[0],						# message
		$_[1],						# domain
		$_[2],						# level
		$config{'verbose'},			# currentVerbosity
		);
}

######################################################

sub warning {
	return if ($seedMode);
	return processMsg("warning",
		$_[0],
		$_[1],
		$_[2],
		$config{'verbose'});
}

######################################################

sub processMsg {
	my $type = shift;
	my $message = shift;
	my $domain = (shift or "console");
	my $level = (shift or 0);
	my $currentVerbosity = shift;

	return unless $interface;

	# Print to console if the current verbosity is high enough
	if ($level <= $currentVerbosity) {
		$interface->writeOutput($type, $message, $domain) if (defined $interface);
	}

}



######################################################

sub showVersion {
	message "$versionText\n";
}

######################################################
sub noCriticalError {
	return ($error{'critical'} <= 0);
}

######################################################
sub getInput{
	my $timeOut = shift;
	return undef if ($seedMode);
	my $input = $interface->getInput($timeOut) or undef;
	return $input;
}

######################################################
#    Log File Control
######################################################

sub sysLog {
	my $type = shift;
	my $message = shift;
# Seperate ChatLog
	if ( $type eq "s") {
		soundPlay($config{'alertSound_onGMnotice'},$config{'alertSound_volume'}) if ($config{'alertSound'} && $^O eq 'MSWin32' && $config{'alertSound_onGMnotice'});
		open CHAT, ">> logs\/$config{'username'}_GMMessage.txt";
		print CHAT "[".getFormattedDate(int(time))."][".uc($type)."] $message";
	} elsif ( $type eq "i") {
		soundPlay($config{'alertSound_onItem'},$config{'alertSound_volume'}) if ($message =~ /\*\*/ && $config{'alertSound'} && $^O eq 'MSWin32' && $config{'alertSound_onItem'});
		open CHAT, ">> logs\/$config{'username'}_items.txt";
		print CHAT "[".getFormattedDate(int(time))."] : $message";
	} elsif ( $type eq "m") {
		open CHAT, ">> logs\/$config{'username'}_monsters.txt";
		print CHAT "[".getFormattedDate(int(time))."] : $message";
	} elsif ( $type eq "shop") {
		soundPlay($config{'alertSound_onShop'},$config{'alertSound_volume'}) if ($config{'alertSound'});
		open CHAT, ">> logs\/$config{'username'}_Shop.txt";
		print CHAT "[".getFormattedDate(int(time))."] $message";
	} else {
		soundPlay($config{'alertSound_onDanger'},$config{'alertSound_volume'}) if ($config{'alertSound'} && $type eq "D");
		soundPlay($config{'alertSound_onPM'},$config{'alertSound_volume'}) if ($config{'alertSound'} && $type eq "pm");
		open CHAT, ">> logs\/$config{'username'}_Chat.txt";
		print CHAT "[".getFormattedDate(int(time))."][".uc($type)."] $message";
	}
	close CHAT;
}

sub clearLog {
	unlink <logs/$config{'username'}*.txt>;
	message "All log cleared.\n";
}

sub getupdateDay{
	my $update_day = (stat($0))[9];
	my @localtime = localtime $update_day;
	$localtime[3] = "0".$localtime[3] if ($localtime[3]<10);
	$localtime[4]++;
	$localtime[4] = "0".$localtime[4] if ($localtime[4]<10);
	$localtime[5] %=100;
	$localtime[5] = "0".$localtime[5] if ($localtime[5]<10);
	return "$localtime[3]/$localtime[4]/$localtime[5]";
}

sub soundPlay {
	my $wav = shift;
	my $vol = shift;
	Win32::Sound::Play($wav,"SND_ASYNC") if ($wav != "");
}

######################################################
#    Socket Control
######################################################

sub recvIncomingData{
	my ($msg);
	$remote_socket->recv($msg, $MAX_READ);
	return $msg;
}

sub haveIncomingData {
	return (defined $remote_socket) ? dataWaiting(\$remote_socket) : 0;
}

1;