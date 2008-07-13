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

    unless ( $self->name =~ /^_/ ) {
	my $wizard_id = $c->can('wizard_id') ? $c->wizard_id 
	    : exists $c->req->params->{wid}  ? $c->req->params->{wid}
	    : ''
	    ;

	my $wizard_id_without_step;
	
	if ( $wizard_id ) {
	    ($wizard_id_without_step) = $wizard_id =~ /([0-9a-zA-Z]{32})/;
	}

	if ( $wizard_id && !$wizard_id_without_step ) {
	    return $self->next::method( @_ );
	}

	_check_wizard_is_changed( $c, $wizard_id_without_step );

	my $wizard;

	if ( ! ( $wizard = _current_wizard( $c ) ) ) {
	    if ( $wizard_id ) {
		$wizard = _new_wizard( $c, $wizard_id );
	    }

	}

	$wizard->load( $c ) if $wizard;

	my @ret = eval { $self->next::method(@_) };

	# can be created in action
	$wizard ||= _current_wizard( $c );

	if ($wizard
	    &&	
	    (
		( 
		    $@ 
		 && $@ eq $Catalyst::Wizard::GOTO_NEXT 
		) 
		||  $wizard->{goto} 
	    ) ) {

	    $wizard->perform_step( $c );
	    undef $@;
	}
	elsif ( $@ ) {
	    die $@;
	}

	return @ret;
    }

    $self->next::method(@_);
}

1;
