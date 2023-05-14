#########################################################################
#  modKore - Hybrid :: Misc Utility
#  http://modkore.sf.net
#
#  This software is open source, licensed under the GNU General Public
#  License, version 2.
#  Basically, this means that you're allowed to modify and distribute
#  this software. However, if you distribute modified versions, you MUST
#  also distribute the source code.
#  See http://www.gnu.org/licenses/gpl.html for the full license.
#########################################################################

package Utils;

#errors detection
use strict;
no strict 'refs';
use Time::HiRes qw(time usleep);

#export function from this module
use Exporter;
our @ISA = ("Exporter");
our @EXPORT = qw(
	binAdd
	binFind
	binFindReverse
	binRemove
	binRemoveAndShift
	binRemoveAndShiftByIndex
	binSize
	existsInList
	existsInPatternList
	findIndex
	findIndexString
	findIndexString_lc
	findIndexString_lc_not_equip
	findIndexStringList_lc
	findKey
	findKeyString
	formatNumber
	minHeapAdd
	getCoordString
	getFormattedDate
	getHex
	getTickCount
	makeCoords
	makeCoords2
	makeIP
	portalExists
	timeConvert
	timeOut
	vocalString
	addTag
	judgeSkillArea
	sysLog_clear
						 );

#######################################
#######################################
#HASH/ARRAY MANAGEMENT
#######################################
#######################################

sub binAdd {
	my $r_array = shift;
	my $ID = shift;
	my $i;
	for ($i = 0; $i <= @{$r_array};$i++) {
		if (!defined($$r_array[$i])) {
			$$r_array[$i] = $ID;
			return $i;
		}
	}
}

sub binFind {
	my $r_array = shift;
	my $ID = shift;
	my $i;
	for ($i = 0; $i < @{$r_array};$i++) {
		if (defined($$r_array[$i]) && $$r_array[$i] eq $ID) {
			return $i;
		}
	}
}

sub binFindReverse {
	my $r_array = shift;
	my $ID = shift;
	my $i;
	for ($i = @{$r_array} - 1; $i >= 0;$i--) {
		if (defined($$r_array[$i]) && $$r_array[$i] eq $ID) {
			return $i;
		}
	}
}

sub binRemove {
	my $r_array = shift;
	my $ID = shift;
	my $i;
	for ($i = 0; $i < @{$r_array};$i++) {
		if (defined($$r_array[$i]) && $$r_array[$i] eq $ID) {
			undef $$r_array[$i];
			last;
		}
	}
}

sub binRemoveAndShift {
	my $r_array = shift;
	my $ID = shift;
	my $found = "";
	my $i;
	my @newArray;
	for ($i = 0; $i < @{$r_array};$i++) {
		if (defined($$r_array[$i]) && $$r_array[$i] ne $ID || $found ne "") {
			push @newArray, $$r_array[$i];
		} else {
			$found = $i;
		}
	}
	@{$r_array} = @newArray;
	return $found;
}

sub binRemoveAndShiftByIndex {
	my $r_array = shift;
	my $index = shift;
	my $found;
	my $i;
	my @newArray;
	for ($i = 0; $i < @{$r_array};$i++) {
		if ($i != $index) {
			push @newArray, $$r_array[$i];
		} else {
			$found = 1;
		}
	}
	@{$r_array} = @newArray;
	return $found;
}

sub binSize {
	my $r_array = shift;
	my $found = 0;
	my $i;
	for ($i = 0; $i < @{$r_array};$i++) {
		if ($$r_array[$i] ne "") {
			$found++;
		}
	}
	return $found;
}

sub existsInList {
	my ($list, $val) = @_;
	my @array = split / *, */, $list;
	return 0 if ($val eq "");
	$val = lc($val);
	foreach (@array) {
		s/^\s+//;
		s/\s+$//;
		s/\s+/ /g;
		next if ($_ eq "");
		return 1 if (lc($_) eq $val);
	}
	return 0;
}

