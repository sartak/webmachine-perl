#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use HTTP::Request;
use Plack::Test;
use Plack::Util;
use Test::More;

test_psgi
    Plack::Util::load_psgi("$FindBin::Bin/../examples/hello-world/app.psgi"),
  sub {
    my $cb = shift;
    my $req = HTTP::Request->new( 'GET', '/' );
    $req->header( Authorization => 'Basic' );

    my $res = $cb->($req);
    isnt( $res->code, 500, 'did not return 500' );
};

done_testing;
