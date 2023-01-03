#!/pro/bin/perl

# Read the export from Thumbs Plus including keywords from filename given.

use 5.018002;	# 5.12 or later to get "unicode_strings" feature
use utf8;	# so literals and identifiers can be in UTF-8
use warnings  qw(FATAL utf8);    # fatalize encoding glitches
use Data::Peek;	# debug
use Text::CSV;

my $csv = Text::CSV->new ({ binary => 1, auto_diag => 1 });

my $fn = "pm-1192242.csv";
-d "sandbox" and substr $fn, 0, 0, "sandbox/";
say $fn;
open my $fh, "<", $fn or die "$fn: $!\n";
#open my $fh, "<:encoding(utf-8)", $fn or die "$fn: $!\n";
say "Point a";

# Returns "the instance" -- of what?  Do I care?
my @hdr = $csv->header ($fh, {
    munge_column_names => sub { state $i; $_ || "nothing.".$i++ }});
say "Point b";

DDumper { csv => $csv, hdr => \@hdr };
say for @hdr;
