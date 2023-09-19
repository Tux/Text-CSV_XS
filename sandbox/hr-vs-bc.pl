#!/pro/bin/perl

use v5.12;
use warnings;
use autodie;

use Data::Peek;
use Text::CSV_XS;

my $data = join "\n" =>
    "code,name,price,description,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0",
    map {
	qq{$_,"art$_",@{[rand 100]},"Product $_",0,1,2,3,4,5,6,7,8,9};
	} 100_000 .. 199_999;

sub hr
{
    my $csv = Text::CSV_XS->new ({ auto_diag => 1 });

    open my $fh, "<", \$data;
    my @cols = @{$csv->getline ($fh)};
    $csv->column_names (@cols);
    while (my $row = $csv->getline_hr ($fh)) { }
    }

sub bc
{
    my $csv = Text::CSV_XS->new ({ auto_diag => 1 });

    open my $fh, "<", \$data;
    my @cols = @{$csv->getline ($fh)};
    my $row = {};
    $csv->bind_columns (\@{$row}{@cols});
    while ($csv->getline ($fh)) { }
    }

use Benchmark "cmpthese";
cmpthese (20, {
    hashrefs	=> \&hr,
    getlines	=> \&bc,
    });
