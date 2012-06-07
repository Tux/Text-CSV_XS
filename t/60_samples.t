#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 8;

BEGIN {
    use_ok "Text::CSV_XS", ();
    plan skip_all => "Cannot load Text::CSV_XS" if $@;
    }

# Some assorted examples from the modules history

# "Pavel Kotala" <pkotala@logis.cz>
{
    my $csv = Text::CSV_XS->new ({
	quote_char	=> '"',
	escape_char	=> '\\',
	sep_char	=> ';',
	binary		=> 1,
	});
    ok ($csv,				"new (\", \\\\, ;, 1)");

    my @list = ("c:\\winnt", "text");
    ok ($csv->combine (@list),		"combine ()");
    my $line = $csv->string;
    ok ($line,				"string ()");
    ok ($csv->parse ($line),		"parse ()");
    my @olist = $csv->fields;
    is (scalar @list, scalar @olist,	"field count");
    is ($list[0], $olist[0],		"field 1");
    is ($list[1], $olist[1],		"field 2");
    }
