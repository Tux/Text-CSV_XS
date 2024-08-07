use strict;
use warnings;

use Text::CSV_XS ();

my $csv = Text::CSV_XS->new ({
    strict       => 1,
    comment_str  => "#",
    sep_char     => "|",
    auto_diag    => 2,
    diag_verbose => 1,
    });

if (shift) {
    $csv->getline (*DATA);
    $csv->getline (*DATA);
    }
else {
    $csv->parse ("a|b");
    $csv->parse ("# some comment");
    }
__END__
a|b
# some comment
