#!/usr/bin/perl

package Text::CSV_XS::Subclass;

use strict;
use warnings;

use base "Text::CSV_XS";

use Test::More tests => 6;

ok (1, "Subclassed");

my $csvs = Text::CSV_XS::Subclass->new ();
is ($csvs->error_diag (), "", "Last failure for new () - OK");

my $sc_csv;
eval { $sc_csv = Text::CSV_XS::Subclass->new ({ ecs_char => ":" }); };
is ($sc_csv, undef, "Unsupported option");
is ($@, "", "error");

is (Text::CSV_XS::Subclass->error_diag (),
    "INI - Unknown attribute 'ecs_char'", "Last failure for new () - FAIL");

is (Text::CSV_XS::Subclass->new ({ fail_me => "now" }), undef, "bad new ()");

1;
