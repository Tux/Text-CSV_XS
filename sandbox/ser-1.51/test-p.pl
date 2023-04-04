#!/pro/bin/perl

use 5.036000;
use Text::CSV_XS 1.50 qw(csv);
use utf8;
use Data::Peek;

# Test input is CRLF.
open my $fh, "<", shift or die;
foreach my $sct (do { local $/ = ""; <$fh> }) {
    my $res = csv (
	in      => \$sct,
	headers => "auto",
	);
    DDumper ($res);
    }
