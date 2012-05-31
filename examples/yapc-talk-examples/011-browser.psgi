#!perl

use strict;
use warnings;

use Web::Machine;

=pod

So what happens then if we provide HTML as well?

open http://0:5000/

Now we prefer HTML over JSON, even though JSON is
the default here.

If you call curl, you get the expected JSON.

curl -v http://0:5000/

=cut

{
    package YAPC::NA::2012::Example011::Resource;
    use strict;
    use warnings;
    use JSON::XS ();

    use parent 'Web::Machine::Resource';

    sub content_types_provided { [
        { 'application/json' => 'to_json' },
        { 'text/html'        => 'to_html' }
    ] }

    sub to_json {
        my $self = shift;
        JSON::XS->new->pretty->encode([
            map {
                +{ $_->[0] => $_->[1]->type }
            } $self->request->header('Accept')->iterable
        ])
    }

    sub to_html {
        my $self = shift;
        '<html><body><ul>' .
            (join "" => map {
                '<li>' . $_->[0] . ' &mdash; ' . $_->[1]->type . '</li>'
            } $self->request->header('Accept')->iterable)
        . '</ul></body></html>'
    }
}

Web::Machine->new( resource => 'YAPC::NA::2012::Example011::Resource' )->to_app;
