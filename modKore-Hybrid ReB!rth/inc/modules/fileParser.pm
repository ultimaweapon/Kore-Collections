#########################################################################
#  modKore - Hybrid :: File Parser
#  http://modkore.sf.net
#
#  This software is open source, licensed under the GNU General Public
#  License, version 2.
#  Basically, this means that you're allowed to modify and distribute
#  this software. However, if you distribute modified versions, you MUST
#  also distribute the source code.
#  See http://www.gnu.org/licenses/gpl.html for the full license.
#########################################################################

package fileParser;

#error detection
use strict;
no warnings;


#export function from this module
use Exporter;
our @ISA = ("Exporter");
our @EXPORT = qw(
	addParseFiles
	convertGatField
	getField
	getGatField
	getRoutePoint
	load
	parseCartControl
	parseChatMsg
	parseDataFile
	parseDataFile_lc
	parseDataFile2
	parseDataFile3
	parseGIDControl
	parseItemsControl
	parseMonControl
	parseNPCs
	parsePortals
	parsePortalsLOS
	parsePplControl
	parseReload
	parseResponses
	parseROLUT
	parseSkillsIDLUT
	parseSkillsLUT
	parseSkillsReverseLUT_lc
	parseSkillsSPLUT
	parseTimeouts
	writeDataFile
	writeDataFileIntact
	writeDataFileIntact2
	writePortalsLOS
	updateMonsterLUT
	updatePortalLUT
	updateNPCLUT
						 );


#######################################
#######################################
#FILE PARSER
#######################################
#######################################

sub addParseFiles {
	my $r_array = shift;
	my $file = shift;
	my $hash = shift;
	my $function = shift;
	my $fields = {};
	$fields->{'file'} = $file;
	$fields->{'hash'} = $hash;
	$fields->{'function'} = $function;
	push @{$r_array} , $fields;
}

sub convertGatField {
	my $file = shift;
	my $r_hash = shift;
	my $i;
	open FILE, "+> $file";
	binmode(FILE);
	print FILE pack("S*", $$r_hash{'width'}, $$r_hash{'height'});
	for ($i = 0; $i < @{$$r_hash{'field'}}; $i++) {
		print FILE pack("C1", $$r_hash{'field'}[$i]);
	}
	close FILE;
}

sub getField {
	my $file = shift;
	my $r_hash = shift;
	my ($data, $read);
	undef %{$r_hash};
	if (!(-e $file)) {
		print "\n!!Could not load field - you must install the kore-field pack!!\n\n";
	}
	if ($file =~ /\//) {
		($$r_hash{'name'}) = $file =~ /^.*\/([\s\S]*)\./;
	} else {
		($$r_hash{'name'}) = $file =~ /([\s\S]*)\./;
	}
	#($$r_hash{'name'}) = $file =~ m{/?([^/.]*)\.};
	open FILE, "<", $file;
	binmode(FILE);
	my $data;
	{
		local($/);
		$data = <FILE>;
	}
	close FILE;
	@$r_hash{'width', 'height'} = unpack("S1 S1", substr($data, 0, 4, ''));
	$$r_hash{'rawMap'} = $data;
	$$r_hash{'binMap'} = pack('b*', $data);
	$$r_hash{'field'} = [unpack("C*", $data)];
	(my $dist_file = $file) =~ s/\.fld$/.dist/i;
	if (-e $dist_file) {
		open FILE, "<", $dist_file;
		binmode(FILE);
		my $dist_data;

		{
			local($/);
			$dist_data = <FILE>;
		}
		close FILE;
		my ($dw, $dh) = unpack("S1 S1", substr($dist_data, 0, 4, ''));
		if ($$r_hash{'width'} == $dw && $$r_hash{'height'} == $dh) {
			$$r_hash{'dstMap'} = $dist_data;
		}
	}
	unless ($$r_hash{'dstMap'}) {
		print "Building distance map for $$r_hash{'name'}.\nThis may take a while, but will only be done once for this map.\n";
		$$r_hash{'dstMap'} = makeDistMap(@$r_hash{'rawMap', 'width', 'height'});
		print "Done.\n";
		open FILE, ">", $dist_file or die "Could not write dist cache file: $!\n";
		binmode(FILE);
		print FILE pack("S1 S1", @$r_hash{'width', 'height'});
		print FILE $$r_hash{'dstMap'};
		close FILE;
	}
}


