#!/pro/bin/perl

use 5.026002;
use warnings;
use Text::CSV_XS;

my $data = <<"EOC";
a,b,c
d,e
f,g,h
EOC

my $csv = Text::CSV_XS->new ({ strict => 1, auto_diag => 2 });
#use DP;DDumper $csv;
#$csv->_cache_diag ();

my ($foo, $bar, $baz);
$csv->bind_columns (\$foo, \$bar, \$baz);

open my $fh, "<", \$data;
while (my $status = $csv->getline ($fh)) {
    say "Line parsed: foo = $foo, bar = $bar, baz = $baz";
#use DP;DDumper $csv;
#    $csv->_cache_diag ();
    }

$csv->error_input () and
    warn "Error parsing CSV: ", $csv->error_diag (), "\n";
