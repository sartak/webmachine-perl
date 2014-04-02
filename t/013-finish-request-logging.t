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
    package DieInFinishRequest;

    use base 'Web::Machine::Resource';

    sub known_methods { [qw[ GET ]] }

    sub finish_request {
        die "Something bad happened\n";
    }
}

my $fsm = Web::Machine::FSM->new();

my @errors;
my $logger = sub { push @errors, @_ };

my $request = Plack::Request->new( { 'psgix.logger' => $logger } );

my $r = DieInFinishRequest->new(
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
    [ { level => 'error', message => "Something bad happened\n" } ],
    'psgix.logger is called with error message'
);

done_testing;
