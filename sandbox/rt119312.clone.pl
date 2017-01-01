#!/pro/bin/perl

use 5.18.2;
use warnings;
use threads;
use Thread::Queue;
#require Text::CSV_XS;

my $input  = "input.csv";
my $output = "output.csv";
my @cols   = qw(a b c d);
my $q;
my $count = 0;

threads->create(sub {
require Text::CSV_XS;
threads->create(sub {

while (1) {
    $q = Thread::Queue->new;
    my $inth  = threads->create (\&inputthread);
    my $outth = threads->create (\&outputthread);
    $inth->join  ();
    $q->enqueue  (undef);
    $outth->join () or die ("thread crashed?\n");
    $count++;
    print "$count\n";
    }

})})->join; sleep 100;

sub inputthread {
    require Text::CSV_XS;
    my $csv = Text::CSV_XS->new ({
	binary         => 1,
	eol            => "\n",
	empty_is_undef => 0,
	decode_utf8    => 0,
	auto_diag      => 1,
	});
    $csv->column_names (@cols);
    open my $fh, "<", $input or die "$input: $!\n";
    binmode $fh;
    my @rows;
    while (1) {
	my $data;
	$csv or die "Data parsed another way\n";
	$data = $csv->getline_hr ($fh);
	unless ($data) {
	    $csv->eof and last;
	    die "Failed to parse CSV line: " . $csv->error_diag . "\n";
	    }
	my @arr = values %$data;
	push @rows, \@arr;
	}
    close $fh;
    $q->enqueue (\@rows);
    } # inputthread

sub outputthread {
    open my $fh, ">", $output or die "$output: $!\n";
    binmode $fh;
    require Text::CSV_XS;
    my $csv = Text::CSV_XS->new ({
	binary      => 1,
	eol         => "\n",
	auto_diag   => 1,
	});
    while (1) {
	my $rows = $q->dequeue;
	defined $rows or last;
	foreach my $data (@$rows) {
	    $csv or die "Data output another way\n";
	    $csv->print ($fh, $data);
	    }
	}
    close $fh;
    return 1;
    } # outputthread
