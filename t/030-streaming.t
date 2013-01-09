#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Plack::Test;

use HTTP::Request::Common;
use HTTP::Response;
use HTTP::Message::PSGI;

use Web::Machine;

my $HTML = '<html><body>Hello World</body></html>';

{
    package My::Resource::String;
    use strict;
    use warnings;

    use parent 'Web::Machine::Resource';

    sub content_types_provided { [{ 'text/html' => 'to_html' }] }

    sub to_html { $HTML }
}

{
    package My::Resource::IO;
    use strict;
    use warnings;

    use parent 'Web::Machine::Resource';

    sub content_types_provided { [{ 'text/html' => 'to_html' }] }

    sub to_html {
        my $str = $HTML;
        open my $fh, '<', \$str;
        return $fh;
    }
}

{
    package My::Resource::Code;
    use strict;
    use warnings;

    use IO::Handle::Util 'io_from_getline';

    use parent 'Web::Machine::Resource';

    sub content_types_provided { [{ 'text/html' => 'to_html' }] }

    sub to_html {
        my $str = $HTML;
        return io_from_getline sub {
            length $str ? substr $str, 0, 1, '' : undef
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
    };

    $response->($responder);
    my $http_response = HTTP::Response->from_psgi($final_response);
    ok($http_response->is_success);
    is($http_response->content, $HTML);
}

my $string_app = Web::Machine->new(
    resource  => 'My::Resource::String',
    streaming => 1
);
test_streaming($string_app);
test_psgi
    app    => $string_app,
    client => sub {
        my $cb = shift;

        {
            my $res = $cb->(GET '/');
            ok($res->is_success) || diag($res->content);
            is($res->content, $HTML);
        }
    };

my $io_app = Web::Machine->new(
    resource  => 'My::Resource::IO',
    streaming => 1
);
test_streaming($io_app);
test_psgi
    app    => $io_app,
    client => sub {
        my $cb = shift;

        {
            my $res = $cb->(GET '/');
            ok($res->is_success) || diag($res->content);
            is($res->content, $HTML);
        }
    };

my $code_app = Web::Machine->new(
    resource  => 'My::Resource::Code',
    streaming => 1
);
test_streaming($code_app);
test_psgi
    app    => $code_app,
    client => sub {
        my $cb = shift;

        {
            my $res = $cb->(GET '/');
            ok($res->is_success) || diag($res->content);
            is($res->content, $HTML);
        }
    };

done_testing;
