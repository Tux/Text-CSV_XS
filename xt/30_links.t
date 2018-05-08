#!/usr/bin/perl

use strict;
use warnings;

eval "use Test::Pod::Links";
$@ or Test::Pod::Links->new->all_pod_files_ok;
