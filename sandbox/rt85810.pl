#!/pro/bin/perl

use strict;
use warnings;

use Text::CSV_XS;
my $csv = Text::CSV_XS->new ({ binary => 1 });
my $str = q{"abc","def"};
$csv->parse ($str);
my $bad_input = $csv->error_input (); # segfaults here
