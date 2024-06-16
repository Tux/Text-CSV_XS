#!/pro/bin/perl

use 5.14.2;
use warnings;

our $VERSION = "0.01 - 20200604";
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

use charnames ":full";
use Encode qw(encode decode);

binmode STDOUT, ":encoding(utf-8)";

foreach my $c (0x0100 .. 0xffff) {
    my $u = chr $c;
    my $n = charnames::viacode ($c)	or next;
    length ($n) < 15			or next;
    my $b = encode ("utf-8", $u);
    length ($b) == 2			or next;
    my @b = unpack "C*" => $b;
    printf "%04x %02x %02x %s\n", $c, @b, $n;
    }
