#!/pro/bin/perl

use 5.14.2;
use warnings;

our $VERSION = "0.01 - 20190314";
our $CMD = $0 =~ s{.*/}{}r;

sub usage {
    my $err = shift and select STDERR;
    say "usage: $CMD ...";
    exit $err;
    } # usage

use CSV;
use Getopt::Long qw(:config bundling);
GetOptions (
    "help|?"		=> sub { usage (0); },
    "V|version"		=> sub { say "$CMD [$VERSION]"; exit 0; },

    "v|verbose:1"	=> \(my $opt_v = 0),
    ) or usage (1);

my $file = "pm1231244.csv";
my $xs = Text::CSV_XS->new ({ strict => 1, auto_diag => 2});
open my $fh, "<", $file or die "$file: $!";
$xs->column_names ([qw( one two three )]);
while (my $line = $xs->getline ($fh)) {
    DDumper ($line);
    }
close $fh;
