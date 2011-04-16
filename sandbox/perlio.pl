#!/pro/bin/perl

use strict;
use warnings;

my $t = shift || 0;

use open IN => ":encoding(UTF-16) :crlf";
@ARGV = "rt66474.csv";

if ($t == 0) {
    print <>;
    exit 0;
    }

if ($t == 1) {
    require IO::Handle;
    while (my $r = *ARGV->getline) {
	print $r;
	}
    exit 0;
    }
