#!/pro/bin/perl

use 5.018002;
use warnings;

use Text::CSV_XS;
use Sereal::Encoder qw ( encode_sereal );
use Storable;

-d "sandbox" and chdir "sandbox";

my $csv = Text::CSV_XS->new ({ sep_char => ':' });

my $result = $csv->parse ("some:string");
my @parts  = $csv->fields;

open my $fh, ">", "somefile.sereal";
$fh->binmode;
print { $fh } encode_sereal ($csv);
close $fh;

store $csv, "somefile.storable";

print "Done\n";
