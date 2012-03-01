package Web::Machine::Util::ContentNegotiation;

use strict;
use warnings;

use List::AllUtils qw[ first any ];

use Web::Machine::Util::MediaType;
use Web::Machine::Util::MediaTypeList;
use Web::Machine::Util::PriorityList;

use Sub::Exporter -setup => {
    exports => [qw[
        choose_media_type
        choose_language
    ]]
};

sub choose_media_type {
    my ($provided, $header) = @_;
    my $requested = Web::Machine::Util::MediaTypeList->new_from_header_list( split /\s*,\s*/ => $header );
    my $parsed_provided = [ map { Web::Machine::Util::MediaType->new_from_string( $_ ) } @$provided ];

    my $chosen;
    foreach my $request ( $requested->iterable ) {
        my $requested_type = $request->[1];
        $chosen = media_match( $requested_type, $parsed_provided );
        last if $chosen;
    }

    ($chosen || return)
}

sub choose_language {
    my ($provided, $header) = @_;

    my $language;

    if ( scalar @$provided ) {
        my $requested     = Web::Machine::Util::PriorityList->new_from_header_list( split /\s*,\s*/ => $header );
        my $star_priority = $requested->priority_of('*');
        my $any_ok        = $star_priority && $star_priority > 0.0;

        #use Data::Dumper; warn Dumper [ $requested->iterable ];
        #use Data::Dumper; warn Dumper $provided;

        my $accepted      = first {
            my ($priority, $range) = @$_;

            #warn join ", " => ($priority, $range);

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
    }

    $language;
}

# sub choose_encoding {
#     my ($provided, $header) = @_;
#     do_choose( [ keys %$provided ], $header, 'identity' );
# }
#
# sub choose_charset {
#     my ($provided, $header) = @_;
#     if ( @$provided ) {
#         my $charsets = map {  } @$provided;
#     }
# }
#
# sub do_choose {
#     my ($choices, $header, $default) = @_;
#
#     $choices = map { lc $_ } $choices;
#
#     my $accepted         = Web::Machine::Util::PriorityList->new_from_header_list( split /\s*, \s/ => $header );
#     my $default_priority = $accepted->priority_of( $default );
#     my $star_priority    = $accepted->priority_of( '*' );
#     my $default_ok       = ( defined $default_priority && $star_priority != 0.0 ) || $default_priority;
#     my $any_ok           = $star_priority && $star_priority > 0.0;
#
#     my $chosen = find {
#         my ($priority, $acceptable) = @$_;
#         if ( $priority == 0.0 ) {
#             $choices = grep { lc $acceptable ne $_ } @$choices;
#             false;
#         } else {
#             first { lc $acceptable eq $_ } @$choices
#         }
#     } $accepted->iterable;
#
#     ($chosen)
#         ||
#     ($any_ok && $choices->[0])
#         ||
#     ($default_ok && (first { $default eq $_ } @$choices) && $default)
# }

sub media_match {
    my ($requested, $provided) = @_;
    return $provided->[0] if $requested->matches_all;
    return first { $_->match( $requested ) } @$provided;
}

sub language_match {
    my ($range, $tag) = @_;
    ((lc $range) eq (lc $tag)) || $range eq "*" || $tag =~ /^$range\-/i;
}

1;

__END__

# ABSTRACT: A Moosey solution to this problem

=head1 SYNOPSIS

  use Web::Machine::FSM::ContentNegotiation;

=head1 DESCRIPTION

