package B7b;
use strict;
use warnings;

use parent 'Web::Machine::Resource';

sub is_authorized { 1 }
sub forbidden { 1 }

1;