sub existsInPatternList{
	my ($list,$val) = @_;
	return 0 if ($val eq "");
	my @array = split /,/, $list;
	foreach (@array) {
		return 1 if ($val =~/$_/);
	}
	return 0;
}

sub findIndex {
	my $r_array = shift;
	my $match = shift;
	my $ID = shift;
	my $i;
	for ($i = 0; $i < @{$r_array} ;$i++) {
		if ((%{$$r_array[$i]} && $$r_array[$i]{$match} eq $ID)
			|| (!%{$$r_array[$i]} && !defined($ID))) {
			return $i;
		}
	}
	if ($ID eq "") {
		return $i;
	}
}


sub findIndexString {
	my $r_array = shift;
	my $match = shift;
	my $ID = shift;
	my $i;
	for ($i = 0; $i < @{$r_array} ;$i++) {
		if ((%{$$r_array[$i]} && $$r_array[$i]{$match} eq $ID)
			|| (!%{$$r_array[$i]} && $ID eq "")) {
			return $i;
		}
	}
	if ($ID eq "") {
		return $i;
	}
}


sub findIndexString_lc {
	my $r_array = shift;
	my $match = shift;
	my $ID = shift;
	my $i;
	for ($i = 0; $i < @{$r_array} ;$i++) {
		if ((defined(%{$$r_array[$i]}) && lc($$r_array[$i]{$match}) eq lc($ID))
			|| (!%{$$r_array[$i]} && $ID eq "")) {
			return $i;
		}
	}
	if ($ID eq "") {
		return $i;
	}
}

sub findIndexString_lc_not_equip {
	my $r_array = shift;
	my $match = shift;
	my $ID = shift;
	my $i;
	for ($i = 0; $i < @{$r_array} ;$i++) {
		if ((%{$$r_array[$i]} && lc($$r_array[$i]{$match}) eq lc($ID) && !($$r_array[$i]{'equipped'}))
			 || (!%{$$r_array[$i]} && $ID eq "")) {			  
			return $i;
		}
	}
	if ($ID eq "") {
		return $i;
	}
}

sub findIndexStringList_lc{
	my $r_array = shift;
	my $match = shift;
	my $ID = shift;
	my ($i,$j);
	my @arr = split / *, */, $ID;
	for ($j = 0; $j < @arr; $j++) {
		for ($i = 0; $i < @{$r_array} ;$i++) {
			if (%{$$r_array[$i]} && lc($$r_array[$i]{$match}) eq lc($arr[$j])) {
				return $i;
			}
		}
	}
	if ($ID eq "") {
		return $i;
	}
}

sub findKey {
	my $r_hash = shift;
	my $match = shift;
	my $ID = shift;
	foreach (keys %{$r_hash}) {
		if ($$r_hash{$_}{$match} == $ID) {
			return $_;
		}
	}
}

sub findKeyString {
	my $r_hash = shift;
	my $match = shift;
	my $ID = shift;
	foreach (keys %{$r_hash}) {
		if ($$r_hash{$_}{$match} eq $ID) {
			return $_;
		}
	}
}

##
# formatNumber(num)
# num: An integer number.
# Returns: A formatted number with commas.
#
# Add commas to $num so large numbers are more readable.
# $num must be an integer, not a floating point number.
#
# Example:
# formatNumber(1000000)   # -> 1,000,000
sub formatNumber {
	my $num = shift;
	if (!$num) {
		return 0;
	} else {
		$num = reverse $num;
		my $len = length($num);
		my $count = 0;
		my $tmp = '';
		my @array = ();

		for (my $i = 0; $i < $len; $i++) {
			$tmp .= substr($num, $i, 1);
			$count++;
			if ($count == 3) {
				$count = 0;
				push @array, $tmp;
				$tmp = '';
			}
		}
		push @array, $tmp if ($tmp ne '');
		return reverse join(',', @array);
	}
}

sub minHeapAdd {
	my $r_array = shift;
	my $r_hash = shift;
	my $match = shift;
	my $i;
	my $found;
	my @newArray;
	for ($i = 0; $i < @{$r_array};$i++) {
		if (!$found && $$r_hash{$match} < $$r_array[$i]{$match}) {
			push @newArray, $r_hash;
			$found = 1;
		}
		push @newArray, $$r_array[$i];
	}
	if (!$found) {
		push @newArray, $r_hash;
	}
	@{$r_array} = @newArray;
}

