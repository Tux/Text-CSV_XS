#!/pro/bin/perl

use strict;
use warnings;
use autodie;

use Text::CSV_XS;
use Spreadsheet::Read;

my $ss  = ReadData (shift // "pivot.csv")->[1];
my $csv = Text::CSV_XS->new ({ binary => 1, auto_diag => 1, eol => "\r\n" });

$csv->print (*STDOUT, [@{$ss->{cell}[$_]}[1..$ss->{maxrow}]]) for 1 .. $ss->{maxcol};
