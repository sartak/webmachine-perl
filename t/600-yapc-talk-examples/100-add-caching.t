#!/usr/bin/perl

use strict;
use warnings;
use FindBin;

use Test::More;
use Test::Fatal;

use Plack::Test;
use Plack::Util;

use HTTP::Request::Common;

BEGIN {
    if (!eval { require Path::Class; Path::Class->import; 1 }) {
        plan skip_all => "Path::Class is required for this test";
    }
}

my $dir = file(__FILE__)->parent->parent->parent->subdir('examples')->subdir('yapc-talk-examples');

test_psgi
    Plack::Util::load_psgi( $dir->file('100-add-caching.psgi')->stringify ),
    sub {
        my $cb  = shift;
        {
            my $res = $cb->(GET "/");
            is($res->code, 200, '... got the expected status');
            is($res->header('Content-Type'), 'text/html', '... got the expected Content-Type header');
            is($res->header('Content-Length'), 46, '... got the expected Content-Length header');
            is(
                $res->content,
                '<html><body><h1>Hello World</h1></body></html>',
                '... got the expected content'
            );
        }

        # conditional GET still returns 200
        {
            my $res = $cb->(GET "/" => (
                'If-Modified-Since' => 'Sun, 27 May 2012 21:34:59 GMT'
            ));
            is($res->code, 200, '... got the expected status');
            is($res->header('Content-Type'), 'text/html', '... got the expected Content-Type header');
            is($res->header('Content-Length'), 46, '... got the expected Content-Length header');
            is(
                $res->content,
                '<html><body><h1>Hello World</h1></body></html>',
                '... got the expected content'
            );
        }

        # conditional GET now returns 304
        {
            my $res = $cb->(GET "/" => (
                'If-Modified-Since' => 'Sun, 27 May 2012 21:35:00 GMT'
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