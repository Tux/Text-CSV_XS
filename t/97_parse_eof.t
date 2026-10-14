#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 12;

use Text::CSV_XS;

# A CR at the very end of parse () input is not part of an EOL, also
# when the last field is empty: report it, do not turn EOF into data
foreach my $bin (0, 1) {
    my $csv = Text::CSV_XS->new ({ binary => $bin });
    ok (!$csv->parse ("a,\r"),			"binary $bin: a,CR fails");
    is (($csv->error_diag)[0], 2032,		"binary $bin: a,CR is 2032");
    ok (!$csv->parse ("a,b\r"),			"binary $bin: a,b,CR fails");
    is (($csv->error_diag)[0], 2032,		"binary $bin: same as non-empty field");
    }

my $s = "a,\r";
utf8::upgrade ($s);
my $csv = Text::CSV_XS->new ();
ok (!$csv->parse ($s),				"UTF-8 upgraded a,CR fails");
is (($csv->error_diag)[0], 2032,		"UTF-8 upgraded a,CR is 2032");

# Unchanged neighbours
$csv = Text::CSV_XS->new ({ binary => 1 });
ok ($csv->parse ("a,\r\n"),			"parse a,CRLF");
is_deeply ([ $csv->fields ], [ "a", "" ],	"a,CRLF");
