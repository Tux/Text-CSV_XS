#!/pro/bin/perl

use 5.14.1;
use warnings;

use Data::Peek;
use Text::CSV_XS "csv";

my %hash;
csv (in => "pm1227312.csv", out => undef, on_in => sub {
    my ($key, $value) = @{$_[1]};
    $key && $key !~ m/^\s*(?:#|$)/ and $hash{$key} = $value;
    });
DDumper \%hash;

%hash = map { @$_ } @{csv (in => "pm1227312.csv", filter => { 0 => sub { !m/^\s*(?:#|$)/ }})};
DDumper \%hash;
