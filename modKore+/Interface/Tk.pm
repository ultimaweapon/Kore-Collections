#########################################################################
#  OpenKore - Tk Interface
#
#  Copyright (c) 2004 OpenKore development team 
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#
#  $Revision: 1.13 $
#  $Id: Tk.pm,v 1.13 2004/11/01 17:42:40 Administrator Exp $
#
#########################################################################

package Interface::Tk;
use strict;
use warnings;

use Interface;
use base qw/Interface/;

use Plugins;
use Globals;
#use Interface::Tk::AboutBox;
#use Interface::Tk::MapViewer;

use MIME::Base64;
use Carp qw/carp croak confess/;
use Time::HiRes qw/time usleep/;
use Tk;
use Tk::ROText;
use Tk::BrowseEntry;
use Tk::NoteBook;
use Tk::FontDialog;
use XML::Dumper;


#these should go in a config file at some point.
our $line_limit = 1000;
our $preferences;
################################################################
# Public Method
################################################################


sub new {
	my $class = shift;
	my $self = {
		mw => undef,
		input_list => [],
		input_offset => 0,
		input_que => [],
		default_font=>"MS_Sans_Serif",
		is_bold => 1,
		#default_font=>"Courier_New",
		input_type => "Command",
		input_pm => "",
		total_lines => 0,
		last_line_end => 0,
		colors => {},
	};

	if ($buildType == 0) {
		eval "use Win32::API;";
		$self->{ShellExecute} = new Win32::API("shell32", "ShellExecute","NPPPPN", "V");
	}

	bless $self, $class;
	if (-e "Tk.xml") {
			$preferences = xml2pl("Tk.xml");
	}else{
		$preferences = {
			Console => {
				-bg=>'black',
				-fg=>'grey',
				-scrollbars => 'e',
				-height => 15,
				-wrap => 'word',
				-width => 55,
				-insertontime => 1,
				-font=>["MS_Sans_Serif",8,'bold',],
				-relief => 'sunken',
			},
		};
	}

	$self->initTk;
	Plugins::addHook('postloadfiles', \&resetColors, $self);
	Plugins::addHook('update', \&updateHook, $self);
	Plugins::addHook('parseMsg', \&parseMsg, $self);
	if ($buildType == 0) {
		my $console;
		eval 'use Win32::Console; $console = new Win32::Console(STD_OUTPUT_HANDLE);';
		$console->Free() if (!$@);
	}
	return $self;
}

sub getInput{
	my $self = shift;
	my $timeout = shift;
	my $msg;
	if ($timeout < 0) {
		until (defined $msg) {
			$self->update();
			if (@{ $self->{input_que} }) { 
				$msg = shift @{ $self->{input_que} }; 
			} 
		}
	} elsif ($timeout > 0) {
		my $end = time + $timeout;
		until ($end < time || defined $msg) {
			$self->update();
			if (@{ $self->{input_que} }) { 
				$msg = shift @{ $self->{input_que} }; 
			} 
		}
	} else {
		if (@{ $self->{input_que} }) { 
			$msg = shift @{ $self->{input_que} }; 
		} 
	}
	$self->update();
	$msg =~ s/\n// if defined $msg;
	return $msg;
}


sub writeOutput {
	my $self = shift;
	my $type = shift || '';
	my $message = shift || '';
	my $domain = shift || '';

	my $scroll = 0;
	$scroll = 1 if (($self->{console}->yview)[1] == 1);
	
	#keep track of lines to limit the number of lines in the text widget
	$self->{total_lines} += $message =~ s/\r?\n/\n/g;

	$self->{console}->insert('end', "\n") if $self->{last_line_end};
	$self->{last_line_end} = $message =~ s/\n$//;

	$self->{console}->insert('end',$message, "$type.$domain");

	#remove extra lines
	if ($self->{total_lines} > $line_limit) {
		my $overage = $self->{total_lines} - $line_limit;
		$self->{console}->delete('1.0', $overage+1 . ".0");
		$self->{total_lines} -= $overage;
	}

	$self->{console}->see('end') if $scroll;
}

sub updateHook {
	my $hookname = shift;
	my $r_args = shift;
	my $self = shift;
	return unless defined $self->{mw};
	$self->updatePos();
	$self->{mw}->update();
	$self->setAiText("@ai_seq");
}

sub update {
	my $self = shift;
	$self->{mw}->update();

	if ($buildType == 0 && $self->{SettingsObj}) {
		if ($self->{SettingsObj}->Wait(0)) {
			my $code;
			$self->{SettingsObj}->GetExitCode($code);
			Settings::parseReload("all") if $code == 0;
			delete $self->{SettingsObj};
		}
	}
}

