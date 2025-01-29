#!/pro/bin/perl

use 5.026002;
use warnings;

use Data::Peek;
use Text::CSV_XS;

my $csv_file = "issue-62.csv";
-d "sandbox" and substr $csv_file, 0, 0, "sandbox/";

my $csv = Text::CSV_XS->new ({ strict => 1, auto_diag => 1 });
open my $fh, "<:encoding(utf8)", $csv_file or die "$csv_file: $!";

my @input_colnames = @{$csv->getline ($fh)};
say "CSV Header : (@input_colnames)";
my $col_val_of_    = {};

DDumper $csv->{_BOUND_COLUMNS};
$csv->bind_columns (\@{$col_val_of_}{@input_colnames});

DDumper $csv->{_BOUND_COLUMNS};
$csv->getline ($fh);

DDumper $csv->{_BOUND_COLUMNS};
