#!/usr/bin/perl

use strict;
use warnings;

#use Test::More "no_plan";
 use Test::More tests => 13;

BEGIN {
    use_ok "Text::CSV_XS", ();
    plan skip_all => "Cannot load Text::CSV_XS" if $@;
    }

my $csv = Text::CSV_XS->new ({ binary => 1, eol => "\n" });

my $fh;
my $foo;
my $bar;
my @foo = ("#", 1..3);

tie $foo, "Foo";
ok ($csv->combine (@$foo),		"combine () from magic");
untie $foo;
is_deeply ([$csv->fields], \@foo,	"column_names ()");

tie $bar, "Bar";
$bar = "#";
ok ($csv->combine ($bar, @{$foo}[1..3]),"combine () from magic");
untie $bar;
is_deeply ([$csv->fields], \@foo,	"column_names ()");

tie $foo, "Foo";
open  $fh, ">", "_76test.csv";
ok ($csv->print ($fh, $foo),		"print with unused magic scalar");
close $fh;
untie $foo;

open  $fh, "<", "_76test.csv";
is_deeply ($csv->getline ($fh), \@foo,	"Content read-back");
close $fh;

tie $foo, "Foo";
ok ($csv->column_names ($foo),		"column_names () from magic");
untie $foo;
is_deeply ([$csv->column_names], \@foo,	"column_names ()");

open  $fh, "<", "_76test.csv";
tie $bar, "Bar";
ok ($csv->bind_columns (\$bar, \my ($f0, $f1, $f2)), "bind");
ok ($csv->getline ($fh),		"fetch with magic");
is_deeply ([$bar,$f0,$f1,$f2], \@foo,	"columns fetched on magic");
# free any refs
is ($csv->bind_columns (undef), undef,	"bind column clear");
untie $bar;
close $fh;

unlink "_76test.csv";

{   package Foo;
    use strict;
    use warnings;

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
    }

{   package Bar;

    use strict;
    use warnings;

    require Tie::Scalar;
    use vars qw( @ISA );
    @ISA = qw(Tie::Scalar);

    sub FETCH
    {
	return ${$_[0]};
	} # FETCH

    sub STORE
    {
	${$_[0]} = $_[1];
	} # STORE

    sub TIESCALAR
    {
	my $bar;
	bless \$bar, "Bar";
	} # TIESCALAR

    1;
    }
