#!/pro/bin/perl

use 5.14.1;
use warnings;

use Data::Peek;
use Spreadsheet::Read;
use Text::CSV_XS;

my $book  = Spreadsheet::Read->new ("pm1226189.xlsx") or
    die "Cannot read spreadsheet: $!\n";
my $sheet = $book->sheet (1) or die "Book has no sheets\n";

my $csv = Text::CSV_XS->new ({
    binary           => 1,
    auto_diag        => 1,
    allow_whitespace => 1,
    });

my @data;
foreach my $col (1 .. $sheet->maxcol) {
    foreach my $row (1 .. $sheet->maxrow) {
	my $cell = $sheet->cell ($col, $row);
	if ($cell && $cell =~ m/,/) {
	    open my $fh, "<", \$cell;
	    $data[$col][$row] = $csv->getline ($fh);
	    close $fh;
	    }
	else {
	    $data[$col][$row] = $cell;
	    }
	}
    }
DDumper \@data;
