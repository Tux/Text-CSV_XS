#!/pro/bin/perl

use 5.18.2;
use warnings;

use Text::CSV_XS;

my $csv = Text::CSV_XS->new ({ auto_diag => 1 });
my $foo;
$csv->bind_columns (\$foo);
$csv->parse ('foo "bar"');
