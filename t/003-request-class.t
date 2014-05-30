#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Web::Machine;

{
    package My::Plack::Request;
    use strict;
    use warnings;

    use parent 'Plack::Request';
}

my $app = Web::Machine->new(
    resource      => 'Web::Machine::Resource',
    request_class => 'My::Plack::Request',
);

my $request = $app->inflate_request({});

isa_ok($request, 'My::Plack::Request');
isa_ok($request, 'Plack::Request');

ok(
    exception {
        Web::Machine->new(
            resource      => 'Web::Machine::Resource',
            request_class => $request,
        );
    },
    'The constructor dies when request_class is not a module name...'
);

like(
    exception {
        Web::Machine->new(
            resource      => 'Web::Machine::Resource',
            request_class => 'Web::Machine',
        );
    },
    qr/must inherit from Plack::Request/,
    '...or if the request_class class does not inherit from Plack::Request'
);

like(
    exception {
        Web::Machine->new(
            resource      => 'Web::Machine::Resource',
            request_class => 'Does::not::Exist',
        );
    },
    qr/must inherit from Plack::Request/,
    '...or if the request_class class does not exist'
);

done_testing;
