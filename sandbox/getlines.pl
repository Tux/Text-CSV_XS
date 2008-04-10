#!/usr/bin/perl -w

require 5.005;
use strict;

use IO::Handle;
use Text::CSV_XS;
use Benchmark qw(:all);

our $csv = Text::CSV_XS->new ({ eol => "\n" });

my $duration = int (shift || 10);
my $bigfile = "_file.csv";
our @fields1 = (
    "Wiedmann", "Jochen",
    "Am Eisteich 9",
    "72555 Metzingen",
    "Germany",
    "+49 7123 14881",
    "joe\@ispsoft,de");
our @fields10  = (@fields1) x 10;

sub max { $_[0] >= $_[1] ? $_[0] : $_[1] }
my $line_count = max (100_000, 20_000 * $duration);

open our $io, ">", $bigfile;
$csv->print ($io, \@fields10) or die "Cannot print ()\n";
timethese ($line_count, { "print    io" => q{ $csv->print ($io, \@fields10) }});
close   $io;
-s $bigfile or die "File is empty!\n";
open    $io, "<", $bigfile;
timethese ($line_count, { "getline  io" => q{ my $ref = $csv->getline ($io) }});
close   $io;
open    $io, "<", $bigfile;
my @f = @fields10;
$csv->bind_columns (\(@f));
timethese ($line_count, { "getline  io" => q{ my $ref = $csv->getline ($io) }});
close   $io;
print "File was ", -s $bigfile, " bytes long\n";
unlink $bigfile;
