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
    Plack::Util::load_psgi( "$FindBin::Bin/../../examples/yapc-talk-examples/000-basic.psgi" ),
    sub {
        my $cb  = shift;
        my $res = $cb->(GET "/");
        is($res->code, 200, '... got the expected status');
        is($res->header('Content-Type'), 'text/html', '... got the expected Content-Type header');
        is($res->header('Content-Length'), 94, '... got the expected Content-Length header');
        is(
            $res->content,
            '<html><head><title>Hello World Resource</title></head><body><h1>Hello World</h1></body></html>',
            '... got the expected content'
        );
    };

done_testing;