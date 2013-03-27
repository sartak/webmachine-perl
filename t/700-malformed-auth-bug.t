#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use HTTP::Request;
use Plack::Test;
use Plack::Util;
use Test::More;

=pod

This references RT# 84232

Specifically we are watching out for errors that happen when
the headers are expanded by HTTP::ActionPack::Headers and
then returning a 400 Bad Request instead

=cut

test_psgi
    Plack::Util::load_psgi("$FindBin::Bin/../examples/hello-world/app.psgi"),
    sub {
        my $cb = shift;
        my $req = HTTP::Request->new( 'GET', '/' );
        $req->header( Authorization => 'Basic' );

        my $res = $cb->($req);
        isnt( $res->code, 500, '... did not return 500' );
        is( $res->code, 400, '... did return 400' );
    };

done_testing;
