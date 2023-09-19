#!/pro/bin/perl

use strict;
use warnings;
use Config;

BEGIN { $ENV{PERL_DESTRUCT_LEVEL} = 2; }

my $PL = $^X;

chomp (my ($vsn) = grep m/^This/, `$PL -v`);
print "-" x 8, " ", "-" x 30, " ", "-" x 90, "\n";
printf "%8s %-30s %s\n", $Config{version}, $PL, $vsn;
print "-" x 8, " ", "-" x 30, " ", "-" x 90, "\n";

$_ = `rm -rf blib`;
$_ = `$PL Makefile.PL 2>/dev/null`;
-f "Makefile" or exit 1;

$_ = `make 2>/dev/null`;

open my $fh, "valgrind --leak-check=full $PL -Mblib sandbox/rt116085.pl 2>&1 |";
while (<$fh>) {
    m/\b(lost|reachable|suppressed):/ or next;
    s/^==\d+==//;
    print;
    }
close $fh;

print "\n";
