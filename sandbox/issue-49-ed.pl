#!/pro/bin/perl

use 5.018002;
use warnings;

use Text::CSV_XS;
use Sereal::Encoder qw( encode_sereal );
use Sereal::Decoder qw( decode_sereal );
use Storable;

-d "sandbox" and chdir "sandbox";

my $fh;

my $csv = Text::CSV_XS->new ({sep_char => ":"});

my $result = $csv->parse ("some:string");
my @parts  = $csv->fields;

open $fh, ">", "somefile.sereal";
$fh->binmode;
print { $fh } encode_sereal ($csv);
close $fh;

store $csv, "somefile.storable";

print "Done stroring\n";

my $csv_st    = retrieve "somefile.storable";
my $result_st = $csv_st->parse ("some:string");
print "Parsed storable\n";
my @parts_st  = $csv_st->fields;
print "Done storable\n";

my $file = "somefile.sereal";
open $fh, $file or die "Cannot open file, $!";
$fh->binmode;
my $data = do { local $/ = undef; <$fh> };
$fh->close;

my $csv_se    = decode_sereal $data;
my $result_se = $csv_se->parse ("some:string");
print "Parsed sereal\n";
my @parts_se  = $csv_se->fields;

print "Done sereal\n";
