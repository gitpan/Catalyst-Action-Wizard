use strict;
use Module::Build;

my $build = Module::Build->new(
    license             => 'perl',
    module_name         => 'Catalyst::Action::Wizard',
    requires            => {
        'perl'                          => 5.006,
        'Catalyst'                      => 0.57,
        'Catalyst::Plugin::Session'     => 0.19,
	'HTTP::Message'			=> 1.57,
    },
    build_requires      => {
        'ok'						=>  0,
        'Test::More'					=>  0,
	'Test::WWW::Mechanize::Catalyst'		=>  0,
	'Catalyst::Plugin::Session::State::Cookie'	=>  0,
    },
    create_makefile_pl  => 'passthrough',
    dist_abstract       => 'Catalyst::Action::Wizard -- Catalyst module for building wizards',
    dist_version	=> '0.001',
    recursive_test_files=> 1,
);

$build->create_build_script;