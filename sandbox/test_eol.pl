#!/pro/bin/perl

use 5.032002;
use warnings;

our $VERSION = "0.01 - 20241217";
our $CMD = $0 =~ s{.*/}{}r;

sub usage {
    my $err = shift and select STDERR;
    say "usage: $CMD ...";
    exit $err;
    } # usage

use lib "lib";
use lib "blib";
use CSV;
use Getopt::Long qw(:config bundling);
GetOptions (
    "help|?"		=> sub { usage (0); },
    "V|version"		=> sub { say "$CMD [$VERSION]"; exit 0; },

    "q|quote!"		=> \ my $opt_q,
    "s|skip!"		=> \(my $opt_s = 0),
    "r|reset!"		=> \(my $opt_r = 0),

    "v|verbose:1"	=> \(my $opt_v = 0),
    ) or usage (1);

my $seol = 2;
@ARGV && $ARGV[0] =~ m/:/ and
    ($seol, $opt_s, $opt_r, $opt_q) = split m/:/ => $ARGV[0];

my $q    = $opt_q ? '"' : "";
my $data = join "" =>
    "Aardvark,${q}snort${q}\r\n",
    "\r\n",
    "Alpaca,${q}spit${q}\r\n",
    "Badger,${q}growl${q}\n",	# No \r
    "Bat,${q}screech${q}\r\n",
    "Bear,${q}roar${q}\r",	# No \n
    "Bee,${q}buzz${q}\r\n",
    "Camel,${q}grunt${q}\r\n",
    "Cobra,${q}shh${q}\r\r",	# \r\r
    "Crow,${q}caw${q}\r\n",
    "Deer,${q}bellow${q}\n",	# No \r
    "Dolphin,${q}click${q}\r\n";
open my $fh, "<", \$data;

my $csv = Text::CSV_XS->new ({
    auto_diag		=> 1,
    diag_verbose	=> 4,
    strict_eol		=> $seol,
    skip_empty_rows	=> $opt_s,
    });

my @csv;
my @wrn;
local $SIG{__WARN__}
while (my $row = $csv->getline ($fh)) {
    DDumper ($row);
    push @csv => [ @$row ];
    $opt_r and $csv->eol (undef);
    }
DDumper { got => \@csv };
DDumper ($csv->error_diag);

