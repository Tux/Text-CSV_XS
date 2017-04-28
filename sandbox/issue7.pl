#!/pro/bin/perl

use 5.18.2;
use warnings;

use Text::CSV_XS qw (csv );

my @foo = map { [ 0 .. 5 ] } 0 .. 3;
csv (in => \@foo, out => \my $file);

print $file;
