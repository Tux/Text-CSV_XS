#!/usr/bin/perl -w

use strict;

my ($cols, $rows) = @ARGV;
$cols ||= 10;
$rows ||= 10;

use Text::CSV_XS;

our $csv = Text::CSV_XS->new ({ binary => 1, eol => "\r\n" });

my @f = (
    1, "Text::CSV_XS", $csv->version, "H.Merijn Brand",
    "1 \x{20ac} = 8.012 NOK", undef, "", "'\n,", '"', "Y");

$cols--;
my @row;
push @row, @f for 1 .. int ($cols / 10);
push @row, @f[(10 - $cols % 10) .. 9];

$csv->print (*STDOUT, [ 1..($cols + 1) ]);
$csv->print (*STDOUT, [ $_, @row ]) for 2 .. $rows;
