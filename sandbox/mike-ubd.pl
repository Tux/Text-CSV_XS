#!/pro/bin/perl

use 5.014002;
use warnings;

use CSV;

my @cols;
my $aoa = csv (
    in           => shift,
    auto_diag    => 1,
    keep_headers => \@cols,
#   callbacks    => { error => sub { DDumper [ @_ ] }},
    on_error     => sub { DDumper [ @_ ] },
    );

DDumper { aoa => $aoa };
Text::CSV_XS->error_diag;
