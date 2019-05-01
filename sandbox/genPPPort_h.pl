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

	Devel::PPPort::WriteFile ($ph);

	my $new = do { local (@ARGV, $/) = ($ph); <> };

	if ($old ne $new) {
	    warn "$ph updated to $Devel::PPPort::VERSION\n";
	    unlink "$ph.bkp";
	    }
	else {
	    unlink $ph;
	    move "$ph.bkp", $ph;
	    }
	}
    }
else {
    Devel::PPPort::WriteFile ($ph);
    warn "Installed new $ph $Devel::PPPort::VERSION\n";
    }

my $cv = "5.6.1";
if (open my $fh, "<", "Makefile.PL") {
    local $/;
    if (<$fh> =~ m/^require\s+(5\.[0-9._]+)\b/) {
	my @v = split m/[._]/ => $1;
	$v[1] =~ m/^(\d\d\d)(.*)/ and splice @v, 1, 1, $1, $2;
	$v[2] ||= 0;
	$cv = join "." => map { $_ + 0 } @v;
	}
    }

warn "Checking against minimum perl version $cv\n";
my $ppp = qx{perl $ph --compat-version=$cv --quiet CSV_XS.xs};

$ppp or exit 0;
warn "Devel::PPPort suggests the following change:\n--8<---\n",
    $ppp, "-->9---\n",
    "run 'perl $ph --compat-version=$cv CSV_XS.xs' to see why\n";
