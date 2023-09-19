#!/pro/bin/perl

use strict;
use warnings;

use Text::CSV_XS;
use Text::CSV_PP;
use Time::HiRes qw( gettimeofday tv_interval );

my ($csv, $fh, $n, @row);

my %test = (
    join => sub {
		for (1..shift) {
		    print $fh join "," => @row;
		    }
		},
    perl => sub {
		for (1..shift) {
		    $csv->combine (@row);
		    print $fh $csv->string;
		    }
		},
    prnt => sub {
		for (1..shift) {
		    $csv->print ($fh, \@row);
		    }
		},
    bndc => sub {
		for (1..shift) {
		    $csv->print ($fh, undef);
		    }
		},
    );

my %res;
print <<EOH;
perl-$]
Text::CSV_XS-$Text::CSV_XS::VERSION
Text::CSV_PP-$Text::CSV_PP::VERSION

test       lines     cols  file size file
-------  ---------   ---- ---------- --------
EOH
foreach my $nc (4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048) {
    #foreach my $nr (4, 16, 1024, 10240, 102400) {
    foreach my $nr (2048) {
	my $fnm = "test.csv";	END { unlink $fnm }
	system "gencsv.pl", "-n", "-o", $fnm, $nc, 2;
	my $fsz = -s $fnm or next;	# Failed to create test file
	printf "-------  %9d x %4d %10d %s\n", $nr, $nc, $fsz, $fnm;
	$csv = "Text::CSV_XS"->new ({ binary => 1 });
	open $fh, "<", $fnm or die "$fnm: $!";
	$csv->getline ($fh);
	@row = @{$csv->getline ($fh)};
	close $fh;
	unlink $fnm;
	open $fh, ">", "/dev/null" or die "/dev/null: $!";

	my $slowest;
	foreach my $typ ("xs", "pp") {
	    #$typ eq "pp" && $fsz > 10_000_000 and next;
	    foreach my $test ("perl", "prnt", "bndc", "join") {
		"$typ$test" eq "ppjoin" and next; # Only run once
		"$typ$test" eq "ppbndc" and next; # Not yet in PP
		unless ($test eq "join") {
		    $csv = "Text::CSV_\U$typ"->new ({ binary => 1, eol => "\n" });
		    $test eq "bndc" and $csv->bind_columns (\(@row));
		    }
		my $start = [ gettimeofday ];
		$n = 0;
		$test{$test}->($nr);
		my $used = tv_interval ($start, [ gettimeofday ]);
		$slowest //= $used;
		my $speed = int (100 * $used / $slowest);
		printf "$typ $test: %9d x %4d printed in %9.3f seconds - %4d\n",
		    $nr, $nc, $used, $speed;
		$nr == 1024 and $res{$nc}{"$typ $test"} = $speed;
		}
	    }
	close $fh;
	}
    }

binmode STDOUT, ":utf8";
$csv = Text::CSV_XS->new ({ eol => "\r\n" });
foreach my $nc (sort { $a <=> $b } keys %res) {
    $csv->print (*STDOUT, [ $nc, @{$res{$nc}}{
	  "xs perl", "xs prnt", "xs bndc", "pp perl", "pp prnt", "pp bndc",
	  "pp join" } ]);
    }
