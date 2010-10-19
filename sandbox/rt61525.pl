#!/pro/bin/perl

use strict;
use warnings;

use Text::CSV_XS;

print "$Text::CSV_XS::VERSION\n";

for my $eol ("\n", "\r", "!") {
    print "--\n";

    my $csv = Text::CSV_XS->new ({
	binary    => 1,
	sep_char  => ":",
	eol       => $eol,
	auto_diag => 1,
	});
    #$eol eq "!" and $csv->eol ($eol);

    my $file = join $eol => qw( "a":"b" "c":"d" );
    open my $fh, "<", \$file or die;

    while (my $pair = $csv->getline ($fh)) {
	print "@$pair\n";
	}
    }
