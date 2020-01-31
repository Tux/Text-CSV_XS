#!/pro/bin/perl

use 5.16.2;
use warnings;

use Text::CSV_XS;

binmode STDOUT, ":encoding(utf-8)";
binmode STDERR, ":encoding(utf-8)";

my $h = shift // 0;

sub show {
    say join ", " => map { "\x{231e}$_\x{231d}" } @_;
    } # show

my $csv = Text::CSV_XS->new ({ auto_diag => 2 });
if ($h) {
    say "Calling header";
    show ($csv->header (*DATA));
    }

while (my $row = $csv->getline (*DATA)) {
    show (@$row);
    }
say "EOF: ", $csv->eof ? "Yes" : "No";

__DATA__
Foo,Bar,Baz
a,xxx,1
b,"xx"xx", 2"
c, foo , 3
