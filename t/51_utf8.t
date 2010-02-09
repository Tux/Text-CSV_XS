#!/usr/bin/perl

use strict;
$^W = 1;

use Test::More;

BEGIN {
    if ($] < 5.008) {
	plan skip_all => "UTF8 tests useless in this ancient perl version";
	}
    else {
	plan tests => 14;
	}
    }

BEGIN {
    require_ok "Encode";
    plan skip_all => "Cannot load Encode"       if $@;
    require_ok "Text::CSV_XS";
    plan skip_all => "Cannot load Text::CSV_XS" if $@;
    require "t/util.pl";
    }

my $csv = Text::CSV_XS->new ({ auto_diag => 1, binary => 1 });

my $euro  = "\x{20ac}";			# utf-8
my $deuro = Encode::encode ("utf8", $euro);	# bytes \xE2\x82\xAC
my $ceuro = qq{"$deuro"};		# quoted

{   my $out = "";
    open my $fh, ">", \$out;
    ok ($csv->print ($fh, [ $euro ]),	"print plain plain");
    close $fh;
    is ($out, $ceuro,			"read  plain plain");
    }

{   my $out = "";
    open my $fh, ">:utf8", \$out;
    ok ($csv->print ($fh, [ $euro ]),	"print plain utf-8");
    close $fh;
    is ($out, $ceuro,			"read  plain utf-8");
    }

{   my $out = "";
    open my $fh, ">:encoding(utf8)", \$out;
    ok ($csv->print ($fh, [ $euro ]),	"print plain utf-8");
    close $fh;
    is ($out, $ceuro,			"read  plain utf-8");
    }

{   my $out = "";
    open my $fh, ">", \$out;
    ok ($csv->print ($fh, [ $deuro ]),	"print decod plain");
    close $fh;
    is ($out, $ceuro,			"read  decod plain");
    }

# These are deliberate fails. User requests double-encoding
my $deeuro = Encode::encode ("utf8", $deuro);

{   my $out = "";
    open my $fh, ">:utf8", \$out;
    ok ($csv->print ($fh, [ $deuro ]),	"print decod utf-8");
    close $fh;
    is ($out, qq{"$deeuro"},		"read  decod utf-8");
    }

{   my $out = "";
    open my $fh, ">:encoding(utf8)", \$out;
    ok ($csv->print ($fh, [ $deuro ]),	"print decod utf-8");
    close $fh;
    is ($out, qq{"$deeuro"},		"read  decod utf-8");
    }
