#!/pro/bin/perl

use strict;
use warnings;
use autodie;

use Time::Local;
use Data::Peek;
use Text::CSV_XS;
use Devel::Size qw( size total_size );

my $file = shift;

print "Reading $file with Text::CSV_XS-$Text::CSV_XS::VERSION ...\n";

my $csv = Text::CSV_XS->new ({ binary => 1, auto_diag => 1 });

open my $fh, "<:encoding(utf-8)", $file;
my @dta;
while (my $row = $csv->getline ($fh)) {
    $row->[$_] = date2tm ($row->[$_]) for 1, 7;
    push @dta, $row;
    }
my $dta = \@dta;

printf "Data size = %d, total size = %d\n", size ($dta), total_size ($dta);

sub date2tm
{
    $_[0] && $_[0] =~ m/^
	([0-9]{4})-([0-2][0-9])-([0-3][0-9]) \s+
	([0-2][0-9]):([0-5][0-9]):([0-5][0-9])
	/x or return 0;
    timelocal ($6, $5, $4, $3, $2 - 1, $1 - 1900);
    } # date2tm
