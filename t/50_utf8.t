#!/usr/bin/perl

use strict;
$^W = 1;

use Test::More;

BEGIN {
    if ($] < 5.008) {
	plan skip_all => "UTF8 tests useless in this ancient perl version";
	}
    else {
	plan tests => 57;
	}
    }

BEGIN {
    require_ok "Text::CSV_XS";
    plan skip_all => "Cannot load Text::CSV_XS" if $@;
    require "t/util.pl";
    }

my $csv = Text::CSV_XS->new ({ binary => 1, always_quote => 1 });

# Special characters to check:
# 0A = \n  2C = ,  20 =     22 = "  
# 0D = \r  3B = ;
foreach my $test (
  # Space-like characters
  [ "\x{0000A0}", "U+0000A0 NO-BRAK SPACE"				],
  [ "\x{00200B}", "U+00200B ZERO WIDTH SPACE"				],
  # Some characters with possible problems in the code point
  [ "\x{000122}", "U+000122 LATIN CAPITAL LETTER G WITH CEDILLA"	],
  [ "\x{002C22}", "U+002C22 GLAGOLITIC CAPITAL LETTER SPIDERY HA"	],
  [ "\x{000A2C}", "U+000A2C GURMUKHI LETTER BA"				],
  [ "\x{000E2C}", "U+000E2C THAI CHARACTER LO CHULA"			],
  [ "\x{010A2C}", "U+010A2C KHAROSHTHI LETTER VA"			],
  # Characters with possible problems in the encoded representation
  #  Should not be possible. ASCII is coded in 000..127, all other
  #  characters in 128..255
  ) {
    my ($u, $msg) = @$test;
    utf8::encode ($u);
    my @in  = ("", " ", $u, "");
    my $exp = join ",", map { qq{"$_"} } @in;

    ok ($csv->combine (@in),		"combine $msg");

    my $str = $csv->string;
    is_binary ($str, $exp,		"string  $msg");

    ok ($csv->parse ($str),		"parse   $msg");
    my @out = $csv->fields;
    # Cannot use is_deeply (), because of the binary content
    is (scalar @in, scalar @out,	"fields  $msg");
    for (0 .. $#in) {
	is_binary ($in[$_], $out[$_],	"field $_ $msg");
	}
    }
