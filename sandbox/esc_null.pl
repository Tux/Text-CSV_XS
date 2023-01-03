#!/pro/bin/perl

use 5.018002;
use warnings;

use Data::Peek;
use Text::CSV_XS;

foreach my $enl (1, 0) {
    foreach my $esc ('"', undef) {
	my $csv = Text::CSV_XS->new ({
	    binary      => 1,
	    auto_diag   => 1,
	    escape_char => $esc,
	    escape_null => $enl,
	    });

	open my $fh, ">", \my $dta;
	$csv->print ($fh, [ "\x00" ]);
	close $fh;

	DHexDump $dta;
	}
    }
