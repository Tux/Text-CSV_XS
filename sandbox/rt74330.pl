#!/pro/bin/perl

use strict;
use warnings;

use Text::CSV_XS;
use Text::CSV_PP;

use Test::More;

foreach my $implementation ("Text::CSV_PP", "Text::CSV_XS") {
    diag "Using $implementation";
    my $csv = $implementation->new ({ binary => 1, auto_diag => 1 });

    my $ax = chr (0xfa);
    my $bx = "foo";

    # We set the UTF-8 flag on a string with no funny characters
    utf8::upgrade ($bx);
    is ($bx, "foo", "no funny characters in the string");

    ok (utf8::valid ($ax), "first string correct in Perl");
    ok (utf8::valid ($bx), "second string correct in Perl");

    $csv->combine ($ax, $bx) or die $csv->error_diag;
    my $foo = $csv->string ();

    ok (utf8::valid ($foo), "is combined string correct inside Perl?");
    is ($foo, qq{\xfa,foo}, "expected result");
    }

done_testing ();
