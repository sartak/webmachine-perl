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
    eval "use MIME::Base64;";
    if ( $@ ) {
        diag('MIME::Base64 is required for this test');
        done_testing;
        exit;
    }
}

test_psgi
    Plack::Util::load_psgi( "$FindBin::Bin/../../examples/yapc-talk-examples/020-auth.psgi" ),
    sub {
        my $cb  = shift;

        {
            my $res = $cb->(GET "/");
            is($res->code, 401, '... got the expected status');
            is($res->header('Content-Type'), undef, '... got the expected Content-Type header');
            is($res->header('WWW-Authenticate'), 'Basic realm="Webmachine"', '... got the expected WWW-Authenticate header');
            is(
                $res->content,
                'Unauthorized',
                '... got the expected content'
            );
        }

        {
            my $res = $cb->(GET "/" => ('Authorization' => 'Basic ' . MIME::Base64::encode_base64('foo:bar')));
            is($res->code, 200, '... got the expected status');
            is($res->header('Content-Type'), 'text/html', '... got the expected Content-Type header');
            is($res->header('Content-Length'), 46, '... got the expected Content-Length header');
            is(
                $res->content,
                '<html><body><h1>Hello World</h1></body></html>',
                '... got the expected content'
            );
        }

        {
            my $res = $cb->(GET "/" => ('Authorization' => 'Basic ' . MIME::Base64::encode_base64('foo:baz')));
            is($res->code, 401, '... got the expected status');
            is($res->header('Content-Type'), undef, '... got the expected Content-Type header');
            is($res->header('WWW-Authenticate'), 'Basic realm="Webmachine"', '... got the expected WWW-Authenticate header');
            is(
                $res->content,
                'Unauthorized',
                '... got the expected content'
            );
        }
    };

done_testing;