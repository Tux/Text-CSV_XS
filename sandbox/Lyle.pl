#!/pro/bin/perl

use strict;
use warnings;

use Text::CSV;
use Data::Peek;

for (1, 2) {
    foreach my $sep (",", "\t") {
	my $csv = Text::CSV->new ({
	    binary		=> 1,
	    sep_char		=> $sep,
	    escape_char		=> undef,
	    allow_whitespace	=> 1,
	    allow_loose_quotes	=> 1,
	    });

	print "-- Testing Lyle-$_ with ", DDisplay ($sep), "\n";
	open my $ifh, "<", "Lyle-$_.txt";

	if (my $row = $csv->getline ($ifh)) {
	    print "PASS: (@$row)\n";
	    }
	else {
	    print "FAIL: ";
	    $csv->error_diag;
	    }
	}
    }
