package B3;
use strict;
use warnings;

use parent 'Web::Machine::Resource';

sub allowed_methods { [qw[ GET HEAD OPTIONS ]] }

sub options { +{ 'X-Hello' => 'OH HAI!' } }

1;