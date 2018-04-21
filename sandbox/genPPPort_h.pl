#!/pro/bin/perl

use strict;
use warnings;

use Devel::PPPort;
use File::Copy;

# Check to see if ppport needs updating
my $ph = "ppport.h";

if (-f $ph) {
    my ($cv) = (qx{perl $ph --version} =~ m{\b([0-9]\.\w+)});
    if ($Devel::PPPort::VERSION lt $cv) {
	warn "Your $ph is newer than Devel::PPPort. Update skipped\n";
	}
    else {
	my $old = do { local (@ARGV, $/) = ($ph); <> };
	move $ph, "$ph.bkp";

	Devel::PPPort::WriteFile ("ppport.h");

	my $new = do { local (@ARGV, $/) = ($ph); <> };

	if ($old ne $new) {
	    warn "ppport.h updated to $Devel::PPPort::VERSION\n";
	    unlink "$ph.bkp";
	    }
	else {
	    unlink $ph;
	    move "$ph.bkp", $ph;
	    }
	}
    }
else {
    Devel::PPPort::WriteFile ("ppport.h");
    warn "Installed new ppport.h $Devel::PPPort::VERSION\n";
    }

my $ppp = qx{perl $ph --compat-version=5.6.1 --quiet CSV_XS.xs};

$ppp or exit 0;
warn "Devel::PPPort suggests the following change:\n--8<---\n",
    $ppp, "-->9---\n",
    "run 'perl $ph --compat-version=5.6.1 CSV_XS.xs' to see why\n";
