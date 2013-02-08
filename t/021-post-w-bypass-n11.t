#!/usr/bin/perl

use strict;
use warnings;
use FindBin;

use Test::More;
use Test::Fatal;

BEGIN {
    if (!eval { require JSON::XS; 1 }) {
        plan skip_all => "JSON::XS is required for this test";
    }
}

use Plack::Test;
use Plack::Util;

use HTTP::Request::Common;

use Web::Machine;

=pod


=cut

my %DB;
{
    package My::Resource::Test021;
    use strict;
    use warnings;

    use Web::Machine::Util qw[ bind_path ];
    use JSON::XS qw[ encode_json decode_json ];

    use parent 'Web::Machine::Resource';

    sub current_id {
        my $self = shift;
        $self->{'current_id'} = shift if @_;
        $self->{'current_id'}
    }

    sub allowed_methods        { [qw[ GET POST ]] }
    sub content_types_provided { [ { 'application/json' => 'to_json'   } ] }
    sub content_types_accepted { [ { 'application/json' => 'from_json' } ] }

    sub create_path_after_handler { 1 }

    sub post_is_create { 1 }
    sub base_uri       { '/' }
    sub create_path    { (shift)->current_id }

    sub to_json {
        my $self = shift;
        if ( my $id = bind_path( '/:id', $self->request->path_info ) ) {
            encode_json( $DB{ $id } )
        } else {
            encode_json([ map { $DB{ $_ } } sort keys %DB ])
        }
    }

    sub from_json {
        my $self = shift;
        my $data = decode_json( $self->request->content );
        $DB{ $data->{'id'} } = $data;
        $self->current_id( $data->{'id'} );
        return;
    }
}

test_psgi(
    Web::Machine->new( resource => 'My::Resource::Test021' )->to_app,
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
                    'Content'      => '{"id":"bar"}'
                )
            );
            is($res->code, 201, '... got the expected status');
            is($res->header('Location'), '/bar', '... got the expected Location header');
        }

        {
            my $res = $cb->(GET "/");
            is($res->code, 200, '... got the expected status');
            is($res->header('Content-Type'), 'application/json', '... got the expected Content-Type header');
            is($res->header('Content-Length'), 14, '... got the expected Content-Length header');
            is(
                $res->content,
                '[{"id":"bar"}]',
                '... got the expected content'
            );
        }

        {
            my $res = $cb->(GET "/bar");
            is($res->code, 200, '... got the expected status');
            is($res->header('Content-Type'), 'application/json', '... got the expected Content-Type header');
            is($res->header('Content-Length'), 12, '... got the expected Content-Length header');
            is(
                $res->content,
                '{"id":"bar"}',
                '... got the expected content'
            );
        }

        {
            my $res = $cb->(
                POST "/", (
                    'Content-Type' => 'application/json',
                    'Content'      => '{"id":"baz"}'
                )
            );
            is($res->code, 201, '... got the expected status');
            is($res->header('Location'), '/baz', '... got the expected Location header');
        }

        {
            my $res = $cb->(GET "/");
            is($res->code, 200, '... got the expected status');
            is($res->header('Content-Type'), 'application/json', '... got the expected Content-Type header');
            is($res->header('Content-Length'), 27, '... got the expected Content-Length header');
            is(
                $res->content,
                '[{"id":"bar"},{"id":"baz"}]',
                '... got the expected content'
            );
        }

        {
            my $res = $cb->(GET "/baz");
            is($res->code, 200, '... got the expected status');
            is($res->header('Content-Type'), 'application/json', '... got the expected Content-Type header');
            is($res->header('Content-Length'), 12, '... got the expected Content-Length header');
            is(
                $res->content,
                '{"id":"baz"}',
                '... got the expected content'
            );
        }

        {
            my $res = $cb->(GET "/bar");
            is($res->code, 200, '... got the expected status');
            is($res->header('Content-Type'), 'application/json', '... got the expected Content-Type header');
            is($res->header('Content-Length'), 12, '... got the expected Content-Length header');
            is(
                $res->content,
                '{"id":"bar"}',
                '... got the expected content'
            );
        }

    }
);

done_testing;