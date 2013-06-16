#!/pro/bin/perl

use 5.016;
use warnings;

use Test::More;
use Data::Peek;
use Text::CSV_XS;

my $data = join "\r" =>
    qq{1,"aap",3},
    qq{2,"noot",5},
    qq{3,"mies",7};

ok (my $csv = Text::CSV_XS->new ({ binary => 1 }), "new csv");

ok (open (my $fh, "<", \$data), "open < data");

ok (my $r = $csv->getline_all ($fh), "getline_all");

is (ref $r,    "ARRAY", "ref is ARRAY");
is (scalar @$r, 3,      "Three lines");
is ($r->[0][0], 1,      "(0, 0)");
is ($r->[1][1], "noot", "(1, 1)");
is ($r->[2][2], 7,      "(2, 2)");

DDumper $r;

done_testing ();
