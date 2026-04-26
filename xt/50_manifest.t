#!/usr/bin/perl

use strict;
use warnings;

$ENV{AUTOMATED_TESTING} and do { print "1..0 # AT\n"; exit 0; };

use Test::More;

eval "use Test::DistManifest";
plan skip_all => "Test::DistManifest required for testing MANIFEST" if $@;
manifest_ok ();
done_testing;
