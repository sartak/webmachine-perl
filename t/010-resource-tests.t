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
    },
    {
        resource => 'C4',
        request  => { REQUEST_METHOD => 'GET', SERVER_PROTOCOL => 'HTTP/1.1', SCRIPT_NAME => '/', HTTP_ACCEPT => 'text/html' },
        response => [ 406, [], [] ]
    },
    # ... (langauge doesn't match, but content type does)
    {
        resource => 'D5',
        request  => { REQUEST_METHOD => 'GET', SERVER_PROTOCOL => 'HTTP/1.1', SCRIPT_NAME => '/', HTTP_ACCEPT_LANGUAGE => 'en' },
        response => [ 406, [], [] ]
    },
    {
        resource => 'D5',
        request  => { REQUEST_METHOD => 'GET', SERVER_PROTOCOL => 'HTTP/1.1', SCRIPT_NAME => '/', HTTP_ACCEPT => 'text/plain', HTTP_ACCEPT_LANGUAGE => 'en' },
        response => [ 406, [], [] ] # won't have written the content type header yet
    },
    # ... (content type and language match, but charset doesn't)
    {
        resource => 'E6',
        request  => { REQUEST_METHOD => 'GET', SERVER_PROTOCOL => 'HTTP/1.1', SCRIPT_NAME => '/', HTTP_ACCEPT_LANGUAGE => 'en', HTTP_ACCEPT_CHARSET => 'iso-8859-5' },
        response => [ 406, [], [] ]
    },
    {
        resource => 'E6',
        request  => { REQUEST_METHOD => 'GET', SERVER_PROTOCOL => 'HTTP/1.1', SCRIPT_NAME => '/', HTTP_ACCEPT_LANGUAGE => 'de', HTTP_ACCEPT_CHARSET => 'iso-8859-5' },
        response => [ 406, [ 'Content-Language' => 'de' ], [] ]
    },
    {
        resource => 'E6',
        request  => { REQUEST_METHOD => 'GET', SERVER_PROTOCOL => 'HTTP/1.1', SCRIPT_NAME => '/', HTTP_ACCEPT => 'text/plain', HTTP_ACCEPT_LANGUAGE => 'de', HTTP_ACCEPT_CHARSET => 'iso-8859-5' },
        response => [ 406, [ 'Content-Language' => 'de' ], [] ] # won't have written the content type header yet
    },
    # ... (no encoding asked for, and no identity provided, but content-type, language and charset matches)
    {
        resource => 'F6',
        request  => { REQUEST_METHOD => 'GET', SERVER_PROTOCOL => 'HTTP/1.1', SCRIPT_NAME => '/', HTTP_ACCEPT => 'text/plain', HTTP_ACCEPT_LANGUAGE => 'de', HTTP_ACCEPT_CHARSET => 'utf-8' },
        response => [ 406, [ 'Content-Language' => 'de', 'Content-Type' => 'text/plain;charset=utf-8' ], [] ]
    },
    {
        resource => 'F6',
        request  => { REQUEST_METHOD => 'GET', SERVER_PROTOCOL => 'HTTP/1.1', SCRIPT_NAME => '/', HTTP_ACCEPT_LANGUAGE => 'de', HTTP_ACCEPT_CHARSET => 'utf-8' },
        response => [ 406, [ 'Content-Language' => 'de', 'Content-Type' => 'text/plain;charset=utf-8' ], [] ]
    },
    {
        resource => 'F6',
        request  => { REQUEST_METHOD => 'GET', SERVER_PROTOCOL => 'HTTP/1.1', SCRIPT_NAME => '/', HTTP_ACCEPT_LANGUAGE => 'de' },
        response => [ 406, [ 'Content-Language' => 'de', 'Content-Type' => 'text/plain' ], [] ]
    },
    {
        resource => 'F6',
        request  => { REQUEST_METHOD => 'GET', SERVER_PROTOCOL => 'HTTP/1.1', SCRIPT_NAME => '/' },
        response => [ 406, [ 'Content-Type' => 'text/plain' ], [] ]
    },
    # ... (same as F6, but now we are asking for an encoding)
    {
        resource => 'F7',
        request  => { REQUEST_METHOD => 'GET', SERVER_PROTOCOL => 'HTTP/1.1', SCRIPT_NAME => '/', HTTP_ACCEPT => 'text/plain', HTTP_ACCEPT_LANGUAGE => 'de', HTTP_ACCEPT_CHARSET => 'utf-8', HTTP_ACCEPT_ENCODING => 'gzip' },
        response => [ 406, [ 'Content-Language' => 'de', 'Content-Type' => 'text/plain;charset=utf-8' ], [] ]
    },
    {
        resource => 'F7',
        request  => { REQUEST_METHOD => 'GET', SERVER_PROTOCOL => 'HTTP/1.1', SCRIPT_NAME => '/', HTTP_ACCEPT_LANGUAGE => 'de', HTTP_ACCEPT_CHARSET => 'utf-8', HTTP_ACCEPT_ENCODING => 'gzip' },
        response => [ 406, [ 'Content-Language' => 'de', 'Content-Type' => 'text/plain;charset=utf-8' ], [] ]
    },
    {
        resource => 'F7',
        request  => { REQUEST_METHOD => 'GET', SERVER_PROTOCOL => 'HTTP/1.1', SCRIPT_NAME => '/', HTTP_ACCEPT_LANGUAGE => 'de', HTTP_ACCEPT_ENCODING => 'gzip' },
        response => [ 406, [ 'Content-Language' => 'de', 'Content-Type' => 'text/plain' ], [] ]
    },
    {
        resource => 'F7',
        request  => { REQUEST_METHOD => 'GET', SERVER_PROTOCOL => 'HTTP/1.1', SCRIPT_NAME => '/', HTTP_ACCEPT_ENCODING => 'gzip' },
        response => [ 406, [ 'Content-Type' => 'text/plain' ], [] ]
    },
    # ...
    {
        resource => 'H7',
        request  => { REQUEST_METHOD => 'GET', SERVER_PROTOCOL => 'HTTP/1.1', SCRIPT_NAME => '/', HTTP_ACCEPT => 'text/plain', HTTP_ACCEPT_LANGUAGE => 'de', HTTP_ACCEPT_CHARSET => 'utf-8', HTTP_ACCEPT_ENCODING => 'gzip', HTTP_IF_MATCH => '*' },
        response => [ 412, [ 'Vary' => 'Accept, Accept-Encoding, Accept-Charset, Accept-Language', 'Content-Encoding' => 'gzip', 'Content-Language' => 'de', 'Content-Type' => 'text/plain;charset=utf-8',  ], [] ]
    },
    {
        resource => 'H7b',
        request  => { REQUEST_METHOD => 'GET', SERVER_PROTOCOL => 'HTTP/1.1', SCRIPT_NAME => '/', HTTP_ACCEPT => 'text/plain', HTTP_ACCEPT_LANGUAGE => 'de', HTTP_ACCEPT_CHARSET => 'utf-8', HTTP_ACCEPT_ENCODING => 'gzip', HTTP_IF_MATCH => '*' },
        response => [ 412, [ 'Vary' => 'Accept-Encoding, Accept-Charset, Accept-Language', 'Content-Encoding' => 'gzip', 'Content-Language' => 'de', 'Content-Type' => 'text/plain;charset=utf-8',  ], [] ]
    },
    {
        resource => 'H7c',
        request  => { REQUEST_METHOD => 'GET', SERVER_PROTOCOL => 'HTTP/1.1', SCRIPT_NAME => '/', HTTP_ACCEPT => 'text/plain', HTTP_ACCEPT_LANGUAGE => 'de', HTTP_ACCEPT_CHARSET => 'utf-8', HTTP_ACCEPT_ENCODING => 'gzip', HTTP_IF_MATCH => '*' },
        response => [ 412, [ 'Vary' => 'Accept-Encoding, Accept-Charset', 'Content-Encoding' => 'gzip', 'Content-Language' => 'de', 'Content-Type' => 'text/plain;charset=utf-8',  ], [] ]
    },
    {
        resource => 'H7d',
        request  => { REQUEST_METHOD => 'GET', SERVER_PROTOCOL => 'HTTP/1.1', SCRIPT_NAME => '/', HTTP_ACCEPT => 'text/plain', HTTP_ACCEPT_LANGUAGE => 'de', HTTP_ACCEPT_CHARSET => 'utf-8', HTTP_ACCEPT_ENCODING => 'gzip', HTTP_IF_MATCH => '*' },
        response => [ 412, [ 'Vary' => 'Accept-Encoding', 'Content-Encoding' => 'gzip', 'Content-Language' => 'de', 'Content-Type' => 'text/plain;charset=utf-8',  ], [] ]
    },
    {
        resource => 'H7e',
        request  => { REQUEST_METHOD => 'GET', SERVER_PROTOCOL => 'HTTP/1.1', SCRIPT_NAME => '/', HTTP_ACCEPT => 'text/plain', HTTP_ACCEPT_LANGUAGE => 'de', HTTP_ACCEPT_CHARSET => 'utf-8', HTTP_ACCEPT_ENCODING => 'gzip', HTTP_IF_MATCH => '*' },
        response => [ 412, [ 'Content-Encoding' => 'gzip', 'Content-Language' => 'de', 'Content-Type' => 'text/plain;charset=utf-8',  ], [] ]
    },
    {
        resource => 'H7f',
        request  => { REQUEST_METHOD => 'GET', SERVER_PROTOCOL => 'HTTP/1.1', SCRIPT_NAME => '/', HTTP_ACCEPT => 'text/plain', HTTP_ACCEPT_LANGUAGE => 'de', HTTP_ACCEPT_CHARSET => 'utf-8', HTTP_ACCEPT_ENCODING => 'gzip', HTTP_IF_MATCH => '*' },
        response => [ 412, [ 'Vary' => 'Accept, Accept-Language', 'Content-Encoding' => 'gzip', 'Content-Language' => 'de', 'Content-Type' => 'text/plain;charset=utf-8',  ], [] ]
    },
);

foreach my $test ( @tests ) {

    my $resource = Plack::Util::load_class( $test->{'resource'} );

    my $request = $resource->new(
        request  => Plack::Request->new( $test->{'request'} ),
        response => Plack::Response->new
    );
    isa_ok($request, $test->{'resource'}, '... make sure we loaded the right class');
    isa_ok($request, 'Web::Machine::Resource', '... created resource (' . $test->{'resource'}. ') successfully');

    my $response;
    is(exception {
        $response = $fsm->run( $request );
    }, undef, '... ran resource (' . $test->{'resource'}. ') successfully');

    is_deeply( $response->finalize, $test->{'response'}, '... got the response for resource (' . $test->{'resource'}. ') we expected' );
}

done_testing;