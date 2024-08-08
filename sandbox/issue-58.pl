use strict;
use warnings;

use Text::CSV_XS ();

my $csv = Text::CSV_XS->new ({
    strict       => 1,
    sep_char     => "|",
    auto_diag    => 2,
    diag_verbose => 1,
    });

$csv->column_names (qw( A B C ));
if (shift) {
    $csv->getline (*DATA);
    }
else {
    $csv->parse ("a|b");
    }
__END__
a|b
