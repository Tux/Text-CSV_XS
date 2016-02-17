#!/usr/bin/perl

use strict;
use warnings;

use Encode qw( encode );
use Test::More tests => 139;

BEGIN {
    $] < 5.008002 and
        plan skip_all => "This test unit requires perl-5.8.2 or higher";

    use_ok "Text::CSV_XS";
    plan skip_all => "Cannot load Text::CSV_XS" if $@;
    require "t/util.pl";
    }

$| = 1;

ok (my $csv = Text::CSV_XS->new, "new for header tests");
is ($csv->sep_char, ",", "Sep = ,");

foreach my $sep (",", ";") {
    my $data = "bAr,foo\n1,2\n3,4,5\n";
    $data =~ s/,/$sep/g;

    $csv->column_names (undef);
    {   open my $fh, "<", \$data;
	ok (my $slf = $csv->header ($fh), "header");
	is ($slf, $csv, "Return self");
	is ($csv->sep_char, $sep, "Sep = $sep");
	is_deeply ([ $csv->column_names ], [qw( bar foo )], "headers");
	is_deeply ($csv->getline ($fh), [ 1, 2 ],    "Line 1");
	is_deeply ($csv->getline ($fh), [ 3, 4, 5 ], "Line 2");
	}

    $csv->column_names (undef);
    {   open my $fh, "<", \$data;
	ok (my $slf = $csv->header ($fh), "header");
	is ($slf, $csv, "Return self");
	is ($csv->sep_char, $sep, "Sep = $sep");
	is_deeply ([ $csv->column_names ], [qw( bar foo )], "headers");
	is_deeply ($csv->getline_hr ($fh), { bar => 1, foo => 2 }, "Line 1");
	is_deeply ($csv->getline_hr ($fh), { bar => 3, foo => 4 }, "Line 2");
	}
    }

my $sep_ok = [ "\t", "|", ",", ";" ];
foreach my $sep (",", ";", "|", "\t") {
    my $data = "bAr,foo\n1,2\n3,4,5\n";
    $data =~ s/,/$sep/g;

    $csv->column_names (undef);
    {   open my $fh, "<", \$data;
	ok (my $slf = $csv->header ($fh, $sep_ok), "header with specific sep set");
	is ($slf, $csv, "Return self");
	is ($csv->sep_char, $sep, "Sep = $sep");
	is_deeply ([ $csv->column_names ], [qw( bar foo )], "headers");
	is_deeply ($csv->getline ($fh), [ 1, 2 ],    "Line 1");
	is_deeply ($csv->getline ($fh), [ 3, 4, 5 ], "Line 2");
	}

    $csv->column_names (undef);
    {   open my $fh, "<", \$data;
	ok (my $slf = $csv->header ($fh, $sep_ok), "header with specific sep set");
	is ($slf, $csv, "Return self");
	is ($csv->sep_char, $sep, "Sep = $sep");
	is_deeply ([ $csv->column_names ], [qw( bar foo )], "headers");
	is_deeply ($csv->getline_hr ($fh), { bar => 1, foo => 2 }, "Line 1");
	is_deeply ($csv->getline_hr ($fh), { bar => 3, foo => 4 }, "Line 2");
	}
    }

for ([ 1010, "" ], [ 1011, "a,b;c,d"], [ 1012, "a,,b" ], [ 1013, "a,a,b" ]) {
    my ($err, $data) = @$_;
    open my $fh, "<", \$data;
    my $self = eval { $csv->header ($fh); };
    is ($self, undef, "FAIL for '$data'");
    ok ($@, "Error");
    is (0 + $csv->error_diag, $err, "Error code $err");
    }
{   open my $fh, "<", \"bar,bAr,bAR,BAR\n1,2,3,4";
    $csv->column_names (undef);
    ok ($csv->header ($fh, { fold => "none" }), "non-unique unfolded headers");
    is_deeply ([ $csv->column_names ], [qw( bar bAr bAR BAR )], "Headers");
    }

foreach my $sep (",", ";") {
    my $data = "bAr,foo\n1,2\n3,4,5\n";
    $data =~ s/,/$sep/g;

    $csv->column_names (undef);
    {   open my $fh, "<", \$data;
	ok (my $slf = $csv->header ($fh, { columns => 0 }), "Header without column setting");
	is ($slf, $csv, "Return self");
	is ($csv->sep_char, $sep, "Sep = $sep");
	is_deeply ([ $csv->column_names ], [], "headers");
	is_deeply ($csv->getline ($fh), [ 1, 2 ],    "Line 1");
	is_deeply ($csv->getline ($fh), [ 3, 4, 5 ], "Line 2");
	}
    }

for ([ undef, "bar" ], [ "lc", "bar" ], [ "uc", "BAR" ], [ "none", "bAr" ]) {
    my ($fold, $hdr) = @$_;

    my $data = "bAr,foo\n1,2\n3,4,5\n";

    $csv->column_names (undef);
    open my $fh, "<", \$data;
    ok (my $slf = $csv->header ($fh, { fold => $fold }), "header with fold ". ($fold || "undef"));
    is (($csv->column_names)[0], $hdr, "folded header to $hdr");
    }

my $fnm = "_85hdr.csv"; END { unlink $fnm; }
$csv->binary (1);
$csv->auto_diag (9);
my $str = qq{zoo,b\x{00e5}r\n1,"1 \x{20ac} each"\n};
for (	[ "none"       => ""	],
	[ "utf-8"      => "\xef\xbb\xbf"	],
	[ "utf-16be"   => "\xfe\xff"		],
	[ "utf-16le"   => "\xff\xfe"		],
	[ "utf-32be"   => "\x00\x00\xfe\xff"	],
	[ "utf-32le"   => "\xff\xfe\x00\x00"	],
#	[ "utf-1"      => "\xf7\x64\x4c"	],
#	[ "utf-ebcdic" => "\xdd\x73\x66\x73"	],
#	[ "scsu"       => "\x0e\xfe\xff"	],
#	[ "bocu-1"     => "\xfb\xee\x28"	],
#	[ "gb-18030"   => "\x84\x31\x95"	],
	) {
    my ($enc, $bom) = @$_;
    open my $fh, ">", $fnm;
    print $fh $bom;
    print $fh encode ($enc eq "none" ? "utf-8" : $enc, $str);
    close $fh;
    open  $fh, "<", $fnm;
    ok (1, "$fnm opened for enc $enc");
    ok ($csv->header ($fh), "headers with BOM for $enc");
    is (($csv->column_names)[1], "b\x{00e5}r", "column name was decoded");
    ok (my $row = $csv->getline_hr ($fh), "getline_hr");
    is ($row->{"b\x{00e5}r"}, "1 \x{20ac} each", "Returned in Unicode");
    unlink $fnm;
    }