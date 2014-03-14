#!/usr/bin/perl

use strict;
use warnings;

#use Test::More "no_plan";
 use Test::More tests => 16;

BEGIN {
    use_ok "Text::CSV_XS", ("csv");
    plan skip_all => "Cannot load Text::CSV_XS" if $@;
    require "t/util.pl";
    }

my $file = "_90test.csv"; END { -f $file and unlink $file }
my $data =
    "foo,bar,baz\n".
    "1,2,3\n".
    "2,a b,\n";
open  FH, ">", $file or die "_90test.csv: $!";
print FH $data;
close FH;

my $aoa = [
    [qw( foo bar baz )],
    [ 1, 2, 3 ],
    [ 2, "a b", "" ],
    ];
my $aoh = [
    { foo => 1, bar => 2, baz => 3 },
    { foo => 2, bar => "a b", baz => "" },
    ];

for my $io ([ $file, "file" ], [ \*FH, "globref" ], [ *FH, "glob" ]) {
    open FH, "<", $file;
    is_deeply (csv ({ in => $io->[0] }), $aoa, "AOA $io->[1]");
    close FH;
    }

for my $io ([ $file, "file" ], [ \*FH, "globref" ], [ *FH, "glob" ]) {
    open FH, "<", $file;
    is_deeply (csv (in => $io->[0], headers => "auto"), $aoh, "AOH $io->[1]");
    close FH;
    }

my @aoa = @{$aoa}[1,2];
is_deeply (csv (file => $file, headers  => "skip"),    \@aoa, "AOA skip");
is_deeply (csv (file => $file, fragment => "row=2-3"), \@aoa, "AOA fragment");

if ($] >= 5.008) {
    is_deeply (csv (in => $file, encoding => "utf-8", headers => ["a", "b", "c"],
		    fragment => "row=2", sep_char => ","),
	   [{ a => 1, b => 2, c => 3 }], "AOH headers fragment");
    }
else {
    ok (1, q{This perl does not support open with "<:encoding(...)"});
    }

ok (csv (in => $aoa, out => $file), "AOA out file");
is_deeply (csv (in => $file), $aoa, "AOA parse out");

ok (csv (in => $aoh, out => $file, headers => "auto"), "AOH out file");
is_deeply (csv (in => $file, headers => "auto"), $aoh, "AOH parse out");

ok (csv (in => $aoh, out => $file, headers => "skip"), "AOH out file no header");
is_deeply (csv (in => $file, headers => [keys %{$aoh->[0]}]),
    $aoh, "AOH parse out no header");

unlink $file;
