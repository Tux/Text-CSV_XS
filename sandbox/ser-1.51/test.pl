#!/pro/bin/perl

use 5.036000;
use Text::CSV_XS 1.51 qw(csv);
use utf8;
use Data::Peek;

# Test input is CRLF.
open my $fh, "<", shift or die;

my $csv = Text::CSV_XS->new ({
    skip_empty_rows => 2,       # stop
    binary          => 1,
    auto_diag       => 2,
    });

my $res;
# 1st CSV: Groups
$res = $csv->csv (
    in              => $fh,
    skip_empty_rows => 2,       # stop
    headers         => "auto"
    );
DDumper ($res);

warn ("POS: ", $fh->tell, "\n");
$csv->column_names (undef);
$res = $csv->csv (
    in              => $fh,
    skip_empty_rows => 2,       # stop
    headers         => "auto"
    );
DDumper ($res);
