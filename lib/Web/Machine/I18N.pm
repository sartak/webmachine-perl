package Web::Machine::I18N;
# ABSTRACT: The I18N support for HTTP information

use strict;
use warnings;

use parent 'Locale::Maketext';

our $VERSION = '0.18';

1;

__END__

=head1 SYNOPSIS

  use Web::Machine::I18N;

=head1 DESCRIPTION

This is basic support for internationalization of HTTP
information. Currently it just provides response bodies
for HTTP errors.






