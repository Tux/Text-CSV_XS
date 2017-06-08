#!/pro/bin/perl

use 5.18.2;
use warnings;

use Data::Peek;
use Text::CSV_XS qw( csv );

my $file = "pm-la-1.csv";
-d "sandbox" and substr $file, 0, 0, "sandbox/";
open my $fh, "<", $file or die "Can't open $file $!";

my $list = csv (
    in       => $file,
    sep_char => "|",
    headers  => [ "item", "seen in" ],
    key      => "item",
    );

DDumper $list;
