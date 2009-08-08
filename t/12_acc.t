#!/usr/bin/perl

use strict;
$^W = 1;	# use warnings core since 5.6

use Test::More tests => 86;

BEGIN {
    use_ok "Text::CSV_XS";
    plan skip_all => "Cannot load Text::CSV_XS" if $@;
    }

my $csv;
ok ($csv = Text::CSV_XS->new,				"new ()");

is ($csv->quote_char,			'"',		"quote_char");
is ($csv->escape_char,			'"',		"escape_char");
is ($csv->sep_char,			',',		"sep_char");
is ($csv->eol,				'',		"eol");
is ($csv->always_quote,			0,		"always_quote");
is ($csv->binary,			0,		"binary");
is ($csv->keep_meta_info,		0,		"keep_meta_info");
is ($csv->allow_loose_quotes,		0,		"allow_loose_quotes");
is ($csv->allow_loose_escapes,		0,		"allow_loose_escapes");
is ($csv->allow_whitespace,		0,		"allow_whitespace");
is ($csv->blank_is_undef,		0,		"blank_is_undef");
is ($csv->empty_is_undef,		0,		"empty_is_undef");
is ($csv->auto_diag,			0,		"auto_diag");
is ($csv->verbatim,			0,		"verbatim");

is ($csv->binary (1),			1,		"binary (1)");
my @fld = ( 'txt =, "Hi!"', "Yes", "", 2, undef, "1.09", "\r", undef );
ok ($csv->combine (@fld),				"combine");
is ($csv->string,
    qq{"txt =, ""Hi!""",Yes,,2,,1.09,"\r",},	"string");

is ($csv->sep_char (";"),		';',		"sep_char (;)");
is ($csv->quote_char ("="),		'=',		"quote_char (=)");
is ($csv->eol (undef),			"",		"eol (undef)");
is ($csv->eol (""),			"",		"eol ('')");
is ($csv->eol ("\r"),			"\r",		"eol (\\r)");
is ($csv->keep_meta_info (1),		1,		"keep_meta_info (1)");
is ($csv->always_quote (undef),		0,		"always_quote (undef)");
is ($csv->always_quote (1),		1,		"always_quote (1)");
is ($csv->allow_loose_quotes (1),	1,		"allow_loose_quotes (1)");
is ($csv->allow_loose_escapes (1),	1,		"allow_loose_escapes (1)");
is ($csv->allow_whitespace (1),		1,		"allow_whitespace (1)");
is ($csv->blank_is_undef (1),		1,		"blank_is_undef (1)");
is ($csv->empty_is_undef (1),		1,		"empty_is_undef (1)");
is ($csv->auto_diag (1),		1,		"auto_diag (1)");
is ($csv->verbatim (1),			1,		"verbatim (1)");
is ($csv->escape_char ("\\"),		"\\",		"escape_char (\\)");
ok ($csv->combine (@fld),				"combine");
is ($csv->string,
    qq{=txt \\=, "Hi!"=;=Yes=;==;=2=;;=1.09=;=\r=;\r},	"string");

# Funny settings, all three translate to \0 internally
ok ($csv = Text::CSV_XS->new ({
    sep_char	=> undef,
    quote_char	=> undef,
    escape_char	=> undef,
    }),						"new (undef ...)");
is ($csv->sep_char,		undef,		"sep_char undef");
is ($csv->quote_char,		undef,		"quote_char undef");
is ($csv->escape_char,		undef,		"escape_char undef");
ok ($csv->parse ("foo"),			"parse (foo)");
$csv->sep_char (",");
ok ($csv->parse ("foo"),			"parse (foo)");
ok (!$csv->parse ("foo,foo\0bar"),		"parse (foo)");
$csv->escape_char ("\\");
ok (!$csv->parse ("foo,foo\0bar"),		"parse (foo)");
$csv->binary (1);
ok ( $csv->parse ("foo,foo\0bar"),		"parse (foo)");

# Some forbidden combinations
foreach my $ws (" ", "\t") {
    ok ($csv = Text::CSV_XS->new ({ escape_char => $ws }), "New blank escape");
    eval { ok ($csv->allow_whitespace (1), "Allow ws") };
    is (($csv->error_diag)[0], 1002, "Wrong combo");
    ok ($csv = Text::CSV_XS->new ({ quote_char  => $ws }), "New blank quote");
    eval { ok ($csv->allow_whitespace (1), "Allow ws") };
    is (($csv->error_diag)[0], 1002, "Wrong combo");
    ok ($csv = Text::CSV_XS->new ({ allow_whitespace => 1 }), "New ws 1");
    eval { ok ($csv->escape_char ($ws),     "esc") };
    is (($csv->error_diag)[0], 1002, "Wrong combo");
    ok ($csv = Text::CSV_XS->new ({ allow_whitespace => 1 }), "New ws 1");
    eval { ok ($csv->quote_char  ($ws),     "esc") };
    is (($csv->error_diag)[0], 1002, "Wrong combo");
    }
eval { $csv = Text::CSV_XS->new ({
    escape_char      => "\t",
    quote_char       => " ",
    allow_whitespace => 1,
    }) };
like ((Text::CSV_XS::error_diag)[1], qr{^INI - allow_whitespace}, "Wrong combo - error message");
is   ((Text::CSV_XS::error_diag)[0], 1002, "Wrong combo - numeric error");

# And test erroneous calls

is (Text::CSV_XS::new (0),		   undef,	"new () as function");
is (Text::CSV_XS::error_diag (), "usage: my \$csv = Text::CSV_XS->new ([{ option => value, ... }]);",
							"Generic usage () message");
is (Text::CSV_XS->new ({ oel     => "" }), undef,	"typo in attr");
is (Text::CSV_XS::error_diag (), "INI - Unknown attribute 'oel'",	"Unsupported attr");
is (Text::CSV_XS->new ({ _STATUS => "" }), undef,	"private attr");
is (Text::CSV_XS::error_diag (), "INI - Unknown attribute '_STATUS'",	"Unsupported private attr");

foreach my $arg (undef, 0, "", " ", 1, [], [ 0 ], *STDOUT) {
    is  (Text::CSV_XS->new ($arg),         undef,	"Illegal type for first arg");
    is ((Text::CSV_XS::error_diag)[0], 1000, "Should be a hashref - numeric error");
    }

1;
