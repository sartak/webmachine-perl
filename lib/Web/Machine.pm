package Web::Machine;
# ABSTRACT: A Perl port of WebMachine

use strict;
use warnings;

use Carp         qw[ confess ];
use Scalar::Util qw[ blessed ];

use Plack::Request;
use Plack::Response;

use HTTP::Headers::ActionPack;

use Web::Machine::FSM;

use parent 'Plack::Component';

sub new {
    my ($class, %args) = @_;

    (exists $args{'resource'}
        && (not blessed $args{'resource'})
            && $args{'resource'}->isa('Web::Machine::Resource'))
                || confess 'You must pass in a resource for this Web::Machine';

    $class->SUPER::new( \%args );
}

sub inflate_request {
    my ($self, $env) = @_;

    my $request = Plack::Request->new( $env );

    HTTP::Headers::ActionPack->new->inflate( $request );

    $request;
}

sub call {
    my ($self, $env) = @_;

    my $request = $self->inflate_request( $env );

    return Web::Machine::FSM->new( %{ $self->{'fsm_args'} || {} } )->run(
        $self->{'resource'}->new(
            request  => $request,
            response => $request->new_response,
        )
    )->finalize;
}

1;

__END__

=head1 SYNOPSIS

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
          q{<html>
              <head>
                  <title>Hello World Resource</title>
              </head>
              <body>
                  <h1>Hello World</h1>
              </body>
           </html>}
      }
  }

  Web::Machine->new( resource => 'HelloWorld::Resource' )->to_app;

=head1 DESCRIPTION

This is a port of L<Webmachine|https://github.com/basho/webmachine>,
actually it is much closer to L<the ruby version|https://github.com/seancribbs/webmachine-ruby>, with
a little bit of L<the javascript version|https://github.com/tautologistics/nodemachine>
and even some of L<the python version|https://github.com/davisp/pywebmachine>
thrown in for good measure.

It runs atop L<Plack>, but since it really handles the whole HTTP
transaction, it is not appropriate to use most middleware modules.
(NOTE: I will write more about this in the future.)

=head1 CAVEAT

This module is extremely young and it is a port of an pretty young (June 2011)
module in another language (ruby), which itself is a port of a still kind of
young module (March 2009) in yet another language (erlang). But that all said,
it really seems like a sane idea and so I stole it and ported it to Perl.

=head1 DEBUGGING

If you set the C<WM_DEBUG> environment variable to C<1> we will print
out information about the path taken through the state machine to STDERR.

=head1 SEE ALSO

=over 4

=item Original Erlang - L<https://github.com/basho/webmachine>

=item Ruby port - L<https://github.com/seancribbs/webmachine-ruby>

=item Node JS port - L<https://github.com/tautologistics/nodemachine>

=item Python port - L<https://github.com/davisp/pywebmachine>

=back