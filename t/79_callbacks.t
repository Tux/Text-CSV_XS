#!/usr/bin/perl

use strict;
use warnings;

 use Test::More tests => 57;
#use Test::More "no_plan";

BEGIN {
    require_ok "Text::CSV_XS";
    plan skip_all => "Cannot load Text::CSV_XS" if $@;
    require "t/util.pl";
    }

$| = 1;

ok (my $csv = Text::CSV_XS->new (), "new");
is ($csv->callbacks, undef,		"no callbacks");

ok ($csv->bind_columns (\my ($c, $s)),	"bind");
ok ($csv->getline (*DATA),		"parse ok");
is ($c, 1,				"key");
is ($s, "foo",				"value");
$s = "untouched";
ok ($csv->getline (*DATA),		"parse bad");
is ($c, 1,				"key");
is ($s, "untouched",			"untouched");
ok ($csv->getline (*DATA),		"parse bad");
is ($c, "foo",				"key");
is ($s, "untouched",			"untouched");
ok ($csv->getline (*DATA),		"parse good");
is ($c, 2,				"key");
is ($s, "bar",				"value");
eval { is ($csv->getline (*DATA), undef,"parse bad"); };
my @diag = $csv->error_diag;
is ($diag[0], 3006,			"too many values");

foreach my $args ([""], [1], [[]], [sub{}], [1,2], [1,2,3], ["error",undef]) {
    eval { $csv->callbacks (@$args); };
    my @diag = $csv->error_diag;
    is ($diag[0], 1004,			"invalid callbacks");
    is ($csv->callbacks, undef,		"not set");
    }

my $error = 3006;
sub ignore
{
    is ($_[0], $error, "Caught error $error");
    $csv->SetDiag (0); # Ignore this error
    } # ignore

my $idx = 1;
ok ($csv->auto_diag (1), "set auto_diag");
my $callbacks = {
    error        => \&ignore,
    after_parse  => sub {
	my ($c, $av) = @_;
	# Just add a field
	push @$av, "NEW";
	},
    before_print => sub {
	my ($c, $av) = @_;
	# First field set to line number
	$av->[0] = $idx++;
	# Maximum 2 fields
	@{$av} > 2 and splice @{$av}, 2;
	# Minimum 2 fields
	@{$av} < 2 and push @{$av}, "";
	},
    };
is (ref $csv->callbacks ($callbacks), "HASH", "callbacks set");
ok ($csv->getline (*DATA),		"parse ok");
is ($c, 1,				"key");
is ($s, "foo",				"value");
ok ($csv->getline (*DATA),		"parse bad, skip 3006");
ok ($csv->getline (*DATA),		"parse good");
is ($c, 2,				"key");
is ($s, "bar",				"value");

$csv->bind_columns (undef);
ok (my $row = $csv->getline (*DATA),	"get row");
is_deeply ($row, [ 1, 2, 3, "NEW" ],	"fetch + value from hook");

$error = 2012; # EOF
ok ($csv->getline (*DATA),		"parse past eof");

my $fn = "_79test.csv";
END { unlink $fn; }

ok ($csv->eol ("\n"), "eol for output");
open my $fh, ">", $fn or die "$fn: $!";
ok ($csv->print ($fh, [ 0, "foo"    ]), "print OK");
ok ($csv->print ($fh, [ 0, "bar", 3 ]), "print too many");
ok ($csv->print ($fh, [ 0           ]), "print too few");
close $fh;

open $fh, "<", $fn or die "$fn: $!";
is (do { local $/; <$fh> }, "1,foo\n2,bar\n3,\n", "Modified output");
close $fh;

is_deeply (Text::CSV_XS::csv (in => $fn, callbacks => $callbacks),
    [[1,"foo","NEW"],[2,"bar","NEW"],[3,"","NEW"]], "using getline_all");

# Test the non-IO interface
ok ($csv->parse ("10,blah,33\n"),			"parse");
is_deeply ([ $csv->fields ], [ 10, "blah", 33, "NEW" ],	"fields");

ok ($csv->combine (11, "fri", 22, 18),			"combine - no hook");
is ($csv->string, qq{11,fri,22,18\n},			"string");

__END__
1,foo
1
foo
2,bar
3,baz,2
1,foo
3,baz,2
2,bar
1,2,3
