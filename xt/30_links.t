#!/usr/bin/perl

use strict;
use warnings;

eval "use Test::Pod::Links";
plan skip_all => "Test::Pod::Links required for testing links in POD" if $@;
Test::Pod::Links->new->all_pod_files_ok;
