#!/pro/bin/perl

use 5.018002;
use warnings;

use Data::Peek;
use Text::CSV;

my $csv = Text::CSV->new ({
    escape_char		=> "\\",
    allow_loose_escapes	=> 1,
    auto_diag		=> 1,
    });

$csv->parse (q{"error, a\' string"});
DDumper [ $csv->fields ];
