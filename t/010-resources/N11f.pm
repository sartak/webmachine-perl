package N11f;
use strict;
use warnings;

use parent 'Web::Machine::Resource';

sub allowed_methods        { [qw[ GET HEAD PUT POST ]] }
sub content_types_provided { [ { 'text/plain' => sub {} } ] }
sub languages_provided     { [qw[ en ]] }
sub charsets_provided      { [ { 'utf-8' => sub {} } ] }
sub resource_exists        { 0 }
sub previously_existed     { 1 }
sub allow_missing_post     { 1 }
sub post_is_create         { 0 }

sub process_post {
    (shift)->response->redirect( '/foo/bar/baz' );
    1;
}

1;
