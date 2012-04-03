package O18b;
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
sub multiple_choices       { 1 }

sub process_post {
    (shift)->response->body( "HELLO WORLD" );
    1;
}

1;
