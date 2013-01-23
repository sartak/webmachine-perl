#!/usr/bin/perl

use strict;
use warnings;
use FindBin;

use Test::More;
use Test::Fatal;

use Plack::Test;
use Plack::Util;

use HTTP::Request::Common;
use MIME::Base64;

BEGIN {
    if (!eval { require JSON::XS; 1 }) {
        plan skip_all => "JSON::XS is required for this test";
    }
    if (!eval { require Path::Class; Path::Class->import; 1 }) {
        plan skip_all => "Path::Class is required for this test";
    }
}

my $dir = file(__FILE__)->parent->parent->parent->subdir('examples')->subdir('yapc-talk-examples');

Plack::Util::load_psgi( $dir->file('030-postback.psgi')->stringify );
Plack::Util::load_psgi( $dir->file('031-postback-w-json.psgi')->stringify );
Plack::Util::load_psgi( $dir->file('032-postback-w-auth.psgi')->stringify );

test_psgi
    Plack::Util::load_psgi( $dir->file('033-postback-w-hateoas.psgi')->stringify ),
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
            my $res = $cb->(PUT "/",
                Content_Type  => 'application/json',
                Content       => '"bar"'
            );
            is($res->code, 401, '... got the expected status');
            is($res->header('Content-Type'), 'text/plain', '... got the expected Content-Type header');
            is($res->header('WWW-Authenticate'), 'Basic realm="Webmachine"', '... got the expected WWW-Authenticate header');
            is(
                $res->content,
                'Unauthorized',
                '... got the expected content'
            );
        }

        {
            my $res = $cb->(PUT "/",
                Content_Type  => 'application/json',
                Authorization => 'Basic ' . MIME::Base64::encode_base64('foo:bar'),
                Content       => '"bar"'
            );
            is($res->code, 204, '... got the expected status');
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

        {
            my $res = $cb->(GET "/" => ('Accept' => 'application/json'));
            is($res->code, 200, '... got the expected status');
            is($res->header('Content-Type'), 'application/json', '... got the expected Content-Type header');
            is($res->header('Content-Length'), 13, '... got the expected Content-Length header');
            is($res->header('Link')->href, '/', '... got the expected Link href header');
            is($res->header('Link')->params->{'content-type'}, 'text/html', '... got the expected Link content-type param');
            is(
                $res->content,
                '["foo","bar"]',
                '... got the expected content'
            );
        }
    };

done_testing;