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
        request  => { REQUEST_METHOD => 'GET' },
        response => [ 503, [], [] ]
    },
    {
        resource => 'B12',
        request  => { REQUEST_METHOD => 'GET' },
        response => [ 501, [], [] ]
    },
    {
        resource => 'B11',
        request  => { REQUEST_METHOD => 'GET' },
        response => [ 414, [], [] ]
    },
    {
        resource => 'B10',
        request  => { REQUEST_METHOD => 'GET' },
        response => [ 405, [ 'Allow' => 'PUT, DELETE' ], [] ]
    },
    {
        resource => 'B9',
        request  => { REQUEST_METHOD => 'GET' },
        response => [ 400, [], [] ]
    },
    {
        resource => 'B8',
        request  => { REQUEST_METHOD => 'GET' },
        response => [ 401, [ 'WWW-Authenticate' => 'Basic realm="Test"' ], [] ]
    },
    {
        resource => 'B8b',
        request  => { REQUEST_METHOD => 'GET' },
        response => [ 500, [], [] ]
    },
    {
        resource => 'B7',
        request  => { REQUEST_METHOD => 'GET' },
        response => [ 403, [], [] ]
    },
    {
        resource => 'B6',
        request  => { REQUEST_METHOD => 'GET' },
        response => [ 501, [], [] ]
    },
    {
        resource => 'B5',
        request  => { REQUEST_METHOD => 'GET' },
        response => [ 415, [], [] ]
    },
    {
        resource => 'B4',
        request  => { REQUEST_METHOD => 'GET' },
        response => [ 413, [], [] ]
    },
    {
        resource => 'B3',
        request  => { REQUEST_METHOD => 'OPTIONS' },
        response => [ 200, [ 'X-Hello' => 'OH HAI!' ], [] ]
    },
    {
        resource => 'C4',
        request  => { REQUEST_METHOD => 'GET', HTTP_ACCEPT => 'text/html' },
        response => [ 406, [], [] ]
    },
    # ... (langauge doesn't match, but content type does)
    {
        resource => 'D5',
        request  => { REQUEST_METHOD => 'GET', HTTP_ACCEPT_LANGUAGE => 'en' },
        response => [ 406, [], [] ]
    },
    {
        resource => 'D5',
        request  => { REQUEST_METHOD => 'GET', HTTP_ACCEPT => 'text/plain', HTTP_ACCEPT_LANGUAGE => 'en' },
        response => [ 406, [], [] ] # won't have written the content type header yet
    },
    # ... (content type and language match, but charset doesn't)
    {
        resource => 'E6',
        request  => { REQUEST_METHOD => 'GET', HTTP_ACCEPT_LANGUAGE => 'en', HTTP_ACCEPT_CHARSET => 'iso-8859-5' },
        response => [ 406, [], [] ]
    },
    {
        resource => 'E6',
        request  => { REQUEST_METHOD => 'GET', HTTP_ACCEPT_LANGUAGE => 'de', HTTP_ACCEPT_CHARSET => 'iso-8859-5' },
        response => [ 406, [ 'Content-Language' => 'de' ], [] ]
    },
    {
        resource => 'E6',
        request  => { REQUEST_METHOD => 'GET', HTTP_ACCEPT => 'text/plain', HTTP_ACCEPT_LANGUAGE => 'de', HTTP_ACCEPT_CHARSET => 'iso-8859-5' },
        response => [ 406, [ 'Content-Language' => 'de' ], [] ] # won't have written the content type header yet
    },
    # ... (no encoding asked for, and no identity provided, but content-type, language and charset matches)
    {
        resource => 'F6',
        request  => { REQUEST_METHOD => 'GET', HTTP_ACCEPT => 'text/plain', HTTP_ACCEPT_LANGUAGE => 'de', HTTP_ACCEPT_CHARSET => 'utf-8' },
        response => [ 406, [ 'Content-Language' => 'de', 'Content-Type' => 'text/plain;charset=utf-8' ], [] ]
    },
    {
        resource => 'F6',
        request  => { REQUEST_METHOD => 'GET', HTTP_ACCEPT_LANGUAGE => 'de', HTTP_ACCEPT_CHARSET => 'utf-8' },
        response => [ 406, [ 'Content-Language' => 'de', 'Content-Type' => 'text/plain;charset=utf-8' ], [] ]
    },
    {
        resource => 'F6',
        request  => { REQUEST_METHOD => 'GET', HTTP_ACCEPT_LANGUAGE => 'de' },
        response => [ 406, [ 'Content-Language' => 'de', 'Content-Type' => 'text/plain' ], [] ]
    },
    {
        resource => 'F6',
        request  => { REQUEST_METHOD => 'GET' },
        response => [ 406, [ 'Content-Type' => 'text/plain' ], [] ]
    },
    # ... (same as F6, but now we are asking for an encoding)
    {
        resource => 'F7',
        request  => { REQUEST_METHOD => 'GET', HTTP_ACCEPT => 'text/plain', HTTP_ACCEPT_LANGUAGE => 'de', HTTP_ACCEPT_CHARSET => 'utf-8', HTTP_ACCEPT_ENCODING => 'gzip' },
        response => [ 406, [ 'Content-Language' => 'de', 'Content-Type' => 'text/plain;charset=utf-8' ], [] ]
    },
    {
        resource => 'F7',
        request  => { REQUEST_METHOD => 'GET', HTTP_ACCEPT_LANGUAGE => 'de', HTTP_ACCEPT_CHARSET => 'utf-8', HTTP_ACCEPT_ENCODING => 'gzip' },
        response => [ 406, [ 'Content-Language' => 'de', 'Content-Type' => 'text/plain;charset=utf-8' ], [] ]
    },
    {
        resource => 'F7',
        request  => { REQUEST_METHOD => 'GET', HTTP_ACCEPT_LANGUAGE => 'de', HTTP_ACCEPT_ENCODING => 'gzip' },
        response => [ 406, [ 'Content-Language' => 'de', 'Content-Type' => 'text/plain' ], [] ]
    },
    {
        resource => 'F7',
        request  => { REQUEST_METHOD => 'GET', HTTP_ACCEPT_ENCODING => 'gzip' },
        response => [ 406, [ 'Content-Type' => 'text/plain' ], [] ]
    },
    # ... (test out all the different variance scenarios, this really is testing G7, but H7 is the terminal node)
    {
        resource => 'H7',
        request  => { REQUEST_METHOD => 'GET', HTTP_ACCEPT => 'text/plain', HTTP_ACCEPT_LANGUAGE => 'de', HTTP_ACCEPT_CHARSET => 'utf-8', HTTP_ACCEPT_ENCODING => 'gzip', HTTP_IF_MATCH => '*' },
        response => [ 412, [ 'Vary' => 'Accept, Accept-Encoding, Accept-Charset, Accept-Language', 'Content-Encoding' => 'gzip', 'Content-Language' => 'de', 'Content-Type' => 'text/plain;charset=utf-8',  ], [] ]
    },
    {
        resource => 'H7b',
        request  => { REQUEST_METHOD => 'GET', HTTP_ACCEPT => 'text/plain', HTTP_ACCEPT_LANGUAGE => 'de', HTTP_ACCEPT_CHARSET => 'utf-8', HTTP_ACCEPT_ENCODING => 'gzip', HTTP_IF_MATCH => '*' },
        response => [ 412, [ 'Vary' => 'Accept-Encoding, Accept-Charset, Accept-Language', 'Content-Encoding' => 'gzip', 'Content-Language' => 'de', 'Content-Type' => 'text/plain;charset=utf-8',  ], [] ]
    },
    {
        resource => 'H7c',
        request  => { REQUEST_METHOD => 'GET', HTTP_ACCEPT => 'text/plain', HTTP_ACCEPT_LANGUAGE => 'de', HTTP_ACCEPT_CHARSET => 'utf-8', HTTP_ACCEPT_ENCODING => 'gzip', HTTP_IF_MATCH => '*' },
        response => [ 412, [ 'Vary' => 'Accept-Encoding, Accept-Charset', 'Content-Encoding' => 'gzip', 'Content-Language' => 'de', 'Content-Type' => 'text/plain;charset=utf-8',  ], [] ]
    },
    {
        resource => 'H7d',
        request  => { REQUEST_METHOD => 'GET', HTTP_ACCEPT => 'text/plain', HTTP_ACCEPT_LANGUAGE => 'de', HTTP_ACCEPT_CHARSET => 'utf-8', HTTP_ACCEPT_ENCODING => 'gzip', HTTP_IF_MATCH => '*' },
        response => [ 412, [ 'Vary' => 'Accept-Encoding', 'Content-Encoding' => 'gzip', 'Content-Language' => 'de', 'Content-Type' => 'text/plain;charset=utf-8',  ], [] ]
    },
    {
        resource => 'H7e',
        request  => { REQUEST_METHOD => 'GET', HTTP_ACCEPT => 'text/plain', HTTP_ACCEPT_LANGUAGE => 'de', HTTP_ACCEPT_CHARSET => 'utf-8', HTTP_ACCEPT_ENCODING => 'gzip', HTTP_IF_MATCH => '*' },
        response => [ 412, [ 'Content-Encoding' => 'gzip', 'Content-Language' => 'de', 'Content-Type' => 'text/plain;charset=utf-8',  ], [] ]
    },
    {
        resource => 'H7f',
        request  => { REQUEST_METHOD => 'GET', HTTP_ACCEPT => 'text/plain', HTTP_ACCEPT_LANGUAGE => 'de', HTTP_ACCEPT_CHARSET => 'utf-8', HTTP_ACCEPT_ENCODING => 'gzip', HTTP_IF_MATCH => '*' },
        response => [ 412, [ 'Vary' => 'Accept, Accept-Language', 'Content-Encoding' => 'gzip', 'Content-Language' => 'de', 'Content-Type' => 'text/plain;charset=utf-8',  ], [] ]
    },
    # ...
    {
        resource => 'G11',
        request  => { REQUEST_METHOD => 'GET', HTTP_IF_MATCH => '0xDEADPORK' },
        response => [ 412, [ 'Content-Encoding' => 'gzip', 'Content-Type' => 'text/plain' ], [] ]
    },
    # ... H12 via G8->H10->H11
    {
        resource => 'H12',
        request  => { REQUEST_METHOD => 'GET', HTTP_IF_UNMODIFIED_SINCE => '18 Mar 2012 15:49:00 GMT' },
        response => [ 412, [ 'Content-Encoding' => 'gzip', 'Content-Type' => 'text/plain' ], [] ]
    },
    # ... H12 via G8->G9->H10->H11
    {
        resource => 'H12',
        request  => { REQUEST_METHOD => 'GET', HTTP_IF_MATCH => '*', HTTP_IF_UNMODIFIED_SINCE => '18 Mar 2012 15:49:00 GMT' },
        response => [ 412, [ 'Content-Encoding' => 'gzip', 'Content-Type' => 'text/plain' ], [] ]
    },
    # ... H12 via G8->G9->G11->H10->H11
    {
        resource => 'H12',
        request  => { REQUEST_METHOD => 'GET', HTTP_IF_UNMODIFIED_SINCE => '18 Mar 2012 15:49:00 GMT', HTTP_IF_MATCH => '0xDEADPORK' },
        response => [ 412, [ 'Content-Encoding' => 'gzip', 'Content-Type' => 'text/plain' ], [] ]
    },
    # ... I4 via H7->I7
    {
        resource => 'I4',
        request  => { REQUEST_METHOD => 'PUT', HTTP_IF_MATCH => '0xDEADPORK' },
        response => [ 301, [ 'Location' => '/foo/bar', 'Content-Type' => 'text/plain' ], [] ]
    },
    {
        resource => 'I4b',
        request  => { REQUEST_METHOD => 'PUT', HTTP_IF_MATCH => '0xDEADPORK' },
        response => [ 500, [ 'Content-Type' => 'text/plain' ], [] ]
    },
    # ... J18 via H10->I12->I13
    {
        resource => 'J18',
        request  => { REQUEST_METHOD => 'GET', HTTP_IF_NONE_MATCH => '*'  },
        response => [ 304, [ 'Content-Encoding' => 'gzip', 'Content-Type' => 'text/plain' ], [] ]
    },
    {
        resource => 'J18',
        request  => { REQUEST_METHOD => 'HEAD', HTTP_IF_NONE_MATCH => '*'  },
        response => [ 304, [ 'Content-Encoding' => 'gzip', 'Content-Type' => 'text/plain' ], [] ]
    },
    {
        resource => 'J18',
        request  => { REQUEST_METHOD => 'PUT', HTTP_IF_NONE_MATCH => '*'  },
        response => [ 412, [ 'Content-Encoding' => 'gzip', 'Content-Type' => 'text/plain' ], [] ]
    },
    # ... J18 via H10->H11->H12->I12
    {
        resource => 'J18',
        request  => { REQUEST_METHOD => 'GET', HTTP_IF_NONE_MATCH => '*', HTTP_IF_UNMODIFIED_SINCE => '18 Mar 2012 15:49:00 GMT'  },
        response => [ 304, [ 'Content-Encoding' => 'gzip', 'Content-Type' => 'text/plain' ], [] ]
    },
    {
        resource => 'J18',
        request  => { REQUEST_METHOD => 'HEAD', HTTP_IF_NONE_MATCH => '*', HTTP_IF_UNMODIFIED_SINCE => '18 Mar 2012 15:49:00 GMT'  },
        response => [ 304, [ 'Content-Encoding' => 'gzip', 'Content-Type' => 'text/plain' ], [] ]
    },
    {
        resource => 'J18',
        request  => { REQUEST_METHOD => 'PUT', HTTP_IF_NONE_MATCH => '*', HTTP_IF_UNMODIFIED_SINCE => '18 Mar 2012 15:49:00 GMT'  },
        response => [ 412, [ 'Content-Encoding' => 'gzip', 'Content-Type' => 'text/plain' ], [] ]
    },
    # ... J18 via H10->I12->I13->K13
    {
        resource => 'J18',
        request  => { REQUEST_METHOD => 'GET', HTTP_IF_NONE_MATCH => '0xDEADBEEF'  },
        response => [ 304, [ 'Content-Encoding' => 'gzip', 'Content-Type' => 'text/plain' ], [] ]
    },
    {
        resource => 'J18',
        request  => { REQUEST_METHOD => 'HEAD', HTTP_IF_NONE_MATCH => '0xDEADBEEF'  },
        response => [ 304, [ 'Content-Encoding' => 'gzip', 'Content-Type' => 'text/plain' ], [] ]
    },
    {
        resource => 'J18',
        request  => { REQUEST_METHOD => 'PUT', HTTP_IF_NONE_MATCH => '0xDEADBEEF'  },
        response => [ 412, [ 'Content-Encoding' => 'gzip', 'Content-Type' => 'text/plain' ], [] ]
    },
    # ...
    {
        resource => 'P3',
        request  => { REQUEST_METHOD => 'PUT' },
        response => [ 409, [ 'Content-Type' => 'text/plain' ], [] ]
    },
    {
        resource => 'P3b',
        request  => { REQUEST_METHOD => 'PUT' },
        response => [ 415, [ 'Content-Type' => 'text/plain' ], [] ]
    },
    {
        resource => 'P3b',
        request  => { REQUEST_METHOD => 'PUT', CONTENT_TYPE => 'text/plain' },
        response => [ 500, [ 'Content-Type' => 'text/plain' ], [] ]
    },
    # ... K5 via H7->I7->K7
    {
        resource => 'K5',
        request  => { REQUEST_METHOD => 'GET' },
        response => [ 301, [ 'Location' => '/foo/bar', 'Content-Type' => 'text/plain' ], [] ]
    },
    {
        resource => 'K5b',
        request  => { REQUEST_METHOD => 'GET' },
        response => [ 500, [ 'Content-Type' => 'text/plain' ], [] ]
    },
    # ... L7 via H7->I7->K7
    {
        resource => 'L7',
        request  => { REQUEST_METHOD => 'GET' },
        response => [ 404, [ 'Content-Type' => 'text/plain' ], [] ]
    },
    # ... M7 via H7->I7->K7->L7
    {
        resource => 'M7',
        request  => { REQUEST_METHOD => 'POST' },
        response => [ 404, [ 'Content-Type' => 'text/plain' ], [] ]
    },
    # ... L5 via H7->I7->K7->K5
    {
        resource => 'L5',
        request  => { REQUEST_METHOD => 'GET' },
        response => [ 307, [ 'Location' => '/foo/bar', 'Content-Type' => 'text/plain' ], [] ]
    },
    {
        resource => 'L5b',
        request  => { REQUEST_METHOD => 'GET' },
        response => [ 500, [ 'Content-Type' => 'text/plain' ], [] ]
    },
    # ... M5 via H7->I7->K7->K5->L5
    {
        resource => 'M5',
        request  => { REQUEST_METHOD => 'GET' },
        response => [ 410, [ 'Content-Type' => 'text/plain' ], [] ]
    },
    # ... N5 via H7->I7->K7->K5->L5->M5
    {
        resource => 'N5',
        request  => { REQUEST_METHOD => 'POST' },
        response => [ 410, [ 'Content-Type' => 'text/plain' ], [] ]
    },
    # ... N11 via H7->I7->K7->K5->L5->M5->N5
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