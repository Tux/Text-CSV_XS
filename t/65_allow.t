#!/usr/bin/perl

use strict;
$^W = 1;

#use Test::More "no_plan";
 use Test::More tests => 617;

BEGIN {
    use_ok "Text::CSV_XS", ();
    plan skip_all => "Cannot load Text::CSV_XS" if $@;
    require "t/util.pl";
    }

my $csv;

ok (1, "Allow unescaped quotes");
# Allow unescaped quotes inside an unquoted field
{   my @bad = (
	# valid, line
	[ 1, 1, qq{foo,bar,"baz",quux},					],
	[ 2, 0, qq{rj,bs,r"jb"s,rjbs},					],
	[ 3, 0, qq{some "spaced" quote data,2,3,4},			],
	[ 4, 1, qq{and an,entirely,quoted,"field"},			],
	[ 5, 1, qq{and then,"one with ""quoted"" quotes",okay,?},	],
	);

    for (@bad) {
	my ($tst, $valid, $bad) = @$_;
	$csv = Text::CSV_XS->new ();
	ok ($csv,			"$tst - new (alq => 0)");
	is ($csv->parse ($bad), $valid,	"$tst - parse () fail");

	$csv->allow_loose_quotes (1);
	ok ($csv->parse ($bad),		"$tst - parse () pass");
	ok (my @f = $csv->fields,	"$tst - fields");
	}

    #$csv = Text::CSV_XS->new ({ quote_char => '"', escape_char => "=" });
    #ok (!$csv->parse (qq{foo,d'uh"bar}),	"should fail");
    }