sub title {
	my $self = shift;
	my $title = shift;

	if (defined $title) {
		if (!defined $self->{currentTitle} || $self->{currentTitle} ne $title) {
			$self->{mw}->title($title);
			$self->{currentTitle} = $title;
		}
	} else {
		return $self->{mw}->title();
	}
}

sub updatePos {
	my $self = shift;
	return unless defined($config{'char'}) && defined($chars[$config{'char'}]) && defined($chars[$config{'char'}]{'pos_to'});
	my ($x,$y) = @{$chars[$config{'char'}]{'pos_to'}}{'x', 'y'};
	$self->{status_posx}->configure( -text =>$x);
	$self->{status_posy}->configure( -text =>$y);
	if ($self->mapIsShown()) {
		if ($self->{map}{field} ne $field{'name'}) {
			$self->loadMap();
			$self->{map}{canvas}->raise($self->{map}{ind}{range});
			$self->{map}{canvas}->raise($self->{map}{ind}{player});
		}
		$self->{map}{canvas}->coords($self->{map}{ind}{player},
			$x - 2, $self->{map}{height} - $y - 2,
			$x + 2, $self->{map}{height} - $y + 2,
		);
		my $dis = $config{'attackDistance'};
		$self->{map}{canvas}->coords($self->{map}{ind}{range},
			$x - $dis, $self->{map}{height} - $y - $dis,
			$x + $dis, $self->{map}{height} - $y + $dis,
		);
	}
}

sub updateStatus {
	my $self = shift;
	my $text = shift;
	$self->{status_gen}->configure(-text => $text);
}

sub setTitle {
	my $self = shift;
	my $text = shift;
	$self->{mw}->title($text);
}

sub setAiText {
	my $self = shift;
	my ($text) = shift;
	$self->{status_ai}->configure(-text => $text);
}

sub addPM {
	my $self = shift;
	my $input_name = shift;
	my $found=1;
	my @pm_list = $self->{pminput}->cget('-choices');
	foreach (@pm_list){
		if ($_ eq $input_name) {
			$found = 0;
			last;
		}
	}
	if ($found) {
		$self->{pminput}->insert("end",$input_name);
	}
}

