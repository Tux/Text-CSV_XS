#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 117;

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
    ok (my $slf = $csv->header ($fh, { fold => $fold }), "header with fold ". ($fold // "undef"));
    is (($csv->column_names)[0], $hdr, "folded header to $hdr");
    }

$csv->binary (1);
$csv->auto_diag (9);
for (	[ "none"       => qq{zoo,b\xc3\xa5r\n1,"1 \xe2\x82\xac each"\n}			],
#	[ "utf-16be"   => qq{\xfe\xffzoo,bar\n1,"1 \x20\xac each"\n}			],
#	[ "utf-16le"   => qq{\xff\xfezoo,bar\n1,"1 \xac\x20 each"\n}			],
#	[ "utf-32be"   => qq{\x00\x00\xfe\xffzoo,bar\n1,"1 \x00\x00\x20\xac each"\n}	],
#	[ "utf-32le"   => qq{\xff\xfe\x00\x00zoo,bar\n1,"1 \xac\x20\x00\x00 each"\n}	],
	[ "utf-8"      => qq{\xef\xbb\xbfzoo,b\xc3\xa5r\n1,"1 \xe2\x82\xac each"\n}		],
#	[ "utf-1"      => qq{\xf7\x64\x4czoo,bar\n1,"1 \xe2\x82\xac each"\n}		],
#	[ "utf-ebcdic" => qq{\xdd\x73\x66\x73zoo,bar\n1,"1 \xe2\x82\xac each"\n}	],
#	[ "scsu"       => qq{\x0e\xfe\xffzoo,bar\n1,"1 \xe2\x82\xac each"\n}		],
#	[ "bocu-1"     => qq{\xfb\xee\x28zoo,bar\n1,"1 \xe2\x82\xac each"\n}		],
#	[ "gb-18030"   => qq{\x84\x31\x95zoo,bar\x33\n1,"1 \xe2\x82\xac each"\n}	],
	) {
    my ($enc, $data) = @$_;
    open my $fh, "<", \$data;
    ok ($csv->header ($fh), "headers with BOM for $enc");
    is (($csv->column_names)[1], "b\x{00e5}r", "column name was decoded");
    ok (my $row = $csv->getline_hr ($fh), "getline_hr");
    is ($row->{"b\x{00e5}r"}, "1 \x{20ac} each", "Returned in Unicode");
    }
