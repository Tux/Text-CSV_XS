#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 109;

BEGIN {
    use_ok "Text::CSV_XS";
    plan skip_all => "Cannot load Text::CSV_XS" if $@;
    require "./t/util.pl";
    }

$|  = 1;
$/  = "\n";
$\  = undef;

my $io;
my $tfn = "_21test.csv"; END { -f $tfn and unlink $tfn; }
my $csv = Text::CSV_XS->new ();

my $UTF8 = ($ENV{LANG} || "C").($ENV{LC_ALL} || "C") =~ m/utf-?8/i ? 1 : 0;

open  $io, ">", $tfn or die "$tfn: $!";
ok (!$csv->print ($io, ["abc", "def\007", "ghi"]), "print bad character");
close $io;

for ( [  1, 1, 1, '""'				],
      [  2, 1, 1, '', ''			],
      [  3, 1, 0, '', 'I said, "Hi!"', ''	],
      [  4, 1, 0, '"', 'abc'			],
      [  5, 1, 0, 'abc', '"'			],
      [  6, 1, 1, 'abc', 'def', 'ghi'		],
      [  7, 1, 1, "abc\tdef", 'ghi'		],
      [  8, 1, 0, '"abc'			],
      [  9, 1, 0, 'ab"c'			],
      [ 10, 1, 0, '"ab"c"'			],
      [ 11, 0, 0, qq("abc\nc")			],
      [ 12, 1, 1, q(","), ','			],
      [ 13, 1, 0, qq("","I said,\t""Hi!""",""), '', qq(I said,\t"Hi!"), '' ],
      ) {
    my ($tst, $validp, $validg, @arg, $row) = @$_;

    open  $io, ">", $tfn or die "$tfn: $!";
    is ($csv->print ($io, \@arg), $validp||"", "$tst - print ()");
    close $io;

    open  $io, ">", $tfn or die "$tfn: $!";
    print $io join ",", @arg;
    close $io;

    open  $io, "<", $tfn or die "$tfn: $!";
    $row = $csv->getline ($io);
    unless ($validg) {
	is ($row, undef, "$tst - false getline ()");
	next;
	}
    ok ($row, "$tst - good getline ()");
    $tst == 12 and @arg = (",", "", "");
    foreach my $a (0 .. $#arg) {
	(my $exp = $arg[$a]) =~ s/^"(.*)"$/$1/;
	is ($row->[$a], $exp, "$tst - field $a");
	}
    }

unlink $tfn;

# This test because of a problem with DBD::CSV

ok (1, "Tests for DBD::CSV");
open  $io, ">", $tfn or die "$tfn: $!";
$csv->binary (1);
$csv->eol    ("\r\n");
ok ($csv->print ($io, [ "id", "name"			]), "Bad character");
ok ($csv->print ($io, [   1,  "Alligator Descartes"	]), "Name 1");
ok ($csv->print ($io, [  "3", "Jochen Wiedmann"		]), "Name 2");
ok ($csv->print ($io, [   2,  "Tim Bunce"		]), "Name 3");
ok ($csv->print ($io, [ " 4", "Andreas K�nig"		]), "Name 4");
ok ($csv->print ($io, [   5				]), "Name 5");
close $io;

my $expected = <<"CONTENTS";
id,name\015
1,"Alligator Descartes"\015
3,"Jochen Wiedmann"\015
2,"Tim Bunce"\015
" 4","Andreas K�nig"\015
5\015
CONTENTS

open  $io, "<", $tfn or die "$tfn: $!";
my $content = do { local $/; <$io> };
close $io;
is ($content, $expected, "Content");
open  $io, ">", $tfn or die "$tfn: $!";
print $io $content;
close $io;
open  $io, "<", $tfn or die "$tfn: $!";

my $fields;
print "# Retrieving data\n";
for (0 .. 5) {
    ok ($fields = $csv->getline ($io),			"Fetch field $_");
    is ($csv->eof, "",					"EOF");
    print "# Row $_: $fields (@$fields)\n";
    }
is ($csv->getline ($io), undef,				"Fetch field 6");
is ($csv->eof, 1,					"EOF");

# Edge cases
for ([  1, 1,    0, "\n"		],
     [  2, 1,    0, "+\n"		],
     [  3, 1,    0, "+"			],
     [  4, 0, 2021, qq{"+"\n}		],
     [  5, 0, 2025, qq{"+\n}		],
     [  6, 0, 2011, qq{""+\n}		],
     [  7, 0, 2027, qq{"+"}		],
     [  8, 0, 2024, qq{"+}		],
     [  9, 0, 2011, qq{""+}		],
     [ 10, 1,    0, "\r"		],
     [ 11, 0, 2031, "\r\b"		],
     [ 12, 0, 2032, "+\r\b"		],
     [ 13, 0, 2032, "+\r\b+"		],
     [ 14, 0, 2022, qq{"\r"}		],
     [ 15, 0, 2022, qq{"\r\b" }		],
     [ 16, 0, 2022, qq{"\r\b"\t}	],
     [ 17, 0, 2025, qq{"+\r\b"}		],
     [ 18, 0, 2025, qq{"+\r\b+"}	],
     [ 19, 0, 2022, qq{"\r"\b}		],
     [ 20, 0, 2022, qq{"\r\b"\b}	],
     [ 21, 0, 2025, qq{"+\r\b"\b}	],
     [ 22, 0, 2025, qq{"+\r\b+"\b}	],
     [ 23, 0, 2037, qq{\b}		],
     [ 24, 0, 2026, qq{"\b"}		],
     ) {
    my ($tst, $valid, $err, $str) = @$_;
    my $raw = $] < 5.008 ? "" : ":raw";
    open  my $io, ">$raw", $tfn or die "$tfn: $!";
    print $io $str;
    close $io;

    $csv = Text::CSV_XS->new ({ escape_char => "+" });
    open     $io, "<$raw", $tfn or die "$tfn: $!";
    my $row = $csv->getline ($io);
    close $io;
    my @err  = $csv->error_diag;
    my $sstr = _readable ($str);
    SKIP: {
	$tst == 10 && $] >= 5.008 && $] < 5.008003 && $UTF8 and
	    skip "Be reasonable, this perl version does not do Unicode reliable", 2;
	ok ($valid ? $row : !$row, "$tst - getline ESC +, '$sstr'");
	is ($err[0], $err, "Error expected $err");
	}
    }