sub getCoordString {
	my $x = shift;
	my $y = shift;
	return pack("C*", int($x / 4), ($x % 4) * 64 + int($y / 16), ($y % 16) * 16);
}

sub getFormattedDate {
	my $thetime = shift;
	my $r_date = shift;
	my @localtime = localtime $thetime;
	my $themonth = ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec')[$localtime[4]];
		$localtime[2] = "0" . $localtime[2] if ($localtime[2] < 10);
		$localtime[1] = "0" . $localtime[1] if ($localtime[1] < 10);
		$localtime[0] = "0" . $localtime[0] if ($localtime[0] < 10);
		$$r_date = "$themonth $localtime[3],".($localtime[5] + 1900)." $localtime[2]:$localtime[1]:$localtime[0]";
	return $$r_date;
}

sub getHex {
	my $data = shift;
	my $i;
	my $return;
	for ($i = 0; $i < length($data); $i++) {
		$return .= uc(unpack("H2",substr($data, $i, 1)));
		if ($i + 1 < length($data)) {
			$return .= " ";
		}
	}
	return $return;
}

sub getTickCount {
	my $time = int(time()*1000);
	if (length($time) > 9) {
		return substr($time, length($time) - 8, length($time));
	} else {
		return $time;
	}
}

sub makeCoords {
	my $r_hash = shift;
	my $rawCoords = shift;
	$$r_hash{'x'} = unpack("C", substr($rawCoords, 0, 1)) * 4 + (unpack("C", substr($rawCoords, 1, 1)) & 0xC0) / 64;
	$$r_hash{'y'} = (unpack("C",substr($rawCoords, 1, 1)) & 0x3F) * 16 + 
				(unpack("C",substr($rawCoords, 2, 1)) & 0xF0) / 16;
}

sub makeCoords2 {
	my $r_hash = shift;
	my $rawCoords = shift;
	$$r_hash{'x'} = (unpack("C",substr($rawCoords, 1, 1)) & 0xFC) / 4 + 
				(unpack("C",substr($rawCoords, 0, 1)) & 0x0F) * 64;
	$$r_hash{'y'} = (unpack("C", substr($rawCoords, 1, 1)) & 0x03) * 256 + unpack("C", substr($rawCoords, 2, 1));
}

sub makeIP {
	my $raw = shift;
	my $ret;
	for (my $i=0;$i < 4;$i++) {
		$ret .= hex(getHex(substr($raw, $i, 1)));
		if ($i + 1 < 4) {
			$ret .= ".";
		}
	}
	return $ret;
}

sub portalExists {
	my ($portals,$map, $r_pos) = @_;
	foreach (keys %{$portals}) {
		if ($$portals{$_}{'source'}{'map'} eq $map && $$portals{$_}{'source'}{'pos'}{'x'} == $$r_pos{'x'}
			&& $$portals{$_}{'source'}{'pos'}{'y'} == $$r_pos{'y'}) {
			return $_;
		}
	}
}

##
# timeConvert(time)
# time: number of seconds.
# Returns: a human-readable version of $time.
#
# Converts $time into a string in the form of "x seconds y minutes z seconds".
sub timeConvert {
	my $time = shift;
	my ($hours,$minutes,$seconds);
	my $gathered = '';

	$hours = int($time / 3600);
	$time = $time % 3600;
	$minutes = int($time / 60);
	$time = $time % 60;
	$seconds = $time;

	$gathered = "$hours hours " if ($hours);
	$gathered .= "$minutes minutes " if ($minutes);
	$gathered .= "$seconds seconds" if ($seconds);
	$gathered =~ s/ $//;
	$gathered = '0 seconds' if ($gathered eq '');
	return $gathered;
}

