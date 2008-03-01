#!/usr/bin/perl

use strict;
$^W = 1;

 use Test::More tests => 61;
#use Test::More "no_plan";

my %err;

BEGIN {
    require_ok "Text::CSV_XS";
    plan skip_all => "Cannot load Text::CSV_XS" if $@;
    require "t/util.pl";

    open XS, "< CSV_XS.xs" or die "Cannot read error messages from XS\n";
    while (<XS>) {
	m/^    { ([0-9]{4}), "([^"]+)"\s+\}/ and $err{$1} = $2;
	}
    }

$| = 1;

my $csv = (Text::CSV_XS->new ({ escape_char => "+", eol => "\n" }));
is (Text::CSV_XS::error_diag (), "",	"Last failure for new () - OK");

sub parse_err ($$)
{
    my ($n_err, $str) = @_;
    my $s_err = $err{$n_err};
    my $STR = _readable ($str);
    is ($csv->parse ($str), 0, "parse ('$STR')");
    is ($csv->error_diag () + 0, $n_err, "Diag in numerical context");
    is ($csv->error_diag (),     $s_err, "Diag in string context");
    my ($c_diag, $s_diag) = $csv->error_diag ();
    is ($c_diag, $n_err,	"Num diag in list context");
    is ($s_diag, $s_err,	"Str diag in list context");
    } # parse_err

is ($csv->error_diag (), undef,		"No errors yet");

parse_err 2010, qq{"x"\r};
parse_err 2011, qq{"x"x};

parse_err 2021, qq{"\n"};
parse_err 2022, qq{"\r"};
parse_err 2025, qq{"+ "};
parse_err 2026, qq{"\0 "};
parse_err 2027,   '"';
parse_err 2031, qq{\r };
parse_err 2032, qq{ \r};
parse_err 2034, qq{1, "bar",2};
parse_err 2037, qq{\0 };

diag ("Next line should be an error message");
$csv->error_diag ();

is (Text::CSV_XS->new ({ ecs_char => ":" }), undef, "Unsupported option");
is (Text::CSV_XS::error_diag (), "Unknown attribute 'ecs_char'",
					"Last failure for new () - FAIL");
is (Text::CSV_XS->error_diag (), "Unknown attribute 'ecs_char'",
					"Last failure for new () - FAIL");
