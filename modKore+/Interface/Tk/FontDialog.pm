package Interface::Tk::FontDialog;

use Tk;
use Tk::LabEntry;
use Tk::Font;
use Tk::DirTree;
use Tk::ProgressBar;

@ISA = qw(Tk::Toplevel);
use base qw/Tk::Derived Tk::Widget Interface::Tk/;

Tk::Widget->Construct('FontDialog');
our $mw;

sub ClassInit{
	my ($class, $main_window) = @_;
	$class->SUPER::ClassInit($main_window);
}

sub Populate{
	my($self, $args) = @_;
	$self->SUPER::Populate($args);
	$self->show();
}

sub show{
	my $self = shift;
	$self->show();
}
1;