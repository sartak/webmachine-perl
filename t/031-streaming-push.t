#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Plack::Test;

use HTTP::Request::Common;
use HTTP::Response;
use HTTP::Message::PSGI;

use Web::Machine;

my $HTML = '<html><body>Hello World</body></html>';

{
    package My::Resource;
    use strict;
    use warnings;

    use parent 'Web::Machine::Resource';

    sub content_types_provided { [{ 'text/html' => 'to_html' }] }

    sub to_html {
        my $str = $HTML;
        return sub {
            my $writer = shift;
            $writer->write($str);
            $writer->close;
        };
    }
}

{
    package My::Resource2;
    use strict;
    use warnings;

    use parent 'Web::Machine::Resource';

    sub content_types_provided { [{ 'text/html' => 'to_html' }] }

    sub to_html {
        my $str = $HTML;
        return sub {
            my $writer = shift;
            while (length $str) {
                my $chunk = substr $str, 0, 1, '';
                $writer->write($chunk);
            }
            $writer->close;
        };
    }
}

sub test_streaming {
    my ($app) = @_;

    my $response = $app->({
        REQUEST_METHOD    => 'GET',
        SERVER_PROTOCOL   => 'HTTP/1.1',
        SERVER_NAME       => 'example.com',
        SCRIPT_NAME       => '/foo',
    });

    is(ref($response), 'CODE');

    my $final_response;
    my $responder = sub {
        $final_response = $_[0];
        if (@$final_response == 2) {
            my @body;
            return Plack::Util::inline_object
                write => sub { push @body, @_ },
                close => sub { push @$final_response, \@body };
        }
    };

    $response->($responder);
    my $http_response = HTTP::Response->from_psgi($final_response);
    ok($http_response->is_success);
    is($http_response->content, $HTML);
}

{
    my $app = Web::Machine->new(
        resource  => 'My::Resource',
        streaming => 1
    );
    test_streaming($app);
    test_psgi
        app    => $app,
        client => sub {
            my $cb = shift;

            {
                my $res = $cb->(GET '/');
                ok($res->is_success) || diag($res->content);
                is($res->content, $HTML);
            }
        };
}

{
    my $app = Web::Machine->new(
        resource  => 'My::Resource2',
        streaming => 1
    );
    test_streaming($app);
    test_psgi
        app    => $app,
        client => sub {
            my $cb = shift;

            {
                my $res = $cb->(GET '/');
                ok($res->is_success) || diag($res->content);
                is($res->content, $HTML);
            }
        };
}

{
    my $app = Web::Machine->new(
        resource => 'My::Resource',
    );
    like(
        exception {
            $app->to_app->({
                REQUEST_METHOD    => 'GET',
                SERVER_PROTOCOL   => 'HTTP/1.1',
                SERVER_NAME       => 'example.com',
                SCRIPT_NAME       => '/foo',
            });
        },
        qr/Can't do a streaming push response unless the 'streaming' option was set/,
    );
}

done_testing;
