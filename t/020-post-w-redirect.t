#!/usr/bin/perl

use strict;
use warnings;
use FindBin;

use Test::More;
use Test::Fatal;

use Plack::Test;
use Plack::Util;

use HTTP::Request::Common;

use Web::Machine;

=pod

This provides an example of how you might use POST to
create elements, but instead of returning the 201 Created
status with a Location header pointing to the newly
created resource, you return a 301 Redirect status with
a Location header taking you back to the original GET
location.

This pattern is more common for human consumable web
resources, but it is perfectly reasonable for computer
consumed ones too (if it works for your app).

=cut

my @STUFF;
{
    package My::Resource::Test020;
    use strict;
    use warnings;

    use JSON::XS qw[ encode_json decode_json ];

    use parent 'Web::Machine::Resource';

    sub allowed_methods        { [qw[ GET POST ]] }
    sub content_types_provided { [ { 'application/json' => 'to_json'   } ] }
    sub content_types_accepted { [ { 'application/json' => 'from_json' } ] }

    sub post_is_create { 1 }
    sub base_uri       { '/' }
    sub create_path    { (shift)->base_uri } # go back to the root

    sub to_json {
        my $self = shift;
        encode_json([ @STUFF ])
    }

    sub from_json {
        my $self = shift;
        push @STUFF => decode_json( $self->request->content );
        return \301;
    }
}

test_psgi(
    Web::Machine->new( resource => 'My::Resource::Test020' )->to_app,
    sub {
        my $cb  = shift;

        {
            my $res = $cb->(GET "/");
            is($res->code, 200, '... got the expected status');
            is($res->header('Content-Type'), 'application/json', '... got the expected Content-Type header');
            is($res->header('Content-Length'), 2, '... got the expected Content-Length header');
            is(
                $res->content,
                '[]',
                '... got the expected content'
            );
        }

        {
            my $res = $cb->(
                POST "/", (
                    'Content-Type' => 'application/json',
                    'Content'      => '{"foo":"bar"}'
                )
            );
            is($res->code, 301, '... got the expected status');
            is($res->header('Location'), '/', '... got the expected Location header');
        }

        {
            my $res = $cb->(GET "/");
            is($res->code, 200, '... got the expected status');
            is($res->header('Content-Type'), 'application/json', '... got the expected Content-Type header');
            is($res->header('Content-Length'), 15, '... got the expected Content-Length header');
            is(
                $res->content,
                '[{"foo":"bar"}]',
                '... got the expected content'
            );
        }

    }
);

done_testing;