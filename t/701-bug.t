#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use HTTP::Request;
use Plack::Test;
use Plack::Util;
use Test::More;
use Web::Machine;

{
    package Resource::Foo;
    use strict;
    use warnings;

    use parent 'Web::Machine::Resource';

    sub allowed_methods { [ 'GET', 'POST' ] }

    sub content_types_provided { [ { 'text/html' => 'to_html' } ] }

    sub to_html { return '<html></html>' }

    sub process_post { 1 }
}

test_psgi(
    Web::Machine->new( resource => 'Resource::Foo' )->to_app,
    sub {
        my $cb = shift;
        my $req = HTTP::Request->new( 'POST', '/' );
        $req->header( Accept => '*/*' );
        $req->header( Expect => '100-continue' );
        $req->header(
            Expect => 'Content-Type',
            'multipart/form-data; boundary=----------------------------261c6e9ed2f6'
        );

        my $body = <<'EOF';
 ------------------------------261c6e9ed2f6
Content-Disposition: form-data; name="l"

abcdef123456
------------------------------261c6e9ed2f6
Content-Disposition: form-data; name="i"

1.2.3.4
------------------------------261c6e9ed2f6--
EOF
        $body =~ s/\n/\r\n/g;

        $req->content($body);

        my $res = $cb->($req);
        isnt( $res->code, 500, '... did not return 500' );
        is( $res->code, 400, '... did return 400' );
    }
);

done_testing;
