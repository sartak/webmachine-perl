#!perl

use strict;
use warnings;

use Web::Machine;

=pod

curl -v http://0:5000/

# fails with a 406
curl -v http://0:5000/ -H 'Accept: image/jpeg'

=cut

{
    package YAPC::NA::2012::Example000::Resource;
    use strict;
    use warnings;
    use JSON::XS qw[ encode_json ];

    use parent 'Web::Machine::Resource';

    sub content_types_provided { [{ 'application/json' => 'to_json' }] }

    sub to_json { encode_json( { message => 'Hello World' } ) }
}

Web::Machine->new( resource => 'YAPC::NA::2012::Example000::Resource' )->to_app;
