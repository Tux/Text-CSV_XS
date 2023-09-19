#!/pro/bin/perl

use strict;
use warnings;

use Test::More;
use Data::Peek;
use Text::CSV_XS;

diag "$Text::CSV_XS::VERSION\n";

for my $eol ("\n", "\r", "!") {
    print "--\n";

    ok (my $csv = Text::CSV_XS->new ({
	binary    => 1,
	sep_char  => ":",
	#eol       => $eol,
	auto_diag => 1,
	}), "new csv");
    $eol eq "!" and $csv->eol ($eol);

    my $file = join $eol => qw( "a":"b" "c":"d" );
    diag DHexDump $file;
    open my $fh, "<", \$file or die;

    while (my $pair = $csv->getline ($fh)) {
	print "@$pair\n";
	}
    }

done_testing;
