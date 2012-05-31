#!perl

use strict;
use warnings;

use Web::Machine;

=pod

Curl by default, it accepts anything, as you can see
when we run this.

curl -v http://0:5000/

However, web browsers are more sophisticated creatures
and have more complicated needs.

open http://0:5000/

You can see that since we only provide JSON, that we
end up matching the */* at the end.

=cut

{
    package YAPC::NA::2012::Example010::Resource;
    use strict;
    use warnings;
    use JSON::XS ();

    use parent 'Web::Machine::Resource';

    sub content_types_provided { [{ 'application/json' => 'to_json' }] }

    sub to_json {
        my $self = shift;
        JSON::XS->new->pretty->encode([
            map {
                +{ $_->[0] => $_->[1]->type }
            } $self->request->header('Accept')->iterable
        ])
    }
}

Web::Machine->new( resource => 'YAPC::NA::2012::Example010::Resource' )->to_app;
