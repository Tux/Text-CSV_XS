#!/pro/bin/perl

use 5.018;
use warnings;

use Clone;
use Text::CSV_XS;

warn "Using Text::CSV_XS version $Text::CSV_XS::VERSION\n";
warn "Using Clone version $Clone::VERSION\n";

my $csv = Text::CSV_XS->new ();

warn "Cloning...\n";
my $clone1 = eval { Clone::clone $csv };
warn "Cloned before parsing\n";

$csv->parse ("a,b");
warn "Ran $csv->parse.\n";

warn "Cloning...\n";
my $clone2 = eval { Clone::clone $csv };
warn "Cloned after parsing\n";
