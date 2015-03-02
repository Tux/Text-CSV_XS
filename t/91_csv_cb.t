#!/usr/bin/perl

use strict;
use warnings;

#use Test::More "no_plan";
 use Test::More tests => 22;

BEGIN {
    use_ok "Text::CSV_XS", ("csv");
    plan skip_all => "Cannot load Text::CSV_XS" if $@;
    require "t/util.pl";
    }

my $file = "_91test.csv"; END { -f $file and unlink $file }
my $data =
    "foo,bar,baz\n".
    "1,2,3\n".
    "2,a b,\n";
open  FH, ">", $file or die "$file: $!";
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

for (qw( after_in on_in before_out )) {
    is_deeply (csv (in => $file, $_ => sub {}), $aoa, "callback $_ on AOA with empty sub");
    is_deeply (csv (in => $file, callbacks => { $_ => sub {} }), $aoa, "callback $_ on AOA with empty sub");
    }
is_deeply (csv (in => $file, after_in => sub {},
    callbacks => { on_in => sub {} }), $aoa, "callback after_in and on_in on AOA");

for (qw( after_in on_in before_out )) {
    is_deeply (csv (in => $file, headers => "auto", $_ => sub {}), $aoh, "callback $_ on AOH with empty sub");
    is_deeply (csv (in => $file, headers => "auto", callbacks => { $_ => sub {} }), $aoh, "callback $_ on AOH with empty sub");
    }
is_deeply (csv (in => $file, headers => "auto", after_in => sub {},
    callbacks => { on_in => sub {} }), $aoh, "callback after_in and on_in on AOH");

is_deeply (csv (in => $file, after_in => sub { push @{$_[1]}, "A" }), [
    [qw( foo bar baz A )],
    [ 1, 2, 3, "A" ],
    [ 2, "a b", "", "A" ],
    ], "AOA ith after_in callback");

is_deeply (csv (in => $file, headers => "auto", after_in => sub { $_[1]{baz} = "A" }), [
    { foo => 1, bar => 2, baz => "A" },
    { foo => 2, bar => "a b", baz => "A" },
    ], "AOH with after_in callback");

is_deeply (csv (in => $file, filter => { 2 => sub { /a/ }}), [
    [qw( foo bar baz )],
    [ 2, "a b", "" ],
    ], "AOA with filter on col 2");
is_deeply (csv (in => $file, filter => { 2 => sub { /a/ },
					 1 => sub { length > 1 }}), [
    [qw( foo bar baz )],
    ], "AOA with filter on col 1 and 2");
is_deeply (csv (in => $file, filter => { foo => sub { $_ > 1 }}), [
    { foo => 2, bar => "a b", baz => "" },
    ], "AOH with filter on column name");

open  FH, ">>", $file or die "$file: $!";
print FH <<"EOD";
3,3,3
4,5,6
5,7,9
6,9,12
7,11,15
8,13,18
EOD
close FH;

is_deeply (csv (in => $file,
	filter => { foo => sub { $_ > 2 && $_[1][2] - $_[1][1] < 4 }}), [
    { foo => 3, bar => 3, baz =>  3 },
    { foo => 4, bar => 5, baz =>  6 },
    { foo => 5, bar => 7, baz =>  9 },
    { foo => 6, bar => 9, baz => 12 },
    ], "AOH with filter on column name + on other numbered fields");

is_deeply (csv (in => $file,
	filter => { foo => sub { $_ > 2 && $_{baz}  - $_{bar}  < 4 }}), [
    { foo => 3, bar => 3, baz =>  3 },
    { foo => 4, bar => 5, baz =>  6 },
    { foo => 5, bar => 7, baz =>  9 },
    { foo => 6, bar => 9, baz => 12 },
    ], "AOH with filter on column name + on other named fields");
