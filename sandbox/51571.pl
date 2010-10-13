#!/pro/bin/perl

use strict;
use warnings;

my ($diag, $recode) = (@ARGV, 0, 0);

use Test::More;
#se Test::NoWarnings;
use Data::Peek;
use Text::CSV_XS;

BEGIN {
    binmode Test::More->builder->$_, ":utf8"
	for qw(output failure_output todo_output);
    }

diag ("Using version $Text::CSV_XS::VERSION");

my $csv = Text::CSV_XS->new ({
    eol       => "\n",
    binary    => 1,
    auto_diag => 1,
    });

my @row = ("\x{2122}", "\x{A9}", "&");
#$recode and chop (@row = map { $_."\x{20ac}" } @row);
$recode and @row = map { utf8::upgrade (my $x = $_); $x } @row;
$diag and diag ("row: (@{[map{DPeek($_)}@row]})");
my $exp = qq("\x{2122}",\x{A9},&\n);
$diag and diag ("exp: ".DPeek ($exp));

ok ($csv->combine (@row));
my $line = $csv->string;
$diag and diag ("got: ".DPeek ($line));

is ($line, $exp, "combine/string result as expected");

$diag and diag ("exp: ".DDump ($exp));
$diag and diag ("got: ".DDump ($line));

my $file = "";
open my $fh, ">:encoding(windows-1252)", \$file;
ok ($csv->print ($fh, \@row));
close $fh;

$diag and diag (DPeek ($file));

open $fh, "<:encoding(windows-1252)", \$file;
$line = <$fh>;
$diag and diag (DPeek ($line));
is ($line, $exp, "print result as expected");

done_testing;