sub makeDistMap {
	my $data = shift;
	my $height = shift;
	my $width = shift;
	for (my $i = 0; $i < length($data); $i++) {
		substr($data, $i, 1, (ord(substr($data, $i, 1)) ? chr(0) : chr(255)));
	}
	my $done = 0;
	until ($done) {
		$done = 1;
		#'push' wall distance right and up
		for (my $y = 0; $y < $height; $y++) {
			for (my $x = 0; $x < $width; $x++) {
				my $i = $y * $width + $x;
				my $dist = ord(substr($data, $i, 1));
				if ($x != $width - 1) {
					my $ir = $y * $width + $x + 1;
					my $distr = ord(substr($data, $ir, 1));
					my $comp = $dist - $distr;
					if ($comp > 1) {
						my $val = $distr + 1;
						$val = 255 if $val > 255;
						substr($data, $i, 1, chr($val));
						$done = 0;
					} elsif ($comp < -1) {
						my $val = $dist + 1;
						$val = 255 if $val > 255;
						substr($data, $ir, 1, chr($val));
						$done = 0;
					}
				}
				if ($y != $height - 1) {
					my $iu = ($y + 1) * $width + $x;
					my $distu = ord(substr($data, $iu, 1));
					my $comp = $dist - $distu;
					if ($comp > 1) {
						my $val = $distu + 1;
						$val = 255 if $val > 255;
						substr($data, $i, 1, chr($val));
						$done = 0;
					} elsif ($comp < -1) {
						my $val = $dist + 1;
						$val = 255 if $val > 255;
						substr($data, $iu, 1, chr($val));
						$done = 0;
					}
				}
			}
		}
		#'push' wall distance left and down
		for (my $y = $height - 1; $y >= 0; $y--) {
			for (my $x = $width - 1; $x >= 0 ; $x--) {
				my $i = $y * $width + $x;
				my $dist = ord(substr($data, $i, 1));
				if ($x != 0) {
					my $il = $y * $width + $x - 1;
					my $distl = ord(substr($data, $il, 1));
					my $comp = $dist - $distl;
					if ($comp > 1) {
						my $val = $distl + 1;
						$val = 255 if $val > 255;
						substr($data, $i, 1, chr($val));
						$done = 0;
					} elsif ($comp < -1) {
						my $val = $dist + 1;
						$val = 255 if $val > 255;
						substr($data, $il, 1, chr($val));
						$done = 0;
					}
				}
				if ($y != 0) {
					my $id = ($y - 1) * $width + $x;
					my $distd = ord(substr($data, $id, 1));
					my $comp = $dist - $distd;
					if ($comp > 1) {
						my $val = $distd + 1;
						$val = 255 if $val > 255;
						substr($data, $i, 1, chr($val));
						$done = 0;
					} elsif ($comp < -1) {
						my $val = $dist + 1;
						$val = 255 if $val > 255;
						substr($data, $id, 1, chr($val));
						$done = 0;
					}
				}
			}
		}
	}
	return $data;
}

sub getGatField {
	my $file = shift;
	my $r_hash = shift;
	my ($i,$data);
	undef %{$r_hash};
	($$r_hash{'name'}) = $file =~ /([\s\S]*)\./;
	open FILE, $file;
	binmode(FILE);
	read(FILE, $data, 16);
	my $width = unpack("L1", substr($data, 6,4));
	my $height = unpack("L1", substr($data, 10,4));
	$$r_hash{'width'} = $width;
	$$r_hash{'height'} = $height;
	while (read(FILE, $data, 20)) {
		$$r_hash{'field'}[$i] = unpack("C1", substr($data, 14,1));
		$i++;
	}
	close FILE;
}

