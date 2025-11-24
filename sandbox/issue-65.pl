#!/pro/bin/perl

# https://github.com/Tux/Text-CSV_XS/issues/65
# https://github.com/user-attachments/files/23283324/MUP_PHY_R25_P05_V20_D23_Prov.csv

use 5.014002;
use warnings;

our $VERSION = "0.02 - 20251124";
our $CMD = $0 =~ s{.*/}{}r;

sub usage {
    my $err = shift and select STDERR;
    say "usage: $CMD [file.csv [1]]";
    exit $err;
    } # usage

use Data::Peek;
use Text::CSV_XS qw( csv );
use Getopt::Long qw(:config bundling);
GetOptions (
    "help|?"		=> sub { usage (0); },
    "V|version"		=> sub { say "$CMD [$VERSION]"; exit 0; },

    "v|verbose:1"	=> \(my $opt_v = 0),
    ) or usage (1);

my $fn = shift // (-d "t" ? "sandbox/issue-65.csv" : "issue-65.csv");
my $x  = shift;

say "Index";
{   my $aoa = csv (
	in      => $fn,
	filter  => { 9                 => sub { $_ eq "Chicago" }, },
	);
    }

if ($x) {
    say "AP City";
    my $aoh = csv (
	in      => $fn,
	headers => "auto",
	after_parse => sub { $_{Rndrng_Prvdr_City} eq "Chicago" or return \"skip" },
	);
    }

say "Name NPI";
{   my $aoh = csv (
	in      => $fn,
	filter  => { Rndrng_NPI        => sub { $_ > 1 }, },
	);
    }

say "Name City";
{   my $aoh = csv (
	in      => $fn,
	filter  => { Rndrng_Prvdr_City => sub { $_ eq "Chicago" }, },
	);
    }
