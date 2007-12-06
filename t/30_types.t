#!/usr/bin/perl

use strict;
$^W = 1;

use Test::More tests => 25;

BEGIN {
    use_ok "Text::CSV_XS", ();
    plan skip_all => "Cannot load Text::CSV_XS" if $@;
    }

$| = 1;

my $csv = Text::CSV_XS->new ({
    types => [
	Text::CSV_XS::IV (),
	Text::CSV_XS::PV (),
	Text::CSV_XS::NV (),
	],
    });

ok ($csv,					"CSV_XS->new ()");

is (@{$csv->{types}}, 3,			"->{types} as hash");
is ($csv->{types}[0], Text::CSV_XS::IV (),	"type IV");
is ($csv->{types}[1], Text::CSV_XS::PV (),	"type PV");
is ($csv->{types}[2], Text::CSV_XS::NV (),	"type NV");

is (ref ($csv->types), "ARRAY",			"->types () as method");
is ($csv->types ()->[0], Text::CSV_XS::IV (),	"type IV");
is ($csv->types ()->[1], Text::CSV_XS::PV (),	"type PV");
is ($csv->types ()->[2], Text::CSV_XS::NV (),	"type NV");

is (length $csv->{_types}, 3,			"->{_types}");
my $inp = join "", map { chr $_ }
    Text::CSV_XS::IV (), Text::CSV_XS::PV (), Text::CSV_XS::NV ();
# should be "\001\000\002"
is ($csv->{_types}, $inp,			"IV PV NV");

ok ($csv->parse ("2.55,CSFDATVM01,3.77"),	"parse ()");
my @fields = $csv->fields ();
is ($fields[0], "2",				"Field 1");
is ($fields[1], "CSFDATVM01",			"Field 2");
is ($fields[2], "3.77",				"Field 3");

ok ($csv->combine ("", "", "1.00"),		"combine ()");
is ($csv->string, ',,1.00',			"string");

my $warning;
$SIG{__WARN__} = sub { $warning = shift };

ok ($csv->parse ($csv->string ()),		"parse (combine ())");
like ($warning, qr/numeric/,			"numeric warning");

@fields = $csv->fields ();
is ($fields[0], "0",				"Field 1");
is ($fields[1], "",				"Field 2");
is ($fields[2], "1",				"Field 3");

is ($csv->types (0), undef,			"delete types");
is ($csv->types,     undef,			"types gone");
