#!/usr/bin/perl

use strict;
$^W = 1;

use Test::More tests => 128;

BEGIN {
    require_ok "Text::CSV_XS";
    plan skip_all => "Cannot load Text::CSV_XS" if $@;
    require "t/util.pl";
    }

$| = 1;

# Embedded newline tests

use IO::Handle;

foreach my $rs ("\n", "\r\n", "\r") {

    my $csv = Text::CSV_XS->new ({ binary => 1 });
       $csv->eol ($/ = $rs);

    foreach my $pass (0, 1) {
	if ($pass == 0) {
	    open FH, ">_eol.csv";
	    }
	else {
	    open FH, "<_eol.csv";
	    }

	foreach my $eol ("", "\r", "\n", "\r\n", "\n\r") {
	    my $s_eol = "$rs - $eol";
	       $s_eol =~ s/\r/\\r/g;
	       $s_eol =~ s/\n/\\n/g;

	    my @p;
	    my @f = ("", 1,
		$eol, " $eol", "$eol ", " $eol ", "'$eol'",
		"\"$eol\"", " \" $eol \"\n ", "EOL");

	    if ($pass == 0) {
		ok ($csv->combine (@f),			"combine |$s_eol|");
		ok (my $str = $csv->string,		"string  |$s_eol|");
		my $state = $csv->parse ($str);
		ok ($state,				"parse   |$s_eol|");
		if ($state) {
		    ok (@p = $csv->fields,		"fields  |$s_eol|");
		    }
		else{
		    is ($csv->error_input, $str,	"error   |$s_eol|");
		    }

		print FH $str;
		}
	    else {
		ok (my $row = $csv->getline (*FH),	"getline |$s_eol|");
		is (ref $row, "ARRAY",			"row     |$s_eol|");
		@p = @$row;
		}

	    local $, = "|";
	    is_binary ("@p", "@f",			"result  |$s_eol|");
	    }

	close FH;
	}

    unlink "_eol.csv";
    }

ok (1, "Specific \\r test from tfrayner");
{   $/ = "\r";
    open  FH, ">_eol.csv";
    print FH qq{a,b,c$/}, qq{"d","e","f"$/};
    close FH;
    open  FH, "<_eol.csv";
    my $c = Text::CSV_XS->new ({ eol => $/ });

    my $row;
    local $" = " ";
    ok ($row = $c->getline (*FH),	"getline 1");
    is (scalar @$row, 3,		"# fields");
    is ("@$row", "a b c",		"fields 1");
    ok ($row = $c->getline (*FH),	"getline 2");
    is (scalar @$row, 3,		"# fields");
    is ("@$row", "d e f",		"fields 2");
    close FH;
    unlink "_eol.csv";
    }

1;