sub timeOut {
	my ($r_time, $compare_time) = @_;
	if ($compare_time ne "") {
		return (time - $r_time >= $compare_time);
	} else {
		return (time - $$r_time{'time'} >= $$r_time{'timeout'});
	}
}

#sub timeOut {
#	my $r_time = shift;
#	my $compare_time = shift;
#	if (defined($compare_time)) { # compare with 2 value
#		#non-defined 1 value
#		if (!defined($r_time)) { $r_time = time()}
#		return (time() - $r_time > $compare_time);

#	} else { #compare within %Hash
#		if (!exists($$r_time{'time'})) { $$r_time{'time'} = time()}
#		if (!exists($$r_time{'timeout'})) { $$r_time{'timeout'} = 0}
#		return (time() - $$r_time{'time'} > $$r_time{'timeout'});
#	}
#}

sub vocalString {
	my $letter_length = shift;
	return if ($letter_length <= 0);
	my $r_string = shift;
	my $test;
	my $i;
	my $password;
	my @cons = ("b", "c", "d", "g", "h", "j", "k", "l", "m", "n", "p", "r", "s", "t", "v", "w", "y", "z", "tr", "cl", "cr", "br", "fr", "th", "dr", "ch", "st", "sp", "sw", "pr", "sh", "gr", "tw", "wr", "ck");
	my @vowels = ("a", "e", "i", "o", "u" , "a", "e" ,"i","o","u","a","e","i","o", "ea" , "ou" , "ie" , "ai" , "ee" ,"au", "oo");
	my %badend = ( "tr" => 1, "cr" => 1, "br" => 1, "fr" => 1, "dr" => 1, "sp" => 1, "sw" => 1, "pr" =>1, "gr" => 1, "tw" => 1, "wr" => 1, "cl" => 1);
	for (;;) {
		$password = "";
		for($i = 0; $i < $letter_length; $i++){
			$password .= $cons[rand(@cons - 1)] . $vowels[rand(@vowels - 1)];
		}
		$password = substr($password, 0, $letter_length);
		($test) = ($password =~ /(..)\z/);
		last if ($badend{$test} != 1);
	}
	$$r_string = $password;
	return $$r_string;
}

#######################################
#######################################
#MISC FUNCTION
#######################################
#######################################

sub addTag{
	my $tag = shift;
	my $detail = shift;
	my $amount = shift;
	return if (!$tag);
	if (defined($amount)  && $amount =~ /\d+/ && $amount == 0) {
		$detail .= "Miss";
	}elsif (defined($amount)  && $amount !~ /\d+/){
		$detail .= $detail;
	}
	return "#".$detail."#";
}

sub judgeSkillArea {
	my $skill = shift;
	if ($skill == 81 || $skill == 85
		|| $skill == 89 || $skill == 83 
		|| $skill == 110 || $skill ==91) { 
		 return 5; 
	} elsif ($skill == 70 || $skill == 79 ){ 
		 return 4; 
	} elsif ($skill == 21 || $skill == 17 ){ 
		 return 3; 
	} elsif ($skill == 88 || $skill == 80
		|| $skill == 11 || $skill == 18
		|| $skill == 140 || $skill == 229 ) { 
		 return 2; 
	} else { 
		 return 0; 
	} 
}

sub sysLog_clear {
	my $file = shift;
	if (-e "$file"."_GMMessage.txt") { unlink("$file"."_GMMessage.txt"); }
	if (-e "$file"."_Items.txt") { unlink("$file"."_Items.txt"); }
	if (-e "$file"."_Chat.txt") { unlink("$file"."_Chat.txt"); }
	if (-e "$file"."_Storage.txt") { unlink("$file"."_Storage.txt"); }
	if (-e "$file"."_Shop.txt") { unlink("$file"."_Shop.txt"); }
	if (-e "$file"."_sendDUMP.txt") { unlink("$file"."_sendDUMP.txt"); }
	if (-e "$file"."_recvDUMP.txt") { unlink("$file"."_recvDUMP.txt"); }
	if (-e "$file"."_Monsters.txt") { unlink("$file"."_Monsters.txt"); }
}

1;