#!/pro/bin/perl

use 5.12.2;
use warnings;

use Text::CSV_XS;

my $csv  = Text::CSV_XS->new ({ binary => 1, always_quote => 1, eol => "\n" });
my $data = "x";
$csv->bind_columns (\$data);

#open my $fh, ">", "text-csv_xs-print.csv";
$csv->say (*STDOUT, undef);
#print $fh "\n";
