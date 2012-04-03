package Web::Machine;
# ABSTRACT: A Perl port of WebMachine

use strict;
use warnings;

1;

__END__

=head1 SYNOPSIS

  use Web::Machine;

=head1 DESCRIPTION

This is a port of L<Webmachine|https://github.com/basho/webmachine>,
actually it is much closer to L<the ruby version|https://github.com/seancribbs/webmachine-ruby>, with
a little bit of L<the javascript version|https://github.com/tautologistics/nodemachine>
and even some of L<the python version|https://github.com/davisp/pywebmachine>
thrown in for good measure.

It runs atop the L<Plack> framework, but since it really handles the whole
HTTP transaction, it is not appropriate to use most middleware modules.
(NOTE: I will write more about this in the future.)

=head1 CAVEAT

This module is extremely young and it is a port of an pretty young (June 2011)
module in another language (ruby), which itself is a port of a still kind of
young module (March 2009) in yet another language (erlang). But that all said,
it really seems like a sane idea and so I stole it and ported it to Perl.

=head1 SEE ALSO

=over 4

=item Original Erlang - L<https://github.com/basho/webmachine>

=item Ruby port - L<https://github.com/seancribbs/webmachine-ruby>

=item Node JS port - L<https://github.com/tautologistics/nodemachine>

=item Python port - L<https://github.com/davisp/pywebmachine>

=back