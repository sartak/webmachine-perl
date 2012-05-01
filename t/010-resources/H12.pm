package H12;
use strict;
use warnings;

use Web::Machine::Util qw[ create_date ];

use parent 'Web::Machine::Resource';

sub content_types_provided { [ { 'text/plain' => sub {} } ] }
sub languages_provided     { [qw[ de ]] }
sub charsets_provided      { [ { 'utf-8' => sub {} } ] }
sub encodings_provided     { +{ 'gzip' => sub {} } }

sub generate_etag { '0xDEADBEEF' }

sub last_modified { create_date( '18 Mar 2012 15:50:00 GMT' ) }

1;