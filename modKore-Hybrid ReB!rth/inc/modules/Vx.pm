#########################################################################
# modKore :: Vx Interface Module
# Based on OO
# Created By Star-Kung - http://modkore.sourceforge.net.
#########################################################################
#  This software is open source, licensed under the GNU General Public
#  License, version 2.
#  Basically, this means that you're allowed to modify and distribute
#  this software. However, if you distribute modified versions, you MUST
#  also distribute the source code.
#  See http://www.gnu.org/licenses/gpl.html for the full license.
#########################################################################

package Vx;
use Tk;
require Tk::ROText;
require Tk::BrowseEntry;


our $mw = MainWindow->new();
our @input_list;
our $input_offset = 0;
our @input_que;
our $input_type = "Command";
our $input_pm;

my $line_limit = 1000; #this should go in a config file at some point.
my $total_lines = 0;
my $last_line_end = 0;
my $default_font = "MS_Sans_Serif";

$mw->protocol('WM_DELETE_WINDOW', \&OnExit);
#$mw->Icon(-image=>$mw->Photo(-file=>"hyb.gif"));
$mw->title("modKore-Hybrid <Vx Module>");
$mw->configure(-menu => $mw->Menu(-menuitems=>
[ map 
	['cascade', $_->[0], -tearoff=> 0, -font=>[-family=>"Tahoma",-size=>8], -menuitems => $_->[1]],
	['~modKore',
		[[qw/command E~xit  -accelerator Ctrl+X/, -font=>[-family=>"Tahoma",-size=>8], -command=>[\&OnExit]],]
	],
	['~View',
		[
			[qw/command Map  -accelerator Ctrl+M/, -font=>[-family=>"Tahoma",-size=>8], -command=>[\&OpenMap]],
			'',
			[qw/command Status -accelerator Alt+D/, -font=>[-family=>"Tahoma",-size=>8], -command=>sub{push(@input_que, "s");}],
			[qw/command Skill -accelerator Alt+S/, -font=>[-family=>"Tahoma",-size=>8], -command=>sub{push(@input_que, "skills");}],
			[qw/command Equipment -accelerator Alt+Q/, -font=>[-family=>"Tahoma",-size=>8], -command=>sub{push(@input_que, "i eq");}],
			[qw/command Stat -accelerator Alt+A/, -font=>[-family=>"Tahoma",-size=>8], -command=>sub{push(@input_que, "st");}],
			[qw/command Usable -accelerator Alt+E/, -font=>[-family=>"Tahoma",-size=>8], -command=>sub{push(@input_que, "i u");}],
			[qw/command Non-Usable -accelerator Alt+W/, -font=>[-family=>"Tahoma",-size=>8], -command=>sub{push(@input_que, "i nu");}],
			[qw/command Exp -accelerator Alt+Z/, -font=>[-family=>"Tahoma",-size=>8], -command=>sub{push(@input_que, "exp");}],
			[qw/command Cart -accelerator Alt+C/, -font=>[-family=>"Tahoma",-size=>8], -command=>sub{push(@input_que, "cart");}],
			'',
			[cascade=>"Guild", -tearoff=> 0, -font=>[-family=>"Tahoma",-size=>8], -menuitems =>
				[
					[qw/command Info -accelerator ALT+F/, -font=>[-family=>"Tahoma",-size=>8], -command=>sub{push(@input_que, "guild i");}],
					[qw/command Member -accelerator ALT+G/, -font=>[-family=>"Tahoma",-size=>8], -command=>sub{push(@input_que, "guild m");}],
					[qw/command Position -accelerator ALT+H/, -font=>[-family=>"Tahoma",-size=>8], -command=>sub{push(@input_que, "guild p");}],
				 ],
			],
			'',
			[cascade=>"Font Weight", -tearoff=> 0, -font=>[-family=>"Tahoma",-size=>8], -menuitems => 
				[
					[Checkbutton  => '~Bold', -variable => \$is_bold,-font=>[-family=>"Tahoma",-size=>8],-command => [\&change_fontWeight]],
				]
			],
		],
	],
	['~Reload',
		[
			[qw/command config -accelerator Ctrl+C/, -font=>[-family=>"Tahoma",-size=>8], -command=>sub{push(@input_que, "reload conf");}],
			[qw/command mon_control  -accelerator Ctrl+W/, -font=>[-family=>"Tahoma",-size=>8], -command=>sub{push(@input_que, "reload mon_");}],
			[qw/command item_control  -accelerator Ctrl+Q/, -font=>[-family=>"Tahoma",-size=>8], -command=>sub{push(@input_que, "reload items_");}],
			[qw/command cart_control  -accelerator Ctrl+E/, -font=>[-family=>"Tahoma",-size=>8], -command=>sub{push(@input_que, "reload cart_");}],
			[qw/command ppl_control  -accelerator Ctrl+D/, -font=>[-family=>"Tahoma",-size=>8], -command=>sub{push(@input_que, "reload ppl_");}],
			[qw/command timeouts  -accelerator Ctrl+Z/, -font=>[-family=>"Tahoma",-size=>8], -command=>sub{push(@input_que, "reload timeouts");}],
			[qw/command pickupitems  -accelerator Ctrl+V/, -font=>[-family=>"Tahoma",-size=>8], -command=>sub{push(@input_que, "reload pick");}],
			[qw/command chatAuto  -accelerator Ctrl+A/, -font=>[-family=>"Tahoma",-size=>8], -command=>sub{push(@input_que, "reload chatAuto");}],
			'',
			[qw/command All  -accelerator Ctrl+S/, -font=>[-family=>"Tahoma",-size=>8], -command=>sub{push(@input_que, "reload all");}],
		]
	],
]
));

