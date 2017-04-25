#!/pro/bin/perl

use 5.18.1;
use warnings;
use Text::CSV_XS;

my $data = <<"__CSV__";
owner,admin
1,1
2
3,
4,4
__CSV__

open my $fh, "<", \$data;

my $csv = Text::CSV_XS->new ({ auto_diag => 1, strict => 1 });
my %row;
$csv->bind_columns (\@row{@{$csv->getline ($fh)}});
while ($csv->getline ($fh)) {
    printf "owner: %s ; admin: %s\n", $row{owner}, $row{admin};
    }
__END__

OUTPUT:
owner: 1 ; admin: 1
owner: 2 ; admin: 1
owner: 3 ; admin: 
owner: 4 ; admin: 4
