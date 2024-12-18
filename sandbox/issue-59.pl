#!/pro/bin/perl

use 5.038;
use Text::CSV_XS;

my $tfn = "issue-59.csv";

open my $fh, ">", $tfn or die "$tfn: $!\n";
print   $fh "Antelope,snort\r\n";
print   $fh "Badger,growl\n"; # only newline
print   $fh "Bat,screech\r\n";
print   $fh "Bear,roar\r"; # only carriage return - no newline
print   $fh "Bee,buzz\r\n";
print   $fh "Camel,grunt\r\n";
print   $fh "Cobra,shh\r\r"; # two CR's
print   $fh "Crow,caw\r\n";
print   $fh "Deer,bellow\n"; # only newline
print   $fh "Dolphin,click\r\n";
close   $fh;

foreach my $ser (0, 1) {
    foreach my $reset (0, 1) {
	foreach my $se (0, 1) {
	    say "###### Test Reset: $reset, strict_eol: $se, skip-empty-rows: $ser";
	    open $fh, "<", $tfn or die "$tfn: $!\n";
	    my $csv = Text::CSV_XS->new ({
		auto_diag       => 1,
		strict_eol      => $se,
		skip_empty_rows => $ser,
		});

	    while (my $row = $csv->getline ($fh)) {
		say @$row > 1
		    ? join "\tmakes " => map { $_ || "-" } @$row
		    : "-- Empty row --";
		$reset and $csv->eol (undef);
		}
	    $csv->_cache_diag;
	    }
	}
    }

unlink $tfn;
