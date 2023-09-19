#!perl

use strict;
use warnings;

use Test::More;
use Text::CSV_XS;

my $csv = Text::CSV_XS->new ({
    binary             => 1,
    sep_char           => "|",
    allow_loose_quotes => 1,
    auto_diag          => 1,
    });

my $fh = \*DATA;
$csv->column_names (@{$csv->getline ($fh)});

my $nbr_lines = 0;
$nbr_lines++ while (my $row = $csv->getline ($fh));

is ($nbr_lines, 3, "processed expected number of lines");

done_testing ();

__DATA__
first|second|third|fourth|fifth|sixth|seventh|eigth|ninth|tenth|eleventh|twelth|thriteenth|fourteenth|fifteenth|sixteenth|seventeenth|eighteenth|nineteenth
1|||||||156999||12 Valley||D||N|3610|||68 V D|EA MATCH
2|||||||195658|"""The Cottage"" 54"|"""The "|K|||||307652|R, M|"""The ", K, |EA MATCH
3|||||||216058|117 The K|||||||||117 The K, |EA MATCH
