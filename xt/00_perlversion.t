#!/pro/bin/perl

use strict;
use warnings;

eval "use Test::More 0.93";
if ($@ || $] < 5.010) {
    print "1..0 # perl-5.10.0 + Test::More 0.93 required for version checks\n";
    exit 0;
    }
eval "use Test::MinimumVersion";
if ($@) {
    print "1..0 # Test::MinimumVersion required for compatability tests\n";
    exit 0;
    }

my %f555 = map { $_ => 1 } glob ("t/*"), glob ("xt/*"), glob ("*.pm"), glob ("*.PL");
my @f560 = ( "t/22_scalario.t", "t/46_eol_si.t", "xt/00_perlversion.t");
my @f580 = ( "t/50_utf8.t",     "t/51_utf8.t");
delete @f555{@f560, @f580};
subtest (p553 => sub {
    all_minimum_version_ok ("5.6.1", { paths => [ sort keys %f555 ]});
    });
subtest (p560 => sub {
    all_minimum_version_ok ("5.6.1", { paths => [           @f560 ]});
    });
subtest (p580 => sub {
    all_minimum_version_ok ("5.8.0", { paths => [           @f580 ]});
    });

done_testing ();
