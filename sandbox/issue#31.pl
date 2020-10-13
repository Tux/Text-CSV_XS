#!/pro/bin/perl

use 5.14.2;
use warnings;

our $VERSION = "0.01 - 20200912";
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

my $in = <DATA>;

dcsv (in => \$in);

dcsv (in => \$in, allow_loose_quotes  => 1);

dcsv (in => \$in, allow_loose_escapes => 1);

dcsv (in => \$in, allow_loose_escapes => 1, allow_loose_quotes => 1);

dcsv (in => \$in, allow_loose_quotes  => 1, escape => undef);

__END__
nj23h32n,"By using "pseudoenergies", we were able to design multiple peptide sequences that showed low micromolar viral entry inhibitory activity.",2010-06-22,
