#!/usr/bin/perl

use strict;
use warnings;

$ENV{AUTOMATED_TESTING} and do { print "1..0 # AT\n"; exit 0; };

use Test::More;

eval "use Test::CPAN::Changes";
plan skip_all => "Test::CPAN::Changes required for this test" if $@;

changes_file_ok ("ChangeLog");

done_testing;