our $console = $mw->Scrolled('ROText',
	-bg=>'black',
	-fg=>'grey',
	-scrollbars => 'e',
	-height => 20,
	-wrap => 'word',
	-width => 55,
	-insertontime => 0,
	-background => 'black',
	-foreground => 'grey',
	-font=>[ -family => $default_font ,-size=>10,],
	-relief => 'sunken',
)->pack(
	-expand => 1,
	-fill => 'both',
	-side => 'top',
);

our $btn_frame = $mw->Frame(
	#-bg=>'black'
)->pack(
	-side => 'right',
	-expand => 0,
	-fill => 'y',
);

our $input_frame = $mw->Frame(
	-bg=>'black'
)->pack(
	-side => 'top',
	-expand => 0,
	-fill => 'x',
);

our $status_frame = $mw->Frame()->pack(
	-side => 'top',
	-expand => 0,
	-fill => 'x',
);

#------ subclass in input frame
our $pminput = $input_frame->BrowseEntry(
	-bg=>'black',
	-fg=>'grey',
	-variable => \$input_pm,
	-width => 8,
	-choices => \@pm_list,
	-state =>'normal',
	-relief => 'flat',
)->pack(
	expand=>0,
	-fill => 'x',
	-side => 'left',
);

our $input = $input_frame->Entry(
	-bg => 'black',
	-fg => 'grey',
	-insertbackground => 'grey',
	-relief => 'sunken',
	-font=>[ -family => $default_font ,-size=>10,],
)->pack(
	-expand=>1,
	-fill => 'x',
	-side => 'left',
);

our $sinput = $input_frame->BrowseEntry(
	-bg=>'black',
	-fg=>'grey',
	-variable => \$input_type,
	-choices => [qw(Command Public Party Guild)],
	-width => 8,
	-state =>'readonly',
	-relief => 'flat',
)->pack	(
	expand=>0,
	-fill => 'x',
	-side => 'left',
);

#------ subclass in status frame
our $status_gen = $status_frame->Label(
	-anchor => 'w',
	-text => 'Ready',
	-font => ['Arial', 8],
	-bd=>0,
	-relief => 'sunken',
)->pack(
	-side => 'left',
	-expand => 1,
	-fill => 'x',
);

