#!/usr/bin/perl

use strict;
use warnings;

$ENV{AUTOMATED_TESTING} and do { print "1..0 # AT\n"; exit 0; };

use Test::More;
eval "use Test::MinimumVersion";
if ($@) {
    print "1..0 # Test::MinimumVersion required for compatability tests\n";
    exit 0;
    }

subtest "5.008001" => sub {
    my @f581 = (glob ("t/*"),  glob ("*.pm"), glob ("*.PL"));
    all_minimum_version_ok ("5.008001", { paths => [ sort @f581 ]});
    };
subtest "5.014000" => sub {
    my @f514 = (glob ("examples/*"));
    all_minimum_version_ok ("5.014000", { paths => [ sort @f514 ]});
    };
subtest "5.012000" => sub {
    my @f518 = (glob ("xt/*"));
    all_minimum_version_ok ("5.018000", { paths => [ sort @f518 ]});
    };

done_testing ();
