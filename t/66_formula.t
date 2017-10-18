#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 90;

BEGIN {
    use_ok "Text::CSV_XS", ();
    plan skip_all => "Cannot load Text::CSV_XS" if $@;
    }

# Some assorted examples from the modules history

ok (my $csv = Text::CSV_XS->new,	"new");

is ($csv->formula,		0,	"default");
is ($csv->formula ($_),		$_,	"formula $_") for 0 .. 5;
is ($csv->formula ($_),		0,	"invalid") for 9, -1, undef, [], {};

is ($csv->formula ("die"),	1,	"die");
is ($csv->formula ("croak"),	2,	"croak");
is ($csv->formula ("diag"),	3,	"diag");
is ($csv->formula ("empty"),	4,	"empty");
is ($csv->formula ("undef"),	5,	"undef");
is ($csv->formula ("xxx"),	0,	"invalid");

is ($csv->formula_handling,		0,	"default");
is ($csv->formula_handling ("DIE"),	1,	"die");
is ($csv->formula_handling ("CROAK"),	2,	"croak");
is ($csv->formula_handling ("DIAG"),	3,	"diag");
is ($csv->formula_handling ("EMPTY"),	4,	"empty");
is ($csv->formula_handling ("UNDEF"),	5,	"undef");
is ($csv->formula_handling ("XXX"),	0,	"invalid");

my %f = qw(
    0 0 none  0
    1 1 die   1
    2 2 croak 2
    3 3 diag  3
    4 4 empty 4
    5 5 undef 5
	xxx   0
    );
foreach my $f (sort keys %f) {
    ok (my $p = Text::CSV_XS->new ({ formula => $f }), "new with $f");
    is ($p->formula, $f{$f}, "Set to $f{$f}");
    }

# Parser

my @data = split m/\n/ => <<"EOC";
a,b,c
1,2,3
=1+2,3,4
1,=2+3,4
1,2,=3+4
EOC

sub parse {
    my $f  = shift;
    my @d;
    ok (my $csv = Text::CSV_XS->new ({ formula => $f }), "new $f");
    for (@data) {
	$csv->parse ($_);
	push @d, [ $csv->fields ];
	}
    \@d;
    } # parse

is_deeply (parse (0), [
    [ "a",	"b",	"c",	],
    [ "1",	"2",	"3",	],
    [ "=1+2",	"3",	"4",	],
    [ "1",	"=2+3",	"4",	],
    [ "1",	"2",	"=3+4",	],
    ], "Default");

my $r = eval { parse (1) };
is ($r, undef,				"Die on formulas");
is ($@, "Formulas are forbidden\n",	"Message");
$@ = undef;

   $r = eval { parse (2) };
is ($r, undef,				"Croak on formulas");
is ($@, "Formulas are forbidden\n",	"Message");
$@ = undef;

my @m;
local $SIG{__WARN__} = sub { push @m, @_ };

is_deeply (parse (3), [
    [ "a",	"b",	"c",	],
    [ "1",	"2",	"3",	],
    [ "=1+2",	"3",	"4",	],
    [ "1",	"=2+3",	"4",	],
    [ "1",	"2",	"=3+4",	],
    ], "Default");
is ($@, undef, "Legal with warnings");
is_deeply (\@m, [
    "Field 1 in record 2 contains formula '=1+2'\n",
    "Field 2 in record 3 contains formula '=2+3'\n",
    "Field 3 in record 4 contains formula '=3+4'\n",
    ],		"Warnings");

is_deeply (parse (4), [
    [ "a",	"b",	"c",	],
    [ "1",	"2",	"3",	],
    [ "",	"3",	"4",	],
    [ "1",	"",	"4",	],
    [ "1",	"2",	"",	],
    ], "Empty");

is_deeply (parse (5), [
    [ "a",	"b",	"c",	],
    [ "1",	"2",	"3",	],
    [ undef,	"3",	"4",	],
    [ "1",	undef,	"4",	],
    [ "1",	"2",	undef,	],
    ], "Undef");

{   @m = ();
    ok (my $csv = Text::CSV_XS->new ({ formula => 3 }), "new 3 hr");
    ok ($csv->column_names ("code", "value", "desc"), "Set column names");
    ok ($csv->parse ("1,=2+3,4"), "Parse");
    is_deeply (\@m,
	[ qq{Field 2 (column: 'value') contains formula '=2+3'\n} ],
	"Warning for HR");
    }

# Writer

sub writer {
    my $f = shift;
    ok (my $csv = Text::CSV_XS->new ({ formula => $f, quote_empty => 1 }), "new $f");
    ok ($csv->combine ("1", "=2+3", "4"), "combine $f");
    $csv->string;
    } # writer

@m = ();
is (       writer (0),   q{1,=2+3,4}, "Out 0");
is (eval { writer (1) }, undef,       "Out 1");
is (eval { writer (2) }, undef,       "Out 2");
is (       writer (3),   q{1,=2+3,4}, "Out 3");
is (       writer (4),   q{1,"",4},   "Out 4");
is (       writer (5),   q{1,,4},     "Out 5");
is_deeply (\@m,  [ "Field 1 contains formula '=2+3'\n" ], "Warning 3");
