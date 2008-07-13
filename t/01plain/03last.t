#
#===============================================================================
#
#         FILE:  03last.t
#
#  DESCRIPTION:  Catalyst::Wizard -last option check
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Pavel Boldin (), <davinchi@cpan.ru>
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  12.07.2008 19:47:37 MSD
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;
use lib qw(t/01plain/lib);

use Test::More tests => 3;

use Catalyst::Wizard;
use Data::Dumper;
use Filter::Simple;
use Digest::MD5 qw(md5_hex);

use Wizard::Test;

$Data::Dumper::Indent = 1;

our $wizards = {};
our $current_wizard;
our $stash = {};

my $c = TestApp->new;

my $new_wizard = Catalyst::Wizard->new( $c );

eval { $new_wizard->add_steps(-last =>  '/testme', -redirect => '/pleasetestme' ) };

get_caller;

like ( $@, qr/-last should be last in/, 'error ok');

$new_wizard->add_steps('/testme', -last => '/laststep');
is_deeply( $new_wizard->{steps}[1], 
    {
	step_type => '-redirect',
	append_wizard_id => 1,
	path => '/laststep',
	last => 1,
	caller => get_caller,
    }, 'last step ok' );


$new_wizard->add_steps(-last => '/laststep');
is( @{ $new_wizard->{steps} }, 2, 'steps count -- no -last step added');

