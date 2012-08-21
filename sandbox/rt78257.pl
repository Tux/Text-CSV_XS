#!/pro/bin/perl

use strict;
use warnings;

# Programs that use an emulated IO class are now required to implement
# tell/seek/read. In Text-CSV_XS-0.88 it was enough to implement getline ().
# Could you make Text-CSV_XS deal with this kind of simplified IO classes?

BEGIN {

    package MyIO;
    sub new { return bless {c => 3}, shift }

    sub getline
    {
	my $self = shift;
	return undef if $self->{c} == 0;
	return join (",", 1 .. $self->{c}--) . "\n";
	}
    }

use Data::Peek;
use Text::CSV_XS ();
print $Text::CSV_XS::VERSION, "\n";
my $io  = MyIO->new;
DPeek ($io->can ("tell"));
my $csv = Text::CSV_XS->new;
while (my $row = $csv->getline ($io)) {
    DDumper $row;
    }
