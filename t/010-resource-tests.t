#!/usr/bin/perl

use strict;
use warnings;

use lib 't/010-resources/';

use Test::More;
use Test::Fatal;

use Plack::Request;
use Plack::Response;
use Plack::Util;

BEGIN {
    use_ok('Web::Machine::FSM');
}

my $fsm = Web::Machine::FSM->new;
isa_ok( $fsm, 'Web::Machine::FSM' );

my @tests = (
    {
        resource => 'B13',
        request  => { REQUEST_METHOD => 'GET', SERVER_PROTOCOL => 'HTTP/1.1', SCRIPT_NAME => '/' },
        response => [ 503, [], [] ]
    },
    {
        resource => 'B12',
        request  => { REQUEST_METHOD => 'GET', SERVER_PROTOCOL => 'HTTP/1.1', SCRIPT_NAME => '/' },
        response => [ 501, [], [] ]
    },
    {
        resource => 'B11',
        request  => { REQUEST_METHOD => 'GET', SERVER_PROTOCOL => 'HTTP/1.1', SCRIPT_NAME => '/' },
        response => [ 414, [], [] ]
    }
);

foreach my $test ( @tests ) {

    my $resource = Plack::Util::load_class( $test->{'resource'} );

    my $request = $resource->new(
        request  => Plack::Request->new( $test->{'request'} ),
        response => Plack::Response->new
    );
    isa_ok($request, 'Web::Machine::Resource', '... created resource (' . $test->{'resource'}. ') successfully');

    my $response;
    is(exception {
        $response = $fsm->run( $request );
    }, undef, '... ran resource (' . $test->{'resource'}. ') successfully');

    is_deeply( $response->finalize, $test->{'response'}, '... got the response for resource (' . $test->{'resource'}. ') we expected' );
}

done_testing;