#!/pro/bin/perl

use 5.014001;
use warnings;

use Text::CSV_XS;
use Benchmark qw(:all);

my @data = ("aa" .. "zz");
open my $io, ">", "/dev/null";
my $csv = Text::CSV_XS->new ({ eol => "\n" });
$csv->bind_columns (\(@data));

cmpthese (1000, {
    "ref"	=> sub { $csv->print ($io, \@data ) for 1..100 },
    "copy"	=> sub { $csv->print ($io, [@data]) for 1..100 },
    "bind"	=> sub { $csv->print ($io,  undef ) for 1..100 },
    });
