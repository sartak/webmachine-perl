#!/usr/bin/perl

use strict;
use warnings;

use lib 't/010-resources/';

use Test::More;
use Test::Fatal;

use Plack::Request;
use Plack::Response;

use Web::Machine::FSM;

{
    package Throw500;

    use base 'Web::Machine::Resource';

    sub service_available {
        die "This is a 500 error\n";
    }
}

my $fsm = Web::Machine::FSM->new();

my @errors;
my $logger = sub { push @errors, @_ };

my $request = Plack::Request->new( { 'psgix.logger' => $logger } );

my $r = Throw500->new(
    request  => $request,
    response => Plack::Response->new
);

is(
    exception { $fsm->run($r) },
    undef,
    'no exception from resource which throws an error'
);

is_deeply(
    \@errors,
    [ { level => 'error', message => "This is a 500 error\n" } ],
    'psgix.logger is called with error message'
);

done_testing;
