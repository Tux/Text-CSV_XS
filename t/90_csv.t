#!/usr/bin/perl

use strict;
use warnings;
use Config;

#use Test::More "no_plan";
 use Test::More tests => 40;

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

my @hdr = qw( foo bar baz );
my $aoa = [
    \@hdr,
    [ 1, 2, 3 ],
    [ 2, "a b", "" ],
    ];
my $aoh = [
    { foo => 1, bar => 2, baz => 3 },
    { foo => 2, bar => "a b", baz => "" },
    ];

SKIP: for my $io ([ $file, "file" ], [ \*FH, "globref" ], [ *FH, "glob" ], [ \$data, "ScalarIO"] ) {
    $] < 5.008 && ref $io->[0] eq "SCALAR" and skip "No ScalarIO support for $]", 1;
    open FH, "<", $file;
    is_deeply (csv ({ in => $io->[0] }), $aoa, "AOA $io->[1]");
    close FH;
    }

SKIP: for my $io ([ $file, "file" ], [ \*FH, "globref" ], [ *FH, "glob" ], [ \$data, "ScalarIO"] ) {
    $] < 5.008 && ref $io->[0] eq "SCALAR" and skip "No ScalarIO support for $]", 1;
    open FH, "<", $file;
    is_deeply (csv (in => $io->[0], headers => "auto"), $aoh, "AOH $io->[1]");
    close FH;
    }

is_deeply (csv (in => $file, headers => { bar => "tender" }), [
    { foo => 1, tender => 2,     baz => 3 },
    { foo => 2, tender => "a b", baz => "" },
    ], "AOH with header map");

my @aoa = @{$aoa}[1,2];
is_deeply (csv (file => $file, headers  => "skip"),    \@aoa, "AOA skip");
is_deeply (csv (file => $file, fragment => "row=2-3"), \@aoa, "AOA fragment");

if ($] >= 5.008001) {
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

my $idx = 0;
sub getrowa { return $aoa->[$idx++]; }
sub getrowh { return $aoh->[$idx++]; }

ok (csv (in => \&getrowa, out => $file), "out from CODE/AR");
is_deeply (csv (in => $file), $aoa, "data from CODE/AR");

$idx = 0;
ok (csv (in => \&getrowh, out => $file, headers => \@hdr), "out from CODE/HR");
is_deeply (csv (in => $file, headers => "auto"), $aoh, "data from CODE/HR");

$idx = 0;
ok (csv (in => \&getrowh, out => $file), "out from CODE/HR (auto headers)");
is_deeply (csv (in => $file, headers => "auto"), $aoh, "data from CODE/HR");
unlink $file;

# Basic "key" checks
SKIP: {
    $] < 5.008 and skip "No ScalarIO support for $]", 2;
    is_deeply (csv (in => \"key,value\n1,2\n", key => "key"),
		    { 1 => { key => 1, value => 2 }}, "key");
    is_deeply (csv (in => \"1,2\n", key => "key", headers => [qw( key value )]),
		    { 1 => { key => 1, value => 2 }}, "key");
    }

# Some "out" checks
open my $fh, ">", $file;
csv (in => [{ a => 1 }], out => $fh);
csv (in => [{ a => 1 }], out => $fh, headers => undef);
csv (in => [{ a => 1 }], out => $fh, headers => "auto");
csv (in => [{ a => 1 }], out => $fh, headers => ["a"]);
csv (in => [{ b => 1 }], out => $fh, headers => { b => "a" });
close $fh;
open  $fh, "<", $file;
is (do {local $/; <$fh>}, "a\r\n1\r\n" x 5, "AoH to out");
close $fh;

# check internal defaults
{
    my $ad = 1;

    sub check
    {
	my ($csv, $ar) = @_;
	is ($csv->auto_diag,	$ad,	"default auto_diag ($ad)");
	is ($csv->binary,	1,	"default binary");
	is ($csv->eol,		"\r\n",	"default eol");
	} # check

    open my $fh, ">", \my $out;
    csv (in => [[1,2]], out => $fh, on_in => \&check);

    # Check that I can overrule auto_diag
    $ad = 0;
    csv (in => [[1,2]], out => $fh, on_in => \&check, auto_diag => 0);
    }

# errors
{   my $err;
    local $SIG{__DIE__} = sub { $err = shift; };
    my $r = eval { csv (in => undef); };
    is ($r, undef, "csv needs in or file");
    like ($err, qr{^usage:}, "error");
    undef $err;
    }

eval {
    exists  $Config{useperlio} &&
    defined $Config{useperlio} &&
    $] >= 5.008                &&
    $Config{useperlio} eq "define" or skip "No scalar ref in this perl", 4;
    my $out = "";
    open my $fh, ">", \$out;
    ok (csv (in => [[ 1, 2, 3 ]], out => $fh), "out to fh to scalar ref");
    is ($out, "1,2,3\r\n",	"Scalar out");
    $out = "";
    ok (csv (in => [[ 1, 2, 3 ]], out => \$out), "out to scalar ref");
    is ($out, "1,2,3\r\n",	"Scalar out");
    };
