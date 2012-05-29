#!perl

use strict;
use warnings;

use Web::Machine;

=pod

curl -v http://0:5000/ -H 'If-Modified-Since: Sun, 27 May 2012 17:34:59 EDT'

curl -v http://0:5000/ -H 'If-Modified-Since: Sun, 27 May 2012 17:35:00 EDT'

=cut

{
    package YAPC::NA::2012::Example001::Resource;
    use strict;
    use warnings;

    use Web::Machine::Util qw[ create_date ];

    use parent 'Web::Machine::Resource';

    sub content_types_provided { [{ 'text/html' => 'to_html' }] }

    sub last_modified { create_date('Sun, 27 May 2012 17:35:00 EDT') }
    sub generate_etag { '0xDEADBEEF' }

    sub to_html {
        join "" =>
        '<html>',
            '<head>',
                '<title>Hello World Resource</title>',
            '</head>',
            '<body>',
                '<h1>Hello World</h1>',
            '</body>',
        '</html>'
    }
}

Web::Machine->new( resource => 'YAPC::NA::2012::Example001::Resource' )->to_app;
