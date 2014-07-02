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

my %f561 = map { $_ => 1 }
    glob ("t/*"), glob ("xt/*"), glob ("*.pm"), glob ("*.PL");
my %f5xx = (
    "5.008.0"  => [qw(
	t/22_scalario.t
	t/46_eol_si.t
	t/50_utf8.t     t/51_utf8.t
	t/70_rt.t	t/78_fragment.t
	t/90_csv.t
	xt/00_perlversion.t
	)],
    "5.010.0" => [],
    "5.012.0" => [],
    "5.014.0" => [],
    "5.016.0" => [],
    );

delete @f561{map { @{$f5xx{$_}} } keys %f5xx};
$f5xx{"5.006.1"} = [ sort keys %f561 ];

foreach my $v (sort keys %f5xx) {
    my @f = @{$f5xx{$v}} or next;
    subtest ($v => sub { all_minimum_version_ok ($v, { paths => [ @f ]}); });
    }

done_testing ();
