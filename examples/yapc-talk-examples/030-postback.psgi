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

    sub allowed_methods        { [qw[ GET PUT POST ]] }
    sub content_types_provided { [ { 'text/html'        => 'to_html'   } ] }
    sub content_types_accepted { [ { 'application/json' => 'from_json' } ] }

    sub to_html { '<html><body><form method="POST"><input type="text" name="message" />'
                . '<input type="submit" /></form><hr/><ul>'
                . (join '' => map { '<li>' . $_ . '</li>' } @MESSAGES) . '</ul></body></html>' }

    sub process_post {
        my $self = shift;
        return \415 unless $self->request->header('Content-Type')->match('application/x-www-form-urlencoded');
        push @MESSAGES => $self->request->param('message');
        $self->response->header('Location' => '/');
        return \301;
    }

    sub from_json {
        my $self = shift;
        push @MESSAGES => JSON::XS->new->allow_nonref->decode( $self->request->content );
    }

}

Web::Machine->new( resource => 'YAPC::NA::2012::Example030::Resource' )->to_app;
