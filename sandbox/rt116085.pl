#!/pro/bin/perl

use 5.018002;
use warnings;

use Data::Peek;
use Text::CSV_XS;

my $csv = Text::CSV_XS->new ({ auto_diag => 1 });
open my $fh, "<", "/tmp/hello.csv";

#DDumper $csv;
my $r = $csv->getline_all ($fh, 9000, 0);
#DDumper $csv;
