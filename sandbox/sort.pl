#!/pro/bin/perl

use 5.16.2;
use warnings;

use Text::CSV_XS qw( csv );

my @sorted = sort {
    $a->[5] cmp $b->[5] ||
    $a->[4] cmp $b->[4]
    } @{csv (in => "sorted.csv")};
csv (out => "sorted.csv", in => \@sorted);

csv (in => [ sort { $a->[5] cmp $b->[5] ||
		    $a->[4] cmp $b->[4]
		    } @{csv (in => "sorted.csv")}],
     out => "sorted.csv");
