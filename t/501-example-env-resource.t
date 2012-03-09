#!/usr/bin/perl

use strict;
use warnings;
use FindBin;

use Test::More;
use Test::Fatal;

use Plack::Test;
use Plack::Util;

use HTTP::Request::Common qw[ GET HEAD PUT POST DELETE ];

BEGIN {
    eval "use JSON::XS;";
    if ( $@ ) {
        diag('JSON::XS is required for this test');
        done_testing;
        exit;
    }
}

test_psgi
    Plack::Util::load_psgi( "$FindBin::Bin/../examples/env-resource/app.psgi" ),
    sub {
        my $cb   = shift;
        my $JSON = JSON::XS->new->allow_nonref;

        # NOTE:
        # we won't test Content-Length in here
        # because that will change based on the
        # contents of ENV, which are not static.
        # - SL

        {
            my $res = $cb->(GET "/");
            is($res->code, 200, '... got the expected status');
            is($res->header('Content-Type'), 'application/json', '... got the expected Content-Type header');
            is_deeply(
                $JSON->decode( $res->content ),
                \%ENV,
                '... got the expected content'
            );
        }

        # test affecting the ENV

        {
            my $res = $cb->(GET "/WEB_MACHINE_TESTING");
            is($res->code, 404, '... got the expected status');
            is($res->header('Content-Type'), 'application/json', '... got the expected Content-Type header');
            is($res->content, '', '... got the expected content');
        }

        $ENV{'WEB_MACHINE_TESTING'} = __FILE__;

        {
            my $res = $cb->(GET "/WEB_MACHINE_TESTING");
            is($res->code, 200, '... got the expected status');
            is($res->header('Content-Type'), 'application/json', '... got the expected Content-Type header');
            is_deeply(
                $JSON->decode( $res->content ),
                __FILE__,
                '... got the expected content'
            );
        }

        {
            my $res = $cb->(DELETE "/WEB_MACHINE_TESTING");
            is($res->code, 204, '... got the expected status');
            is($res->header('Content-Type'), 'application/json', '... got the expected Content-Type header');
            is($res->content, '', '... got the expected content');
        }

        {
            my $res = $cb->(GET "/WEB_MACHINE_TESTING");
            is($res->code, 404, '... got the expected status');
            is($res->header('Content-Type'), 'application/json', '... got the expected Content-Type header');
            is($res->content, '', '... got the expected content');
        }

        # now through the web-service

        {
            my $res = $cb->(GET "/WEB_MACHINE_AUTOMATED_TESTING");
            is($res->code, 404, '... got the expected status');
            is($res->header('Content-Type'), 'application/json', '... got the expected Content-Type header');
            is($res->content, '', '... got the expected content');
        }

        {
            my $res = $cb->(PUT "/WEB_MACHINE_AUTOMATED_TESTING", (
                'Content-Type' => 'application/json', 'Content' => '"FOOBAR"'
            ));
            is($res->code, 204, '... got the expected status');
            is($res->header('Content-Type'), 'application/json', '... got the expected Content-Type header');
            is($res->content, '', '... got the expected content');
        }

        ok(exists $ENV{'WEB_MACHINE_AUTOMATED_TESTING'}, '... the variable exists now');
        is($ENV{'WEB_MACHINE_AUTOMATED_TESTING'}, 'FOOBAR', '... the variable has the value we want');

        {
            my $res = $cb->(GET "/WEB_MACHINE_AUTOMATED_TESTING");
            is($res->code, 200, '... got the expected status');
            is($res->header('Content-Type'), 'application/json', '... got the expected Content-Type header');
            is_deeply(
                $JSON->decode( $res->content ),
                "FOOBAR",
                '... got the expected content'
            );
        }

        {
            my $res = $cb->(DELETE "/WEB_MACHINE_AUTOMATED_TESTING");
            is($res->code, 204, '... got the expected status');
            is($res->header('Content-Type'), 'application/json', '... got the expected Content-Type header');
            is($res->content, '', '... got the expected content');
        }

        {
            my $res = $cb->(GET "/WEB_MACHINE_AUTOMATED_TESTING");
            is($res->code, 404, '... got the expected status');
            is($res->header('Content-Type'), 'application/json', '... got the expected Content-Type header');
            is($res->content, '', '... got the expected content');
        }

        # test loading multiples

        {
            my $res = $cb->(GET "/WEB_MACHINE_AUTOMATED_TESTING_BULK_FOO");
            is($res->code, 404, '... got the expected status');
            is($res->header('Content-Type'), 'application/json', '... got the expected Content-Type header');
            is($res->content, '', '... got the expected content');
        }

        {
            my $res = $cb->(GET "/WEB_MACHINE_AUTOMATED_TESTING_BULK_BAR");
            is($res->code, 404, '... got the expected status');
            is($res->header('Content-Type'), 'application/json', '... got the expected Content-Type header');
            is($res->content, '', '... got the expected content');
        }

        {
            my $res = $cb->(PUT "/", (
                'Content-Type' => 'application/json',
                'Content' => $JSON->encode({
                    WEB_MACHINE_AUTOMATED_TESTING_BULK_FOO => 'FOO',
                    WEB_MACHINE_AUTOMATED_TESTING_BULK_BAR => 'BAR',
                })
            ));
            is($res->code, 204, '... got the expected status');
            is($res->header('Content-Type'), 'application/json', '... got the expected Content-Type header');
            is($res->content, '', '... got the expected content');
        }

        ok(exists $ENV{'WEB_MACHINE_AUTOMATED_TESTING_BULK_FOO'}, '... the variable exists now');
        is($ENV{'WEB_MACHINE_AUTOMATED_TESTING_BULK_FOO'}, 'FOO', '... the variable has the value we want');

        ok(exists $ENV{'WEB_MACHINE_AUTOMATED_TESTING_BULK_BAR'}, '... the variable exists now');
        is($ENV{'WEB_MACHINE_AUTOMATED_TESTING_BULK_BAR'}, 'BAR', '... the variable has the value we want');

        {
            my $res = $cb->(GET "/WEB_MACHINE_AUTOMATED_TESTING_BULK_FOO");
            is($res->code, 200, '... got the expected status');
            is($res->header('Content-Type'), 'application/json', '... got the expected Content-Type header');
            is_deeply(
                $JSON->decode( $res->content ),
                "FOO",
                '... got the expected content'
            );
        }

        {
            my $res = $cb->(GET "/WEB_MACHINE_AUTOMATED_TESTING_BULK_BAR");
            is($res->code, 200, '... got the expected status');
            is($res->header('Content-Type'), 'application/json', '... got the expected Content-Type header');
            is_deeply(
                $JSON->decode( $res->content ),
                "BAR",
                '... got the expected content'
            );
        }

        {
            my $res = $cb->(DELETE "/WEB_MACHINE_AUTOMATED_TESTING_BULK_FOO");
            is($res->code, 204, '... got the expected status');
            is($res->header('Content-Type'), 'application/json', '... got the expected Content-Type header');
            is($res->content, '', '... got the expected content');
        }

        {
            my $res = $cb->(DELETE "/WEB_MACHINE_AUTOMATED_TESTING_BULK_BAR");
            is($res->code, 204, '... got the expected status');
            is($res->header('Content-Type'), 'application/json', '... got the expected Content-Type header');
            is($res->content, '', '... got the expected content');
        }

        {
            my $res = $cb->(GET "/WEB_MACHINE_AUTOMATED_TESTING_BULK_FOO");
            is($res->code, 404, '... got the expected status');
            is($res->header('Content-Type'), 'application/json', '... got the expected Content-Type header');
            is($res->content, '', '... got the expected content');
        }

        {
            my $res = $cb->(GET "/WEB_MACHINE_AUTOMATED_TESTING_BULK_BAR");
            is($res->code, 404, '... got the expected status');
            is($res->header('Content-Type'), 'application/json', '... got the expected Content-Type header');
            is($res->content, '', '... got the expected content');
        }

        ## check some of the expected errors ...

        {
            my $res = $cb->(POST "/");
            is($res->code, 405, '... got the expected status');
            is($res->header('Allow'), 'GET, HEAD, PUT', '... got the expected Allow header');
            is($res->content, '', '... got the expected content');
        }

        {
            my $res = $cb->(DELETE "/");
            is($res->code, 405, '... got the expected status');
            is($res->header('Allow'), 'GET, HEAD, PUT', '... got the expected Allow header');
            is($res->content, '', '... got the expected content');
        }

        {
            my $res = $cb->(POST "/FOO");
            is($res->code, 405, '... got the expected status');
            is($res->header('Allow'), 'GET, HEAD, PUT, DELETE', '... got the expected Allow header');
            is($res->content, '', '... got the expected content');
        }

        {
            my $res = $cb->(PUT "/WEB_MACHINE_AUTOMATED_TESTING", (
                'Content-Type' => 'application/xml', 'Content' => '<FOOBAR/>'
            ));
            is($res->code, 415, '... got the expected status');
            is($res->header('Content-Type'), 'application/json', '... got the expected Content-Type header');
            is($res->content, '', '... got the expected content');
        }

        {
            my $res = $cb->(GET "/", 'Accept' => 'text/html');
            is($res->code, 406, '... got the expected status');
            is($res->content, '', '... got the expected content');
        }

    };

done_testing;