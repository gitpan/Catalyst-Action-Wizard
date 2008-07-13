#
#===============================================================================
#
#         FILE:  Wizarded.pm
#
#  DESCRIPTION:  Wizarded applications base class
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Pavel Boldin (), <davinchi@cpan.ru>
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  25.06.2008 14:20:31 MSD
#     REVISION:  ---
#===============================================================================

package CatalystX::Wizarded;

use strict;
use warnings;

require Catalyst::Controller;


sub wizard {
    my $c = shift;
    $c->action->wizard( $c, caller => [ caller ], @_ );
}

sub have_wizard {
    my $c = shift;
    Catalyst::Wizard::_current_wizard( $c );
}

sub import {
    my $self = shift;
    Catalyst::Controller->_action_class('Catalyst::Action::Wizard');

    my %defaults = (
	expires	    => 86400,
	instance    => 'Catalyst::Wizard',
    );

    while (my ($k, $v) = each %defaults) {
	if (!exists(caller()->config->{wizard}{$k})) {
	    caller()->config->{wizard}{$k} = $v;
	}
    }

    {
	no strict 'refs';
	*{caller().'::wizard'}	    = \&wizard	   ;
	*{caller().'::have_wizard'} = \&have_wizard;
    }
}



1;
