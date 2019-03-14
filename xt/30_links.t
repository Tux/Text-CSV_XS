#!/usr/bin/perl

use strict;
use warnings;

eval "use Test::Pod::Links";
if ($@) {
    print "1..0 # Test::Pod::Links required for this test\n";
    exit 0;
    }
Test::Pod::Links->new->all_pod_files_ok;
