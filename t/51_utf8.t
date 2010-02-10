#!/usr/bin/perl

use strict;
$^W = 1;

use Test::More;

BEGIN {
    $] < 5.008 and
	plan skip_all => "UTF8 tests useless in this ancient perl version";
    }

my @tests;

BEGIN {
    delete $ENV{PERLIO};

    my $euro_ch = "\x{20ac}";

    utf8::encode    (my $bytes = $euro_ch);
    utf8::downgrade (my $bytes_dn = $bytes);
    utf8::upgrade   (my $bytes_up = $bytes);

    @tests = (
	# $test                        $perlio             $data,      $encoding $expect_w
	# ---------------------------- ------------------- ----------- --------- ----------
	[ "Unicode  default",          "",                 $euro_ch,   "utf8",   "warn",    ],
	[ "Unicode  binmode",          "[binmode]",        $euro_ch,   "utf8",   "warn",    ],
	[ "Unicode  :utf8",            ":utf8",            $euro_ch,   "utf8",   "no warn", ],
	[ "Unicode  :encoding(utf8)",  ":encoding(utf8)",  $euro_ch,   "utf8",   "no warn", ],
	[ "Unicode  :encoding(UTF-8)", ":encoding(UTF-8)", $euro_ch,   "utf8",   "no warn", ],

	[ "bytes dn default",          "",                 $bytes_dn,  "[none]", "no warn", ],
	[ "bytes dn binmode",          "[binmode]",        $bytes_dn,  "[none]", "no warn", ],
	[ "bytes dn :utf8",            ":utf8",            $bytes_dn,  "utf8",   "no warn", ],
	[ "bytes dn :encoding(utf8)",  ":encoding(utf8)",  $bytes_dn,  "utf8",   "no warn", ],
	[ "bytes dn :encoding(UTF-8)", ":encoding(UTF-8)", $bytes_dn,  "utf8",   "no warn", ],

	[ "bytes up default",          "",                 $bytes_up,  "[none]", "no warn", ],
	[ "bytes up binmode",          "[binmode]",        $bytes_up,  "[none]", "no warn", ],
	[ "bytes up :utf8",            ":utf8",            $bytes_up,  "utf8",   "no warn", ],
	[ "bytes up :encoding(utf8)",  ":encoding(utf8)",  $bytes_up,  "utf8",   "no warn", ],
	[ "bytes up :encoding(UTF-8)", ":encoding(UTF-8)", $bytes_up,  "utf8",   "no warn", ],
	);

    plan tests => 1 + 6 * @tests;
    }

BEGIN {
    require_ok "Text::CSV_XS";
    plan skip_all => "Cannot load Text::CSV_XS" if $@;
    require "t/util.pl";
    }

sub hexify { join " ", map { sprintf "%02x", $_ } unpack "C*", @_ }
sub warned { length ($_[0]) ? "warn" : "no warn" }

my $csv = Text::CSV_XS->new ({ auto_diag => 1, binary => 1 });

for (@tests) {
    my ($test, $perlio, $data, $enc, $expect_w) = @$_;

    my $expect = qq{"$data"};
    $enc eq "utf8" and utf8::encode ($expect);

    my ($p_out, $p_fh) = ("");
    my ($c_out, $c_fh) = ("");

    if ($perlio eq "[binmode]") {
	open $p_fh, ">", \$p_out;  binmode $p_fh;
	open $c_fh, ">", \$c_out;  binmode $c_fh;
	}
    else {
	open $p_fh, ">$perlio", \$p_out;
	open $c_fh, ">$perlio", \$c_out;
	}

    my $p_warn = "";
    {	local $SIG{__WARN__} = sub { $p_warn .= join "", @_ };
	ok ((print $p_fh qq{"$data"}),        "$test perl print");
	close $p_fh;
	}

    my $c_warn = "";
    {	local $SIG{__WARN__} = sub { $c_warn .= join "", @_ };
	ok ($csv->print ($c_fh, [ $data ]),   "$test csv print");
	close $c_fh;
	}

    is (hexify ($c_out), hexify ($p_out),   "$test against Perl");
    is (hexify ($c_out), hexify ($expect),  "$test against expected");

    is (warned ($c_warn), warned ($p_warn), "$test against Perl warning");
    is (warned ($c_warn), $expect_w,        "$test against expected warning");
    }
