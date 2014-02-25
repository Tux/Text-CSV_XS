#!/usr/bin/perl

use strict;
use warnings;

#use Test::More tests => 179;
 use Test::More "no_plan";

BEGIN {
    require_ok "Text::CSV_XS";
    plan skip_all => "Cannot load Text::CSV_XS" if $@;
    require "t/util.pl";
    }

$| = 1;

ok (my $csv = Text::CSV_XS->new (), "new");
is ($csv->callbacks, undef,		"no callbacks");

ok ($csv->bind_columns (\my ($c, $s)),	"bind");
ok ($csv->getline (*DATA),		"parse ok");
is ($c, 1,				"key");
is ($s, "foo",				"value");
$s = "untouched";
ok ($csv->getline (*DATA),		"parse bad");
is ($c, 1,				"key");
is ($s, "untouched",			"untouched");
ok ($csv->getline (*DATA),		"parse bad");
is ($c, "foo",				"key");
is ($s, "untouched",			"untouched");
ok ($csv->getline (*DATA),		"parse good");
is ($c, 2,				"key");
is ($s, "bar",				"value");
eval { is ($csv->getline (*DATA), undef,	"parse bad"); };
my @diag = $csv->error_diag;
is ($diag[0], 3006,			"too many values");

foreach my $args ([""], [1], [[]], [sub{}], [1,2], [1,2,3], ["error",undef]) {
    eval { $csv->callbacks (@$args); };
    my @diag = $csv->error_diag;
    is ($diag[0], 1004,			"invalid callbacks");
    is ($csv->callbacks, undef,		"not set");
    }

my $error = 3006;
sub ignore
{
    is ($_[0], $error, "Caught error $error");
    $csv->SetDiag (0); # Ignore this error
    } # ignore

ok ($csv->auto_diag (1), "set auto_diag");
is (ref $csv->callbacks ({ error => \&ignore }), "HASH", "callback set");
ok ($csv->getline (*DATA),		"parse ok");
is ($c, 1,				"key");
is ($s, "foo",				"value");
ok ($csv->getline (*DATA),		"parse bad, skip 3006");
ok ($csv->getline (*DATA),		"parse good");
is ($c, 2,				"key");
is ($s, "bar",				"value");
$error = 2012; # EOF
ok ($csv->getline (*DATA),		"parse past eof");

__END__
1,foo
1
foo
2,bar
3,baz,2
1,foo
3,baz,2
2,bar
