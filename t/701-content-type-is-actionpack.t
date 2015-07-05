#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use HTTP::Request;
use Plack::Test;
use Plack::Util;
use Test::More;
use Web::Machine;

# Normally we'd use done_testing but the test is in the resource code so we
# need to make sure it gets called at all.
plan tests => 1;

=pod

This references https://github.com/houseabsolute/webmachine-perl/issues/27

We need to ensure that we always get the Content-Type header by calling
$request->header('Content-Type') rather than $request->content_type. The
latter doesn't actually look at the headers object, meaning we don't get the
inflated ActionPack header.

=cut

{
    package My::Resource::Test701;

    use strict;
    use warnings;

    use parent 'Web::Machine::Resource';

    use Test::More;

    sub allowed_methods { ['POST'] }

    sub content_types_provided {
        [
            {
                'text/plain' => sub { return 'foo' }
            }
        ];
    }

    sub process_post { \202 }

    sub known_content_type {
        isa_ok(
            $_[1],
            'HTTP::Headers::ActionPack::MediaType',
            'values passed to known_content_type'
        );
        return 1;
    }
}

test_psgi(
    Web::Machine->new( resource => 'My::Resource::Test701' )->to_app,
    sub {
        my $cb = shift;
        my $req = HTTP::Request->new( 'POST', '/' );
        $req->header( 'Content-Type' => 'text/plain' );
        $cb->($req);
    }
);
