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
        diag('Path::Class is required for this test');
        done_testing;
        exit;
    }
}

my $dir = file(__FILE__)->parent->parent->parent->subdir('examples')->subdir('yapc-talk-examples');

test_psgi
    Plack::Util::load_psgi( $dir->file('110-service-unavailable.psgi')->stringify ),
    sub {
        my $cb = shift;
        my $f  = Path::Class::File->new("$FindBin::Bin/../../site_down");

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

        $f->touch;

        {
            my $res = $cb->(GET "/");
            is($res->code, 503, '... got the expected status');
            is($res->header('Content-Type'), undef, '... got the expected Content-Type header');
            is($res->header('Content-Length'), undef, '... got the expected Content-Length header');
            is(
                $res->content,
                '<html><body><h1>Service Unavailable</h1>Please come back later.</body></html>',
                '... got the expected content'
            );
        }

        $f->remove;

    };

done_testing;