#!/usr/bin/perl

use strict;
$^W = 1;

#use Test::More "no_plan";
 use Test::More tests => 5;

BEGIN {
    use_ok "Text::CSV_XS", ();
    plan skip_all => "Cannot load Text::CSV_XS" if $@;
    }

my $csv = Text::CSV_XS->new ({ binary => 1, eol => "\n" });

my $foo;
my @foo = ("#", 1..3);

tie $foo, "Foo";
open  FH, ">_test.csv";
ok ($csv->print (*FH, $foo),		"print with unused magic scalar");
close FH;
untie $foo;

open  FH, "<_test.csv";
is_deeply ($csv->getline (*FH), \@foo,	"Content read-back");
close FH;

tie $foo, "Foo";
ok ($csv->column_names ($foo),		"column_names () from magic");
untie $foo;
is_deeply ([$csv->column_names], \@foo,	"column_names ()");

unlink "_test.csv";

package Foo;

use strict;
local $^W = 1;

require Tie::Scalar;
use vars qw( @ISA );
@ISA = qw(Tie::Scalar);

sub FETCH
{
    [ "#", 1 .. 3 ];
    } # FETCH

sub TIESCALAR
{
    bless [], "Foo";
    } # TIESCALAR

1;
