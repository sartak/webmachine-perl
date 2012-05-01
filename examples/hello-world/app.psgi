#!perl

use strict;
use warnings;

use Web::Machine;

{
    package HelloWorld::Resource;
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

Web::Machine->new( resource => 'HelloWorld::Resource' )->to_app;
