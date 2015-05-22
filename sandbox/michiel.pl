use v5.14;
use warnings;

use HTTP::Tiny;
use JSON::PP;
use Data::Peek;
use Text::CSV_XS qw (csv);
use Time::Piece;

my $url = "https://gist.githubusercontent.com/jorin-vogel/7f19ce95a9a842956358/raw/e319340c2f6691f9cc8d8cc57ed532b5093e3619/data.json";

my $http = HTTP::Tiny->new ();
my $response = $http->get ($url);

# weed out records without credit card #
my @data = grep ($_->{creditcard}, @{decode_json $response->{content}});

DDumper \@data;

my $time = localtime;

my @hdr = qw( name creditcard );
csv ( in => [map { [ @{$_}{@hdr} ] } @data ], headers => \@hdr);
      #out => $time->ymd(""). ".csv",
