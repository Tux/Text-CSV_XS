#!/pro/bin/perl

use 5.016000;
use warnings;

use lib qw( blib/lib blib/arch );

use Text::CSV_XS;
use Time::HiRes qw( gettimeofday tv_interval );

our $csv = Text::CSV_XS->new ({ eol => "\n" });

my $bigfile = "_file.csv";
our @fields1 = (
    "Wiedmann", "Jochen",
    "Am Eisteich 9",
    "72555 Metzingen",
    "Germany",
    "+49 7123 14881",
    "joe\@ispsoft,de");
our @fields10  = (@fields1) x 10;

my $n = 500_000;
my $np = shift // 85000;
my $ng = shift // 85000;

open our $io, ">", $bigfile;
$csv->print ($io, \@fields10) or die "Cannot print ()\n";
my $t0 = [ gettimeofday ];
$csv->print ($io, \@fields10) for 1 .. $n;
my $d = $n / tv_interval ($t0);
close $io;
printf "print  : %10.2f %8.3f\n", $d, $d / $np;
-s $bigfile or die "File is empty!\n";
my @f = @fields10;
$csv->bind_columns (\(@f));
open    $io, "<", $bigfile;
$t0 = [ gettimeofday ];
$csv->getline ($io) for 1 .. $n;
$d = $n / tv_interval ($t0);
close   $io;
printf "getline: %10.2f %8.3f\n", $d, $d / $np;
unlink $bigfile;
