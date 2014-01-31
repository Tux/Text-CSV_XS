#/pro/bin/perl

use 5.12.1;
use warnings;

use Test::More;

use Carp;
#use Data::Peek;
use Text::CSV_XS "csv";

my $lac = "sandbox/la.csv";
my $lat = "sandbox/la.txt";

my $r;
ok ($r = csv (in => $lac), "Default, only in => file");
is_deeply ($r, [["Foo","Bar"],[1,2],[2,3]]);

ok ($r = csv (in => $lac, headers => "skip"), "headers => skip");
is_deeply ($r, [[1,2],[2,3]]);

ok ($r = csv (in => $lac, fragment => "row=2-*"), "in with fragment");
is_deeply ($r, [[1,2],[2,3]]);

ok ($r = csv (in => $lac, headers => "auto"), "headers => auto");
is_deeply ($r, [{Foo=>1,Bar=>2},{Foo=>2,Bar=>3}]);

ok ($r = csv (in => $lac, headers => [qw( foo bar )]), "headers => [...]");
is_deeply ($r, [{foo=>"Foo",bar=>"Bar"},{foo=>1,bar=>2},{foo=>2,bar=>3}]);

my $aoa;
# with la.txt having a valid header
ok ($aoa = csv (in => $lat, sep_char => "|"), "txt with sep_char");
is (ref $aoa,      "ARRAY", "is array");
is (ref $aoa->[0], "ARRAY", "... of arrays");

ok (open my $fh, "<", $lat);
is_deeply (csv (in => $fh, sep_char => "|"), $aoa, "in is FH");

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

my $aoh = csv (in => $lat, sep_char => "|", headers => [qw( Name Hobby Age )]);
is (ref $aoh,      "ARRAY");
is (ref $aoh->[0], "HASH");
my %new = map { $_->{Name} => $_ } @{$aoh};

is_deeply (\%hoh, \%new, "New matches old");

is_deeply (csv (in => $lat, sep_char => "|", fragment => "col=1;3",
		     headers => [ "Name", "Age" ]),
   [ { Name => "Jan", Age =>  7, },
     { Name => "LA",  Age => 25, },
     { Name => "Tux", Age => 52, }]);

csv (in => $aoh, headers => "auto", out => "flubber.csv");

done_testing;
