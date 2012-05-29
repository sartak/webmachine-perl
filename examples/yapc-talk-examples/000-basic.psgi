#!perl

use strict;
use warnings;

use Web::Machine;

=pod

curl -v http://0:5000/

=cut

{
    package YAPC::NA::2012::Example000::Resource;
    use strict;
    use warnings;

    use parent 'Web::Machine::Resource';

    sub content_types_provided { [{ 'text/html' => 'to_html' }] }

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

Web::Machine->new( resource => 'YAPC::NA::2012::Example000::Resource' )->to_app;
