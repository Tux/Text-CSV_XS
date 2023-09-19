#!/pro/bin/perl

use strict;
use warnings;
use Text::CSV_XS;

my $input = <<EOT;
a,b,c,d
e,f,g,h
EOT

my $r = eval { main () };
unless ($r) {
    print "Got an error [$@]\n";
    }

sub main
{
    my @cols = 1 .. 3;
    my $csv = Text::CSV_XS->new ({binary => 1, eol => $/, auto_diag => 2});
    my %row;
    $csv->bind_columns (\@row{@cols});
    open (my $fh, "<", \$input) or die "Err: $!";

    while ($csv->getline ($fh)) {
	print "Got: ", join ("|", @row{@cols}), "\n";
	}
    return 1;
    } # main
