#!perl

use strict;
use warnings;

use Web::Machine;

=pod

And showing preference is just as simple as changing
the order of items in content_types_provided

# now HTML is the default
curl -v http://0:5000/

# and you must ask specifically for JSON
curl -v http://0:5000/ -H 'Accept: application/json'

=cut

{
    package YAPC::NA::2012::Example002::Resource;
    use strict;
    use warnings;
    use JSON::XS qw[ encode_json ];

    use parent 'Web::Machine::Resource';

    sub content_types_provided { [
        { 'text/html'        => 'to_html' },
        { 'application/json' => 'to_json' },
    ] }

    sub to_json { encode_json( { message => 'Hello World' } ) }
    sub to_html { '<html><body><h1>Hello World</h1></body></html>' }
}

Web::Machine->new( resource => 'YAPC::NA::2012::Example002::Resource' )->to_app;
