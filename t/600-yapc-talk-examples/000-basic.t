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
        pass('JSON::XS is required for this test');
        done_testing;
        exit;
    }
    eval "use Path::Class;";
    if ( $@ ) {
        pass('Path::Class is required for this test');
        done_testing;
        exit;
    }
}

my $dir = file(__FILE__)->parent->parent->parent->subdir('examples')->subdir('yapc-talk-examples');

test_psgi
    Plack::Util::load_psgi( $dir->file('000-basic.psgi')->stringify ),
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
            my $res = $cb->(GET "/" => ('Accept' => 'image/jpeg'));
            is($res->code, 406, '... got the expected status');
            is($res->header('Content-Type'), undef, '... got the expected Content-Type header');
            is($res->header('Content-Length'), undef, '... got the expected Content-Length header');
            is(
                $res->content,
                'Not Acceptable',
                '... got the expected content'
            );
        }
    };

done_testing;