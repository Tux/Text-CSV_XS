#!/usr/bin/perl

use Test::More;

eval "use Test::Pod::Links";
plan skip_all => "Test::Pod::Links required for testing POD Links" if $@;

Test::Pod::Links->new->pod_file_ok ("CSV_XS.pm");
done_testing;
