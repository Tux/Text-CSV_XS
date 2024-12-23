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
use Term::ANSIColor;
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
    ($seol, $opt_s, $opt_r, $opt_q) = split m/:/ => $ARGV[0] =~ s/^://r;

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

my $attr = {
    auto_diag		=> 1,
    diag_verbose	=> 4,
    strict_eol		=> 0 + ($seol  || 0),
    skip_empty_rows	=> 0 + ($opt_s || 0),
    };
my $csv = Text::CSV_XS->new ($attr);

binmode STDOUT, ":encoding(utf-8)";

sub tag { colored (shift, "bold") . ":" }
my $M = color ("bold dark red on_white");
my $B = color ("blue on_bright_white");
my $R = color ("reset");

my @csv;
my @wrn;
{   local $SIG{__WARN__} = sub { push @wrn => [ @_ ] };
    while (my $row = $csv->getline ($fh)) {
	$opt_v > 1 and DDumper ($row);
	push @csv => [ @$row ];
	$opt_r and $csv->eol (undef);
	}
    }

say   tag ("ATTR");
printf "  %-15s => %1d\n", $_, $attr->{$_} for sort keys %$attr;
print tag ("IN"), "\n", $data =~ s/\r/$B\x{240d}$R/gr =~ s/\n/$M\x{240a}$R\n/gr;
say   join "\n" => tag ("ERR"), map { "  $_" } $csv->error_diag;
print tag ("WARN"), "\n", map { $_->[0] } @wrn;
say   tag ("GOT");
say   join ", " => @$_ for @csv;
