#!/pro/bin/perl

use 5.18.2;
use warnings;

use Data::Peek;
use Text::CSV_XS;

# First make two csv files, one with an empty (dangling) header column, one that's ok.
# These are both "Mac" format meaning only carriage returns for EOL.
my $fn_bad  = "rt123320_bad.csv";
my $fn_good = "rt123320_good.csv";
if (open my $bfh, ">", $fn_bad) {
    print $bfh join "\r" =>
	q{col1,col2,col3,},
	q{"One","","Three"},
	q{"Four","Five and a half","Six"},
	q{};
    close $bfh;
    }
if (open my $gfh, ">", $fn_good) {
    print $gfh join "\r" =>
	q{col1,col2,col3},
	q{"One","Two","Three"},
	"";
    close $gfh;
    }
-e $fn_bad  or die "$fn_bad missing!\n";
-e $fn_good or die "$fn_good missing!\n";

my $csv = Text::CSV_XS->new ({ binary => 1, auto_diag => 1, eol => "\r", });

open my $bfh, "<", $fn_bad  or die "$!\n";
open my $gfh, "<", $fn_good or die "$!\n";

# Get the header of the bad file (this will fail).
my @bad_header;
eval {
    local $@;
    @bad_header = $csv->header ($bfh);
    DDumper { header_from_bad => \@bad_header };
    1;
    } or warn "Failed to get header from $fn_bad!\n";

# Get the header of the good file (this will fail too but should not).
my @good_header;
eval {
    local $@;
    @good_header = $csv->header ($gfh);
    DDumper { header_from_good => \@good_header };
    1;
    } or print "Failed to get header from $fn_good!\n";

close $bfh;
close $gfh;