our $status_ai = $status_frame->Label(
	-text => 'Ai - Status',
	-font => ['Arial', 8],
	-width => 25,
	-relief => 'ridge',
)->pack(
	-side => 'left',
	-expand => 0,
	-fill => 'x',
);

our $status_posx = $status_frame->Label(
	-text => '0',
	-font => ['Arial', 8],
	-width => 4,
	-relief => 'ridge',
)->pack(
	-side => 'left',
	-expand => 0,
	-fill => 'x',
);

our $status_posy = $status_frame->Label(
	-text => '0',
	-font => ['Arial', 8],
	-width => 4,
	-relief => 'ridge',
)->pack(
	-side => 'left',
	-expand => 0,
	-fill => 'x',
);

#Binding
$mw->bind('all','<Control-x>'=>[\&OnExit]);
$mw->bind('all','<Control-m>'=>[\&OpenMap]);
$mw->bind('all','<Control-c>'=>sub{push(@input_que, "reload conf");});
$mw->bind('all','<Control-w>'=>sub{push(@input_que, "reload mon_");});
$mw->bind('all','<Control-q>'=>sub{push(@input_que, "reload items_");});
$mw->bind('all','<Control-e>'=>sub{push(@input_que, "reload cart_");});
$mw->bind('all','<Control-d>'=>sub{push(@input_que, "reload ppl_");});
$mw->bind('all','<Control-z>'=>sub{push(@input_que, "reload timeouts");});
$mw->bind('all','<Control-v>'=>sub{push(@input_que, "reload pick");});
$mw->bind('all','<Control-a>'=>sub{push(@input_que, "reload chatAuto");});
$mw->bind('all','<Control-s>'=>sub{push(@input_que, "reload all");});
$mw->bind('all','<Alt-d>'=>sub{push(@input_que, "s");});
$mw->bind('all','<Alt-s>'=>sub{push(@input_que, "skills");});
$mw->bind('all','<Alt-q>'=>sub{push(@input_que, "i eq");});
$mw->bind('all','<Alt-a>'=>sub{push(@input_que, "st");});
$mw->bind('all','<Alt-e>'=>sub{push(@input_que, "i u");});
$mw->bind('all','<Alt-w>'=>sub{push(@input_que, "i nu");});
$mw->bind('all','<Alt-z>'=>sub{push(@input_que, "exp");});
#cookiemaster cart shortcut
$mw->bind('all','<Alt-c>'=>sub{push(@input_que, "cart");});
#digitalpheer guild shortcut 
$mw->bind('all','<Alt-f>'=>sub{push(@input_que, "guild i");});
$mw->bind('all','<Alt-g>'=>sub{push(@input_que, "guild m");});
$mw->bind('all','<Alt-h>'=>sub{push(@input_que, "guild p");});

$input->bind('<Up>' => [\&inputUp]);
$input->bind('<Down>' => [\&inputDown]);
$input->bind('<Return>' => [\&inputEnter]);

sub inputUp {
	my $line;
	chomp($line = $input->get);
	unless ($input_offset) {
		$input_list[$input_offset] = $line;
	}
	$input_offset++;
	$input_offset -= $#input_list + 1 while $input_offset > $#input_list;
	
	$input->delete('0', 'end');
	$input->insert('end', "$input_list[$input_offset]");
}

sub inputDown {
	my $line;

	chomp($line = $input->get);
	unless ($input_offset) {
		$input_list[$input_offset] = $line;
	}
	$input_offset--;
	$input_offset += $#input_list + 1 while $input_offset < 0;
	
	$input->delete('0', 'end');
	$input->insert('end', "$input_list[$input_offset]");
}

sub inputEnter {
	my $line;
	$line = $input->get;
	if ($input_pm eq "") {
		if ($input_type eq "Public" && $line !~/^e (\d+)/) {
			$line = "c ".$line;
		}elsif ($input_type eq "Party"){
			$line = "p ".$line;
		}elsif ($input_type eq "Guild"){
			$line = "g ".$line;
		}
	}else{
		pm_add($input_pm);
		$line = "pm \"$input_pm\" $line";
	}
	$input->delete('0', 'end');
	return unless $line;

	$input_list[0] = $line;
	unshift(@input_list, "");
	$input_offset = 0;
	push(@input_que, $line);
}

