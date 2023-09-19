#!/pro/bin/perl

use 5.018002;
use warnings;
use Text::CSV_XS;
my $csv = Text::CSV_XS->new ({binary => 1, auto_diag => 1, eol => $/});
my $header_rec = $csv->getline (*DATA) or die $csv->error_diag ();
$csv->parse ($header_rec) or die $csv->error_diag ();
my @columns = $csv->fields ();
say for @columns;
__END__
"Entry Type","Cust ID",Company,"Item ID","Item Ident","Kit ID","Kit Ident","Date Sync",Notes
