#!/pro/bin/perl

use 5.016;
use warnings;
use autodie;

use lib qw( blib/lib blib/arch );

sub build
{
    my $bs = shift;

    open my $fh, "<", "CSV_XS.xs";
    my $xs = do { local $/; <$fh> };
    close $fh;
    $xs =~ s{^#define\s+BUFFER_SIZE\s+\K[0-9]+}{$bs}m;
    open    $fh, ">", "CSV_XS.xs";
    print $fh $xs;
    close $fh;

    qx{make};
    } # build

build (1024);
my ($np, $ng) = qx{perl buftest2.pl} =~ m/:\s+([0-9.]+)/g;
say "print: $np/s, getline: $ng/s";

for ( 4 .. 16 ) {
    build (1 << $_);

    system "perl", "buftest2.pl", $np, $ng;
    }
