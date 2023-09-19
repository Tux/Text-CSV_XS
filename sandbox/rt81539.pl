#!/pro/bin/perl

use strict;
use warnings;

#se Devel::Size qw( size total_size );
#se Test::Valgrind;

use Text::CSV_XS;

print "My PID: $$\n";

my $line = join (",", ('a'..'z')) . "\n";
my $data = $line x 10000;

my $csv  = Text::CSV_XS->new ({
    always_quote   => 0,
    quote_space    => 1,
    quote_null     => 1,
    binary         => 1,
    blank_is_undef => 1,
    empty_is_undef => 1,
    auto_diag      => 1,
    });

my $count = 0;
my @statm = qw( size resident share text lib data dt);
my %statm = map { $_ => 0 } @statm;

sub statm
{
    open my $ms, "<", "/proc/$$/statm";
    @statm{@statm} = split m/\s+/ => <$ms>;
    close $ms;
    print STDERR join (", " => map { sprintf "%s = %6d", $_, $statm{$_} }
	qw( size resident share data )), "\n";
    } # statm

statm;
for (1..20) {
    open my $fh, "<", \$data;

    #my $header_ref  = $csv->getline ($fh);
    my $columns_ref = $csv->getline ($fh);

    $csv->column_names (@{$columns_ref});

    my $lines = $csv->getline_all ($fh);

    close $fh;

    $count++;
    #print "Did $count runs. sizeof (\$csv) = ", total_size ($csv), "\n";

    statm;
    }
