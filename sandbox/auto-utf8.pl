#!/pro/bin/perl

use 5.014000;
use warnings;

use Data::Peek;
use Text::CSV_XS;

my $data = join "" => <DATA>;

my $csv = Text::CSV_XS->new ({ binary => 1, auto_diag => 1 });

open my $fh, "<", \$data;
while (my $row = $csv->getline ($fh)) {
    DPeek $row->[1];
    }
close $fh;
say "--";

$csv->bind_columns (\my ($f1, $f2, $f3));
open    $fh, "<", \$data;
while ($csv->getline ($fh)) {
    DPeek $f2;
    }
close $fh;

__END__
1,aap,2
1,áap,2
1,Ã¡ap,2
1,aap,2
1,áap,2
1,Ã¡ap,2
