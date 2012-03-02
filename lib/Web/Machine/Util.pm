package Web::Machine::Util;

use strict;
use warnings;

use JSON::XS ();

use Sub::Exporter -setup => {
    exports => [qw[
        true
        false
        is_bool
        unquote_header
    ]]
};

sub true  () { JSON::XS::true()           }
sub false () { JSON::XS::false()          }
sub is_bool  { JSON::XS::is_bool( shift ) }

sub unquote_header {
    my $value = shift;
    if ( $value = /^"(.*)"$/ ) {
        return $1;
    }
    return $value;
}

1;

__END__

# ABSTRACT: A Moosey solution to this problem

=head1 SYNOPSIS

  use Web::Machine::Util;

=head1 DESCRIPTION

