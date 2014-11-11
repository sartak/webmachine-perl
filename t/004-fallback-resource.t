#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Plack::Request;
use Plack::Response;

BEGIN {
    use_ok('Web::Machine');
}

{
    package Good::Resource;
    use strict;
    use warnings;

    use parent 'Web::Machine::Resource';

    sub content_types_provided { [{ 'text/html' => 'to_html' }] }

    sub to_html { '<html><body>Hello World</body></html>' }
}

{
    package Bad::Resource;
    use strict;
    use warnings;

    use parent 'Web::Machine::Resource';

    sub new {
      die "Something broke";
    }
}

my $app = Web::Machine->new(
    resource => [qw/ Bad::Resource Good::Resource / ],
)->to_app;

my $env = {
           REQUEST_METHOD    => 'GET',
           SERVER_PROTOCOL   => 'HTTP/1.1',
           SERVER_NAME       => 'example.com',
           SCRIPT_NAME       => '/foo',
          };


ok my $resp = $app->($env), 'created resource';

done_testing;
