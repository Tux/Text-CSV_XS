#!/pro/bin/perl

use 5.014002;
use warnings;

our $VERSION = "0.01 - 20200523";
our $CMD = $0 =~ s{.*/}{}r;

sub usage {
    my $err = shift and select STDERR;
    say "usage: $CMD ...";
    exit $err;
    } # usage

use blib;
use Data::Peek;
use Text::CSV_XS qw( csv );
use Getopt::Long qw(:config bundling);
GetOptions (
    "help|?"		=> sub { usage (0); },
    "V|version"		=> sub { say "$CMD [$VERSION]"; exit 0; },

    "v|verbose:1"	=> \(my $opt_v = 0),
    ) or usage (1);

my $no_col = "nc000";
my $rows = csv (
    in        => *DATA,
    encoding  => ":encoding(utf-8)",
    bom       => 1,
    munge     => sub { lc (s/\W+/_/gr =~ s/^_+//r) || $no_col++ },
    auto_diag => 1,
    callbacks => {
	error => sub {
	    my ($err) = @_;
	    say "I'm IN HERE $err";
	    if ($err == 1012) {
		say "Setting diag to 0";
		Text::CSV_XS->SetDiag (0);
		}
	    return;
	    },
	},
    );
DDumper $rows;

__END__
a,b,c,
1,2,3,
