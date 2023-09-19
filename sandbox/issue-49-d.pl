#!/pro/bin/perl

use 5.018002;
use warnings;

use Text::CSV_XS;
use Sereal::Decoder qw( decode_sereal );
use Storable;

-d "sandbox" and chdir "sandbox";

local $| = 1;

my $csv_st    = retrieve "somefile.storable";
my $result_st = $csv_st->parse ("some:string");
print "Parsed storable\n";
my @parts_st  = $csv_st->fields;
print "Done storable\n";

my $file = "somefile.sereal";
open my $fh, "<", $file or die "Cannot open file, $!";
$fh->binmode;
my $data = do { local $/ = undef; <$fh> };
$fh->close;

my $csv = decode_sereal $data;

my $result = $csv->parse ("some:string");
print "Parsed sereal\n";
my @parts  = $csv->fields;

print "Done sereal\n";
