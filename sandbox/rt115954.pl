#!/pro/bin/perl

use 5.18.2;
use warnings;
use Text::CSV_XS;

my $data = <<"EOD";
1,bad to the bone,foo
2,"bad "to the" bone",bar
3,""bad to the bone"",baz
EOD

my $csv = Text::CSV_XS->new ({ binary => 1, allow_loose_escapes => 1 });
open my $fh, "<", \$data;
while (my $r = $csv->getline ($fh)) {
    say "@$r";
    }
+$csv->error_diag and say "ERROR";
$csv->eof and say "EOF";
say join " " => $csv->error_diag;

__END__
At first I thought I was crazy and hadn't encountered what I thought I did.
But then I was able to reproduce it minimally:

$ cat badcsv.csv
1,bad to the bone,foo
2,"bad "to the" bone",bar
3,""bad to the bone"",baz

$ cat badcsv.pl
use strict;
use 5.010;
use Text::CSV_XS;
my $csv = Text::CSV_XS->new({ binary => 1, allow_loose_escapes => 1 });
while (my $r = $csv->getline(\*STDIN)){
  say "@$r";
}
say "EOF" if $csv->eof;
say join " ", $csv->error_diag;

$ perl badcsv.pl < badcsv.csv
1 bad to the bone foo
2 bad "to the" bone bar
EOF
2027 EIQ - Quoted field not terminated 26 3 2
