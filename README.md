# NAME

Web::Machine - A Perl port of Webmachine

# VERSION

version 0.17

# SYNOPSIS

    use strict;
    use warnings;

    use Web::Machine;

    {
        package HelloWorld::Resource;
        use strict;
        use warnings;

        use parent 'Web::Machine::Resource';

        sub content_types_provided { [{ 'text/html' => 'to_html' }] }

        sub to_html {
            q{<html>
                <head>
                    <title>Hello World Resource</title>
                </head>
                <body>
                    <h1>Hello World</h1>
                </body>
             </html>}
        }
    }

    Web::Machine->new( resource => 'HelloWorld::Resource' )->to_app;

# DESCRIPTION

`Web::Machine` provides a RESTful web framework modeled as a state
machine. You define one or more resource classes. Each resource represents a
single RESTful URI end point, such as a user, an email, etc. The resource
class can also be the target for `POST` requests to create a new user, email,
etc.

Each resource is a state machine, and each request for a resource is handled
by running the request through that state machine.

`Web::Machine` is built on top of [Plack](https://metacpan.org/pod/Plack), but it handles the full request
and response cycle.

See [Web::Machine::Manual](https://metacpan.org/pod/Web::Machine::Manual) for more details on using `Web::Machine` in
general, and how `Web::Machine` and [Plack](https://metacpan.org/pod/Plack) interact.

This is a port of [Webmachine](https://github.com/basho/webmachine), actually
it is much closer to [the Ruby
version](https://github.com/seancribbs/webmachine-ruby), with a little bit of
[the JavaScript version](https://github.com/tautologistics/nodemachine) and
even some of [the Python version](https://github.com/benoitc/pywebmachine)
thrown in for good measure.

You can learn a bit about Web::Machine's history from the slides for my [2012
YAPC::NA talk](https://speakerdeck.com/stevan_little/rest-from-the-trenches).

To learn more about Webmachine, take a look at the links in the SEE ALSO
section.

# METHODS

NOTE: This module is a [Plack::Component](https://metacpan.org/pod/Plack::Component) subclass and so follows the interface
set forward by that module.

- `new( resource => $resource_classname, ?resource_args => $arg_list, ?tracing => 1|0, ?streaming => 1|0, ?request_class => $request_class )`

    The constructor expects to get a `$resource_classname`, which it will use to
    load and create an instance of the resource class. If that class requires any
    additional arguments, they can be specified with the `resource_args`
    parameter. The contents of the `resource_args` parameter will be made
    available to the `init()` method of `Web::Machine::Resource`.

    The `new` method can also take an optional `tracing` parameter which it will
    pass on to [Web::Machine::FSM](https://metacpan.org/pod/Web::Machine::FSM) and an optional `streaming` parameter, which
    if true will run the request in a [PSGI](http://plackperl.org/) streaming
    response. This can be useful if you need to run your content generation
    asynchronously.

    The optional `request_class` parameter accepts the name of a module that will
    be used as the request object. The module must be a class that inherits from
    [Plack::Request](https://metacpan.org/pod/Plack::Request). Use this if you have a subclass of [Plack::Request](https://metacpan.org/pod/Plack::Request) that
    you would like to use in your [Web::Machine::Resource](https://metacpan.org/pod/Web::Machine::Resource).

- `inflate_request( $env )`

    This takes a raw PSGI `$env` and inflates it into a [Plack::Request](https://metacpan.org/pod/Plack::Request) instance.
    By default this also uses [HTTP::Headers::ActionPack](https://metacpan.org/pod/HTTP::Headers::ActionPack) to inflate the headers
    of the request to be complex objects.

- `create_fsm`

    This will create the [Web::Machine::FSM](https://metacpan.org/pod/Web::Machine::FSM) object to run. It will get passed
    the value of the `tracing` constructor parameter.

- `create_resource( $request )`

    This will create the [Web::Machine::Resource](https://metacpan.org/pod/Web::Machine::Resource) instance using the class specified
    in the `resource` constructor parameter. It will pass in the `$request` object
    and call `new_response` on the `$request` object to get a [Plack::Response](https://metacpan.org/pod/Plack::Response)
    instance.

- `finalize_response( $response )`

    Given a `$response` which is a [Plack::Response](https://metacpan.org/pod/Plack::Response) object, this will finalize
    it and return a raw PSGI response.

- `call( $env )`

    This is the `call` method overridden from the [Plack::Component](https://metacpan.org/pod/Plack::Component) superclass.

# DEBUGGING

If you set the `WM_DEBUG` environment variable to `1` we will print
out information about the path taken through the state machine to STDERR.

If you set `WM_DEBUG` to `diag` then debugging information will be printed
using [Test::More](https://metacpan.org/pod/Test::More)'s `diag()` sub instead.

# SEE ALSO

- The diagram - [https://github.com/Webmachine/webmachine/wiki/Diagram](https://github.com/Webmachine/webmachine/wiki/Diagram)
- Original Erlang - [https://github.com/basho/webmachine](https://github.com/basho/webmachine)
- Ruby port - [https://github.com/seancribbs/webmachine-ruby](https://github.com/seancribbs/webmachine-ruby)
- Node JS port - [https://github.com/tautologistics/nodemachine](https://github.com/tautologistics/nodemachine)
- Python port - [https://github.com/benoitc/pywebmachine](https://github.com/benoitc/pywebmachine)
- 2012 YAPC::NA slides - [https://speakerdeck.com/stevan\_little/rest-from-the-trenches](https://speakerdeck.com/stevan_little/rest-from-the-trenches)
- an elaborate machine is indispensable: a blog post by Justin Sheehy - [http://blog.therestfulway.com/2008/09/webmachine-is-resource-server-for-web.html](http://blog.therestfulway.com/2008/09/webmachine-is-resource-server-for-web.html)
- Resources, For Real This Time (with Webmachine): a video by Sean Cribbs - [http://www.youtube.com/watch?v=odRrLK87s\_Y](http://www.youtube.com/watch?v=odRrLK87s_Y)

# SUPPORT

bugs may be submitted through [https://github.com/houseabsolute/webmachine-perl/issues](https://github.com/houseabsolute/webmachine-perl/issues).

# AUTHORS

- Stevan Little &lt;stevan@cpan.org>
- Dave Rolsky &lt;autarch@urth.org>

# CONTRIBUTORS

- Andreas Marienborg &lt;andreas.marienborg@gmail.com>
- Andrew Nelson &lt;anelson@cpan.org>
- Arthur Axel 'fREW' Schmidt &lt;frioux@gmail.com>
- Carlos Fernando Avila Gratz &lt;cafe@q1software.com>
- Fayland Lam &lt;fayland@gmail.com>
- George Hartzell &lt;hartzell@alerce.com>
- Gregory Oschwald &lt;goschwald@maxmind.com>
- Jesse Luehrs &lt;doy@tozt.net>
- John SJ Anderson &lt;genehack@genehack.org>
- Mike Raynham &lt;enquiries@mikeraynham.co.uk>
- Nathan Cutler &lt;ncutler@suse.cz>
- Olaf Alders &lt;olaf@wundersolutions.com>
- Stevan Little &lt;stevan.little@gmail.com>
- Thomas Sibley &lt;tsibley@cpan.org>

# COPYRIGHT AND LICENCE

This software is copyright (c) 2016 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