################################################################
# Public Method
################################################################
sub update{
	$mw->update();
}

sub pos_update{
	my ($x,$y) = @_;
	$status_posx->configure( -text =>$x);
	$status_posy->configure( -text =>$y);
	if (Exists $map_mw ) {
		$map_mw{'canvas'}->delete($map_mw{'player'}) if($map_mw{'player'});
		$map_mw{'canvas'}->delete($map_mw{'range'}) if ($map_mw{'range'});
		$map_mw{'player'} = $map_mw{'canvas'}->createOval(
			$x-2,$map_mw{'map'}{'y'} - $y-2,
			$x+2,$map_mw{'map'}{'y'} - $y+2,
			,-fill => '#ffcccc', -outline=>'#ff0000');
		my $dis = $main::config{'attackDistance'};
		$map_mw{'range'} = $map_mw{'canvas'}->createOval(
			$x-$dis,$map_mw{'map'}{'y'} - $y-$dis,
			$x+$dis,$map_mw{'map'}{'y'} - $y+$dis,
			,-outline=>'#ff0000');
	}
}

sub status_update{
	my $text = shift;
	$status_gen->configure(-text => $text);
}

sub setTitle{
	my $text = shift;
	$mw->title("Hybrid : ".$text);
}

sub setAiText{
	my ($text) = shift;
	$status_ai->configure(-text => $text);
}

sub add_out_text {
	if (my @text = @_) {
		my $scroll = 0;
		$scroll = 1 if (($console->yview)[1] == 1);
		my $tagname;
		my $text = join('', @text);
		
		#keep track of lines to limit the number of lines in the text widget
		$total_lines += $text =~ s/\r?\n/\n/g;
		
		$console->insert('end', "\n") if $last_line_end;
		$last_line_end = $text =~ s/\n$//;
		
		if ($text =~/^#/) {
			($tagname) = $text =~/^#(.*)#/;
			$text =~ s/^#(.*)#//;
			$console->insert('end', $text, $tagname);
		} elsif ($text =~ /Not Identified/) {
			$console->insert ('end', $text, 'inventoryNoID');
		} elsif ($text =~ /Eqp/) {
			$console->insert('end', $text, 'equip');
		} elsif ($text =~ /disconnected/) {
			$console->insert('end', $text, 'disconnected');
		} elsif ($text =~ /connected/) {
			$console->insert('end', $text, 'connected');
		} else {
			$console->insert('end', $text);
		}

		if ($total_lines > $line_limit) {
			my $overage = $total_lines - $line_limit;
			$console->delete('1.0', $overage+1 . ".0");
			$total_lines -= $overage;
		}
		
		$console->see('end') if $scroll;
	}
}

sub OnExit{
	push(@input_que, 'quit');
}

sub getInput{
	if (getInputNum()) {
		my $command = shift @input_que;
		return $command;
	}else{ return '';}
}

sub getInputNum{
	return scalar(@input_que);
}

