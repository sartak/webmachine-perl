#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Plack::Test;

use HTTP::Request::Common;

use Web::Machine;

my $HTML = '<html><body>Hello World</body></html>';

{
    package My::Resource::String;
    use strict;
    use warnings;

    use parent 'Web::Machine::Resource';

    sub content_types_provided { [{ 'text/html' => 'to_html' }] }

    sub to_html { $HTML }
}

{
    package My::Resource::IO;
    use strict;
    use warnings;

    use parent 'Web::Machine::Resource';

    sub content_types_provided { [{ 'text/html' => 'to_html' }] }

    sub to_html {
        my $str = $HTML;
        open my $fh, '<', \$str;
        return $fh;
    }
}

{
    package My::Resource::Code;
    use strict;
    use warnings;

    use IO::Handle::Util 'io_from_getline';

    use parent 'Web::Machine::Resource';

    sub content_types_provided { [{ 'text/html' => 'to_html' }] }

    sub to_html {
        my $str = $HTML;
        return io_from_getline sub {
            length $str ? substr $str, 0, 1, '' : undef
        };
    }
}

test_psgi
    app    => Web::Machine->new(resource => 'My::Resource::String'),
    client => sub {
        my $cb = shift;

        {
            my $res = $cb->(GET '/');
            ok($res->is_success) || diag($res->content);
            is($res->content, $HTML);
        }
    };

test_psgi
    app    => Web::Machine->new(resource => 'My::Resource::IO'),
    client => sub {
        my $cb = shift;

        {
            my $res = $cb->(GET '/');
            ok($res->is_success) || diag($res->content);
            is($res->content, $HTML);
        }
    };

test_psgi
    app    => Web::Machine->new(resource => 'My::Resource::Code'),
    client => sub {
        my $cb = shift;

        {
            my $res = $cb->(GET '/');
            ok($res->is_success) || diag($res->content);
            is($res->content, $HTML);
        }
    };

done_testing;
