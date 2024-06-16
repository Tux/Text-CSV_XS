#!/pro/bin/perl

use 5.014002;
use warnings;

our $VERSION = "0.01 - 20230122";
our $CMD = $0 =~ s{.*/}{}r;

sub usage {
    my $err = shift and select STDERR;
    say "usage: $CMD ...";
    exit $err;
    } # usage

use Data::Peek;
use Text::CSV_XS qw( csv            );
use Getopt::Long qw(:config bundling);
GetOptions (
    "help|?"		=> sub { usage (0); },
    "V|version"		=> sub { say "$CMD [$VERSION]"; exit 0; },

    "v|verbose:1"	=> \(my $opt_v = 0),
    ) or usage (1);

my $fn = "BOM-NH-$$.csv"; END { -f $fn and unlink $fn }

open my $fh, ">:encoding(utf-8)", $fn or die "$fn: $!\n";
say $fh "\N{BOM}foo,bar,baz";
say $fh "1,2,42";
close $fh;

DDumper csv (in => $fn, bom => 1);

DDumper csv (in => $fn, bom => 1, set_column_names => 0);
