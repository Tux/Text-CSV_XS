#!/usr/bin/perl

use strict;
use warnings;

#use Test::More "no_plan";
 use Test::More tests => 17;

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

unlink $file;
