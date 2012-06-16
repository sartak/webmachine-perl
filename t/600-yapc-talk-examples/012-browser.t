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
    eval "use GD::Simple;";
    if ( $@ ) {
        pass('GD::Simple is required for this test');
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
    Plack::Util::load_psgi( $dir->file('012-browser.psgi')->stringify ),
    sub {
        my $cb  = shift;

        {
            my $res = $cb->(GET "/" => ('Accept' => '*/*'));
            is($res->code, 200, '... got the expected status');
            is($res->header('Content-Type'), 'image/gif', '... got the expected Content-Type header');
            is($res->header('Content-Length'), 103, '... got the expected Content-Length header');
            ok(
                $res->content,
                '... got the expected content'
            );
        }

        {
            my $res = $cb->(GET "/" => ('Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'));
            is($res->code, 200, '... got the expected status');
            is($res->header('Content-Type'), 'text/html', '... got the expected Content-Type header');
            is($res->header('Content-Length'), 208, '... got the expected Content-Length header');
            is(
                $res->content,
                '<html><body><ul><li>1 &mdash; text/html</li><li>1 &mdash; application/xhtml+xml</li><li>0.9 &mdash; application/xml</li><li>0.8 &mdash; */*</li></ul><br/><img src="/hello_world.gif" border="1"/></body></html>',
                '... got the expected content'
            );
        }
    };

done_testing;