#!perl

use strict;
use warnings;

use Web::Machine;


{
    package YAPC::NA::2012::Example030::Resource;
    use strict;
    use warnings;
    use JSON::XS ();

    use parent 'Web::Machine::Resource';

    our @MESSAGES = ();

    sub post_is_create         { 1 }
    sub create_path            { '/' }
    sub allowed_methods        { [qw[ GET POST ]] }
    sub content_types_provided { [ { 'text/html' => 'to_html' } ] }
    sub content_types_accepted { [
        { 'application/json'                  => 'from_json' },
        { 'application/x-www-form-urlencoded' => 'from_html' },
    ] }

    sub to_html { '<html><body><form method="POST"><input type="text" name="message" />'
                . '<input type="submit" /></form><hr/><ul>'
                . (join '' => map { '<li>' . $_ . '</li>' } @MESSAGES) . '</ul></body></html>' }

    sub from_html {
        my $self = shift;
        push @MESSAGES => $self->request->param('message');
        return \301;
    }

    sub from_json {
        my $self = shift;
        push @MESSAGES => JSON::XS->new->allow_nonref->decode( $self->request->content );
        return \301;
    }

}

Web::Machine->new( resource => 'YAPC::NA::2012::Example030::Resource' )->to_app;
