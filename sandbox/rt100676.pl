#!/pro/bin/perl

use 5.018002;
use warnings;

use autodie;
use Data::Peek;
use Text::CSV_XS;

my $csv = Text::CSV_XS->new ({
    auto_diag          =>  1,
    diag_verbose       =>  9,
    binary             =>  1,
    keep_meta_info     => 11,
    quote_space        =>  0,
    quote_binary       =>  0,
    decode_utf8        =>  0,
    allow_loose_quotes =>  1,
    });

my $line = "Hello,World,\x13Field\x13With\x13Control\x13Chars";

DPeek $line;

$csv->parse ($line);
my @fld = $csv->fields;
DPeek for @fld;

$csv->combine (@fld);
DPeek $csv->string;
say $csv->string;
