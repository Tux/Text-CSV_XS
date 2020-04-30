#!/pro/bin/perl

use 5.18.2;
use warnings;

use Data::Peek;
use Text::CSV_XS;

my $csv = Text::CSV_XS->new;

my $data  = "3.14,1";
my @types = (Text::CSV_XS::NV, Text::CSV_XS::IV);

my ($nv, $iv);

warn "with types(expected flags):\n";

sub st {
    if (my $t = $csv->types) {
	say "  types: @$t";
	}
    else {
	say "  types: none";
	}
    } # st

st;
$csv->types (\@types);
st;
$csv->parse ($data);
($nv, $iv) = $csv->fields;

DPeek $nv; # PVNV with NOK flag
DPeek $iv; # PVIV with IOK flag

warn "\nwithout types(expected flags):\n";

st;
$csv->types (undef);
st;
$csv->parse ($data);
($nv, $iv) = $csv->fields;

DPeek $nv; # PVNV with POK flag
DPeek $iv; # PVIV with POK flag

warn "\nwith types(unexpected flags):\n";

st;
$csv->_cache_diag;
$csv->types (\@types);
st;
$csv->_cache_diag;
$csv->parse ($data);
($nv, $iv) = $csv->fields;

DPeek $nv; # PVNV with POK flag, but NOK expected
DDump $nv; # PVNV with POK flag, but NOK expected
DPeek $iv; # PVIV with POK flat, but IOK expected
DDump $iv; # PVIV with POK flat, but IOK expected
