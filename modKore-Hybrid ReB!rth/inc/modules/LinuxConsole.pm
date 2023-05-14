#########################################################################
#  modKore - Hybrid :: LinuxConsole by VCL
#  http://modkore.sf.net
#
#  This software is open source, licensed under the GNU General Public
#  License, version 2.
#  Basically, this means that you're allowed to modify and distribute
#  this software. However, if you distribute modified versions, you MUST
#  also distribute the source code.
#  See http://www.gnu.org/licenses/gpl.html for the full license.
#########################################################################
package LinuxConsole;

#errors detection
use strict;
no warnings;

use Exporter;
our @ISA = ("Exporter");

sub new {
	my $type = $_[0];
	my $self = {};
	bless $self, $type;
	return $self;
}

sub Attr {
	# Do nothing for now
}

sub Title {
	# We can't print to STDOUT (it'll get redirected to Vx)
	# so we print to /dev/tty instead
	if ($ENV{'TERM'} eq "xterm" && open(TTY, "> /dev/tty")) {
		print TTY "\e]2;" . $_[1] ."\a";
		close(TTY);
	}
}
1;