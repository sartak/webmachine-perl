package B8;
use strict;
use warnings;

use parent 'Web::Machine::Resource';

sub is_authorized { 'Basic realm="Test"' }

1;