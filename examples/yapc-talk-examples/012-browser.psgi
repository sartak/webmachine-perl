#!perl

use strict;
use warnings;

use Web::Machine;

=pod

And of course, you don't have to just provide
text based results ...

=cut

{
    package YAPC::NA::2012::Example012::Resource;
    use strict;
    use warnings;
    use JSON::XS ();
    use GD::Simple;

    use parent 'Web::Machine::Resource';

    sub content_types_provided { [
        { 'image/gif' => 'to_gif'  },
        { 'text/html' => 'to_html' },
    ] }

    sub to_html {
        my $self = shift;
        '<html><body><ul>' .
            (join "" => map {
                '<li>' . $_->[0] . ' &mdash; ' . $_->[1]->type . '</li>'
            } $self->request->header('Accept')->iterable)
        . '</ul><br/><img src="/hello_world.gif" border="1"/></body></html>'
    }

    sub to_gif {
        my $self = shift;
        my $img  = GD::Simple->new( 130, 20 );
        $img->fgcolor('red');
        $img->moveTo(15, 15);
        $img->string( $self->request->path_info );
        $img->gif;
    }
}

Web::Machine->new( resource => 'YAPC::NA::2012::Example012::Resource' )->to_app;
