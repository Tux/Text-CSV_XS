#!/usr/bin/perl

use strict;
use warnings;

$ENV{AUTOMATED_TESTING} and do { print "1..0 # AT\n"; exit 0; };

use Test::More;

eval "use Test::Pod::Links";
plan skip_all => "Test::Pod::Links required for testing POD links" if $@;
Test::Pod::Links->new->pod_file_ok ("CSV_XS.pm");
done_testing;
