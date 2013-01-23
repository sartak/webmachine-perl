#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

BEGIN {
    if (!eval { require Test::TCP; Test::TCP->import; 1 }) {
        plan skip_all => "Test::TCP is required for this test";
    }
    if (!eval { require JSON::XS; JSON::XS->import; 1 }) {
        plan skip_all => "JSON is required for this test";
    }
}

use Net::HTTP;
use Plack::Runner;

use Web::Machine;

pipe(my $read, my $write);
alarm(60);

{
    package My::Resource;
    use strict;
    use warnings;

    use IO::Handle::Util 'io_from_getline';

    use parent 'Web::Machine::Resource';

    sub content_types_provided { [{ 'application/json' => 'to_json' }] }

    sub to_json {
        my $self = shift;

        my @lines = (
            '[',
            '{"foo": "1"}',
            '{"bar": "2"}',
            '{"baz": "3"}',
            ']',
        );

        return io_from_getline sub {
            { sysread($read, my $buf, 1) }
            my $line = shift @lines;
            return "$line\n";
        };
    }
}

my $app = Web::Machine->new(resource => 'My::Resource')->to_app;

test_tcp
    client => sub {
        my ($port, $pid) = @_;

        close $read;

        my $http = Net::HTTP->new(
            Host     => 'localhost',
            PeerPort => $port,
        );
        $http->write_request(GET => '/', Accept => 'application/json');

        my ($code, $mess, %headers) = $http->read_response_headers;
        is($code, 200);
        is($headers{'Content-Type'}, 'application/json');

        syswrite($write, 'a');

        my $chunk;
        $http->read_entity_body($chunk, 1024);
        is($chunk, "[\n");

        syswrite($write, 'a');

        $http->read_entity_body($chunk, 1024);
        is_deeply(decode_json($chunk), { foo => 1 });

        syswrite($write, 'a');

        $http->read_entity_body($chunk, 1024);
        is_deeply(decode_json($chunk), { bar => 2 });

        syswrite($write, 'a');

        $http->read_entity_body($chunk, 1024);
        is_deeply(decode_json($chunk), { baz => 3 });
    },
    server => sub {
        my ($port) = @_;

        close $write;

        my $runner = Plack::Runner->new;
        $runner->parse_options(
            '--server' => 'Standalone',
            '--env'    => 'test',
            '--port'   => $port,
        );
        $runner->run($app);
    };

alarm(0);

done_testing;
