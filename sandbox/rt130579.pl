#!/pro/bin/perl

use 5.18.3;
use warnings;

use Text::CSV_XS;

use Data::Peek;

my @hdr = map { "a$_" } "01".."39";
my $row = {};
my $reader = new Text::CSV_XS ({
    binary              => 1,
    sep_char            => "|",
#   allow_loose_quotes  => 1,
#   allow_loose_escapes => 1,
    quote_char          => undef,
    escape_char		=> undef,
    auto_diag           => 1,
    });
$reader->bind_columns (\@{$row}{@hdr});

DDumper ($reader->getline (*DATA));
DDumper ($row);
__END__
val1|val2|val3|val4|val5|val6|val7|val8|val9|val10"|val11|val12|val13|val14|val15|val16|val17|val18|val19|val20|val21|val22|val23|val24|val25|val26|val27|val28|val29|val30|val31|val32|val33|val34|val35|val36|val37|val38|val39
