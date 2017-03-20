#!/pro/bin/perl

use 5.18.2;
use warnings;
use Text::CSV_XS;

open my $fh,   "<:encoding(utf-8)", \"c1\npr\x{c3}\x{b6}blem\n\n";
binmode STDOUT, ":encoding(utf-8)";

my $csv = Text::CSV_XS->new ({ binary => 1, auto_diag => 1 });
my %row;
$csv->bind_columns (\@row{@{$csv->getline ($fh)}});
while ($csv->getline ($fh)) {
    printf "STRING: >%s< ; LENGTH: %d ; HOTFIX LENGTH: %d\n",
        $row{c1},
        length    $row{c1},
        length "".$row{c1};
    }
