#!/pro/bin/perl

use strict;
use warnings;

use Text::CSV_XS;
use Text::CSV_PP;
use Time::HiRes qw( gettimeofday tv_interval );

my ($csv, $fh, $n, @row);

my %test = (
    perl => sub {
		while (<$fh>) {
		    $csv->parse ($_) or die $csv->error_diag;
		    $n++;
		    @row = $csv->fields;
		    $row[2] eq "Text::CSV_XS" or die "Parse error";
		    }
		},
    gtln => sub {
		while (my $row = $csv->getline ($fh)) {
		    $n++;
		    $row->[2] eq "Text::CSV_XS" or die "Parse error";
		    }
		},
    bndc => sub {
		$csv->bind_columns (\(@row));
		while (my $row = $csv->getline ($fh)) {
		    $n++;
		    $row[2] eq "Text::CSV_XS" or die "Parse error";
		    }
		},
    );

print "           lines   cols  file size file\n",
      "         ========= ==== ========== ========\n";
foreach my $nc (4, 16, 64, 512, 2048) {
    foreach my $nr (4, 16, 1024, 10240, 102400) {
	$nr * $nc > 48_000_000 and next;
	my $fnm = "test.csv";	END { unlink $fnm }
	system "gencsv.pl", "-n", "-o", $fnm, $nc, $nr + 1;
	my $fsz = -s $fnm or next;	# Failed to create test file
	printf "-------  %9d x %4d %10d %s\n", $nr, $nc, $fsz, $fnm;
	my $slowest;
	foreach my $test ("xs_perl", "xs_gtln", "xs_bndc", "pp_perl", "pp_gtln") {
	    my ($typ, $meth) = ($test =~ m/^(\w\w)_(.*)/);
	    $typ eq "pp" && $fsz > 10_000_000 and next;
	    open $fh, "<", $fnm or die "$fnm: $!";
	    $csv = "Text::CSV_\U$typ"->new ({ binary => 1 });
	    $csv->parse (scalar <$fh>) or die $csv->error_diag;
	    @row = $csv->fields;
	    my $ncol = @row;
	    my $start = [ gettimeofday ];
	    $n = 0;
	    $test{$meth}->();
	    my $used = tv_interval ($start, [ gettimeofday ]);
	    $slowest //= $used;
	    printf STDERR "$test: %9d x %4d parsed in %9.3f seconds - %4d\n",
		$n, $ncol, $used, int (100 * $used / $slowest);
	    eof   $fh or die $csv->error_diag;
	    close $fh or die "$fnm: $!";
	    }
	}
    }