sub getRoutePoint {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my ($key,$value_1,$value_2);
	if (!(-e $file)) {
		print "\n!!Could not load Waypoint - you must install waypoint for this map!!\n\n";
		return 0;
	}
	if ($file =~ /\//) {
		($$r_hash{'name'}) = $file =~ /\/([\s\S]*)\./;
	} else {
		($$r_hash{'name'}) = $file =~ /([\s\S]*)\./;
	}
	open FILE, $file;
	$$r_hash{'max'} = 0;
	foreach (<FILE>) {
		next if (/^#/ || /^\n/);
		s/[\r\n]//g;
		($value_1,$value_2) = $_ =~ /(\d+):(\d+)/;
		$$r_hash{$$r_hash{'max'}}{'x'} = $value_1;
		$$r_hash{$$r_hash{'max'}}{'y'} = $value_2;
		$$r_hash{'max'}++;
	}
	close FILE;
}

sub load {
	my $r_array = shift;
	foreach (@{$r_array}) {
		if (-e $$_{'file'}) {
			print "Loading $$_{'file'}...\n";
		} else {
			print "Error: Couldn't load $$_{'file'}\n";
		}
		&{$$_{'function'}}("$$_{'file'}", $$_{'hash'});
	}
}

sub parseCartControl {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my ($key,@args,$argls);
	open FILE, $file;
	foreach (<FILE>) {
		next if (/^#/ || /^\n/);
		s/[\r\n]//g;
		s/\s+$//g;
		($key, $argls) = $_ =~ /([\s\S]+?)\s+(\d+[\s\S]*)/;
		$key =~ s/_/ /g;
		@args = split / /,$argls;
		if ($key ne "") {
			$$r_hash{lc($key)}{'keep'} = $args[0];
			$$r_hash{lc($key)}{'addAuto'} = $args[1];
			$$r_hash{lc($key)}{'getAuto'} = $args[2];
			$$r_hash{lc($key)}{'storage'} = $args[3];
		}
	}
	close FILE;
}

# Parse Chatauto.txt
sub parseChatMsg {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my ($key,$value,$j,$args);
	open FILE, $file;
	my $i=0;
	foreach(<FILE>) {
		next if (/^#/ || /^\n/);
		s/[\r\n]//g;
		s/\s+$//g;
		($key, $args) = $_ =~ /([\s\S]*)\t([\s\S]*)/;
		if ($key ne "") {
				$key =~ s/_/ /g;
				my @data = split /,/,lc($key);
				my @args = split /,/,$args;
				push @{ $$r_hash{'/ans'}{$i} },@args;
				foreach my $keys (@data) {
					$$r_hash{$keys} = $i;
				}
				$i++;
		}
	}
	close FILE;
}

sub parseDataFile {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my ($key,$value);
	open FILE, $file;
	foreach (<FILE>) {
		next if (/^#/ || /^\n/);
		s/[\r\n]//g;
		s/\s+$//g;
		($key, $value) = $_ =~ /([\s\S]*)\s+([\s\S]*?)$/;
		if ($key ne "" && $value ne "") {
			$$r_hash{$key} = $value;
		}
	}
	close FILE;
}

sub parseDataFile_lc {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my ($key,$value);
	open FILE, $file;
	foreach (<FILE>) {
		next if (/^#/ || /^\n/);
		s/[\r\n]//g;
		s/\s+$//g;
		($key, $value) = $_ =~ /([\s\S]*)\s+([\s\S]*?)$/;
		if ($key ne "" && $value ne "") {
			$$r_hash{lc($key)} = $value;
		}
	}
	close FILE;
}

sub parseDataFile2 {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my ($key,$value);
	open FILE, $file;
	foreach (<FILE>) {
		next if (/^#/ || /^\n/);
		s/[\r\n]//g;
		s/\s+$//g;
		($key, $value) = $_ =~ /([\s\S]*?)\s+([\s\S]*)$/;
		$key =~ s/\s//g;
		if ($key eq "") {
			($key) = $_ =~ /([\s\S]*)$/;
			$key =~ s/\s//g;
		}
		if ($key ne "") {
			$$r_hash{$key} = $value;
		}
	}
	close FILE;
}

sub parseDataFile3 {
	my $file = shift;
	my $r_hash = shift;
	my ($ID,$key, $value);
	undef %{$r_hash};
	open FILE, $file;
	foreach (<FILE>) {
		next if (/^#/ || /^\n/);
		s/[\r\n]//g;
		s/\s+$//g;
		($key, $value) = $_ =~ /([\s\S]*?)\s+([\s\S]*)$/;
		if($key ne "" ){
			$ID = pack("L1",$key);
			if ($value eq ""){
				$value = 1;
			}
			$$r_hash{$ID} = $value;
		}
	}
	close FILE;
}

#parse GID function
sub parseGIDControl {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my ($key,@args,$argls);
	open FILE, $file;
	foreach (<FILE>) {
		next if (/^#/ || /^\n/);
		s/[\r\n]//g;
		s/\s+$//g;
		($key, $argls) = $_ =~ /([\s\S]+?)\s+(\d+[\s\S]*)/;
		@args = split / /,$argls;
		if ($key ne "") {
			$key = pack("L1",$key);
			$$r_hash{$key}{'teleport_auto'} = $args[0];
			$$r_hash{$key}{'disconnect_auto'} = $args[1];
		}
	}
	close FILE;
}

sub parseItemsControl {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my ($key,@args,$argls);
	open FILE, $file;
	foreach (<FILE>) {
		next if (/^#/ || /^\n/);
		s/[\r\n]//g;
		s/\s+$//g;
		($key, $argls) = $_ =~ /([\s\S]+?)\s+(\d+[\s\S]*)/;
		$key =~ s/_/ /g;
		@args = split / /,$argls;
		if ($key ne "") {
			$$r_hash{lc($key)}{'keep'} = $args[0];
			$$r_hash{lc($key)}{'storage'} = $args[1];
			$$r_hash{lc($key)}{'sell'} = $args[2];
		}
	}
	close FILE;
}

sub parseMonControl {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my ($key,@args,$argls);
	open FILE, $file;
	foreach (<FILE>) {
		next if (/^#/ || /^\n/);
		s/[\r\n]//g;
		s/\s+$//g;
		($key, $argls) = $_ =~ /([\s\S]+?)\s+(\d+[\s\S]*)/;
		$key =~ s/_/ /g;
		@args = split / /,$argls;
		if ($key ne "") {
			$$r_hash{lc($key)}{'attack_auto'} = $args[0];
			$$r_hash{lc($key)}{'teleport_auto'} = $args[1];
			$$r_hash{lc($key)}{'teleport_search'} = $args[2];
			$$r_hash{lc($key)}{'skillcancel_auto'} = $args[3];
			$$r_hash{lc($key)}{'aggressive_auto'} = $args[4];
		}
	}
	close FILE;
}

sub parseNPCs {
	my $file = shift;
	my $r_hash = shift;
	my ($i, $string);
	undef %{$r_hash};
	my ($key,$value,@args);
	open FILE, $file;
	foreach (<FILE>) {
		next if (/^#/ || /^\n/);
		s/[\r\n]//g;
		s/\s+/ /g;
		s/\s+$//g;
		@args = split /\s/, $_;
		if (@args > 4) {
			$$r_hash{$args[0]}{'map'} = $args[1];
			$$r_hash{$args[0]}{'pos'}{'x'} = $args[2];
			$$r_hash{$args[0]}{'pos'}{'y'} = $args[3];
			$string = $args[4];
			for ($i = 5; $i < @args; $i++) {
				$string .= " $args[$i]";
			}
			$$r_hash{$args[0]}{'name'} = $string;
		}
	}
	close FILE;
}

sub parsePortals {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my ($key,$value,$i,%IDs,@args);
	my $j = 0;
	open FILE, $file;
	foreach (<FILE>) {
		next if (/^#/ || /^\n/);
		s/[\r\n]//g;
		s/\s+/ /g;
		s/\s+$//g;
		@args = split /\s/, $_;
		if (@args > 5) {
			$IDs{$args[0]}{$args[1]}{$args[2]} = "$args[0] $args[1] $args[2]";
			$$r_hash{"$args[0] $args[1] $args[2]"}{'source'}{'ID'} = "$args[0] $args[1] $args[2]";
			$$r_hash{"$args[0] $args[1] $args[2]"}{'source'}{'map'} = $args[0];
			$$r_hash{"$args[0] $args[1] $args[2]"}{'source'}{'pos'}{'x'} = $args[1];
			$$r_hash{"$args[0] $args[1] $args[2]"}{'source'}{'pos'}{'y'} = $args[2];
			$$r_hash{"$args[0] $args[1] $args[2]"}{'dest'}{'map'} = $args[3];
			$$r_hash{"$args[0] $args[1] $args[2]"}{'dest'}{'pos'}{'x'} = $args[4];
			$$r_hash{"$args[0] $args[1] $args[2]"}{'dest'}{'pos'}{'y'} = $args[5];
			if ($args[6] ne "") {
				$$r_hash{"$args[0] $args[1] $args[2]"}{'npc'}{'ID'} = $args[6];
				for ($i = 7; $i < @args; $i++) {
					$$r_hash{"$args[0] $args[1] $args[2]"}{'npc'}{'steps'}[@{$$r_hash{"$args[0] $args[1] $args[2]"}{'npc'}{'steps'}}] = $args[$i];
				}
			}
		}
		$j++;
	}
	foreach (keys %{$r_hash}) {
		$$r_hash{$_}{'dest'}{'ID'} = $IDs{$$r_hash{$_}{'dest'}{'map'}}{$$r_hash{$_}{'dest'}{'pos'}{'x'}}{$$r_hash{$_}{'dest'}{'pos'}{'y'}};
	}
	close FILE;
}

sub parsePortalsLOS {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my $key;
	open FILE, $file;
	foreach (<FILE>) {
		next if (/^#/ || /^\n/);
		s/[\r\n]//g;
		s/\s+/ /g;
		s/\s+$//g;
		my @args = split /\s/, $_;
		if (@args) {
			my $map = shift @args;
			my $x = shift @args;
			my $y = shift @args;
			for (my $i = 0; $i < @args; $i += 4) {
				$$r_hash{"$map $x $y"}{"$args[$i] $args[$i+1] $args[$i+2]"} = $args[$i+3];
			}
		}
	}
	close FILE;
}

#parse Ppl function
sub parsePplControl {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my ($key,@args,$argls);
	open FILE, $file;
	foreach (<FILE>) {
		next if (/^#/ || /^\n/);
		s/[\r\n]//g;
		s/\s+$//g;
		($key, $argls) = $_ =~ /([\s\S]+?)\t(\d+[\s\S]*)/;
		@args = split / /,$argls;
		if ($key ne "") {
			$$r_hash{$key}{'ignored_auto'} = $args[0];
			$$r_hash{$key}{'teleport_auto'} = $args[1];
			$$r_hash{$key}{'disconnect_auto'} = $args[2];
		}
	}
	close FILE;
}

sub parseReload {
	my $r_array = shift;
	my $temp = shift;
	my (@temp1,%temp3,$temp2,$except,$found,$qm);
	while ($temp =~ /(\w+)/g) {
		$temp2 = $1;
		$qm = quotemeta $temp2;
		if ($temp2 eq "all") {
			foreach (@{$r_array}) {
				$temp3{$$_{'file'}} = $_;
			}
		} elsif ($temp2 =~ /\bexcept\b/i || $temp2 =~ /\bbut\b/i) {
			$except = 1;
		} else {
			if ($except) {
				foreach (@{$r_array}) {
					delete $temp3{$$_{'file'}} if $$_{'file'} =~ /$qm/i;
				}
			} else {
				foreach (@{$r_array}) {
					$temp3{$$_{'file'}} = $_ if $$_{'file'} =~ /$qm/i;
				}
			}
		}
	}
	foreach $temp (keys %temp3) {
		$temp1[@temp1] = $temp3{$temp};
	}
	load(\@temp1);
}

sub parseResponses {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my ($key,$value,$i);
	open FILE, $file;
	foreach (<FILE>) {
		next if (/^#/ || /^\n/);
		s/[\r\n]//g;
		($key, $value) = $_ =~ /([\s\S]*?) ([\s\S]*)$/;
		if ($key ne "" && $value ne "") {
			$i = 0;
			while ($$r_hash{"$key\_$i"} ne "") {
				$i++;
			}
			$$r_hash{"$key\_$i"} = $value;
		}
	}
	close FILE;
}

sub parseROLUT {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my @stuff;
	open FILE, $file;
	foreach (<FILE>) {
		s/\r//g;
		next if /^\/\//;
		@stuff = split /#/, $_;
		$stuff[1] =~ s/_/ /g;
		if ($stuff[0] ne "" && $stuff[1] ne "") {
			$$r_hash{$stuff[0]} = $stuff[1];
		}
	}
	close FILE;
}

sub parseSkillsIDLUT {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my @stuff;
	my $i;
	open(FILE, "<$file");
	$i = 1;
	foreach (<FILE>) {
		@stuff = split /#/, $_;
		$stuff[1] =~ s/_/ /g;
		if ($stuff[0] ne "" && $stuff[1] ne "") {
			$$r_hash{$i} = $stuff[1];
		}
		$i++;
	}
	close FILE;
}

sub parseSkillsLUT {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my @stuff;
	my $i;
	open(FILE, "<$file");
	$i = 1;
	foreach (<FILE>) {
		@stuff = split /#/, $_;
		$stuff[1] =~ s/_/ /g;
		if ($stuff[0] ne "" && $stuff[1] ne "") {
			$$r_hash{$stuff[0]} = $stuff[1];
		}
		$i++;
	}
	close FILE;
}

sub parseSkillsReverseLUT_lc {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my @stuff;
	my $i;
	open(FILE, "< $file");
	$i = 1;
	foreach (<FILE>) {
		@stuff = split /#/, $_;
		$stuff[1] =~ s/_/ /g;
		if ($stuff[0] ne "" && $stuff[1] ne "") {
			$$r_hash{lc($stuff[1])} = $stuff[0];
		}
		$i++;
	}
	close FILE;
}

sub parseSkillsSPLUT {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my $ID;
	my $i;
	$i = 1;
	open(FILE, "< $file");
	foreach (<FILE>) {
		if (/^\@/) {
			undef $ID;
			$i = 1;
		} elsif (!$ID) {
			($ID) = /([\s\S]+)#/;
		} else {
			($$r_hash{$ID}{$i++}) = /(\d+)#/;
		}
	}
	close FILE;
}

sub parseTimeouts {
	my $file = shift;
	my $r_hash = shift;
	my ($key,$value);
	open(FILE, "< $file");
	foreach (<FILE>) {
		next if (/^#/ || /^\n/);
		s/[\r\n]//g;
		($key, $value) = $_ =~ /([\s\S]*) ([\s\S]*?)$/;
		if ($key ne "" && $value ne "") {
			$$r_hash{$key}{'timeout'} = "$value";
		}
	}
	close FILE;
}

sub writeDataFile {
	my $file = shift;
	my $r_hash = shift;
	my ($key,$value);
	open(FILE, "+> $file");
	foreach (keys %{$r_hash}) {
		if ($_ ne "") {
			print FILE "$_ $$r_hash{$_}\n";
		}
	}
	close FILE;
}

sub writeDataFileIntact {
	my $file = shift;
	my $r_hash = shift;
	my $data;
	my $key;
	open(FILE,"< $file");
	foreach (<FILE>) {
		if (/^#/ || $_ =~ /^\n/ || $_ =~ /^\r/) {
			$data .= $_;
			next;
		}
		($key) = $_ =~ /^(\w+)/;
		$data .= "$key $$r_hash{$key}\n";
	}
	close FILE;
	open(FILE, "> $file");
	print FILE $data;
	close FILE;
}

sub writeDataFileIntact2 {
	my $file = shift;
	my $r_hash = shift;
	my $data;
	my $key;
	open(FILE, "< $file");
	foreach (<FILE>) {
		if (/^#/ || $_ =~ /^\n/ || $_ =~ /^\r/) {
			$data .= $_;
			next;
		}
		($key) = $_ =~ /^(\w+)/;
		$data .= "$key $$r_hash{$key}{'timeout'}\n";
	}
	close FILE;
	open(FILE, "> $file");
	print FILE $data;
	close FILE;
}

sub writePortalsLOS {
	my $file = shift;
	my $r_hash = shift;
	open(FILE, "+> $file");
	foreach my $key (keys %{$r_hash}) {
		next if (!(keys %{$$r_hash{$key}}));
		print FILE $key;
		foreach (keys %{$$r_hash{$key}}) {
			print FILE " $_ $$r_hash{$key}{$_}";
		}
		print FILE "\n";
	}
	close FILE;
}

sub updateMonsterLUT {
	my $file = shift;
	my $ID = shift;
	my $name = shift;
	open FILE, ">> $file";
	print FILE "$ID $name\n";
	close FILE;
}

sub updatePortalLUT {
	my ($file, $src, $x1, $y1, $dest, $x2, $y2) = @_;
	open FILE, ">> $file";
	print FILE "$src $x1 $y1 $dest $x2 $y2\n";
	close FILE;
}

sub updateNPCLUT {
	my ($file, $ID, $map, $x, $y, $name) = @_;
	open FILE, ">> $file"; 
	print FILE "$ID $map $x $y $name\n"; 
	close FILE; 
} 

1;