#!/usr/bin/perl

use strict;
$^W = 1;

 use Test::More tests => 99;
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

my $csv = Text::CSV_XS->new ();
is (Text::CSV_XS::error_diag (), "",	"Last failure for new () - OK");
is_deeply ([ $csv->error_diag ], [ 0, "", 0], "OK in list context");

sub parse_err ($$$)
{
    my ($n_err, $p_err, $str) = @_;
    my $s_err = $err{$n_err};
    my $STR = _readable ($str);
    is ($csv->parse ($str), 0,	"$n_err - Err for parse ('$STR')");
    is ($csv->error_diag () + 0, $n_err, "$n_err - Diag in numerical context");
    is ($csv->error_diag (),     $s_err, "$n_err - Diag in string context");
    my ($c_diag, $s_diag, $p_diag) = $csv->error_diag ();
    is ($c_diag, $n_err,	"$n_err - Num diag in list context");
    is ($s_diag, $s_err,	"$n_err - Str diag in list context");
    is ($p_diag, $p_err,	"$n_err - Pos diag in list context");
    } # parse_err

parse_err 2023, 19, qq{2023,",2008-04-05,"Foo, Bar",\n}; # "

$csv = Text::CSV_XS->new ({ escape_char => "+", eol => "\n" });
is ($csv->error_diag (), "",		"No errors yet");

parse_err 2010,  3, qq{"x"\r};
parse_err 2011,  4, qq{"x"x};

parse_err 2021,  2, qq{"\n"};
parse_err 2022,  2, qq{"\r"};
parse_err 2025,  2, qq{"+ "};
parse_err 2026,  2, qq{"\0 "};
parse_err 2027,  1,   '"';
parse_err 2031,  1, qq{\r };
parse_err 2032,  2, qq{ \r};
parse_err 2034,  4, qq{1, "bar",2};
parse_err 2037,  1, qq{\0 };

{   my @warn;
    local $SIG{__WARN__} = sub { push @warn, @_ };
    $csv->error_diag ();
    ok (@warn == 1, "Got error message");
    like ($warn[0], qr{^# CSV_XS ERROR: 2037 - EIF}, "error content");
    }

is (Text::CSV_XS->new ({ ecs_char => ":" }), undef, "Unsupported option");

{   my @warn;
    local $SIG{__WARN__} = sub { push @warn, @_ };
    Text::CSV_XS::error_diag ();
    ok (@warn == 1, "Error_diag in void context ::");
    like ($warn[0], qr{^# CSV_XS ERROR: 1000 - INI}, "error content");
    }
{   my @warn;
    local $SIG{__WARN__} = sub { push @warn, @_ };
    Text::CSV_XS->error_diag ();
    ok (@warn == 1, "Error_diag in void context ->");
    like ($warn[0], qr{^# CSV_XS ERROR: 1000 - INI}, "error content");
    }

{   my @warn;
    local $SIG{__WARN__} = sub { push @warn, @_ };
    is (Text::CSV_XS->new ({ auto_diag => 0, ecs_char => ":" }), undef,
	"Unsupported option");
    ok (@warn == 0, "Error_diag in from new ({ auto_diag => 0})");
    }
{   my @warn;
    local $SIG{__WARN__} = sub { push @warn, @_ };
    is (Text::CSV_XS->new ({ auto_diag => 1, ecs_char => ":" }), undef,
	"Unsupported option");
    ok (@warn == 1, "Error_diag in from new ({ auto_diag => 1})");
    like ($warn[0], qr{^# CSV_XS ERROR: 1000 - INI}, "error content");
    }

is (Text::CSV_XS::error_diag (), "INI - Unknown attribute 'ecs_char'",
					"Last failure for new () - FAIL");
is (Text::CSV_XS->error_diag (), "INI - Unknown attribute 'ecs_char'",
					"Last failure for new () - FAIL");
is (Text::CSV_XS::error_diag (bless {}, "Foo"), "INI - Unknown attribute 'ecs_char'",
					"Last failure for new () - FAIL");
$csv->SetDiag (0);
is (0 + $csv->error_diag (), 0,  "Reset error NUM");
is (    $csv->error_diag (), "", "Reset error NUM");

ok (1, "Test auto_diag");
$csv = Text::CSV_XS->new ({ auto_diag => 1 });
{   my @warn;
    local $SIG{__WARN__} = sub { push @warn, @_ };
    is ($csv->parse ('"","'), 0, "1 - bad parse");
    ok (@warn == 1, "1 - One error");
    like ($warn[0], qr '^# CSV_XS ERROR: 2027 -', "1 - error message");
    }
{   ok ($csv->{auto_diag} = 2, "auto_diag = 2 to die");
    eval { $csv->parse ('"","') };
    like ($@, qr '^# CSV_XS ERROR: 2027 -', "2 - error message");
    }

1;
