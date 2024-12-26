#!/pro/bin/perl

use 5.014002;
use warnings;

our $VERSION = "0.01 - 20241224";
our $CMD = $0 =~ s{.*/}{}r;

sub usage {
    my $err = shift and select STDERR;
    say "usage: $CMD ...";
    exit $err;
    } # usage

use Text::CSV_XS qw( csv);
use Getopt::Long qw(:config bundling);
GetOptions (
    "help|?"            => sub { usage (0); },
    "V|version"         => sub { say "$CMD [$VERSION]"; exit 0; },

    "n=i"		=> \(my $N = 10),

    "v|verbose:1"       => \(my $opt_v = 0),
    ) or usage (1);

my $fni = "streaming-i-$$.csv";
my $fno = "streaming-o-$$.csv";

open my $fh, ">", $fni;
say $fh qq{ID,product,price USD};
printf $fh "%d,Product %d,%1.2f\n", $_, $_, rand (200000) / 100 for 1 .. $N;
close $fh;

my ($I, $O);
my $co = Text::CSV_XS->new ({
    eol       => "\n",
    auto_diag => 1,
    callbacks => {
      before_print => sub {
        say "O: ",++$O;
        $_[1][2] =~ s/USD$/EUR/ or $_[1][2] = sprintf "%1.2f", $_[1][2] * 0.96;
        },
      },
    });
open my $fho, ">", $fno;
csv (
    in        => $fni,
    out       => undef,
    callbacks => {
      after_parse  => sub {
        say "I: ",++$I;
        $co->print ($fho, $_[1]);
        },
      },
    );
close $fno;

unlink $fno;

csv (in => $fni, out => $fno, quote_space => 0);
system "cat -ve $fni";
system "cat -ve $fno";

unlink $fni, $fno;
