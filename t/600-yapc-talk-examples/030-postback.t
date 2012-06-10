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
    Plack::Util::load_psgi( "$FindBin::Bin/../../examples/yapc-talk-examples/030-postback.psgi" ),
    sub {
        my $cb  = shift;

        {
            my $res = $cb->(GET "/");
            is($res->code, 200, '... got the expected status');
            is($res->header('Content-Type'), 'text/html', '... got the expected Content-Type header');
            is($res->header('Content-Length'), 126, '... got the expected Content-Length header');
            is(
                $res->content,
                '<html><body><form method="POST"><input type="text" name="message" /><input type="submit" /></form><hr/><ul></ul></body></html>',
                '... got the expected content'
            );
        }

        {
            my $res = $cb->(POST "/", [ message => 'foo' ]);
            is($res->code, 301, '... got the expected status');
            is($res->header('Location'), '/', '... got the right Location header');
        }

        {
            my $res = $cb->(GET "/");
            is($res->code, 200, '... got the expected status');
            is($res->header('Content-Type'), 'text/html', '... got the expected Content-Type header');
            is($res->header('Content-Length'), 138, '... got the expected Content-Length header');
            is(
                $res->content,
                '<html><body><form method="POST"><input type="text" name="message" /><input type="submit" /></form><hr/><ul><li>foo</li></ul></body></html>',
                '... got the expected content'
            );
        }

        {
            my $res = $cb->(POST "/", Content_Type => 'application/json', Content => '"bar"');
            is($res->code, 301, '... got the expected status');
            is($res->header('Location'), '/', '... got the right Location header');
        }

        {
            my $res = $cb->(GET "/");
            is($res->code, 200, '... got the expected status');
            is($res->header('Content-Type'), 'text/html', '... got the expected Content-Type header');
            is($res->header('Content-Length'), 150, '... got the expected Content-Length header');
            is(
                $res->content,
                '<html><body><form method="POST"><input type="text" name="message" /><input type="submit" /></form><hr/><ul><li>foo</li><li>bar</li></ul></body></html>',
                '... got the expected content'
            );
        }
    };

done_testing;