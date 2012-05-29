#!/usr/bin/perl

use strict;
use warnings;
use FindBin;

use Test::More;
use Test::Fatal;

use Plack::Test;
use Plack::Util;

use HTTP::Request::Common;

test_psgi
    Plack::Util::load_psgi( "$FindBin::Bin/../../examples/yapc-talk-examples/001-add-caching.psgi" ),
    sub {
        my $cb  = shift;
        {
            my $res = $cb->(GET "/");
            is($res->code, 200, '... got the expected status');
            is($res->header('Content-Type'), 'text/html', '... got the expected Content-Type header');
            is($res->header('Content-Length'), 94, '... got the expected Content-Length header');
            is(
                $res->content,
                '<html><head><title>Hello World Resource</title></head><body><h1>Hello World</h1></body></html>',
                '... got the expected content'
            );
        }

        # conditional GET still returns 200
        {
            my $res = $cb->(GET "/" => (
                'If-Modified-Since' => 'Sun, 27 May 2012 17:34:59 EDT'
            ));
            is($res->code, 200, '... got the expected status');
            is($res->header('Content-Type'), 'text/html', '... got the expected Content-Type header');
            is($res->header('Content-Length'), 94, '... got the expected Content-Length header');
            is(
                $res->content,
                '<html><head><title>Hello World Resource</title></head><body><h1>Hello World</h1></body></html>',
                '... got the expected content'
            );
        }

        # conditional GET now returns 304
        {
            my $res = $cb->(GET "/" => (
                'If-Modified-Since' => 'Sun, 27 May 2012 17:35:00 EDT'
            ));
            is($res->code, 304, '... got the expected status');
            is($res->header('Content-Type'), undef, '... got the expected Content-Type header');
            is($res->header('Content-Encoding'), undef, '... got the expected Content-Encoding header');
            is($res->header('Content-Language'), undef, '... got the expected Content-Language header');
            is($res->header('ETag'), '"0xDEADBEEF"', '... got the expected ETag header');
            is($res->header('Last-Modified'), 'Sun, 27 May 2012 21:35:00 GMT', '... got the expected Last-Modified header');
            is($res->content, '', '... got the expected content');
        }

    };

done_testing;