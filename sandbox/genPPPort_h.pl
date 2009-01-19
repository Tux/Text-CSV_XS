#!/pro/bin/perl

use strict;
use warnings;

use Devel::PPPort;
use File::Copy;

# Check to see if ppport needs updating
my $ph = "ppport.h";

my $old = do { local (@ARGV, $/) = ($ph); <> };
move $ph, "$ph.bkp";

Devel::PPPort::WriteFile ("ppport.h");

my $new = do { local (@ARGV, $/) = ($ph); <> };

if ($old ne $new) {
    print STDERR "ppport.h updated to $Devel::PPPort::VERSION\n";
    unlink "$ph.bkp";
    }
else {
    unlink $ph;
    move "$ph.bkp", $ph;
    }
