#!/usr/bin/perl

use strict;
$^W = 1;

 use Test::More tests => 14;
#use Test::More "no_plan";

BEGIN {
    require_ok "Text::CSV_XS";
    plan skip_all => "Cannot load Text::CSV_XS" if $@;
    require "t/util.pl";
    }

$| = 1;

my ($csv, $c_diag, $s_diag) = (Text::CSV_XS->new ({ escape_char => "+" }));

is ($csv->error_diag (), undef,		"No errors yet");

$csv->parse ('"');
diag ("Next line should be an error message");
$csv->error_diag ();

is ($csv->error_diag () + 0, 2027,	"Diag in numerical context");
is ($csv->error_diag (), "EIQ - Quoted field not terminated",
					"Diag in string context");

   ($c_diag, $s_diag) = $csv->error_diag ();
is ($c_diag, 2027,			"Diag in numerical context");
is ($s_diag, "EIQ - Quoted field not terminated",
					"Diag in string context");

is ($csv->escape_char ("+"), "+",	"Set escape char to +");
is ($csv->parse (q{1, "bar",2}), 0,	"Parse error");
   ($c_diag, $s_diag) = $csv->error_diag ();
is ($c_diag, 2034,			"Diag in numerical context");
is ($s_diag, "EIF - Loose unescaped quote",
					"Diag in string context");

is (Text::CSV_XS::error_diag (), "",	"Last failure for new () - OK");
is (Text::CSV_XS->new ({ ecs_char => ":" }), undef, "Unsupported option");
is (Text::CSV_XS::error_diag (), "Unknown attribute 'ecs_char'",
					"Last failure for new () - FAIL");
is (Text::CSV_XS->error_diag (), "Unknown attribute 'ecs_char'",
					"Last failure for new () - FAIL");
