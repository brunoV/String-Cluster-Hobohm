package String::Cluster::Hobohm::Types;
use strict;
use warnings;

# ABSTRACT: Specific types for String::Cluster::Hobohm;

use MouseX::Types -declare => ['Quotient'];
use MouseX::Types::Mouse 'Num';

subtype Quotient, as Num, where { $_ >= 0 && $_ <= 1 };

1;
