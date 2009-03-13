#!/pro/bin/perl

use strict;
$^W = 1;

eval "use Test::MinimumVersion";
if ($@) {
    print "1..0 # Test::Minimumversion required for compatability tests\n";
    exit 0;
    }

my $pm_dup = "tmp/CSV_XS.pm";

my $mod;
{   local (@ARGV, $/) = ("CSV_XS.pm");
    ($mod = <>) =~ s{^use warnings;}{local \$^W = 1;}m;
    }
open my $pm, ">", $pm_dup or die "$pm_dup";
print $pm $mod;
close $pm;

all_minimum_version_ok ("5.005_03", { paths => [qw( t xt ), $pm_dup, glob "*.PL" ]});

unlink $pm_dup;
