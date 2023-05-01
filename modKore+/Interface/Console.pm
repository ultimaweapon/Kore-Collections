#########################################################################
#  OpenKore - Console Interface Dynamic Loader
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
#  $Revision: 1.2 $
#  $Id: Console.pm,v 1.2 2004/09/04 07:11:39 Administrator Exp $
#
#########################################################################
##
# MODULE DESCRIPTION: Console Interface dynamic loader
#
# Loads the apropriate Console Interface for each system at runtime.
# Primarily used to load Interface::Console::Win32 for windows systems and
# Interface::Console::Other for systems that support proper STDIN handles

package Interface::Console;

use strict;
use warnings;
use Interface;
use base qw(Interface);
use Globals;


sub new {
	# Automatically load the correct module for
	# the current operating system

	if ($buildType == 0) {
		# Win32
		eval "use Interface::Console::Win32;";
		die $@ if $@;
		return new Interface::Console::Win32;
	} else {
		# Linux/Unix
		use DynaLoader;
		my $useGtk = 0;

		# Try to load the GTK+ interface if we're in X, and GTK2 (and the Perl bindings) are available
		if ($ENV{DISPLAY} && DynaLoader::dl_findfile('libgtk-x11-2.0.so.0')) {
			eval "use Gtk2;";
			$useGtk = 1 if (!$@);
		}

		if ($useGtk) {
			my $mod = 'Interface::Console::Other::Gtk';
			my $str = "use $mod;";
			eval ${\$str};
			die $@ if $@;
			Modules::register("$mod");
			return new Interface::Console::Other::Gtk;

		} else {
			my $mod = 'Interface::Console::Other';
			my $str = "use $mod;";
			eval ${\$str};
			die $@ if $@;
			Modules::register("$mod");
			return new Interface::Console::Other;
		}
	}
}


1 #end of module
