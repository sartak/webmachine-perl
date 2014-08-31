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
