#!/pro/bin/perl

use strict;
use File::Spec;

$] >= 5.006 and exit 0;

my $pm;
foreach my $d (@INC) {
    $pm = File::Spec->catfile ($d, "Text", "CSV_XS.pm");
    -f $pm and last;
    }
-f $pm	or die "CSV_XS.pm is missing\n";

print STDERR "Changing 'use warnings;' to 'local \$^W = 1;' in $pm ...\n";
my $mod;
{   local (@ARGV, $/) = ($pm);
    ($mod = <>) =~ s{^use warnings;}{local \$^W = 1;}m;
    }

chmod 0666, $pm;
unlink $pm;
open    PM, "> $pm" or die "Cannot rewrite $pm: $!\n";
binmode PM;
print   PM $mod;
close   PM;
chmod 0444, $pm;
