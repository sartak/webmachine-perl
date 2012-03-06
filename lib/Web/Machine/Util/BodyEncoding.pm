package Web::Machine::Util::BodyEncoding;

use strict;
use warnings;

use Web::Machine::Util qw[ first ];

use Sub::Exporter -setup => {
    exports => [qw[
        encode_body_if_set
        encode_body
    ]]
};

sub encode_body_if_set {
    my ($resource, $response, $metadata) = @_;
    encode_body( $resource, $response, $metadata ) if $response->body;
}

sub encode_body {
    my ($resource, $response, $metadata) = @_;

    my $chosen_encoding = $metadata->{'Content-Encoding'};
    my $encoder         = $resource->encodings_provided->{ $chosen_encoding };

    my $chosen_charset  = $metadata->{'Charset'};
    my $charsetter      = $resource->charsets_provided
                        && (first { $_ && $_->[0] eq $chosen_charset } @{ $resource->charsets_provided })
                        || sub { $_[1] };
    # TODO:
    # Make this support the other
    # body types that Plack supports
    # (arrays, code refs, etc).
    # - SL
    $response->body([
        $resource->$encoder(
            $resource->$charsetter(
                $response->body
            )
        )
    ]);

    $response->header( 'Content-Length' => length join "" => @{ $response->body } );
}


1;

__END__

# ABSTRACT: A Moosey solution to this problem

=head1 SYNOPSIS

  use Web::Machine::Util::BodyEncoding;

=head1 DESCRIPTION