ok (1, "Allow loose escapes");
# Allow escapes to escape characters that should not be escaped
{   my @bad = (
	# valid, line
	[ 1, 1, qq{1,foo,bar,"baz",quux},				],
	[ 2, 1, qq{2,escaped,"quote\\"s",in,"here"},			],
	[ 3, 1, qq{3,escaped,quote\\"s,in,"here"},			],
	[ 4, 1, qq{4,escap\\'d chars,allowed,in,unquoted,fields},	],
	[ 5, 0, qq{5,42,"and it\\'s dog",},				],

	[ 6, 1, qq{\\,},						],
	[ 7, 1, qq{\\},							],
	[ 8, 0, qq{foo\\},						],
	);

    for (@bad) {
	my ($tst, $valid, $bad) = @$_;
	$csv = Text::CSV_XS->new ({ escape_char => "\\" });
	ok ($csv,			"$tst - new (ale => 0)");
	is ($csv->parse ($bad), $valid,	"$tst - parse () fail");

	$csv->allow_loose_escapes (1);
	if ($tst >= 8) {
	    # Should always fail
	    ok (!$csv->parse ($bad),	"$tst - parse () pass");
	    }
	else {
	    ok ($csv->parse ($bad),	"$tst - parse () pass");
	    ok (my @f = $csv->fields,	"$tst - fields");
	    }
	}
    }

ok (1, "Allow whitespace");
# Allow whitespace to surround sep char
{   my @bad = (
	# valid, line
	[  1, 1, qq{1,foo,bar,baz,quux},				],
	[  2, 1, qq{1,foo,bar,"baz",quux},			],
	[  3, 1, qq{1, foo,bar,"baz",quux},			],
	[  4, 1, qq{ 1,foo,bar,"baz",quux},			],
	[  5, 0, qq{1,foo,bar, "baz",quux},			],
	[  6, 1, qq{1,foo ,bar,"baz",quux},			],
	[  7, 1, qq{1,foo,bar,"baz",quux },			],
	[  8, 1, qq{1,foo,bar,"baz","quux"},			],
	[  9, 0, qq{1,foo,bar,"baz" ,quux},			],
	[ 10, 0, qq{1,foo,bar,"baz","quux" },			],
	[ 11, 0, qq{ 1 , foo , bar , "baz" , quux },		],
	[ 12, 0, qq{  1  ,  foo  ,  bar  ,  "baz"  ,  quux  },	],
	[ 13, 0, qq{  1  ,  foo  ,  bar  ,  "baz"\t ,  quux  },	],
	);

    foreach my $eol ("", "\n", "\r", "\r\n") {
	my $s_eol = _readable ($eol);
	for (@bad) {
	    my ($tst, $ok, $bad) = @$_;
	    $csv = Text::CSV_XS->new ({ eol => $eol, binary => 1 });
	    ok ($csv,				"$s_eol / $tst - new - '$bad')");
	    is ($csv->parse ($bad), $ok,	"$s_eol / $tst - parse () fail");

	    $csv->allow_whitespace (1);
	    ok ($csv->parse ("$bad$eol"),	"$s_eol / $tst - parse () pass");

	    ok (my @f = $csv->fields,		"$s_eol / $tst - fields");

	    local $" = ",";
	    is ("@f", $bad[0][-1],		"$s_eol / $tst - content");
	    }
	}
    }

ok (1, "Allow whitespace, esc = +");
# Allow whitespace to surround sep char
{   my @bad = (
	# valid, line
	[  1, 1, qq{1,foo,bar,baz,quux},			],
	[  2, 1, qq{1,foo,bar,"baz",quux},			],
	[  3, 1, qq{1, foo,bar,"baz",quux},			],
	[  4, 1, qq{ 1,foo,bar,"baz",quux},			],
#	[  5, 0, qq{1,foo,bar, "baz",quux},			],
	[  6, 1, qq{1,foo ,bar,"baz",quux},			],
	[  7, 1, qq{1,foo,bar,"baz",quux },			],
	[  8, 1, qq{1,foo,bar,"baz","quux"},			],
	[  9, 0, qq{1,foo,bar,"baz" ,quux},			],
	[ 10, 0, qq{1,foo,bar,"baz","quux" },			],
	[ 11, 0, qq{1,foo,bar,"baz","quux" },			],
#	[ 12, 0, qq{ 1 , foo , bar , "baz" , quux },		],
#	[ 13, 0, qq{  1  ,  foo  ,  bar  ,  "baz"  ,  quux  },	],
#	[ 14, 0, qq{  1  ,  foo  ,  bar  ,  "baz"\t ,  quux  },	],
	);

    foreach my $eol ("", "\n", "\r", "\r\n") {
	my $s_eol = _readable ($eol);
	for (@bad) {
	    my ($tst, $ok, $bad) = @$_;
	    $csv = Text::CSV_XS->new ({ eol => $eol, binary => 1, escape_char => "+" });
	    ok ($csv,				"$s_eol / $tst - new - '$bad')");
	    is ($csv->parse ($bad), $ok,	"$s_eol / $tst - parse () fail");

	    $csv->allow_whitespace (1);
	    ok ($csv->parse ("$bad$eol"),	"$s_eol / $tst - parse () pass");

	    ok (my @f = $csv->fields,		"$s_eol / $tst - fields");

	    local $" = ",";
	    is ("@f", $bad[0][-1],		"$s_eol / $tst - content");
	    }
	}
    }

ok (1, "Trailing junk");
foreach my $bin (0, 1) {
    foreach my $eol (undef, "\r") {
	my $s_eol = _readable ($eol);
	my $csv = Text::CSV_XS->new ({ binary => $bin, eol => $eol });
	ok ($csv, "$s_eol - new)");
	my @bad = (
	    # test, line
	    [ 1, qq{"\r\r\n"\r},	],
	    [ 2, qq{"\r\r\n"\r\r},	],
	    [ 3, qq{"\r\r\n"\r\r\n},	],
	    [ 4, qq{"\r\r\n"\t \r},	],
	    [ 5, qq{"\r\r\n"\t \r\r},	],
	    [ 6, qq{"\r\r\n"\t \r\r\n},	],
	    );

	foreach my $arg (@bad) {
	    my ($tst, $bad) = @$arg;
	    my $ok = ($bin and $eol) ? 1 : 0;
	    is ($csv->parse ($bad), $ok,	"$tst - parse () default");

	    $csv->allow_whitespace (1);
	    is ($csv->parse ($bad), $ok,	"$tst - parse () allow");
	    }
	}
    }

{   ok (1, "verbatim");
    my $csv = Text::CSV_XS->new ({
	sep_char => "^",
	binary   => 1,
	});

    my @str = (
	qq{M^^Abe^Timmerman#\r\n},
	qq{M^^Abe\nTimmerman#\r\n},
	);

    my $gc;

    ok (1, "verbatim on parse ()");
    foreach $gc (0, 1) {
	$csv->verbatim ($gc);

	ok ($csv->parse ($str[0]),		"\\n   $gc parse");
	my @fld = $csv->fields;
	is (@fld, 4,				"\\n   $gc fields");
	is ($fld[2], "Abe",			"\\n   $gc fld 2");
	if ($gc) {	# Note line ending is still there!
	    is ($fld[3], "Timmerman#\r\n",	"\\n   $gc fld 3");
	    }
	else {		# Note the stripped \r!
	    is ($fld[3], "Timmerman#",		"\\n   $gc fld 3");
	    }

	ok ($csv->parse ($str[1]),		"\\n   $gc parse");
	@fld = $csv->fields;
	is (@fld, 3,				"\\n   $gc fields");
	if ($gc) {	# All newlines verbatim
	    is ($fld[2], "Abe\nTimmerman#\r\n",	"\\n   $gc fld 2");
	    }
	else {		# Note, rest is next line
	    is ($fld[2], "Abe",			"\\n   $gc fld 2");
	    }
	}

    $csv->eol ($/ = "#\r\n");
    foreach $gc (0, 1) {
	$csv->verbatim ($gc);

	ok ($csv->parse ($str[0]),		"#\\r\\n $gc parse");
	my @fld = $csv->fields;
	is (@fld, 4,				"#\\r\\n $gc fields");
	is ($fld[2], "Abe",			"#\\r\\n $gc fld 2");
	is ($fld[3], "Timmerman#\r\n",		"#\\r\\n $gc fld 3");

	ok ($csv->parse ($str[1]),		"#\\r\\n $gc parse");
	@fld = $csv->fields;
	is (@fld, 3,				"#\\r\\n $gc fields");
	is ($fld[2], "Abe\nTimmerman#\r\n",	"#\\r\\n $gc fld 2");
	}

    ok (1, "verbatim on getline (*FH)");
    use IO::Handle;
    open  FH, ">_test.csv";
    print FH @str, "M^Abe^*\r\n";
    close FH;

    foreach $gc (0, 1) {
	$csv->verbatim ($gc);

	open FH, "<_test.csv";

	my $row;
	ok ($row = $csv->getline (*FH),		"#\\r\\n $gc getline");
	is (@$row, 4,				"#\\r\\n $gc fields");
	is ($row->[2], "Abe",			"#\\r\\n $gc fld 2");
	is ($row->[3], "Timmerman",		"#\\r\\n $gc fld 3");

	ok ($row = $csv->getline (*FH),		"#\\r\\n $gc parse");
	is (@$row, 3,				"#\\r\\n $gc fields");
	is ($row->[2], "Abe\nTimmerman",	"#\\r\\n $gc fld 2");
	}

    $gc = $csv->verbatim ();
    ok (my $row = $csv->getline (*FH),		"#\\r\\n $gc parse EOF");
    is (@$row, 3,				"#\\r\\n $gc fields");
    is ($row->[2], "*\r\n",			"#\\r\\n $gc fld 2");

    close FH;
    unlink "_test.csv";
    }
