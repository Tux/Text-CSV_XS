#!/pro/bin/perl

use 5.018002;
use warnings;

use Text::CSV_XS;
use Data::Peek;

my $csv = Text::CSV_XS->new ({ binary => 1, eol => "\r\n" });

$csv->print (*STDOUT, [ "Perl", "", "Definitely lost", "", "Indirectly lost", "", "Possibly lost", "", "Still reachable", "", "Suppressed", "", "ERROR SUMMARY", "", "", "" ]);
$csv->print (*STDOUT, [ "version", "Config", "bytes", "blocks", "bytes", "blocks", "bytes", "blocks", "bytes", "blocks", "bytes", "blocks", "errors", "contexts", "suppressed", "from" ]);

my ($pv, $pc);
my @keys = qw( definitely indirectly possibly reachable suppressed );
my %sum;
open my $fh, "<", "memcheck.log";
while (<$fh>) {
    if (m/^=== \S+\s+(\S+)\s+(.*)/) {
	$pv = $1;
	$pc = $2;
	$sum{$pv}{$pc} = { map {( $_ => [ "-", "-" ])} @keys };
	next;
	}

    if (my ($type, $bytes, $blocks) = m/^\s+(?|(definitely|indirectly|possibly) lost|still (reachable)|(suppressed)):\s*([0-9.,]+) bytes in ([0-9.,]+)/) {
	$sum{$pv}{$pc}{$type} = [ $bytes, $blocks ];
	next;
	}
    if (m/ERROR/) {
	my @cnt = m/([0-9,.]+)/g;
	$sum{$pv}{$pc}{ERR} = \@cnt;
	#DDumper $sum{$pv}{$pc};
	$csv->print (*STDOUT, [ $pv, $pc, map { s/,//gr }
	    (map { @{$sum{$pv}{$pc}{$_}} } @keys),
	    @cnt,
	    ]);
	next;
	}
    }

#DDumper \%sum;
