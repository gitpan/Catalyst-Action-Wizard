#
#===============================================================================
#
#         FILE:  Wizard.pm
#
#  DESCRIPTION:  Wizarded action.
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Pavel Boldin (), <davinchi@cpan.ru>
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  21.06.2008 19:34:41 MSD
#     REVISION:  ---
#===============================================================================

=head1 NAME

Catalyst::Action::Wizard -- actions like realization of wizards. You need this
if you have some multi-actions data gathering which unlikely to be saved
in session and to big to pass them as POST or GET parameters.

=cut

package Catalyst::Action::Wizard;

use strict;
use warnings;


use Catalyst::Action;
use Catalyst::Wizard;
use Catalyst::Utils;
use Class::C3;

use Scalar::Util;
use Data::Dumper;
use base 'Catalyst::Action';

our $VERSION = '0.001';

sub refaddr($) {
    sprintf "%x", Scalar::Util::refaddr(shift);
}

sub _current_wizard {
    return Catalyst::Wizard::_current_wizard(@_);
}

sub _new_wizard {
    my $c    = shift;
    my $wizard_id = shift || 'new';

    my $class = $c->config->{wizard}{class} || 'Catalyst::Wizard';

    Catalyst::Utils::ensure_class_loaded( $class );

    Catalyst::Wizard::DEBUG && 
	Catalyst::Wizard->info( 'calling _new_wizard: '.$wizard_id );

    _current_wizard($c, $class->new( $c, $wizard_id ) );
}

sub wizard {
    my $self	= shift;
    my $c	= shift;

    if ( @_ ) { 

	if ( !_current_wizard( $c ) ) {
	    _new_wizard( $c );
	}

	_current_wizard($c)->add_steps(caller => [ caller ], @_);
    }

    return _current_wizard($c);
}

sub _check_wizard_is_changed {
    my $c = shift;
    my $wizard_id_without_step = shift;

    my $wizard_id_changed = _current_wizard($c) && $c->can('req');

    $wizard_id_changed &&= 
	    exists ($c->req->params->{wid})
	&&   
	    _current_wizard( $c )->{wizard_id} ne $wizard_id_without_step;


    if ( $wizard_id_changed ) { 
	_current_wizard($c, '');
    }
}

sub execute {
    my $self = shift;
    my ($controller, $c) = @_;

    #warn "executing: $self";

    if ( $self->name eq '_BEGIN' ) {
	my $wizard_id = $c->can('wizard_id') ? $c->wizard_id 
	    : exists $c->req->params->{wid}  ? $c->req->params->{wid}
	    : ''
	    ;

	my $wizard_id_without_step;
	
	if ( $wizard_id ) {
	    ($wizard_id_without_step) = $wizard_id =~ /([0-9a-zA-Z]{32})/;
	}

	#if ( $wizard_id && !$wizard_id_without_step ) {
	#   return $self->next::method( @_ );
	#}

	#_check_wizard_is_changed( $c, $wizard_id_without_step );

	if ( $wizard_id && $wizard_id_without_step ) {
	    _new_wizard( $c, $wizard_id );
	}

    } elsif ( not $self->name =~ /^_/ ) {

	my @ret = eval { $self->next::method(@_) };

	# can be created in action
	my $wizard = _current_wizard( $c );

	if ($wizard
	    &&	
	    (
		( 
		    $@ 
		 && $@ eq $Catalyst::Wizard::GOTO_NEXT 
		) 
		||  $wizard->{goto} 
	    ) ) {

	    undef $@;
	    $wizard->perform_step( $c );
	}
	elsif ( $@ ) {
	    die $@;
	}

	return @ret;
    } elsif ( $self->name eq '_END' ) {
	if ( _current_wizard( $c ) ) {
	    _current_wizard( $c )->save( $c );
	}
    }

    $self->next::method(@_);
}

1;