################################################################
# Private? Method
################################################################
#FIXME many of thise methods don't support OO calls yet, update them and all their references
sub initTk {
	my $self = shift;
	
	$self->{mw} = MainWindow->new();
	$self->{mw}->protocol('WM_DELETE_WINDOW', [\&OnExit, $self]);
	#$self->{mw}->Icon(-image=>$self->{mw}->Photo(-file=>"opk.gif"));
	$self->{mw}->title("modKore-Plus!");
	$self->{mw}->minsize(430,310);
	$self->{menuFont} = $self->{mw}->fontCreate(-family => $self->{default_font}, -size => 8, -weight => "bold");

	#------ Frame Control
	$self->{main_frame} = $self->{mw}->Frame()->pack(-side => 'top',-expand => 1,-fill => 'both',);
	#$self->{btn_frame} = $self->{main_frame}->Frame()->pack(-side => 'right',-expand => 0,-fill => 'y',);
	#$self->{console_frame} = $self->{main_frame}->Frame(-bg=>'black')->pack(-side => 'left',-expand => 1,-fill => 'both',);
	$self->{input_frame} = $self->{mw}->Frame(-bg=>'black')->pack(-side => 'top',-expand => 0,-fill => 'x',);
	$self->{status_frame} = $self->{mw}->Frame()->pack(-side => 'top',-expand => 0,-fill => 'x',);

	#------ subclass in console frame
	#$self->{tabPane} = $self->{console_frame}->NoteBook(-relief=>'flat',-border=>1,-tabpadx=>1,-tabpady=>1,-font=>${$self->{menuFont}},-bg=>'#CDCDCD',-foreground=>'grey',-inactivebackground=>"#999999")->pack(-expand => 1,-fill => 'both',-side => 'top',);
	$self->{tabPane} = $self->{main_frame}->NoteBook(-relief=>'flat',-border=>1,-tabpadx=>1,-tabpady=>1,-font=>$self->{menuFont},-fg=>'#333333',-inactivebackground=>"#999999",)->pack(-expand => 1,-fill => 'both',-side => 'top',);
	$self->{consoleTab} = $self->{tabPane}->add("Console",-label=>'Console');
#	$self->{chatTab} = $self->{tabPane}->add("Chat",-label=>'Chat');
#	$self->{guildTab} = $self->{tabPane}->add("Guild",-label=>'Guild');
#	$self->{pmTab} = $self->{tabPane}->add("Pm",-label=>'PM');
	$self->{console} = $self->{consoleTab}->Scrolled('ROText',%{$preferences->{Console}})->pack(-expand => 1,-fill => 'both',-side => 'top',);
#	$self->{chatTab}->Label(-text => "~ Comming Soon ~", -font => $self->{menuFont})->pack(-expand => 1,-fill => 'both',-side => 'top',);
#	$self->{guildTab}->Label(-text => "~ Comming Soon ~", -font => $self->{menuFont})->pack(-expand => 1,-fill => 'both',-side => 'top',);
#	$self->{pmTab}->Label(-text => "~ Comming Soon ~", -font => $self->{menuFont})->pack(-expand => 1,-fill => 'both',-side => 'top',);
#	$self->{chatLog} = $self->{chatTab}->Scrolled('ROText',-bg=>'black',-fg=>'grey',
#		-scrollbars => 'e',
#		-height => 15,
#		-wrap => 'word',
#		-width => 55,
#		-insertontime => 0,
#		-background => 'black',
#		-foreground => 'grey',
#		-font=>[ -family => $self->{default_font} ,-size=>10,],
#		-relief => 'sunken',
#	)->pack(
#		-expand => 1,
#		-fill => 'both',
#		-side => 'top',
#	);

#	$self->{guildLog} = $self->{guildTab}->Scrolled('ROText',-bg=>'black',-fg=>'grey',
#		-scrollbars => 'e',
#		-height => 15,
#		-wrap => 'word',
#		-width => 55,
#		-insertontime => 0,
#		-background => 'black',
#		-foreground => 'grey',
#		-font=>[ -family => $self->{default_font} ,-size=>10,],
#		-relief => 'sunken',
#	)->pack(
#		-expand => 1,
#		-fill => 'both',
#		-side => 'top',
#	);

	#------ subclass in input frame
	$self->{pminput} = $self->{input_frame}->BrowseEntry(
		-bg => 'black',
		-fg=>'grey',
		-insertbackground => 'black',
		-variable => \$self->{input_pm},
		-width => 15,
		-choices => $self->{pm_list},
		-state =>'normal',
		-relief => 'flat',
	)->pack(
		-expand=>0,
		-fill => 'x',
		-side => 'left',
	);

	$self->{input} = $self->{input_frame}->Entry(
		-bg => 'black',
		-fg => 'grey',
		-insertbackground => 'grey',
		-relief => 'sunken',
		-font=>[ -family => $self->{default_font} ,-size=>10,],
	)->pack(
		-expand=>1,
		-fill => 'x',
		-side => 'left',
	);

	$self->{sinput} = $self->{input_frame}->BrowseEntry(
		-bg=>'black',
		-fg=>'grey',
		-variable => \$self->{input_type},
		-choices => [qw(Command Public Party Guild)],
		-width => 8,
		-state =>'readonly',
		-relief => 'flat',
	)->pack	(
		-expand=>0,
		-fill => 'x',
		-side => 'left',
	);

	$self->{scrollend} = $self->{input_frame}->Button(-text => "V", 
														   -command => [sub{my $self=shift; $self->{console}->see('end'); }, $self],
#														   -padx=>5,-pady=>5,
														   -takefocus => 0,
														   -font=>[ -family => $self->{default_font} ,-size=>5,],
														   -activeforeground => "black",
														   -activebackground => "#EDEDED",
														   -relief => "flat",
														   -anchor => "w")->pack(-expand=>0, -side => "left");

	#------ subclass in status frame
	$self->{status_gen} = $self->{status_frame}->Label(
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

	$self->{status_ai} = $self->{status_frame}->Label(
		-text => 'Ai - Status',
		-font => ['Arial', 8],
		-width => 25,
		-relief => 'ridge',
	)->pack(
		-side => 'left',
		-expand => 0,
		-fill => 'x',
	);

	$self->{status_posx} = $self->{status_frame}->Label(
		-text => '0',
		-font => ['Arial', 8],
		-width => 4,
		-relief => 'ridge',
	)->pack(
		-side => 'left',
		-expand => 0,
		-fill => 'x',
	);

	$self->{status_posy} = $self->{status_frame}->Label(
		-text => '0',
		-font => ['Arial', 8],
		-width => 4,
		-relief => 'ridge',
	)->pack(
		-side => 'left',
		-expand => 0,
		-fill => 'x',
	);


	$self->{mw}->configure(-menu => $self->{mw}->Menu(-menuitems=>
	[ map 
		['cascade', $_->[0], -tearoff=> 0, -font=>[-family=>"Tahoma",-size=>8], -menuitems => $_->[1]],
		['modKore',
			[[qw/command E~xit  -accelerator Ctrl+X/, -font=>[-family=>"Tahoma",-size=>8], -command=>[\&OnExit,$self]],]
		],
		['View',
			[
				[qw/command Map  -accelerator Ctrl+M/, -font=>[-family=>"Tahoma",-size=>8], -command=>[\&mapToggle, $self]],
				'',
				[qw/command Status -accelerator Alt+D/, -font=>[-family=>"Tahoma",-size=>8], -command=>[sub{my $self=shift; push(@{$self->{input_que}},"s");}, $self]],
				[qw/command Skill -accelerator Alt+S/, -font=>[-family=>"Tahoma",-size=>8], -command=>[sub{my $self=shift; push(@{$self->{input_que}},"skills");}, $self]],
				[qw/command Equipment -accelerator Alt+Q/, -font=>[-family=>"Tahoma",-size=>8], -command=>[sub{my $self=shift; push(@{$self->{input_que}},"i eq");}, $self]],
				[qw/command Stat -accelerator Alt+A/, -font=>[-family=>"Tahoma",-size=>8], -command=>[sub{my $self=shift; push(@{$self->{input_que}},"st");}, $self]],
				[qw/command Usable -accelerator Alt+E/, -font=>[-family=>"Tahoma",-size=>8], -command=>[sub{my $self=shift; push(@{$self->{input_que}},"i u");}, $self]],
				[qw/command Non-Usable -accelerator Alt+W/, -font=>[-family=>"Tahoma",-size=>8], -command=>[sub{my $self=shift; push(@{$self->{input_que}},"i nu");}, $self]],
				[qw/command Exp -accelerator Alt+Z/, -font=>[-family=>"Tahoma",-size=>8], -command=>[sub{my $self=shift; push(@{$self->{input_que}},"exp");}, $self]],
				[qw/command Cart -accelerator Alt+C/, -font=>[-family=>"Tahoma",-size=>8], -command=>[sub{my $self=shift; push(@{$self->{input_que}},"cart");}, $self]],
				'',
				[cascade=>"Guild", -tearoff=> 0, -font=>[-family=>"Tahoma",-size=>8], -menuitems =>
					[
						[qw/command Info -accelerator ALT+F/, -font=>[-family=>"Tahoma",-size=>8], -command=>[sub{my $self=shift; push(@{$self->{input_que}},"guild i");}, $self]],
						[qw/command Member -accelerator ALT+G/, -font=>[-family=>"Tahoma",-size=>8], -command=>[sub{my $self=shift; push(@{$self->{input_que}},"guild m");}, $self]],
						[qw/command Position -accelerator ALT+H/, -font=>[-family=>"Tahoma",-size=>8], -command=>[sub{my $self=shift; push(@{$self->{input_que}},"guild p");}, $self]],
					 ],
				],
				'',
				[qw/command Font  -accelerator Ctrl+F/, -font=>[-family=>"Tahoma",-size=>8], -command=>[\&change_font, $self]],
#				[cascade=>"Font Weight", -tearoff=> 0, -font=>[-family=>"Tahoma",-size=>8], -menuitems => 
#					[
#						[Checkbutton  => '~Bold', -variable => \$self->{is_bold},-font=>[-family=>"Tahoma",-size=>8],-command => [\&change_fontWeight , $self]],
#					]
#				],
			],
		],
		['Reload',
			[
				[qw/command config -accelerator Ctrl+C/, -font=>[-family=>"Tahoma",-size=>8], -command=>[sub{my $self=shift; push(@{$self->{input_que}}, "reload conf");} ,$self]],
				[qw/command mon_control  -accelerator Ctrl+W/, -font=>[-family=>"Tahoma",-size=>8], -command=>[sub{my $self=shift; push(@{$self->{input_que}}, "reload mon_");} ,$self]],
				[qw/command item_control  -accelerator Ctrl+Q/, -font=>[-family=>"Tahoma",-size=>8], -command=>[sub{my $self=shift; push(@{$self->{input_que}}, "reload items_");} ,$self]],
				[qw/command cart_control  -accelerator Ctrl+E/, -font=>[-family=>"Tahoma",-size=>8], -command=>[sub{my $self=shift; push(@{$self->{input_que}}, "reload cart_");} ,$self]],
				[qw/command ppl_control  -accelerator Ctrl+D/, -font=>[-family=>"Tahoma",-size=>8], -command=>[sub{my $self=shift; push(@{$self->{input_que}}, "reload ppl_");} ,$self]],
				[qw/command timeouts  -accelerator Ctrl+Z/, -font=>[-family=>"Tahoma",-size=>8], -command=>[sub{my $self=shift; push(@{$self->{input_que}}, "reload timeouts");} ,$self]],
				[qw/command pickupitems  -accelerator Ctrl+V/, -font=>[-family=>"Tahoma",-size=>8], -command=>[sub{my $self=shift; push(@{$self->{input_que}}, "reload pick");} ,$self]],
				[qw/command chatAuto  -accelerator Ctrl+A/, -font=>[-family=>"Tahoma",-size=>8], -command=>[sub{my $self=shift; push(@{$self->{input_que}}, "reload chatAuto");} ,$self]],
				'',
				[qw/command All  -accelerator Ctrl+S/, -font=>[-family=>"Tahoma",-size=>8], -command=>[sub{my $self=shift; push(@{$self->{input_que}}, "reload all");} ,$self]],
			]
		],
		['About',
			[
				[qw/command modKore-Plus!/, -font=>[-family=>"Tahoma",-size=>8], -command=>[\&aboutBox, $self]],
				[command=>'modKore Document', -font=>[-family=>"Tahoma",-size=>8], -command=>[\&launchURL,"http://modkore.sf.net/docs/"]],
				'',
				[command=>'Donate to modKore', -font=>[-family=>"Tahoma",-size=>8], -command=>[\&launchURL,"http://sourceforge.net/donate/index.php?group_id=85587"]],
			]
		],
	]
	));

	#Binding
	#FIXME Do I want to quit on cut? ... NO!
	#$self->{mw}->bind('all','<Control-x>'=>[\&OnExit]);
	$self->{mw}->bind('all','<Control-m>'=>[\&mapToggle, $self]);
	$self->{mw}->bind('all','<Control-f>'=>[\&change_font, $self]);
	#FIXME hey that's copy....
	$self->{mw}->bind('all','<Control-c>'=>[\&insertInput , $self, "reload conf"]);
	$self->{mw}->bind('all','<Control-w>'=>[\&insertInput, $self, "reload mon_"]);
	$self->{mw}->bind('all','<Control-q>'=>[\&insertInput , $self, "reload items_"]);
	$self->{mw}->bind('all','<Control-e>'=>[\&insertInput , $self, "reload cart_"]);
	$self->{mw}->bind('all','<Control-d>'=>[\&insertInput , $self, "reload ppl_"]);
	$self->{mw}->bind('all','<Control-z>'=>[\&insertInput , $self, "reload timeouts"]);
	#FIXME hey that's paste....
	$self->{mw}->bind('all','<Control-v>'=>[\&insertInput , $self, "reload pick" ]);
	$self->{mw}->bind('all','<Control-a>'=>[\&insertInput , $self, "reload chatAuto"]);
	$self->{mw}->bind('all','<Control-s>'=>[\&insertInput , $self, "reload all"]);
	$self->{mw}->bind('all','<Alt-d>'=>[\&insertInput , $self, "s"]);
	$self->{mw}->bind('all','<Alt-s>'=>[\&insertInput , $self, "skills"]);
	$self->{mw}->bind('all','<Alt-q>'=>[\&insertInput , $self, "i eq"]);
	$self->{mw}->bind('all','<Alt-a>'=>[\&insertInput , $self, "st"]);
	$self->{mw}->bind('all','<Alt-e>'=>[\&insertInput , $self, "i u"]);
	$self->{mw}->bind('all','<Alt-w>'=>[\&insertInput , $self, "i nu"]);
	$self->{mw}->bind('all','<Alt-z>'=>[\&insertInput , $self, "exp"]);
	#cookiemaster cart shortcut
	$self->{mw}->bind('all','<Alt-c>'=>[\&insertInput , $self, "cart"]);
	#digitalpheer guild shortcut 
	$self->{mw}->bind('all','<Alt-f>'=>[\&insertInput , $self, "guild i"]);
	$self->{mw}->bind('all','<Alt-g>'=>[\&insertInput , $self, "guild m"]);
	$self->{mw}->bind('all','<Alt-h>'=>[\&insertInput , $self, "guild p"]);
	$self->{input}->bind('<Up>' => [\&inputUp, $self]);
	$self->{input}->bind('<Down>' => [\&inputDown, $self]);
	$self->{input}->bind('<Return>' => [\&inputEnter, $self]);


	if ($buildType == 0) {
		$self->{mw}->bind('all','<MouseWheel>'=>[\&w32mWheel, $self, Ev('k')]);
	} else {
		#I forgot the X code. will insert later
	}
	$self->{input}->focus();
}


sub insertInput{
	my $dummy = shift;
	my $self=shift;
	my $command = shift;
	 push(@{$self->{input_que}}, $command);
}

sub errorDialog {
	my $self = shift;
	my $msg = shift;
	$self->{mw}->messageBox(
		-icon => 'error',
		-message => $msg,
		-title => 'Error',
		-type => 'Ok'
		);
}

sub inputUp {
	my $inputarea = shift; #this is redundant =\
	my $self = shift;

	my $line;

	chomp($line = $self->{input}->get);
	unless ($self->{input_offset}) {
		$self->{input_list}[$self->{input_offset}] = $line;
	}
	$self->{input_offset}++;
	$self->{input_offset} -= $#{$self->{input_list}} + 1 while $self->{input_offset} > $#{$self->{input_list}};
	
	$self->{input}->delete('0', 'end');
	$self->{input}->insert('end', $self->{input_list}[$self->{input_offset}]);
}

sub inputDown {
	my $inputarea = shift; #this is redundant =\
	my $self = shift;

	my $line;

	chomp($line = $self->{input}->get);
	unless ($self->{input_offset}) {
		$self->{input_list}[$self->{input_offset}] = $line;
	}
	$self->{input_offset}--;
	$self->{input_offset} += $#{$self->{input_list}} + 1 while $self->{input_offset} < 0;
	
	$self->{input}->delete('0', 'end');
	$self->{input}->insert('end', $self->{input_list}[$self->{input_offset}]);
}

sub inputEnter {
	my $inputarea = shift; #this is redundant =\
	my $self = shift;
	my $line;
	$line = $self->{input}->get;
	return if $line eq "";
	if ($self->{input_pm} eq "") {
		if ($self->{input_type} eq "Public" && $line !~/^e (\d+)/) {
			$line = "c ".$line;
		}elsif ($self->{input_type} eq "Party"){
			$line = "p ".$line;
		}elsif ($self->{input_type} eq "Guild"){
			$line = "g ".$line;
		}
	}else{
		$self->addPM($self->{input_pm});
		$line = "pm \"$self->{input_pm}\" $line";
	}

	$self->{input}->delete('0', 'end');

	$self->{input_list}[0] = $line;
	unshift(@{$self->{input_list}}, "");
	$self->{input_offset} = 0;
	push(@{ $self->{input_que} }, $line);
}

sub inputPaste {
	my $inputarea = shift; #this is redundant =\
	my $self = shift;

	my $line;

	$line = $self->{input}->get;
#	print "'$line'\n";

	$self->{input}->delete('0', 'end');

	my @lines = split(/\n/, $line);
	$line = pop(@lines);
	push(@{ $self->{input_que} }, @lines);
	$self->{input}->insert('end', $line) if $line;
}

sub w32mWheel {
	my $action_area = shift;
	my $self = shift;
	my $zDist = shift;
	$self->{console}->yview('scroll', -int($zDist/40), "units");
}

sub OnExit{
	my $self = shift;
	if (!-e "Tk.xml") {
		pl2xml(\$preferences,"Tk.xml");
	}
	push(@{ $self->{input_que} }, "quit");
}

sub showManual {
	my $self = shift;
	$self->{ShellExecute}->Call(0, '', 'http://openkore.sourceforge.net/manual/', '', '', 1);
}

sub resetColors {
	my $hookname = shift;
	my $r_args = shift;
	my $self = shift;
	return if $hookname ne 'postloadfiles';
	my $colors_loaded = 0;
#	foreach my $filehash (@{ $r_args->{files} }) {
#		if ($filehash->{file} =~ /consolecolors.txt$/) {
#			$colors_loaded = 1;
#			last;
#		}
#	}
#	return unless $colors_loaded;
	my %gdefault = (-foreground => 'grey', -background => 'black');
	eval {
		$self->{console}->configure(%gdefault);
		$self->{input}->configure(%gdefault);
		$self->{pminput}->configure(%gdefault);
		$self->{sinput}->configure(%gdefault);
	};
	if ($@) {
		if ($@ =~ /unknown color name "(.*)" at/) {
			System::message("Color '$1' not recognised.\n");
			return undef if !$consoleColors{''}{'useColors'}; #don't bother throwing a lot of errors in the next section.
		} else {
			die $@;
		}
	}
	foreach my $type (keys %consoleColors) {
		next if $type eq '';
		my %tdefault =%gdefault;
		if ($consoleColors{''}{'useColors'} && $consoleColors{$type}{'default'}) {
			$consoleColors{$type}{'default'} =~ m|([^/]*)(?:/(.*))?|;
			$tdefault{-foreground} = defined($1) && $1 ne 'default' ? $1 : $gdefault{-foreground};
			$tdefault{-background} = defined($2) && $2 ne 'default' ? $2 : $gdefault{-background};
		}
		eval {
			$self->{console}->tagConfigure($type, %tdefault);
		};
		if ($@) {
			if ($@ =~ /unknown color name "(.*)" at/) {
				#Log::message("Color '$1' not recognised in consolecolors.txt at [$type]: default.\n");
			} else {
				die $@;
			}
		}
		foreach my $domain (keys %{ $consoleColors{$type} }) {
			my %color = %tdefault;
			if ($consoleColors{''}{'useColors'} && $consoleColors{$type}{$domain}) {
				$consoleColors{$type}{$domain} =~ m|([^/]*)(?:/(.*))?|;
				$color{-foreground} = defined($1) && $1 ne 'default' ? $1 : $tdefault{-foreground};
				$color{-background} = defined($2) && $2 ne 'default' ? $2 : $tdefault{-background};
			}
			eval {
				$self->{console}->tagConfigure("$type.$domain", %color);
			};
			if ($@) {
				if ($@ =~ /unknown color name "(.*)" at/) {
					#Log::message("Color '$1' not recognised in consolecolors.txt at [$type]: $domain.\n");
				} else {
					die $@;
				}
			}
		}
	}
}

sub mapToggle {
	my ($self);

	if (@_ == 1) {
		$self = $_[0];
	} elsif (@_ == 2) {
		$self = $_[1];
	} else {
		die "wrong number of args to mapToggle\n";
	}
	if (!defined($self->{map}) && $chars[$config{'char'}] && %field) {
		$self->{map}{window} = $self->{mw}->Toplevel();
		my ($x,$y) = @{$chars[$config{'char'}]{'pos_to'}}{'x', 'y'};
		$self->{map}{window}->title(sprintf "Map View: %8s p:(%3d, %3d)", $field{'name'}, $x, $y);
		$self->{map}{window}->protocol('WM_DELETE_WINDOW', 
			sub {
				$self->mapToggle();
			}
		);
		$self->{map}{window}->resizable(0,0);
		$self->{map}{canvas} = $self->{map}{window}->Canvas(
			-width => 200,
			-height => 200,
			-background => 'white',
		)->pack(
			-side => 'top'
		);
		$self->loadMap();
		
			
		my $dis = $config{'attackDistance'};
		$self->{map}{ind}{range} = $self->{map}{canvas}->createOval(
			-$dis, $self->{map}{height} - $dis,
			 $dis, $self->{map}{height} + $dis,
			-outline => '#ff0000',
		);
		$self->{map}{ind}{player} = $self->{map}{canvas}->createOval(
			-2, $self->{map}{height} - 2,
			 2, $self->{map}{height} + 2,
			-fill => '#ffcccc', -outline=>'#ff0000'
		);
		
#		if ($main::sys{'enableMoveClick'}) {
#			$map_mw->bind('<Double-1>', [\&dblchk , Ev('x') , Ev('y')]);
#		}
		#$self->{map}{window}->bind('<1>', [\&mapMove, $self, Ev('x') , Ev('y'), 2]); 
		#$self->{map}{window}->bind('<3>', [\&mapMove, $self, Ev('x') , Ev('y'), 1]); 
		$self->{map}{window}->bind('<Double-1>', [\&dblchk, $self, Ev('x') , Ev('y')]); 
		$self->{map}{window}->bind('<Motion>', [\&pointchk, $self, Ev('x') , Ev('y')]); 
		$self->updatePos();
	} elsif (defined $self->{map}) {
		$self->{map}{window}->destroy();
		undef $self->{map}{canvas};
		undef $self->{map}{window};
		undef $self->{map};
	}
}

sub pointchk {
	my (undef, $self, $mvcpx, $mvcpy) = @_;
	if (@_ == 3) {
		($self, $mvcpx, $mvcpy) = @_;
	} elsif (@_ == 4) {
		(undef, $self, $mvcpx, $mvcpy) = @_;
	} else {
		die "wrong number of args to pointchk\n";
	}
	$mvcpy = $self->{map}{height} - $mvcpy;
	$self->{map}{window}->title(sprintf "Map View: %8s \[%3d, %3d\]", $field{'name'},$mvcpx, $mvcpy);
	$self->{map}{window}->update; 
}

sub dblchk {
	my (undef, $self, $mvcpx, $mvcpy) = @_;
	if (@_ == 3) {
		($self, $mvcpx, $mvcpy) = @_;
	} elsif (@_ == 4) {
		(undef, $self, $mvcpx, $mvcpy) = @_;
	} else {
		die "wrong number of args to pointchk\n";
	}
	$mvcpy = $self->{map}{height} - $mvcpy;
	push(@{ $self->{input_que} }, "move $mvcpx $mvcpy");
}

sub mapIsShown {
	my $self = shift;
	return defined($self->{map});
}

sub loadMap {
	my $self = shift;
	return if (!$self->mapIsShown());
	$self->{map}{field} = $field{'name'};
	$self->{map}{canvas}->delete('map');
	$self->{map}{canvas}->createText(50,20,-text =>'Processing..',-tags=>'loading');
	if (-e "maps/$field{'name'}.gif") {
		my ($len,$data);
		open (FILE, "< maps/$field{'name'}.gif");
		binmode(FILE);
		$len = (-s "maps/$field{'name'}.gif");
		read(FILE, $data, $len);
		$data = encode_base64($data);
		close(FILE);
		$self->{map_bitmap} = $self->{map}{canvas}->Photo(-data=>$data, -format=>'gif');
	}elsif (-e "maps/$field{'name'}.xpm") {
		$self->{map_bitmap} = $self->{map}{canvas}->Pixmap(-file =>"maps/$field{'name'}.xpm");
	}elsif (-e "maps/$field{'name'}.xbm") {
		$self->{map_bitmap} = $self->{map}{canvas}->Bitmap(-file =>"maps/$field{'name'}.xbm");
	}else{
#		open(F, "> maps/$field{'name'}.xpm");
#		binmode F;
#		print F ${&xpmmake(\%field)};
#		close F;
		$self->{map_bitmap} = $self->{map}{canvas}->Bitmap(-data => ${&xbmmake(\%field)});
	}
	$self->{map}{canvas}->createImage(2,2,-image => $self->{map_bitmap},-anchor => 'nw',-tags=>'map');
	$self->{map}{canvas}->configure(
			-width => $field{'width'},
			-height => $field{'height'}
	);
	$self->{map}{width} = $field{'width'};
	$self->{map}{height} = $field{'height'};
	$self->{map}{canvas}->delete('loading');
}

#should this cache xbm files?
sub xbmmake {
	my $r_hash = shift;
	my ($i,$j,$k,$hx,$hy,$mvw_x,$mvw_y);
	my $line=0;
	my $dump=0;
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
			$dump+=256 if (defined($$r_hash{'field'}[$hy+$k]) && $$r_hash{'field'}[$hy+$k] >0);
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

sub xpmmake {
	my $r_hash = shift;
	my $data = "/* XPM */\n" .
		"static char * my_xpm[] = {\n" .
		"\"$$r_hash{width} $$r_hash{height} 3 1\",\n" .
		"\" \tc #004100\",\n" .
		"\"A\tc #000000\",\n" .
		"\".\tc #008200\",\n";
	for (my $y = $$r_hash{height} - 1; $y >= 0; $y--) {
		$data .= "\"";
		for (my $x = 0; $x < $$r_hash{width}; $x++) {
			my $char = substr($$r_hash{rawMap}, $y * $$r_hash{width} + $x, 1);
			if ($char eq "\0") {
				$data .= '.';
			} elsif ($char eq "\1") {
				$data .= ' ';
			} else {
				$data .= 'A';
			}
		}
		$data .= "\",\n";
	}
	$data .= "};\n";
	return \$data;
}

#sub change_fontWeight{
#	my $self = shift;
#	if ($self->{is_bold}) {
#		$self->{console}->configure(-font=>[-family => $self->{default_font},-size=>8,-weight=>'bold']);
#	}else{
#		$self->{console}->configure(-font=>[-family => $self->{default_font},-size=>8,-weight=>'normal']);
#	}
#}

sub change_font{
	my $self = shift;
	my $font = $self->{mw}->FontDialog->Show();
	$self->{console}->configure(-font=>$font) if (defined $font);
}

sub aboutBox{
	my ($self);

	if (@_ == 1) {
		$self = $_[0];
	} elsif (@_ == 2) {
		$self = $_[1];
	} else {
		die "wrong number of args to mapToggle\n";
	}
	if (!defined($self->{about})) {
		$self->{about}{window} = $self->{mw}->Toplevel();
		$self->{about}{window}->title("About modKore-Plus!");
		$self->{about}{window}->protocol('WM_DELETE_WINDOW', 
			sub {
				$self->aboutBox();
			}
		);
		$self->{about}{window}->resizable(0,0);
		$self->{about}{canvas} = $self->{about}{window}->Canvas(
			-width => 200,
			-height => 100,
			-background => 'white',
		)->pack(
			-side => 'top'
		);
		eval { PerlApp::extract_bound_file("opk.gif"); };
		if (!$@) {
			$self->{about}{photo} = $self->{about}{window}->Photo(-file=>PerlApp::extract_bound_file("opk.gif"));
		}else{
			$self->{about}{photo} = $self->{about}{window}->Photo(-file=>"opk.gif");
		}
		
		$self->{about}{canvas}->createImage(2,2,-image=>$self->{about}{photo},-anchor => 'nw');

	} elsif (defined $self->{about}) {
		$self->{about}{window}->destroy();
		undef $self->{about}{canvas};
		undef $self->{about}{window};
		undef $self->{about};
	}
}

sub parseMsg {
	my $hookname = shift;
	my $msg = shift;
	my $self = shift;
	return if (!defined $self->{mw} || length($msg) < 2);
	my $switch = uc(unpack("H2", substr($msg, 1, 1))) . uc(unpack("H2", substr($msg, 0, 1)));
	if ($switch eq "0087") {
	}elsif ($switch eq "0097") {
		my ($privMsgUser) = substr($msg, 4, 24) =~ /([\s\S]*?)\000/;
		$self->addPM($privMsgUser);
	}
}

sub launchURL {
	my $url = shift;
	eval "use Win32::API;";
	my $ShellExecute = new Win32::API("shell32", "ShellExecute", "NPPPPN", "V");
	$ShellExecute->Call(0, '', $url, '', '', 1);
}

1; #end of module
