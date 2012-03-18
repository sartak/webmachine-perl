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
    },
    {
        resource => 'B10',
        request  => { REQUEST_METHOD => 'GET', SERVER_PROTOCOL => 'HTTP/1.1', SCRIPT_NAME => '/' },
        response => [ 405, [ 'Allow' => 'PUT, DELETE' ], [] ]
    },
    {
        resource => 'B9',
        request  => { REQUEST_METHOD => 'GET', SERVER_PROTOCOL => 'HTTP/1.1', SCRIPT_NAME => '/' },
        response => [ 400, [], [] ]
    },
    {
        resource => 'B8',
        request  => { REQUEST_METHOD => 'GET', SERVER_PROTOCOL => 'HTTP/1.1', SCRIPT_NAME => '/' },
        response => [ 401, [ 'WWW-Authenticate' => 'Basic realm="Test"' ], [] ]
    },
    {
        resource => 'B8b',
        request  => { REQUEST_METHOD => 'GET', SERVER_PROTOCOL => 'HTTP/1.1', SCRIPT_NAME => '/' },
        response => [ 500, [], [] ]
    },
    {
        resource => 'B7',
        request  => { REQUEST_METHOD => 'GET', SERVER_PROTOCOL => 'HTTP/1.1', SCRIPT_NAME => '/' },
        response => [ 403, [], [] ]
    },
    {
        resource => 'B6',
        request  => { REQUEST_METHOD => 'GET', SERVER_PROTOCOL => 'HTTP/1.1', SCRIPT_NAME => '/' },
        response => [ 501, [], [] ]
    },
    {
        resource => 'B5',
        request  => { REQUEST_METHOD => 'GET', SERVER_PROTOCOL => 'HTTP/1.1', SCRIPT_NAME => '/' },
        response => [ 415, [], [] ]
    },
    {
        resource => 'B4',
        request  => { REQUEST_METHOD => 'GET', SERVER_PROTOCOL => 'HTTP/1.1', SCRIPT_NAME => '/' },
        response => [ 413, [], [] ]
    },
    {
        resource => 'B3',
        request  => { REQUEST_METHOD => 'OPTIONS', SERVER_PROTOCOL => 'HTTP/1.1', SCRIPT_NAME => '/' },
        response => [ 200, [ 'X-Hello' => 'OH HAI!' ], [] ]
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