#!/pro/bin/perl

# echo hello,world >hello.csv; echo hello,two >>hello.csv; echo hello,three >>hello.csv
# unix2dos hello.csv
# iconv -f UTF-8 -t UTF-16 <hello.csv >hello2.csv

use strict;
use warnings;

use Text::CSV_XS;

my $t = $ARGV[0] || 0;

use open (IN => ":encoding(UTF-16) :crlf");
@ARGV = "rt66474.csv";

if ($t == 0) {
    print "no Text::CSV_XS\n";
    print <>;
    exit 0;
    }

my $csv = Text::CSV_XS->new ({
    auto_diag	=> 1,
    binary	=> 1,
#   eol		=> $/,
    });

if ($t == 1) {
    print "Text::CSV_XS getline\n";
    while (my $r = $csv->getline (*ARGV)) {
	print join (",", @$r), "\n";
	}
    exit 0;
    }

if ($t == 2) {
    print "Text::CSV_XS parse\n";
    while (my $l = <>) {
	$csv->parse ($l);
	print join (",", $csv->fields) . "\n";
	}
    exit 0;
    }

if ($t == 3) {
    print "Text::CSV_XS getline, read first line\n";
    my $s = <>;
    while (my $r = $csv->getline (*ARGV)) {
	print join (",", @$r) . "\n";
	}
    exit 0;
    }

if ($t == 4) {
    print "Text::CSV_XS getline with exlicit open\n";
    open my $fh, "<:encoding(UTF-16) :crlf", @ARGV or die "open failed: $!\n";
    while (my $r = $csv->getline ($fh)) {
	print join (",", @$r), "\n";
	}
    exit 0;
    }

if ($t == 5) {
    print "Text::CSV_XS getline with IO::Handle cheat\n";
    require IO::Handle;
    while (my $r = $csv->getline (*ARGV)) {
	print join (",", @$r), "\n";
	}
    exit 0;
    }

