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
    eval "use JSON::XS;";
    if ( $@ ) {
        diag('JSON::XS is required for this test');
        done_testing;
        exit;
    }
}

test_psgi
    Plack::Util::load_psgi( "$FindBin::Bin/../../examples/yapc-talk-examples/011-browser.psgi" ),
    sub {
        my $cb  = shift;

        {
            my $res = $cb->(GET "/" => ('Accept' => '*/*'));
            is($res->code, 200, '... got the expected status');
            is($res->header('Content-Type'), 'application/json', '... got the expected Content-Type header');
            is($res->header('Content-Length'), 32, '... got the expected Content-Length header');
            is_deeply(
                JSON::XS::decode_json( $res->content ),
                [ { 1 => "*/*" } ] ,
                '... got the expected content'
            );
        }

        {
            my $res = $cb->(GET "/" => ('Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'));
            is($res->code, 200, '... got the expected status');
            is($res->header('Content-Type'), 'text/html', '... got the expected Content-Type header');
            is($res->header('Content-Length'), 163, '... got the expected Content-Length header');
            is(
                $res->content,
                '<html><body><ul><li>1 &mdash; text/html</li><li>1 &mdash; application/xhtml+xml</li><li>0.9 &mdash; application/xml</li><li>0.8 &mdash; */*</li></ul></body></html>',
                '... got the expected content'
            );
        }
    };

done_testing;