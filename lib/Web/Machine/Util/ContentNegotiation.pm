package Web::Machine::Util::ContentNegotiation;

use strict;
use warnings;

use List::Util      qw[ first ];
use List::MoreUtils qw[ any ];

use Web::Machine::Util::MediaType;
use Web::Machine::Util::MediaTypeList;
use Web::Machine::Util::PriorityList;

use Sub::Exporter -setup => {
    exports => [qw[
        choose_media_type
        match_acceptable_media_type
        choose_language
        choose_charset
        choose_encoding
    ]]
};

sub choose_media_type {
    my ($provided, $header) = @_;
    my $requested       = Web::Machine::Util::MediaTypeList->new_from_header_list( split /\s*,\s*/ => $header );
    my $parsed_provided = [ map { Web::Machine::Util::MediaType->new_from_string( $_ ) } @$provided ];

    my $chosen;
    foreach my $request ( $requested->iterable ) {
        my $requested_type = $request->[1];
        $chosen = media_match( $requested_type, $parsed_provided );
        last if $chosen;
    }

    ($chosen || return)
}

sub match_acceptable_media_type {
    my ($to_match, $accepted) = @_;
    my $content_type = Web::Machine::Util::MediaType->new_from_string( $to_match );
    if ( my $acceptable = first { $content_type->match( $_ ) } @$accepted ) {
        return $acceptable;
    }
    return;
}

sub choose_language {
    my ($provided, $header) = @_;

    return 1 if scalar @$provided == 0;

    my $language;
    my $requested     = Web::Machine::Util::PriorityList->new_from_header_list( split /\s*,\s*/ => $header );
    my $star_priority = $requested->priority_of('*');
    my $any_ok        = $star_priority && $star_priority > 0.0;

    my $accepted      = first {
        my ($priority, $range) = @$_;
        if ( $priority == 0.0 ) {
            $provided = [ grep { language_match( $range, $_ )  } @$provided ];
            return 0;
        }
        else {
            return any { language_match( $range, $_ ) } @$provided;
        }
    } $requested->iterable;

    if ( $accepted ) {
        $language = first { language_match( $accepted->[-1], $_ ) } @$provided;
    }
    elsif ( $any_ok ) {
        $language = $provided->[0];
    }

    $language;
}

sub choose_charset {
    my ($provided, $header) = @_;
    if ( @$provided ) {
        my @charsets = map { $_->[0] } @$provided;
        # NOTE:
        # Making the default charset UTF-8, which
        # is maybe sensible, I dunno.
        # - SL
        if ( my $charset = make_choice( \@charsets, $header, 'UTF-8' )) {
            return $charset;
        }
    }
    return 1;
}

sub choose_encoding {
    my ($provided, $header) = @_;
    my @encodings = keys %$provided;
    if ( @encodings ) {
        if ( my $encoding = make_choice( \@encodings, $header, 'identity' ) ) {
            return $encoding;
        }
    }
    return;
}

## ....

sub media_match {
    my ($requested, $provided) = @_;
    return $provided->[0] if $requested->matches_all;
    return first { $_->match( $requested ) } @$provided;
}

sub language_match {
    my ($range, $tag) = @_;
    ((lc $range) eq (lc $tag)) || $range eq "*" || $tag =~ /^$range\-/i;
}

sub make_choice {
    my ($choices, $header, $default) = @_;

    $choices = [ map { lc $_ } @$choices ];

    my $accepted         = Web::Machine::Util::PriorityList->new_from_header_list( split /\s*,\s*/ => $header );
    my $default_priority = $accepted->priority_of( $default );
    my $star_priority    = $accepted->priority_of( '*' ) || 0.0;
    my $default_ok       = ( defined $default_priority && $star_priority != 0 ) || $default_priority;
    my $any_ok           = $star_priority && $star_priority > 0.0;

    my $chosen = first {
        my ($priority, $acceptable) = @$_;
        if ( $priority == 0.0 ) {
            $choices = [ grep { lc $acceptable ne $_ } @$choices ];
            return 0;
        } else {
            return any { lc $acceptable eq $_ } @$choices;
        }
    } $accepted->iterable;

    ($chosen && $chosen->[-1])
        ||
    ($any_ok && $choices->[0])
        ||
    ($default_ok && (any { $default eq $_ } @$choices) && $default)
}


1;

__END__

# ABSTRACT: A Moosey solution to this problem

=head1 SYNOPSIS

  use Web::Machine::FSM::ContentNegotiation;

=head1 DESCRIPTION

