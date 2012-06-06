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
    Plack::Util::load_psgi( "$FindBin::Bin/../../examples/yapc-talk-examples/120-bind-path.psgi" ),
    sub {
        my $cb  = shift;

        {
            my $res = $cb->(GET "/");
            is($res->code, 200, '... got the expected status');
            is($res->header('Content-Type'), 'text/html', '... got the expected Content-Type header');
            is($res->header('Content-Length'), 74, '... got the expected Content-Length header');
            is(
                $res->content,
                '<html><body>Please specify and controller, action and an id.</body></html>',
                '... got the expected content'
            );
        }

        {
            my $res = $cb->(GET "/user/edit/10");
            is($res->code, 200, '... got the expected status');
            is($res->header('Content-Type'), 'text/html', '... got the expected Content-Type header');
            is($res->header('Content-Length'), 97, '... got the expected Content-Length header');
            is(
                $res->content,
                "<html><body>You are performing the 'edit' action on the 'user' controller for '10'.</body></html>",
                '... got the expected content'
            );
        }

    };

done_testing;