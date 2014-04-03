package Web::Machine::FSM;
# ABSTRACT: The State Machine runner

use strict;
use warnings;

use IO::Handle::Util 'io_from_getline';
use Plack::Util;
use Try::Tiny;
use HTTP::Status qw[ is_error ];
use Web::Machine::I18N;
use Web::Machine::FSM::States qw[
    start_state
    is_status_code
    is_new_state
    get_state_name
    get_state_desc
];

sub new {
    my ($class, %args) = @_;
    bless {
        tracing        => !!$args{'tracing'},
        tracing_header => $args{'tracing_header'} || 'X-Web-Machine-Trace'
    } => $class
}

sub tracing        { (shift)->{'tracing'} }
sub tracing_header { (shift)->{'tracing_header'} }

sub run {
    my ( $self, $resource ) = @_;

    my $DEBUG = $ENV{'WM_DEBUG'};

    my $request  = $resource->request;
    my $response = $resource->response;
    my $metadata = {};
    $request->env->{'web.machine.context'} = $metadata;

    my @trace;
    my $tracing = $self->tracing;

    my $state = start_state;

    try {
        while (1) {
            warn "entering " . get_state_name( $state ) . " (" . get_state_desc( $state ) . ")\n" if $DEBUG;
            push @trace => get_state_name( $state ) if $tracing;
            my $result = $state->( $resource, $request, $response, $metadata );
            if ( ! ref $result ) {
                # TODO:
                # We should be I18N this
                # specific error
                # - SL
                warn "! ERROR with " . ($result || 'undef') . "\n" if $DEBUG;
                $response->status( 500 );
                $response->header( 'Content-Type' => 'text/plain' );
                $response->body( [ "Got bad state: " . ($result || 'undef') ] );
                last;
            }
            elsif ( is_status_code( $result ) ) {
                warn ".. terminating with " . ${ $result } . "\n" if $DEBUG;
                $response->status( $$result );

                if ( is_error( $$result ) && !$response->body ) {
                    # NOTE:
                    # this will default to en, however I
                    # am not really confident that this
                    # will end up being sufficient.
                    # - SL
                    my $lang = Web::Machine::I18N->get_handle( $metadata->{'Language'} || 'en' )
                        or die "Could not get language handle for " . $metadata->{'Language'};
                    $response->header( 'Content-Type' => 'text/plain' );
                    $response->body([ $lang->maketext( $$result ) ]);
                }

                if ( $DEBUG ) {
                    require Data::Dumper;
                    local $Data::Dumper::Useqq = 1;
                    warn Data::Dumper::Dumper( $request->env );
                    warn Data::Dumper::Dumper( $response->finalize );
                }

                last;
            }
            elsif ( is_new_state( $result ) ) {
                warn "-> transitioning to " . get_state_name( $result ) . "\n" if $DEBUG;
                $state = $result;
            }
        }
    } catch {
        # TODO:
        # We should be I18N the errors
        # - SL
        warn $_ if $DEBUG;

        if ( $request->logger ) {
            $request->logger->( { level => 'error', message => $_ } );
        }

        $response->status( 500 );

        # NOTE:
        # this way you can handle the
        # exception if you like via
        # the finish_request call below
        # - SL
        $metadata->{'exception'} = $_;
    };

    $self->filter_response( $resource )
        unless $request->env->{'web.machine.streaming_push'};
    try {
        $resource->finish_request( $metadata );
    }
    catch {
        warn $_ if $DEBUG;

        if ( $request->logger ) {
            $request->logger->( { level => 'error', message => $_ } );
        }

        $response->status( 500 );
    };
    $response->header( $self->tracing_header, (join ',' => @trace) )
        if $tracing;

    $response;
}

sub filter_response {
    my $self = shift;
    my ($resource) = @_;

    my $response = $resource->response;
    my $filters = $resource->request->env->{'web.machine.content_filters'};

    # XXX patch Plack::Response to make _body not private?
    my $body = $response->_body;

    for my $filter (@$filters) {
        if (ref($body) eq 'ARRAY') {
            $response->body( [ map { $filter->($_) } @$body ] );
            $body = $response->body;
        }
        else {
            my $old_body = $body;
            $body = io_from_getline sub { $filter->($old_body->getline) };
            $response->body($body);
        }
    }

    if (ref($body) eq 'ARRAY'
     && !Plack::Util::status_with_no_entity_body($response->status)) {
        $response->header(
            'Content-Length' => Plack::Util::content_length($body)
        );
    }
}

1;

__END__

=head1 SYNOPSIS

  use Web::Machine::FSM;

=head1 DESCRIPTION

This is the heart of the L<Web::Machine>, this is the thing
which runs the state machine whose states are contained in the
L<Web::Machine::FSM::States> module.

=head1 METHODS

=over 4

=item C<new ( %params )>

This accepts two C<%params>, the first is a boolean to
indicate if you should turn on tracing or not, and the second
is optional name of the HTTP header in which to place the
tracing information.

=item C<tracing>

Are we tracing or not?

=item C<tracing_header>

Accessor for the HTTP header name to store tracing data in.
This default to C<X-Web-Machine-Trace>.

=item C<run ( $resource )>

Given a L<Web::Machine::Resource> instance, this will execute
the state machine.

=back

=head1 SEE ALSO

=over 4

=item L<Web Machine state diagram|http://wiki.basho.com/Webmachine-Diagram.html>

=back






