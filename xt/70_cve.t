#!/usr/bin/perl

use strict;
use warnings;

$ENV{AUTOMATED_TESTING} and do { print "1..0 # AT\n"; exit 0; };

use Test::More;
eval "use Test::CVE";
plan skip_all => "Test::CVE required for this test" if $@;

has_no_cves ();
done_testing;
