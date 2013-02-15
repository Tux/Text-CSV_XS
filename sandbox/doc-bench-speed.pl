#!/pro/bin/perl

use 5.016;
use warnings;
use Benchmark qw( cmpthese );

use Text::CSV_XS;

# getline_hr doc

my $data = join "\n", map { join "," => ("foo") x 14 } 1.. 100_000;

cmpthese (4, {
    hashrefs	=> sub {
	my $csv = Text::CSV_XS->new ();
	open my $fh, "<", \$data;
	$csv->column_names ("a" .. "n");
	while (my $row = $csv->getline_hr ($fh)) {}
	},
    getlines	=> sub {
	my $csv = Text::CSV_XS->new ();
	open my $fh, "<", \$data;
	my $row = {};
	$csv->bind_columns (\@{$row}{"a" .. "n"});
	while ($csv->getline ($fh)) {}
	},
    });
