#!/pro/bin/perl

use strict;
use warnings;

use Data::Peek;
use Text::CSV_XS;

open my $fh, ">:utf8", "testw.csv";
print $fh qq{1,"\x{2603}3",3\r\n};
close $fh;

open $fh, "<:raw", "testw.csv";

my $csv = Text::CSV_XS->new ({
    auto_diag => 1,
    sep_char => "\xe2",
    allow_loose_escapes => 1,
    allow_loose_quotes => 1,
    #quote_char => undef,
    #escape_char => undef,
    binary => 1,
    });
DDumper ($csv->getline ($fh));

close $fh;
unlink "testw.csv";
