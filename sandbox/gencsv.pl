#!/pro/bin/perl -w

use strict;

sub usage
{
    my $err = shift and select STDERR;
    print "usage: $0: [-n] [cols [rows]]\n";
    exit $err;
    } # usage

use Getopt::Long qw(:config bundling nopermute);
my $opt_n = 0;		# Disable newlines
GetOptions (
    "help|?"	=> sub { usage (0); },
    "n"		=> \$opt_n,
    ) or usage (1);

my ($cols, $rows) = @ARGV;
$cols ||= 10;
$rows ||= 10;

use Text::CSV_XS;

our $csv = Text::CSV_XS->new ({ binary => 1, eol => "\r\n" });

my @f = grep { defined $_ && $opt_n ? !/\n/ : 1 } (
    1, "Text::CSV_XS", $csv->version, "H.Merijn Brand",
    "1 \x{20ac} = 8.012 NOK", undef, "", "'\n,", '"', "Y");

$cols--;
my @row;
push @row, @f for 1 .. int ($cols / 10);
push @row, @f[(10 - $cols % 10) .. 9];

$csv->print (*STDOUT, [ 1..($cols + 1) ]);
$csv->print (*STDOUT, [ $_, @row ]) for 2 .. $rows;
