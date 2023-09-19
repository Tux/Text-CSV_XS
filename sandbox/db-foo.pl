#!/pro/bin/perl

use strict;
use warnings;

use Text::CSV_XS;
use PROCURA::DBD;

my $dbh = DBDlogon (0);
my $tbl = "foo";

my $csv = Text::CSV_XS->new ({ binary => 1, eol => $/ });
open my $fh, ">", "$tbl.csv" or die "$tbl.csv: $!";
my $sth = $dbh->prepare ("select * from $tbl");
$sth->execute;
$csv->print ($fh, $sth->{NAME_lc});
while (my $row = $sth->fetch) {
    $csv->print ($fh, $row);
    }
close $fh;

