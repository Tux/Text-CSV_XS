#!/pro/bin/perl

use 5.14.2;
use warnings;

our $VERSION = "0.01 - 20200130";
our $CMD = $0 =~ s{.*/}{}r;

sub usage {
    my $err = shift and select STDERR;
    say "usage: $CMD ...";
    exit $err;
    } # usage

use CSV;
use Capture::Tiny qw( :all );;
use Getopt::Long  qw(:config bundling);
GetOptions (
    "help|?"		=> sub { usage (0); },
    "V|version"		=> sub { say "$CMD [$VERSION]"; exit 0; },

    "v|verbose:1"	=> \(my $opt_v = 0),
    ) or usage (1);

my %e = (
    2021 => [qw( -N --no-binary		)],
    2022 => [qw( -N --no-binary		)],
    2024 => [qw( -N -e :		)]
    );

my %m;
my $csv = Text::CSV_XS->new;
foreach my $e (1000 .. 9999) {
    $csv->SetDiag ($e);
    my $s = "" . $csv->error_diag or next;
    $s =~ m/[\x00-\x1f]/ and $s = DDisplay ($s) =~ s/^"(.*)"\z/$1/r;
    $m{$e} = $s;
    }

foreach my $ef (sort glob "E*.csv") {
    print STDERR "$ef\t";
    my $e = $ef =~ s/^E(\d+).*/$1/r;
    my $out = capture_merged {
	system $^X, "../examples/csv-check", @{$e{$e} || []}, $ef;
	};
    unless ($out =~ m/# CSV_XS ERROR: (.*)/) {
	say "$ef does not generate a parsable error:\n$out";
	next;
	}
    my $em = $1 =~ s/^([0-9]+) - //r;
    my $en = $1 // "----";
    if ($en eq $e) {
	warn "OK\n";
	}
    else {
	warn "$en - $em\n";
	}
    }
