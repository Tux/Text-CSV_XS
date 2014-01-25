#/pro/bin/perl

use 5.16.2;
use warnings;

use Test::More;

use Carp;
use Data::Peek;
use Text::CSV_XS "csv";

my $lac = "sandbox/la.csv";
my $lat = "sandbox/la.txt";

my $r;
ok ($r = csv (file => $lac));
is_deeply ($r, [["Foo","Bar"],[1,2],[2,3]]);

ok ($r = csv (file => $lac, headers => "skip"));
is_deeply ($r, [[1,2],[2,3]]);

ok ($r = csv (file => $lac, fragment => "row=2-*"));
is_deeply ($r, [[1,2],[2,3]]);

ok ($r = csv (file => $lac, headers => "auto"));
is_deeply ($r, [{Foo=>1,Bar=>2},{Foo=>2,Bar=>3}]);

ok ($r = csv (file => $lac, headers => [qw( foo bar )]));
is_deeply ($r, [{foo=>"Foo",bar=>"Bar"},{foo=>1,bar=>2},{foo=>2,bar=>3}]);

my $aoa;
# with la.txt having a valid header
ok ($aoa = csv (file => $lat, sep_char => "|"));
is (ref $aoa,      "ARRAY");
is (ref $aoa->[0], "ARRAY");

ok (open my $fh, "<", $lat);
is_deeply (csv (data => $fh, sep_char => "|"), $aoa);

my %hoh = (
    Jan              => {
        Name             => "Jan",
        Hobby            => "Birdwatching",
        Age              => 7,
        },
    LA               => {
        Name             => "LA",
        Hobby            => "coding",
        Age              => 25,
        },
    Tux              => {
        Name             => "Tux",
        Hobby            => "skiing",
        Age              => 52,
        }
    );

my $aoh = csv (file => $lat, sep_char => "|", headers => [qw( Name Hobby Age )]);
is (ref $aoh,      "ARRAY");
is (ref $aoh->[0], "HASH");
my %new = map { $_->{Name} => $_ } @{$aoh};

is_deeply (\%hoh, \%new, "New matches old");

is_deeply (csv (file => $lat, sep_char => "|", fragment => "col=1;3",
		     headers => [ "Name", "Age" ]),
   [ { Name => "Jan", Age =>  7, },
     { Name => "LA",  Age => 25, },
     { Name => "Tux", Age => 52, }]);

done_testing;
