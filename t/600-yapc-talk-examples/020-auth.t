#!/usr/bin/perl

use strict;
use warnings;
use FindBin;

use Test::More;
use Test::Fatal;

use Plack::Test;
use Plack::Util;

use MIME::Base64;
use HTTP::Request::Common;

BEGIN {
    if (!eval { require Path::Class; Path::Class->import; 1 }) {
        plan skip_all => "Path::Class is required for this test";
    }
}

my $dir = file(__FILE__)->parent->parent->parent->subdir('examples')->subdir('yapc-talk-examples');

test_psgi
    Plack::Util::load_psgi( $dir->file('020-auth.psgi')->stringify ),
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