sub parseColorFile {
	my $file = shift;
	my $r_hash = shift;
	my @old_tags = keys %$r_hash;
	undef %{$r_hash};
	open FILE, $file;
	foreach (<FILE>) {
		next if (/^#/);
		s/[\r\n]//g;
		s/\s+$//g;
		my ($key, $fgcolor, $bgcolor) =m!([\S\S]+)\s+([^/]+)?(?:/(.+))?$!;
		if ($key eq 'default_only') {
			$r_hash->{$key} = $fgcolor;
		} elsif ($key ne '') {
			$r_hash->{$key} = {-foreground => $fgcolor, -background => $bgcolor};
		}
	}
	$console->configure(%{ $r_hash->{default} });
	$input->configure(%{ $r_hash->{default} });
	if (isTrue($r_hash->{default_only})) {
		foreach my $tag (@old_tags) {
			next if $tag eq 'default' || $tag eq 'default_only';
			$console->tagConfigure(
				$tag,
				%{ $r_hash->{default} }
			);
		}
	} else {
		foreach my $tag (keys %$r_hash) {
			next if $tag eq 'default' || $tag eq 'default_only';
			$console->tagConfigure(
				$tag,
				%{ $r_hash->{$tag} }
			);
		}
	}
	close FILE;
}

sub isTrue {
	my $value = shift;
	return 0 unless defined $value;
	return $value eq 'true' || $value eq 'yes' || $value eq 'on';
}

sub change_fontWeight{
	if ($is_bold) {
		$console->configure(-font=>[-family => $default_font ,-size=>10,-weight=>bold]);
		$input->configure(-font=>[-family => $default_font ,-size=>10,-weight=>bold]);
	}else{
		$console->configure(-font=>[-family => $default_font ,-size=>10,-weight=>normal]);
		$input->configure(-font=>[-family => $default_font ,-size=>10,-weight=>normal]);
	}
}


sub OpenMap{
	if (not Exists $map_mw) {
		undef %obj;
		my ($x,$y);
		$map_mw = $mw->Toplevel();
		$map_mw->title("Map View : ".$main::field{'name'});
		$map_mw->protocol('WM_DELETE_WINDOW', 
			sub {
				undef %obj;
				$map_mw->destroy();
			}
		);
		$map_mw->resizable(0,0);
		$map_mw{'canvas'} = $map_mw->Canvas(-width =>200,-height =>200,-background => 'white',)->pack(-side => 'top');
		loadMap(\%main::field);
		$x = $status_posx->cget(-text);
		$y = $status_posy->cget(-text);
		$map_mw{'player'} = $map_mw{'canvas'}->createOval(
			$x-2,$map_mw{'map'}{'y'} - $y-2,
			$x+2,$map_mw{'map'}{'y'} - $y+2,
			,-fill => '#ffcccc', -outline=>'#ff0000');
		my $dis = $main::config{'attackDistance'};
		$map_mw{'range'} = $map_mw{'canvas'}->createOval(
			$x-$dis,$map_mw{'map'}{'y'} - $y-$dis,
			$x+$dis,$map_mw{'map'}{'y'} - $y+$dis,
			,-outline=>'#ff0000');
		if ($main::sys{'enableMoveClick'}) {
			$map_mw->bind('<Double-1>', [\&dblchk , Ev('x') , Ev('y')]);
		}
		$map_mw->bind('<Motion>', [\&pointchk , Ev('x') , Ev('y')]); 
	}
}

sub pointchk{
	my $mvcpx=$_[1];
	my $mvcpy = $map_mw{'map'}{'y'} - $_[2];
	$map_mw->title("Map View : ".$main::field{'name'}." \[$mvcpx , $mvcpy\]");
	$map_mw->update; 
}

sub dblchk{
	my $mvcpx=$_[1];
	my $mvcpy = $map_mw{'map'}{'y'} - $_[2];
	push(@input_que, "move $mvcpx $mvcpy"); 
} 

sub is_showMap{
	return Exists($map_mw);
}
sub loadMap{
	my $r_hash = shift;
	print "#GMnotice#Loading Map : ",$$r_hash{'name'},"\n";
	$map_mw{'canvas'}->delete('map');
	$map_mw{'canvas'}->createText(50,20,-text =>'Processing..',-tags=>'map');
	$map_mw{'map'} = $map_mw{'canvas'}->Bitmap(-data=>${&xbmmake(\%{$r_hash})});
	$map_mw{'canvas'}->delete('map');
	$map_mw{'canvas'}->createImage(2,2,-image =>$map_mw{'map'},-anchor => 'nw',-tags=>'map');
	$map_mw{'canvas'}->configure(
			-width => $$r_hash{'width'},
			-height => $$r_hash{'height'}
	);
	$map_mw{'map'}{'x'}=$$r_hash{'width'};
	$map_mw{'map'}{'y'}=$$r_hash{'height'};
}
sub addObj{
	my ($id,$type) = @_;
	my ($fg,$bg);
	return if (!is_showMap());
	if ($type eq "npc") {
		$fg = "#ABD5BD";
		$bg = "#005826";
	}elsif ($type eq "m") {
		$fg = "#A9D3E3";
		$bg = "#0076A3";
	}elsif ($type eq "p") {
		$fg = "#FFFFCC";
		$bg = "#FF6600";
	}else {
		$fg = "#666666";
		$bg = "#FF6600";
	}
	$obj{$id}[0] = $fg;
	$obj{$id}[1] = $bg;
}
sub moveObj{
	return if (!is_showMap());
	my ($id,$type,$x,$y,$newx,$newy) = @_;
	my $range;
	if($obj{$id}){
		$map_mw{'canvas'}->delete($obj{$id});
	}else{
		addObj($id,$type);
	}
	if (defined $newx && defined $newy) {
		$x = $newx;
		$y= $newy;
	}
	$obj{$id} = $map_mw{'canvas'}->createOval(
			$x-2,$map_mw{'map'}{'y'} - $y-2,
			$x+2,$map_mw{'map'}{'y'} - $y+2,
			,-fill => $obj{$id}[0], -outline=>$obj{$id}[1]); 
}
sub removeObj{
	my ($id) = shift;
	return if (!$obj{$id} || !is_showMap());
	$map_mw{'canvas'}->delete($obj{$id});
	undef @{$obj{$id}};
}
sub removeAllObj{
	return if (!is_showMap());
	foreach (keys %obj) {
		$map_mw{'canvas'}->delete($obj{$_}) if ($obj{$_});
		undef @{$obj{$id}};
	}
}
sub followObj{
	return if (!is_showMap());
	my ($id,$type) = @_;
	$obj{$id}[0] = "#FFCCFF";
	$obj{$id}[1] = "#CC00CC";
}
sub xbmmake{
	my $r_hash = shift;
	my ($i,$j,$k,$hx,$hy,$mvw_x,$mvw_y);
	my $line=0;
	my $dump='';
	my @data=[];
	$mvw_x=$$r_hash{'width'};
	$mvw_y=$$r_hash{'height'};
	if (($mvw_x % 8)==0){
		$hx=$mvw_x;
	}else{
		$hx=$mvw_x+(8-($mvw_x % 8));
	}
	for($j=0;$j<$mvw_y;$j++){
		$hy=($mvw_x*($mvw_y-$j-1));
		for($k=0;$k<$hx;$k++){
			$dump+=256 if($$r_hash{'field'}[$hy+$k] >0);
			$dump=$dump/2;
			if(($k % 8) ==7){
				$line.=sprintf("0x%02x\,",$dump);
				$dump=0;
			}
		}
	}
	$line="#define data_width $mvw_x\n#define data_height $mvw_y\nstatic unsigned char data_bits[] = {\n".$line."};";
	return \$line;
}

sub Terminate{
	exit;
}

sub pm_add{
	my $input_name = shift;
	my $found=1;
	my @pm_list = $pminput->cget('-choices');
	foreach (@pm_list){
		if ($_ eq $input_name) {
			$found = 0;
			last;
		}
	}
	if ($found) {
		$pminput->insert("end",$input_name);
	}
}


###########################################################################
# TieHandle Method 
# *Avoid to edit in this place
###########################################################################

sub TIEHANDLE {
	my $self;
	if (0) {
		$self = 1;
		open DEBUG, "> debug.txt";
		my $oh = select(DEBUG);
		$| = 1;
		select($oh);
	} else {
		$self = 0;
	}
	bless \$self, shift;
}

sub PRINT {
	my $self = shift;
	my $output = join '', @_;
	$output =~ s/\000//;
	if ($$self) {
		print DEBUG $output;
	}
	add_out_text($output);
	update();
}


1;