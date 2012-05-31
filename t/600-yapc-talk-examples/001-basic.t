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
    Plack::Util::load_psgi( "$FindBin::Bin/../../examples/yapc-talk-examples/001-basic.psgi" ),
    sub {
        my $cb  = shift;

        {
            my $res = $cb->(GET "/");
            is($res->code, 200, '... got the expected status');
            is($res->header('Content-Type'), 'application/json', '... got the expected Content-Type header');
            is($res->header('Content-Length'), 25, '... got the expected Content-Length header');
            is(
                $res->content,
                '{"message":"Hello World"}',
                '... got the expected content'
            );
        }

        {
            my $res = $cb->(GET "/" => ('Accept' => 'text/html'));
            is($res->code, 200, '... got the expected status');
            is($res->header('Content-Type'), 'text/html', '... got the expected Content-Type header');
            is($res->header('Content-Length'), 46, '... got the expected Content-Length header');
            is(
                $res->content,
                '<html><body><h1>Hello World</h1></body></html>',
                '... got the expected content'
            );
        }
    };

done_testing;