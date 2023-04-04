#!/pro/bin/perl

use 5.036000;
use Text::CSV_XS 1.50 qw(csv);
use utf8;
use Data::Peek;

# Test input is CRLF.
my $ifn = shift or die "usage: $0 file.csv\n";

my %dta;
my $sct = "pt0";
my @hdr;

csv (in    => $ifn,
     out   => undef,
     on_in => sub {
	DDumper $_[1];
	if (@{$_[1]} == 1 && $_[1][0] eq "") {	# Empty row
	    @hdr = ();
	    $sct++;
	    return;
	    }
	unless (@hdr) {
	    @hdr = @{$_[1]};
	    return;
	    }
	my %r; @r{@hdr} = @{$_[1]};
	push @{$dta{$sct}} => \%r;
	},
    );
DDumper \%dta;
