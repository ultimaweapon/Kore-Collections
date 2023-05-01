#########################################################################
#  OpenKore - Interface::Console::Gtk
#  Console interface for with a little bit of GTK+
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
#  $Id: Gtk.pm,v 1.2 2004/07/28 08:46:01 hongli Exp $
#
#########################################################################

package Interface::Console::Other::Gtk;

use strict;
use warnings;
no warnings qw(redefine uninitialized);
use Gtk2;
use POSIX;

use Interface::Console::Other;
use base qw(Interface::Console::Other);
use Globals;

our $initialized;


sub new {
	my $class = shift;
	my $interface;

	$interface = $class->SUPER::new(@_);
	bless $interface, $class;
	return $interface;
}

sub _initGtk {
	return if $initialized;
	$initialized = 1;
	Gtk2::init();
}

sub errorDialog {
	my $self = shift;
	my $message = shift;

	my $dialog;
	my $name = $chars[$config{user}]{name};
	_initGtk();
	$dialog = new Gtk2::MessageDialog(undef, 'modal', 'error', 'close',
		"%s", $message);
	if ($name) {
		$dialog->set_title("$name - OpenKore Error");
	} else {
		$dialog->set_title("OpenKore Error");
	}
	$dialog->set_resizable(0);
	$dialog->run();
	$dialog->destroy();
}

return 1;
