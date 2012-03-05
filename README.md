## Web::Machine

This is a port of [Webmachine](https://github.com/basho/webmachine),
actually it is much closer to
[the ruby version](https://github.com/seancribbs/webmachine-ruby), with
a little bit of [the javascript version](https://github.com/tautologistics/nodemachine)
and even some of [the python version](https://github.com/davisp/pywebmachine)
thrown in for good measure.

It runs atop the [Plack](https://www.metacpan.org/module/Plack) framework,
but since it really handles the whole HTTP transaction, it is not appropriate
to use most middleware modules. (NOTE: I will write more about this in the
future.)

## Getting Started

This module is extremely young and it is a port of an pretty young (June 2011)
module in another language (ruby), which itself is a port of a still kind of
young module (March 2009) in yet another language (erlang). But that all said,
it really seems like a sane idea and so I stole it and ported it to Perl.

NOTE: More details to come, but for now, this is all.



