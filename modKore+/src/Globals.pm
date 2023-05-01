#########################################################################
#  OpenKore - Global variables
#
#  This software is open source, licensed under the GNU General Public
#  License, version 2.
#  Basically, this means that you're allowed to modify and distribute
#  this software. However, if you distribute modified versions, you MUST
#  also distribute the source code.
#  See http://www.gnu.org/licenses/gpl.html for the full license.
#
#
#
#  $Revision: 1.1 $
#  $Id: Globals.pm,v 1.1 2004/11/01 17:42:42 Administrator Exp $
#
#########################################################################
##
# MODULE DESCRIPTION: Global variables
#
# This module defines all kinds of global variables.

package Globals;

use strict;
use Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(
	@ai_seq
	@ai_seq_args
	%ai_v

	@chars
	@playersID
	%players
	@monstersID
	%monsters
	@portalsID
	%portals
	@itemsID
	%items
	@npcsID
	%npcs
	%field

	%jobs_lut
	@sex_lut 
	%config
	%items_control
	%mon_control
	%ppl_control
	%gid_control
	%itemsPickup
	%timeout
	%qmsg
	%responses
	%overallAuth
	%cart_control
	%shop
	%consoleColors

	%cities_lut
	%emotions_lut
	%equipTypes_lut
	%items_lut
	%itemTypes_lut
	%maps_lut
	%monsters_lut
	%npcs_lut
	%portals_lut
	%portals_los
	%skills_lut
	%skillsID_lut
	%skills_rlut
	%skillsSP_lut
	%rpackets
	%skillsST_lut
	%cards_lut
	%elements_lut
	%GameMasters
	$buildType
	$conState
	$quit
	$char
	);


# AI
our @ai_seq;
our @ai_seq_args;
our %ai_v;

our $quit;
our $char;
# Game state
our @chars;
our @playersID;
our %players;
our @monstersID;
our %monsters;
our @portalsID;
our %portals;
our @itemsID;
our %items;
our @npcsID;
our %npcs;
our %field;

# Data & Constants Data

our %config;
our %consoleColors;
our %items_control;
our %mon_control;
our %ppl_control;
our %gid_control;
our %itemsPickup;
our %timeout;
our %qmsg;
our %responses;
our %overallAuth;
our %cart_control;
our %shop;
our %cities_lut;
our %emotions_lut;
our %equipTypes_lut;
our %items_lut;
our %itemTypes_lut;
our %maps_lut;
our %monsters_lut;
our %npcs_lut;
our %portals_lut;
our %portals_los;
our %skills_lut;
our %skillsID_lut;
our %skills_rlut;
our %skillsSP_lut;
our %rpackets;
our %skillsST_lut;
our %cards_lut;
our %elements_lut;
our %GameMasters;

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
	22=>'Wedding Suit',
	23=>'Super Novice',
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

our %skillarea_lut = (
	126=>"Safety Wal",
	127=>"Fire Wal",
	128=>"Warp Potal",
	129=>"Casting Warp Portal",
	131=>"Santuary",
	132=>"Magnus Exorcismus",
	133=>"Pneuma",
	134=>"Big Magic",
	135=>"Fire Pillar",
	141=>"Ice Wall",
	142=>"Quagmire",
	143=>"Blast Mine",
	144=>"Skid Trap",
	145=>"Ankle Snare",
	146=>"Venom Dust",
	147=>"Land Mine",
	148=>"Shockwave Trap",
	149=>"Sandman",
	150=>"Flasher",
	151=>"Freezing Trap",
	152=>"Claymore Trap",
	154=>"Volcano",
	155=>"Deluge",
	156=>"Violent Gale",
	157=>"Land Protector",
	158=>"Lullaby",
	159=>"Rich Man Mr.Kim",
	160=>"Eternal Chaos",
	161=>"Drum Sound on Battlefield",
	162=>"Ring of Nibelungen",
	163=>"Roki's Weil",
	164=>"Into Abyss",
	165=>"Invulnerable Siegfried",
	166=>"Dissonance",
	167=>"Whistle",
	168=>"Assassin Cross at Sunset",
	169=>"Bragi's Poem",
	170=>"Idun's Apple",
	171=>"Ugly Dance",
	172=>"Humming",
	173=>"Don't Forget Me",
	174=>"Kiss of Fortune",
	175=>"Service For You",
);

our $buildType;
our $conState;
# Detect operating system
if ($^O eq 'MSWin32' || $^O eq 'cygwin') {
	$buildType = 0;
} else {
	$buildType = 1;
}

return 1;