#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Encode qw( decode is_utf8 );
use HTTP::Message::PSGI;
use HTTP::Request::Common qw( GET );
use Plack::Util;

use Web::Machine;

my $tb = Test::Builder->new;
binmode $_, ':encoding(UTF-8)'
    for $tb->output, $tb->failure_output, $tb->todo_output;

{
    package My::Resource::Test022::Base;
    use strict;
    use warnings;

    use Encode qw( encode );

    use parent 'Web::Machine::Resource';

    sub allowed_methods { [qw[ GET ]] }
    sub content_types_provided { [ { 'text/plain' => 'body' } ] }

    # The o with umlauts is encoded as 0xc3 0xb6 in UTF-8 and as 0xf6 in
    # ISO-8859-1.
    our $Body = do {
        use utf8;
        "Hellö Wörld";
    };

    sub body {
        my $self = shift;

        if ( $self->request->parameters->{stream} ) {
            my $bytes = encode( 'UTF-8', $Body );
            open my $fh, '<:encoding(UTF-8)', \$bytes;
            return $fh;
        }
        else {
            return $Body;
        }
    }
}

{
    package My::Resource::Test022::Pairs;
    use strict;
    use warnings;

    use Encode qw( encode );

    use parent -norequire, 'My::Resource::Test022::Base';

    sub encodings_provided {
        return {
            identity => sub { $_[1] },
            'add-x'  => sub { $_[1] . 'x' },
        };
    }

    sub charsets_provided {
        return [
            {
                'UTF-8' => sub { encode( 'UTF-8', $_[1] ) }
            },
            {
                'ISO-8859-1' => sub { encode( 'ISO-8859-1', $_[1] ) }
            },
        ];
    }

    sub default_charset {
        return {
            'UTF-8' => sub { encode( 'UTF-8', $_[1] ) }
        };
    }
}

{
    package My::Resource::Test022::Strings;
    use strict;
    use warnings;

    use parent -norequire, 'My::Resource::Test022::Base';

    sub charsets_provided {
        return [qw( UTF-8 ISO-8859-1 )];
    }

    sub default_charset {
        return 'UTF-8';
    }
}

# In order to test this properly we can't use test_psgi. That passes the
# response through HTTP::Response, which ends up doing an unconditional call
# to utf8::downgrade on the reponse body. That makes it hard to test how
# encodings are being handled!
ok(
    is_utf8($My::Resource::Test022::Base::Body),
    'text in resource is marked as UTF-8'
);

my %tests = (
    'UTF-8' => [
        0x48,    # H
        0x65,    # e
        0x6c,    # l
        0x6c,    # l
        0xc3,    # [UTF-8 o with umlauts - byte 1]
        0xb6,    # [UTF-8 o with umlauts - byte 2]
        0x20,    # [space]
        0x57,    # W
        0xc3,    # [UTF-8 o with umlauts - byte 1]
        0xb6,    # [UTF-8 o with umlauts - byte 2]
        0x72,    # r
        0x6c,    # l
        0x64,    # d
    ],
    'ISO-8859-1' => [
        0x48,    # H
        0x65,    # e
        0x6c,    # l
        0x6c,    # l
        0xf6,    # [ISO-8859-1 o with umlauts]
        0x20,    # [space]
        0x57,    # W
        0xf6,    # [ISO-8859-1 o with umlauts]
        0x72,    # r
        0x6c,    # l
        0x64,    # d
    ],
);

for my $resource (qw( Pairs Strings )) {
    my $app = Web::Machine->new(
        resource => 'My::Resource::Test022::' . $resource )->to_app;

    my $desc = $resource;
    for my $stream ( 0, 1 ) {
        $desc .= $stream ? ' - body as stream' : ' - body as arrayref';

        for my $charset ( sort keys %tests ) {
            test_charset(
                app            => $app,
                charset        => $charset,
                charset_header => 1,
                bytes          => $tests{$charset},
                stream         => $stream,
                description    => "$desc - $charset",
            );
        }

        test_charset(
            app            => $app,
            charset        => 'UTF-8',
            charset_header => 0,
            bytes          => $tests{'UTF-8'},
            stream         => $stream,
            description    => "$desc - no Accept-Charset header",
        );

        next if $resource eq 'Strings';

        test_encoding(
            app         => $app,
            stream      => $stream,
            description => "$desc - encoding test",
        );
    }
}

done_testing;

sub test_charset {
    my %args = @_;

    my $uri = _uri(%args);

    my @headers
        = $args{charset_header} ? ( 'Accept-Charset' => $args{charset} ) : ();
    my $env = GET( $uri, @headers )->to_psgi;

    my $response = $args{app}->($env);

    ok(
        $response->[0],
        "status code is 200 - $args{description}"
    );

    my $body = _body( $response, $args{stream} );

    ok(
        !is_utf8($body),
        "body is bytes, not characters -  - $args{description}"
    );

    is(
        decode( $args{charset}, $body ),
        $My::Resource::Test022::Base::Body,
        "body decoded as $args{charset} matches original - $args{description}"
    );

    is_deeply(
        [ map { ord($_) } split //, $body ],
        $args{bytes},
        "body contains the expected $args{charset} bytes - $args{description}"
    );

    unless ($args{stream}) {
        is(
            Plack::Util::header_get($response->[1], "content-length"),
            scalar @{$args{bytes}},
            "content-length matches the expected number of $args{charset} bytes - $args{description}"
        );
    }
}

sub test_encoding {
    my %args = @_;

    my $uri = _uri(%args);
    my $env = GET(
        $uri,
        'Accept-Charset'  => 'UTF-8',
        'Accept-Encoding' => 'add-x',
    )->to_psgi;

    my $response = $args{app}->($env);

    ok(
        $response->[0],
        "status code is 200 - $args{description}"
    );

    my $body = _body( $response, $args{stream} );
    ok(
        !is_utf8($body),
        "body is bytes, not characters - $args{description}"
    );

    is(
        decode( 'UTF-8', $body ),
        $My::Resource::Test022::Base::Body . 'x',
        "body has an x at the end with add-x encoding - $args{description}"
    );
}

sub _uri {
    my %args = @_;
    return $args{stream} ? '/?stream=1' : '/';
}

sub _body {
    my $response = shift;
    my $stream   = shift;

    if ($stream) {
        return do {
            my $fh = $response->[2];
            local $/;
            <$fh>;
        };
    }
    else {
        return join q{}, @{ $response->[2] };
    }
}
