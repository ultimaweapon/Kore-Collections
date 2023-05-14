#########################################################################
#  modKore-Hybrid :: Settings
#  http://modkore.sf.net
#
#  Original Code :: OpenKore - Settings 
#  This module defines configuration variables and filenames of data files.
#
#  This software is open source, licensed under the GNU General Public
#  License, version 2.
#  Basically, this means that you're allowed to modify and distribute
#  this software. However, if you distribute modified versions, you MUST
#  also distribute the source code.
#  See http://www.gnu.org/licenses/gpl.html for the full license.
#########################################################################

package Settings;

#errors detection
use strict;
no warnings;

#Require Module
use Getopt::Long;

#export from this module
use Exporter;
our @ISA = ("Exporter");
our @EXPORT_OK = qw(parseArguments);
our @EXPORT = qw(
	$def_config
	$def_table
	$def_field
	$MAX_READ
	%jobs_lut
	@sex_lut
	$versionText
);


# Constants
our %jobs_lut = (
	0=>'Novice',
	1=>'Swordsman',
	2=>'Mage',
	3=>'Archer',
	4=>'Acolyte',
	5=>'Merchant',
	6=>'Thief',
	7=>'Knight',
	8=>'Priest',
	9=>'Wizard',
	10=>'Blacksmith',
	11=>'Hunter',
	12=>'Assassin',
	13=>'Knight P',
	14=>'Crusader',
	15=>'Monk',
	16=>'Sage',
	17=>'Rogue',
	18=>'Alchemist',
	19=>'Bard',
	20=>'Dancer',
	21=>'Crusader P',
	22=>'unKnown 22',
	23=>'unKnown 23',
	4001=>'Novice High',
	4002=>'Swordsman High',
	4003=>'Magician High',
	4004=>'Archer High',
	4005=>'Acolyte High',
	4006=>'Merchant High',
	4007=>'Thief High',
	4008=>'Lord Knight',
	4009=>'High Priest',
	4010=>'High Wizard',
	4011=>'Whitesmith',
	4012=>'Sniper',
	4013=>'Assassin Cross',
	4015=>'Paladin',
	4016=>'Champion',
	4017=>'Professor',
	4018=>'Stalker',
	4019=>'Creator',
	4020=>'Clown / Gypsy',
);

our @sex_lut = ("Girl","Boy");
our $MAX_READ = 30000;

# Data Source Path Variables
our $def_config;
our $def_table;
our $def_field;
our $versionText = "*** modKore-Hybrid ReB!rth -- http://modkore.sf.net ***\n";

sub parseArguments {
	my $help_option;
	# init Command Line
	&GetOptions(
					'control=s',\$def_config,
					'fields=s',\$def_field,
					'tables=s',\$def_table,
					'help',\$help_option
					);
	if ($help_option) { 
		print "Usage: .exe name [options...]\n";
		print "The supported options are:\n";
		print "--help\t\tDisplays this help message.\n";
		print "--control=path\tWhere config folder to use.\n";
		print "--fields=path\tWhere fields folder to use.\n";
		print "--tables=path\tWhere tables folder to use.\n";
		exit();
	}

	$def_config = "control" if (!defined $def_config);
	$def_table = "tables" if (!defined $def_table);
	$def_field = "fields" if (!defined $def_field);

	if (! -d "logs") {
		if (!mkdir("logs")) {
			print "Error: unable to create folder ($!)\n";
			exit 1;
		}
	}
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

1;