#!/pro/bin/perl

use strict;
use warnings;

use Devel::PPPort;
use File::Copy;

# Check to see if ppport needs updating
my $ph = "ppport.h";

my ($cv) = (qx{perl $ph --version} =~ m{\b([0-9]\.\w+)});
if ($Devel::PPPort::VERSION lt $cv) {
    print STDERR "Your $ph is newer than Devel::PPPort. Update skipped\n";
    exit 0;	# I have a newer already
    }

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
