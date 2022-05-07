#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 41;

BEGIN {
    use_ok "Text::CSV_XS", qw( :CONSTANTS PV IV NV );
    plan skip_all => "Cannot load Text::CSV_XS" if $@;
    }

is (              PV,             0, "Type PV");
is (              IV,             1, "Type IV");
is (              NV,             2, "Type NV");

is (              PV (),          0, "Type PV f");
is (              IV (),          1, "Type IV f");
is (              NV (),          2, "Type NV f");

is (Text::CSV_XS::PV,             0, "Type T:C:PV");
is (Text::CSV_XS::IV,             1, "Type T:C:IV");
is (Text::CSV_XS::NV,             2, "Type T:C:NV");

is (Text::CSV_XS::PV (),          0, "Type T:C:PV f");
is (Text::CSV_XS::IV (),          1, "Type T:C:IV f");
is (Text::CSV_XS::NV (),          2, "Type T:C:NV f");

is (              CSV_TYPE_PV,    0, "Type CT_PV");
is (              CSV_TYPE_IV,    1, "Type CT_IV");
is (              CSV_TYPE_NV,    2, "Type CT_NV");

is (              CSV_TYPE_PV (), 0, "Type CT_PV f");
is (              CSV_TYPE_IV (), 1, "Type CT_IV f");
is (              CSV_TYPE_NV (), 2, "Type CT_NV f");

is (Text::CSV_XS::CSV_TYPE_PV,    0, "Type T:C:CT_PV");
is (Text::CSV_XS::CSV_TYPE_IV,    1, "Type T:C:CT_IV");
is (Text::CSV_XS::CSV_TYPE_NV,    2, "Type T:C:CT_NV");

is (Text::CSV_XS::CSV_TYPE_PV (), 0, "Type T:C:CT_PV f");
is (Text::CSV_XS::CSV_TYPE_IV (), 1, "Type T:C:CT_IV f");
is (Text::CSV_XS::CSV_TYPE_NV (), 2, "Type T:C:CT_NV f");

is (              CSV_FLAGS_IS_QUOTED,          1, "is_Q");
is (              CSV_FLAGS_IS_BINARY,          2, "is_B");
is (              CSV_FLAGS_ERROR_IN_FIELD,     4, "is_E");
is (              CSV_FLAGS_IS_MISSING,        16, "is_M");

is (              CSV_FLAGS_IS_QUOTED (),       1, "is_Q f");
is (              CSV_FLAGS_IS_BINARY (),       2, "is_B f");
is (              CSV_FLAGS_ERROR_IN_FIELD (),  4, "is_E f");
is (              CSV_FLAGS_IS_MISSING (),     16, "is_M f");

is (Text::CSV_XS::CSV_FLAGS_IS_QUOTED,          1, "is_Q");
is (Text::CSV_XS::CSV_FLAGS_IS_BINARY,          2, "is_B");
is (Text::CSV_XS::CSV_FLAGS_ERROR_IN_FIELD,     4, "is_E");
is (Text::CSV_XS::CSV_FLAGS_IS_MISSING,        16, "is_M");

is (Text::CSV_XS::CSV_FLAGS_IS_QUOTED (),       1, "T:C:is_Q f");
is (Text::CSV_XS::CSV_FLAGS_IS_BINARY (),       2, "T:C:is_B f");
is (Text::CSV_XS::CSV_FLAGS_ERROR_IN_FIELD (),  4, "T:C:is_E f");
is (Text::CSV_XS::CSV_FLAGS_IS_MISSING (),     16, "T:C:is_M f");
