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
    eval "use Path::Class;";
    if ( $@ ) {
        pass('Path::Class is required for this test');
        done_testing;
        exit;
    }
}

my $dir = file(__FILE__)->parent->parent->parent->subdir('examples')->subdir('yapc-talk-examples');

test_psgi
    Plack::Util::load_psgi( $dir->file('120-bind-path.psgi')->stringify ),
    sub {
        my $cb  = shift;

        {
            my $res = $cb->(GET "/");
            is($res->code, 404, '... got the expected status');
            is($res->header('Content-Type'), 'text/html', '... got the expected Content-Type header');
            is(
                $res->content,
                'Not Found',
                '... got the expected content'
            );
        }

        {
            my $res = $cb->(GET "/edit/10");
            is($res->code, 200, '... got the expected status');
            is($res->header('Content-Type'), 'text/html', '... got the expected Content-Type header');
            is($res->header('Content-Length'), 58, '... got the expected Content-Length header');
            is(
                $res->content,
                "<html><body><h1>action('edit') id('10')</h1></body></html>",
                '... got the expected content'
            );
        }

    };

done_testing;