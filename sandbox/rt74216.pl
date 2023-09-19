#!/pro/bin/perl

use strict;
use warnings;
use Test::More;
use Text::CSV_XS;

slurp_check ();

my $crlf = "\015\012";
my $csv_data = "a,b,c" . $crlf . "1,2,3" . $crlf;
open my $csv_fh, "<", \$csv_data or die $!;
my $csv = Text::CSV_XS->new ({ eol => $crlf });
my $csv_parse = $csv->getline ($csv_fh);

## now prints 1
slurp_check ();

## restore $/ to get 100 again
{ local $/ = "\n"; slurp_check () }

done_testing ();

sub slurp_check
{
    my $data = join "\n", 1 .. 100;
    open my $fh, "<", \$data or die $!;
    is (scalar @{[<$fh>]}, 100);
    close $fh;
    }
