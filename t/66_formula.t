#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 42;

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

is ($csv->formula ("DIE"),	1,	"die");
is ($csv->formula ("CROAK"),	2,	"croak");
is ($csv->formula ("DIAG"),	3,	"diag");
is ($csv->formula ("EMPTY"),	4,	"empty");
is ($csv->formula ("UNDEF"),	5,	"undef");
is ($csv->formula ("XXX"),	0,	"invalid");

my @data = split m/\n/ => <<"EOC";
a,b,c
1,2,3
=1+2,3,4
1,=2+3,4
1,2,=3+4
EOC

sub parse {
    my $f = shift;
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

{ my @m;
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
  }

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
