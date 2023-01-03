#!/pro/bin/perl

use 5.018002;
use warnings;

use JSON;
use Data::Peek;
use Text::CSV_XS;

my $data = <<\csv;
f1,f2
1.1,2
4.2,5
4.4,6
3.2,5
csv

open my $fh, "<", \$data or die $!;

my $csv   = Text::CSV_XS->new;
my $csv_t = Text::CSV_XS->new;

my @result;

push @result => { head => $csv->getline ($fh) }; # ok: expecting strings

$csv->types   ([ Text::CSV_XS::NV, Text::CSV_XS::IV ]);
push @result => { exp_num => $csv->getline ($fh) }; # err: expecting numbers, but got strings

$csv_t->types ([ Text::CSV_XS::NV, Text::CSV_XS::IV ]);
push @result => { exp_num => $csv_t->getline ($fh) }; # ok: expecting numbers

$csv_t->types (undef);
push @result => { exp_str => $csv_t->getline ($fh) }; # ok: expecting strings

$csv_t->types ([ Text::CSV_XS::NV, Text::CSV_XS::IV ]);
push @result => { exp_num => $csv_t->getline ($fh) }; # err: expecting numbers in JSON

print JSON->new->pretty->encode (\@result);
