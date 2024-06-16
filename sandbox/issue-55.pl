#!/pro/bin/perl

use 5.014002;
use warnings;

our $VERSION = "0.01 - 20240510";
our $CMD = $0 =~ s{.*/}{}r;

sub usage {
    my $err = shift and select STDERR;
    say "usage: $CMD ...";
    exit $err;
    } # usage

use CSV;
use Getopt::Long qw(:config bundling noignorecase);
GetOptions (
    "help|?"		=> sub { usage (0); },
    "V|version"		=> sub { say "$CMD [$VERSION]"; exit 0; },

    "v|verbose:1"	=> \(my $opt_v = 0),
    ) or usage (1);

my $csv = Text::CSV_XS->new ({ auto_diag => 1,
    callbacks => { after_parse => sub { DDumper { csv => $_[0], row => $_[1] }; 1; } }});
while (my $row = $csv->getline (*DATA)) {
    say @$row;
    }
__END__
a,b,c
1,2,3
2,3,4
3,4,5
4,5,6
