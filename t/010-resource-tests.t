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

my $fsm = Web::Machine::FSM->new( tracing => 1 );
isa_ok( $fsm, 'Web::Machine::FSM' );

my @tests = (
    {
        resource => 'B13',
        request  => { REQUEST_METHOD => 'GET' },
        response => [ 503, [], [] ],
        trace    => 'b13'
    },
    {
        resource => 'B12',
        request  => { REQUEST_METHOD => 'GET' },
        response => [ 501, [], [] ],
        trace    => 'b13,b12'
    },
    {
        resource => 'B11',
        request  => { REQUEST_METHOD => 'GET' },
        response => [ 414, [], [] ],
        trace    => 'b13,b12,b11'
    },
    {
        resource => 'B10',
        request  => { REQUEST_METHOD => 'GET' },
        response => [ 405, [ 'Allow' => 'PUT, DELETE' ], [] ],
        trace    => 'b13,b12,b11,b10'
    },
    {
        resource => 'B9',
        request  => { REQUEST_METHOD => 'GET' },
        response => [ 400, [], [] ],
        trace    => 'b13,b12,b11,b10,b9'
    },
    {
        resource => 'B8',
        request  => { REQUEST_METHOD => 'GET' },
        response => [ 401, [ 'WWW-Authenticate' => 'Basic realm="Test"' ], [] ],
        trace    => 'b13,b12,b11,b10,b9,b8'
    },
    {
        resource => 'B8b',
        request  => { REQUEST_METHOD => 'GET' },
        response => [ 500, [], [] ],
        trace    => 'b13,b12,b11,b10,b9,b8'
    },
    {
        resource => 'B7',
        request  => { REQUEST_METHOD => 'GET' },
        response => [ 403, [], [] ],
        trace    => 'b13,b12,b11,b10,b9,b8,b7'
    },
    {
        resource => 'B6',
        request  => { REQUEST_METHOD => 'GET' },
        response => [ 501, [], [] ],
        trace    => 'b13,b12,b11,b10,b9,b8,b7,b6'
    },
    {
        resource => 'B5',
        request  => { REQUEST_METHOD => 'GET' },
        response => [ 415, [], [] ],
        trace    => 'b13,b12,b11,b10,b9,b8,b7,b6,b5'
    },
    {
        resource => 'B4',
        request  => { REQUEST_METHOD => 'GET' },
        response => [ 413, [], [] ],
        trace    => 'b13,b12,b11,b10,b9,b8,b7,b6,b5,b4'
    },
    {
        resource => 'B3',
        request  => { REQUEST_METHOD => 'OPTIONS' },
        response => [ 200, [ 'X-Hello' => 'OH HAI!' ], [] ],
        trace    => 'b13,b12,b11,b10,b9,b8,b7,b6,b5,b4,b3'
    },
    {
        resource => 'C4',
        request  => { REQUEST_METHOD => 'GET', HTTP_ACCEPT => 'text/html' },
        response => [ 406, [], [] ],
        trace    => 'b13,b12,b11,b10,b9,b8,b7,b6,b5,b4,b3,c3,c4'
    },
    # ... (langauge doesn't match, but content type does)
    {
        resource => 'D5',
        request  => { REQUEST_METHOD => 'GET', HTTP_ACCEPT_LANGUAGE => 'en' },
        response => [ 406, [], [] ],
        trace    => 'b13,b12,b11,b10,b9,b8,b7,b6,b5,b4,b3,c3,d4,d5'
    },
    {
        resource => 'D5',
        request  => { REQUEST_METHOD => 'GET', HTTP_ACCEPT => 'text/plain', HTTP_ACCEPT_LANGUAGE => 'en' },
        response => [ 406, [], [] ], # won't have written the content type header yet
        trace    => 'b13,b12,b11,b10,b9,b8,b7,b6,b5,b4,b3,c3,c4,d4,d5'
    },
    # ... (content type and language match, but charset doesn't)
    {
        resource => 'E6',
        request  => { REQUEST_METHOD => 'GET', HTTP_ACCEPT_LANGUAGE => 'de', HTTP_ACCEPT_CHARSET => 'iso-8859-5' },
        response => [ 406, [ 'Content-Language' => 'de' ], [] ],
        trace    => 'b13,b12,b11,b10,b9,b8,b7,b6,b5,b4,b3,c3,d4,d5,e5,e6'
    },
    {
        resource => 'E6',
        request  => { REQUEST_METHOD => 'GET', HTTP_ACCEPT_LANGUAGE => 'de', HTTP_ACCEPT_CHARSET => 'iso-8859-5' },
        response => [ 406, [ 'Content-Language' => 'de' ], [] ],
        trace    => 'b13,b12,b11,b10,b9,b8,b7,b6,b5,b4,b3,c3,d4,d5,e5,e6'
    },
    {
        resource => 'E6',
        request  => { REQUEST_METHOD => 'GET', HTTP_ACCEPT => 'text/plain', HTTP_ACCEPT_LANGUAGE => 'de', HTTP_ACCEPT_CHARSET => 'iso-8859-5' },
        response => [ 406, [ 'Content-Language' => 'de' ], [] ], # won't have written the content type header yet
        trace    => 'b13,b12,b11,b10,b9,b8,b7,b6,b5,b4,b3,c3,c4,d4,d5,e5,e6'
    },
    # ... (no encoding asked for, and no identity provided, but content-type, language and charset matches)
    {
        resource => 'F6',
        request  => { REQUEST_METHOD => 'GET', HTTP_ACCEPT => 'text/plain', HTTP_ACCEPT_LANGUAGE => 'de', HTTP_ACCEPT_CHARSET => 'utf-8' },
        response => [ 406, [ 'Content-Language' => 'de', 'Content-Type' => 'text/plain;charset=utf-8' ], [] ],
        trace    => 'b13,b12,b11,b10,b9,b8,b7,b6,b5,b4,b3,c3,c4,d4,d5,e5,e6,f6'
    },
    {
        resource => 'F6',
        request  => { REQUEST_METHOD => 'GET', HTTP_ACCEPT_LANGUAGE => 'de', HTTP_ACCEPT_CHARSET => 'utf-8' },
        response => [ 406, [ 'Content-Language' => 'de', 'Content-Type' => 'text/plain;charset=utf-8' ], [] ],
        trace    => 'b13,b12,b11,b10,b9,b8,b7,b6,b5,b4,b3,c3,d4,d5,e5,e6,f6'
    },
    {
        resource => 'F6',
        request  => { REQUEST_METHOD => 'GET', HTTP_ACCEPT_LANGUAGE => 'de' },
        response => [ 406, [ 'Content-Language' => 'de', 'Content-Type' => 'text/plain' ], [] ],
        trace    => 'b13,b12,b11,b10,b9,b8,b7,b6,b5,b4,b3,c3,d4,d5,e5,f6'
    },
    {
        resource => 'F6',
        request  => { REQUEST_METHOD => 'GET' },
        response => [ 406, [ 'Content-Type' => 'text/plain' ], [] ],
        trace    => 'b13,b12,b11,b10,b9,b8,b7,b6,b5,b4,b3,c3,d4,e5,f6'
    },
    # ... (same as F6, but now we are asking for an encoding)
    {
        resource => 'F7',
        request  => { REQUEST_METHOD => 'GET', HTTP_ACCEPT => 'text/plain', HTTP_ACCEPT_LANGUAGE => 'de', HTTP_ACCEPT_CHARSET => 'utf-8', HTTP_ACCEPT_ENCODING => 'gzip' },
        response => [ 406, [ 'Content-Language' => 'de', 'Content-Type' => 'text/plain;charset=utf-8' ], [] ],
        trace    => 'b13,b12,b11,b10,b9,b8,b7,b6,b5,b4,b3,c3,c4,d4,d5,e5,e6,f6,f7'
    },
    {
        resource => 'F7',
        request  => { REQUEST_METHOD => 'GET', HTTP_ACCEPT_LANGUAGE => 'de', HTTP_ACCEPT_CHARSET => 'utf-8', HTTP_ACCEPT_ENCODING => 'gzip' },
        response => [ 406, [ 'Content-Language' => 'de', 'Content-Type' => 'text/plain;charset=utf-8' ], [] ],
        trace    => 'b13,b12,b11,b10,b9,b8,b7,b6,b5,b4,b3,c3,d4,d5,e5,e6,f6,f7'
    },
    {
        resource => 'F7',
        request  => { REQUEST_METHOD => 'GET', HTTP_ACCEPT_LANGUAGE => 'de', HTTP_ACCEPT_ENCODING => 'gzip' },
        response => [ 406, [ 'Content-Language' => 'de', 'Content-Type' => 'text/plain' ], [] ],
        trace    => 'b13,b12,b11,b10,b9,b8,b7,b6,b5,b4,b3,c3,d4,d5,e5,f6,f7'
    },
    {
        resource => 'F7',
        request  => { REQUEST_METHOD => 'GET', HTTP_ACCEPT_ENCODING => 'gzip' },
        response => [ 406, [ 'Content-Type' => 'text/plain' ], [] ],
        trace    => 'b13,b12,b11,b10,b9,b8,b7,b6,b5,b4,b3,c3,d4,e5,f6,f7'
    },
    # ... (test out all the different variance scenarios, this really is testing G7, but H7 is the terminal node)
    {
        resource => 'H7',
        request  => { REQUEST_METHOD => 'GET', HTTP_ACCEPT => 'text/plain', HTTP_ACCEPT_LANGUAGE => 'de', HTTP_ACCEPT_CHARSET => 'utf-8', HTTP_ACCEPT_ENCODING => 'gzip', HTTP_IF_MATCH => '*' },
        response => [ 412, [ 'Vary' => 'Accept, Accept-Encoding, Accept-Charset, Accept-Language', 'Content-Encoding' => 'gzip', 'Content-Language' => 'de', 'Content-Type' => 'text/plain;charset=utf-8',  ], [] ],
        trace    => 'b13,b12,b11,b10,b9,b8,b7,b6,b5,b4,b3,c3,c4,d4,d5,e5,e6,f6,f7,g7,h7'
    },
    {
        resource => 'H7b',
        request  => { REQUEST_METHOD => 'GET', HTTP_ACCEPT => 'text/plain', HTTP_ACCEPT_LANGUAGE => 'de', HTTP_ACCEPT_CHARSET => 'utf-8', HTTP_ACCEPT_ENCODING => 'gzip', HTTP_IF_MATCH => '*' },
        response => [ 412, [ 'Vary' => 'Accept-Encoding, Accept-Charset, Accept-Language', 'Content-Encoding' => 'gzip', 'Content-Language' => 'de', 'Content-Type' => 'text/plain;charset=utf-8',  ], [] ],
        trace    => 'b13,b12,b11,b10,b9,b8,b7,b6,b5,b4,b3,c3,c4,d4,d5,e5,e6,f6,f7,g7,h7'
    },
    {
        resource => 'H7c',
        request  => { REQUEST_METHOD => 'GET', HTTP_ACCEPT => 'text/plain', HTTP_ACCEPT_LANGUAGE => 'de', HTTP_ACCEPT_CHARSET => 'utf-8', HTTP_ACCEPT_ENCODING => 'gzip', HTTP_IF_MATCH => '*' },
        response => [ 412, [ 'Vary' => 'Accept-Encoding, Accept-Charset', 'Content-Encoding' => 'gzip', 'Content-Language' => 'de', 'Content-Type' => 'text/plain;charset=utf-8',  ], [] ],
        trace    => 'b13,b12,b11,b10,b9,b8,b7,b6,b5,b4,b3,c3,c4,d4,d5,e5,e6,f6,f7,g7,h7'
    },
    {
        resource => 'H7d',
        request  => { REQUEST_METHOD => 'GET', HTTP_ACCEPT => 'text/plain', HTTP_ACCEPT_LANGUAGE => 'de', HTTP_ACCEPT_CHARSET => 'utf-8', HTTP_ACCEPT_ENCODING => 'gzip', HTTP_IF_MATCH => '*' },
        response => [ 412, [ 'Vary' => 'Accept-Encoding', 'Content-Encoding' => 'gzip', 'Content-Language' => 'de', 'Content-Type' => 'text/plain;charset=utf-8',  ], [] ],
        trace    => 'b13,b12,b11,b10,b9,b8,b7,b6,b5,b4,b3,c3,c4,d4,d5,e5,e6,f6,f7,g7,h7'
    },
    {
        resource => 'H7e',
        request  => { REQUEST_METHOD => 'GET', HTTP_ACCEPT => 'text/plain', HTTP_ACCEPT_LANGUAGE => 'de', HTTP_ACCEPT_CHARSET => 'utf-8', HTTP_ACCEPT_ENCODING => 'gzip', HTTP_IF_MATCH => '*' },
        response => [ 412, [ 'Content-Encoding' => 'gzip', 'Content-Language' => 'de', 'Content-Type' => 'text/plain;charset=utf-8',  ], [] ],
        trace    => 'b13,b12,b11,b10,b9,b8,b7,b6,b5,b4,b3,c3,c4,d4,d5,e5,e6,f6,f7,g7,h7'
    },
    {
        resource => 'H7f',
        request  => { REQUEST_METHOD => 'GET', HTTP_ACCEPT => 'text/plain', HTTP_ACCEPT_LANGUAGE => 'de', HTTP_ACCEPT_CHARSET => 'utf-8', HTTP_ACCEPT_ENCODING => 'gzip', HTTP_IF_MATCH => '*' },
        response => [ 412, [ 'Vary' => 'Accept, Accept-Language', 'Content-Encoding' => 'gzip', 'Content-Language' => 'de', 'Content-Type' => 'text/plain;charset=utf-8',  ], [] ],
        trace    => 'b13,b12,b11,b10,b9,b8,b7,b6,b5,b4,b3,c3,c4,d4,d5,e5,e6,f6,f7,g7,h7'
    },
    # ...
    {
        resource => 'G11',
        request  => { REQUEST_METHOD => 'GET', HTTP_IF_MATCH => '0xDEADPORK' },
        response => [ 412, [ 'Content-Encoding' => 'gzip', 'Content-Type' => 'text/plain' ], [] ],
        trace    => 'b13,b12,b11,b10,b9,b8,b7,b6,b5,b4,b3,c3,d4,e5,f6,g7,g8,g9,g11'
    },
    # ... H12 via G8->H10->H11
    {
        resource => 'H12',
        request  => { REQUEST_METHOD => 'GET', HTTP_IF_UNMODIFIED_SINCE => '18 Mar 2012 15:49:00 GMT' },
        response => [ 412, [ 'Content-Encoding' => 'gzip', 'Content-Type' => 'text/plain' ], [] ],
        trace    => 'b13,b12,b11,b10,b9,b8,b7,b6,b5,b4,b3,c3,d4,e5,f6,g7,g8,h10,h11,h12'
    },
    # ... H12 via G8->G9->H10->H11
    {
        resource => 'H12',
        request  => { REQUEST_METHOD => 'GET', HTTP_IF_MATCH => '*', HTTP_IF_UNMODIFIED_SINCE => '18 Mar 2012 15:49:00 GMT' },
        response => [ 412, [ 'Content-Encoding' => 'gzip', 'Content-Type' => 'text/plain' ], [] ],
        trace    => 'b13,b12,b11,b10,b9,b8,b7,b6,b5,b4,b3,c3,d4,e5,f6,g7,g8,g9,h10,h11,h12'
    },
    # ... H12 via G8->G9->G11->H10->H11
    {
        resource => 'H12',
        request  => { REQUEST_METHOD => 'GET', HTTP_IF_UNMODIFIED_SINCE => '18 Mar 2012 15:49:00 GMT', HTTP_IF_MATCH => '0xDEADBEEF' },
        response => [ 412, [ 'Content-Encoding' => 'gzip', 'Content-Type' => 'text/plain' ], [] ],
        trace    => 'b13,b12,b11,b10,b9,b8,b7,b6,b5,b4,b3,c3,d4,e5,f6,g7,g8,g9,g11,h10,h11,h12'
    },
    # ... I4 via H7->I7
    {
        resource => 'I4',
        request  => { REQUEST_METHOD => 'PUT', HTTP_IF_MATCH => '0xDEADPORK' },
        response => [ 301, [ 'Location' => '/foo/bar', 'Content-Type' => 'text/plain' ], [] ],
        trace    => 'b13,b12,b11,b10,b9,b8,b7,b6,b5,b4,b3,c3,d4,e5,f6,g7,h7,i7,i4'
    },
    {
        resource => 'I4b',
        request  => { REQUEST_METHOD => 'PUT', HTTP_IF_MATCH => '0xDEADPORK' },
        response => [ 500, [ 'Content-Type' => 'text/plain' ], [] ],
        trace    => 'b13,b12,b11,b10,b9,b8,b7,b6,b5,b4,b3,c3,d4,e5,f6,g7,h7,i7,i4'
    },
    # ... J18 via H10->I12->I13
    {
        resource => 'J18',
        request  => { REQUEST_METHOD => 'GET', HTTP_IF_NONE_MATCH => '*'  },
        response => [ 304, [ 'Content-Encoding' => 'gzip', 'Content-Type' => 'text/plain' ], [] ],
        trace    => 'b13,b12,b11,b10,b9,b8,b7,b6,b5,b4,b3,c3,d4,e5,f6,g7,g8,h10,i12,i13,j18'
    },
    {
        resource => 'J18',
        request  => { REQUEST_METHOD => 'HEAD', HTTP_IF_NONE_MATCH => '*'  },
        response => [ 304, [ 'Content-Encoding' => 'gzip', 'Content-Type' => 'text/plain' ], [] ],
        trace    => 'b13,b12,b11,b10,b9,b8,b7,b6,b5,b4,b3,c3,d4,e5,f6,g7,g8,h10,i12,i13,j18'
    },
    {
        resource => 'J18',
        request  => { REQUEST_METHOD => 'PUT', HTTP_IF_NONE_MATCH => '*'  },
        response => [ 412, [ 'Content-Encoding' => 'gzip', 'Content-Type' => 'text/plain' ], [] ],
        trace    => 'b13,b12,b11,b10,b9,b8,b7,b6,b5,b4,b3,c3,d4,e5,f6,g7,g8,h10,i12,i13,j18'
    },
    # ... J18 via H10->H11->H12->I12->I13
    {
        resource => 'J18',
        request  => { REQUEST_METHOD => 'GET', HTTP_IF_NONE_MATCH => '*', HTTP_IF_UNMODIFIED_SINCE => '18 Mar 2012 15:49:00 GMT'  },
        response => [ 304, [ 'Content-Encoding' => 'gzip', 'Content-Type' => 'text/plain' ], [] ],
        trace    => 'b13,b12,b11,b10,b9,b8,b7,b6,b5,b4,b3,c3,d4,e5,f6,g7,g8,h10,h11,h12,i12,i13,j18'
    },
    {
        resource => 'J18',
        request  => { REQUEST_METHOD => 'HEAD', HTTP_IF_NONE_MATCH => '*', HTTP_IF_UNMODIFIED_SINCE => '18 Mar 2012 15:49:00 GMT'  },
        response => [ 304, [ 'Content-Encoding' => 'gzip', 'Content-Type' => 'text/plain' ], [] ],
        trace    => 'b13,b12,b11,b10,b9,b8,b7,b6,b5,b4,b3,c3,d4,e5,f6,g7,g8,h10,h11,h12,i12,i13,j18'
    },
    {
        resource => 'J18',
        request  => { REQUEST_METHOD => 'PUT', HTTP_IF_NONE_MATCH => '*', HTTP_IF_UNMODIFIED_SINCE => '18 Mar 2012 15:49:00 GMT'  },
        response => [ 412, [ 'Content-Encoding' => 'gzip', 'Content-Type' => 'text/plain' ], [] ],
        trace    => 'b13,b12,b11,b10,b9,b8,b7,b6,b5,b4,b3,c3,d4,e5,f6,g7,g8,h10,h11,h12,i12,i13,j18'
    },
    # ... J18 via H10->I12->I13->K13
    {
        resource => 'J18',
        request  => { REQUEST_METHOD => 'GET', HTTP_IF_NONE_MATCH => '0xDEADBEEF'  },
        response => [ 304, [ 'Content-Encoding' => 'gzip', 'Content-Type' => 'text/plain' ], [] ],
        trace    => 'b13,b12,b11,b10,b9,b8,b7,b6,b5,b4,b3,c3,d4,e5,f6,g7,g8,h10,i12,i13,k13,j18'
    },
    {
        resource => 'J18',
        request  => { REQUEST_METHOD => 'HEAD', HTTP_IF_NONE_MATCH => '0xDEADBEEF'  },
        response => [ 304, [ 'Content-Encoding' => 'gzip', 'Content-Type' => 'text/plain' ], [] ],
        trace    => 'b13,b12,b11,b10,b9,b8,b7,b6,b5,b4,b3,c3,d4,e5,f6,g7,g8,h10,i12,i13,k13,j18'
    },
    {
        resource => 'J18',
        request  => { REQUEST_METHOD => 'PUT', HTTP_IF_NONE_MATCH => '0xDEADBEEF'  },
        response => [ 412, [ 'Content-Encoding' => 'gzip', 'Content-Type' => 'text/plain' ], [] ],
        trace    => 'b13,b12,b11,b10,b9,b8,b7,b6,b5,b4,b3,c3,d4,e5,f6,g7,g8,h10,i12,i13,k13,j18'
    },
    # ...
    {
        resource => 'P3',
        request  => { REQUEST_METHOD => 'PUT' },
        response => [ 409, [ 'Content-Type' => 'text/plain' ], [] ],
        trace    => 'b13,b12,b11,b10,b9,b8,b7,b6,b5,b4,b3,c3,d4,e5,f6,g7,h7,i7,i4,p3'
    },
    {
        resource => 'P3b',
        request  => { REQUEST_METHOD => 'PUT' },
        response => [ 415, [ 'Content-Type' => 'text/plain' ], [] ],
        trace    => 'b13,b12,b11,b10,b9,b8,b7,b6,b5,b4,b3,c3,d4,e5,f6,g7,h7,i7,i4,p3'
    },
    {
        resource => 'P3b',
        request  => { REQUEST_METHOD => 'PUT', CONTENT_TYPE => 'text/plain' },
        response => [ 500, [ 'Content-Type' => 'text/plain' ], [] ],
        trace    => 'b13,b12,b11,b10,b9,b8,b7,b6,b5,b4,b3,c3,d4,e5,f6,g7,h7,i7,i4,p3'
    },
    # ... K5 via H7->I7->K7
    {
        resource => 'K5',
        request  => { REQUEST_METHOD => 'GET' },
        response => [ 301, [ 'Location' => '/foo/bar', 'Content-Type' => 'text/plain' ], [] ],
        trace    => 'b13,b12,b11,b10,b9,b8,b7,b6,b5,b4,b3,c3,d4,e5,f6,g7,h7,i7,k7,k5'
    },
    {
        resource => 'K5b',
        request  => { REQUEST_METHOD => 'GET' },
        response => [ 500, [ 'Content-Type' => 'text/plain' ], [] ],
        trace    => 'b13,b12,b11,b10,b9,b8,b7,b6,b5,b4,b3,c3,d4,e5,f6,g7,h7,i7,k7,k5'
    },
    # ... L7 via H7->I7->K7
    {
        resource => 'L7',
        request  => { REQUEST_METHOD => 'GET' },
        response => [ 404, [ 'Content-Type' => 'text/plain' ], [] ],
        trace    => 'b13,b12,b11,b10,b9,b8,b7,b6,b5,b4,b3,c3,d4,e5,f6,g7,h7,i7,k7,l7'
    },
    # ... M7 via H7->I7->K7->L7
    {
        resource => 'M7',
        request  => { REQUEST_METHOD => 'POST' },
        response => [ 404, [ 'Content-Type' => 'text/plain' ], [] ],
        trace    => 'b13,b12,b11,b10,b9,b8,b7,b6,b5,b4,b3,c3,d4,e5,f6,g7,h7,i7,k7,l7,m7'
    },
    # ... L5 via H7->I7->K7->K5
    {
        resource => 'L5',
        request  => { REQUEST_METHOD => 'GET' },
        response => [ 307, [ 'Location' => '/foo/bar', 'Content-Type' => 'text/plain' ], [] ],
        trace    => 'b13,b12,b11,b10,b9,b8,b7,b6,b5,b4,b3,c3,d4,e5,f6,g7,h7,i7,k7,k5,l5'
    },
    {
        resource => 'L5b',
        request  => { REQUEST_METHOD => 'GET' },
        response => [ 500, [ 'Content-Type' => 'text/plain' ], [] ],
        trace    => 'b13,b12,b11,b10,b9,b8,b7,b6,b5,b4,b3,c3,d4,e5,f6,g7,h7,i7,k7,k5,l5'
    },
    # ... M5 via H7->I7->K7->K5->L5
    {
        resource => 'M5',
        request  => { REQUEST_METHOD => 'GET' },
        response => [ 410, [ 'Content-Type' => 'text/plain' ], [] ],
        trace    => 'b13,b12,b11,b10,b9,b8,b7,b6,b5,b4,b3,c3,d4,e5,f6,g7,h7,i7,k7,k5,l5,m5'
    },
    # ... N5 via H7->I7->K7->K5->L5->M5
    {
        resource => 'N5',
        request  => { REQUEST_METHOD => 'POST' },
        response => [ 410, [ 'Content-Type' => 'text/plain' ], [] ],
        trace    => 'b13,b12,b11,b10,b9,b8,b7,b6,b5,b4,b3,c3,d4,e5,f6,g7,h7,i7,k7,k5,l5,m5,n5'
    },
    # send a content type we dont handle
    {
        resource => 'N11',
        request  => { REQUEST_METHOD => 'POST', SCRIPT_NAME => '/bar', CONTENT_TYPE => 'text/plain' },
        response => [ 415, [ 'Location' => '/bar/foo', 'Content-Type' => 'text/plain' ], [] ],
        trace    => 'b13,b12,b11,b10,b9,b8,b7,b6,b5,b4,b3,c3,d4,e5,f6,g7,h7,i7,k7,k5,l5,m5,n5,n11'
    },
    # ...
    {
        resource => 'N11b',
        request  => { REQUEST_METHOD => 'POST' },
        response => [ 500, [ 'Location' => '/baz/bar/foo', 'Content-Type' => 'text/plain' ], [] ],
        trace    => 'b13,b12,b11,b10,b9,b8,b7,b6,b5,b4,b3,c3,d4,e5,f6,g7,h7,i7,k7,k5,l5,m5,n5,n11'
    },
    # ...
    {
        resource => 'N11c',
        request  => { REQUEST_METHOD => 'POST' },
        response => [ 500, [ 'Content-Type' => 'text/plain' ], [] ],
        trace    => 'b13,b12,b11,b10,b9,b8,b7,b6,b5,b4,b3,c3,d4,e5,f6,g7,h7,i7,k7,k5,l5,m5,n5,n11'
    },
    # ...
    {
        resource => 'N11d',
        request  => { REQUEST_METHOD => 'POST' },
        response => qr/^Process Post Invalid/,
        trace    => 'b13,b12,b11,b10,b9,b8,b7,b6,b5,b4,b3,c3,d4,e5,f6,g7,h7,i7,k7,k5,l5,m5,n5,n11'
    },
    # ...
    {
        resource => 'N11e',
        request  => { REQUEST_METHOD => 'POST' },
        response => qr/^Create Path Nil/,
        trace    => 'b13,b12,b11,b10,b9,b8,b7,b6,b5,b4,b3,c3,d4,e5,f6,g7,h7,i7,k7,k5,l5,m5,n5,n11'
    },
    # ... P11 via H7->I7->K7->K5->L5->M5->N5->N11
    {
        resource => 'P11',
        request  => { REQUEST_METHOD => 'POST' },
        response => [ 201, [ 'Location' => '/foo', 'Content-Type' => 'text/plain' ], [] ],
        trace    => 'b13,b12,b11,b10,b9,b8,b7,b6,b5,b4,b3,c3,d4,e5,f6,g7,h7,i7,k7,k5,l5,m5,n5,n11,p11'
    },
    # add a base to the request
    {
        resource => 'P11',
        request  => { REQUEST_METHOD => 'POST', SCRIPT_NAME => '/bar' },
        response => [ 201, [ 'Location' => '/bar/foo', 'Content-Type' => 'text/plain' ], [] ],
        trace    => 'b13,b12,b11,b10,b9,b8,b7,b6,b5,b4,b3,c3,d4,e5,f6,g7,h7,i7,k7,k5,l5,m5,n5,n11,p11'
    },
    # ...
    {
        resource => 'P11b',
        request  => { REQUEST_METHOD => 'POST' },
        response => [ 201, [ 'Location' => '/baz/bar/foo', 'Content-Type' => 'text/plain' ], [] ],
        trace    => 'b13,b12,b11,b10,b9,b8,b7,b6,b5,b4,b3,c3,d4,e5,f6,g7,h7,i7,k7,k5,l5,m5,n5,n11,p11'
    },
    # ...
    {
        resource => 'P11c',
        request  => { REQUEST_METHOD => 'POST' },
        response => [ 201, [ 'Location' => '/foo/bar/baz', 'Content-Type' => 'text/plain' ], [] ],
        trace    => 'b13,b12,b11,b10,b9,b8,b7,b6,b5,b4,b3,c3,d4,e5,f6,g7,h7,i7,k7,k5,l5,m5,n5,n11,p11'
    },
    # O18 via N11
    {
        resource => 'O18',
        request  => { REQUEST_METHOD => 'POST' },
        response => [ 200, [ 'Content-Length' => 11, 'Content-Type' => 'text/plain' ], [ 'HELLO WORLD' ] ],
        trace    => 'b13,b12,b11,b10,b9,b8,b7,b6,b5,b4,b3,c3,d4,e5,f6,g7,h7,i7,k7,k5,l5,m5,n5,n11,p11,o20,o18,o18b'
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
    isa_ok($response, 'Plack::Response');

    my $trace = $response->header( $fsm->tracing_header );
    is( $trace, $test->{'trace'}, '... got the trace we expected' );
    $response->headers->remove_header( $fsm->tracing_header );

    my $finalized = $response->finalize;
    if ( ref $test->{'response'} eq 'ARRAY' ) {
        is_deeply( $finalized, $test->{'response'}, '... got the response for resource (' . $test->{'resource'}. ') we expected' );
    }
    else {
        is( $finalized->[0], 500, '... got the error status for resource (' . $test->{'resource'}. ') we expected' );
        like( $finalized->[2]->[0], $test->{'response'}, '... got the error response for resource (' . $test->{'resource'}. ') we expected' );
    }


}

done_testing;