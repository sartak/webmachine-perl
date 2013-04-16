package Web::Machine::Util::BodyEncoding;
# ABSTRACT: Module to handle body encoding

use strict;
use warnings;

use Encode ();
use Web::Machine::Util qw[ first pair_key pair_value ];

use Sub::Exporter -setup => {
    exports => [qw[
        encode_body_if_set
        encode_body
    ]]
};

sub encode_body_if_set {
    my ($resource, $response) = @_;
    encode_body( $resource, $response ) if $response->body;
}

sub encode_body {
    my ($resource, $response) = @_;

    my $metadata        = $resource->request->env->{'web.machine.context'};
    my $chosen_encoding = $metadata->{'Content-Encoding'};
    my $encoder         = $resource->encodings_provided->{ $chosen_encoding };

    my $chosen_charset = $metadata->{'Charset'};
    my $charsetter;
    if ( $chosen_charset && $resource->charsets_provided ) {
        my $match =             first {
                my $name = $_ && ref $_ ? pair_key($_) : $_;
                $name && $name eq $chosen_charset;
            }
            @{ $resource->charsets_provided };

        $charsetter
            = ref $match
            ? pair_value($match)
            : sub { Encode::encode( $match, $_[1] ) };
    }

    $charsetter ||= sub { $_[1] };

    push @{ $resource->request->env->{'web.machine.content_filters'} ||= [] },
        sub {
            my $chunk = shift;
            return unless defined $chunk;
            return $resource->$encoder($resource->$charsetter($chunk));
        };
}


1;

__END__

=head1 SYNOPSIS

  use Web::Machine::Util::BodyEncoding;

=head1 DESCRIPTION

This handles the body encoding.

=head1 FUNCTIONS

=over 4

=item C<encode_body_if_set ( $resource, $response, $metadata )>

If the C<$response> has a body, this will call C<encode_body>.

=item C<encode_body ( $resource, $response, $metadata )>

This will find the right encoding (from the 'Content-Encoding' entry
in the C<$metadata> HASH ref) and the right charset (from the 'Charset'
entry in the C<$metadata> HASH ref), then find the right transformers
in the C<$resource>. After that it will attempt to convert the charset
and encode the body of the C<$response>. Once completed it will set
the C<Content-Length> header in the response as well.

=back
