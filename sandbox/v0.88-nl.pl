#!/pro/bin/perl

use strict;
use warnings;
use autodie;

use Text::CSV_XS;

my $csv = Text::CSV_XS->new ({binary => 1, auto_diag => 1, eol => "\n" });
my $dta = "";
open my $fh, ">:encoding(utf-8)", \$dta;
$csv->print ($fh, [ $_, "x\n\x{20ac} $_,00\n" x $_ ]) for 0..1024;
close $fh;

open    $fh, "<:encoding(utf-8)", \$dta;
while (my $row = $csv->getline ($fh)) {
    print STDERR "\r", $row->[0], " ";
    }
close $fh;
