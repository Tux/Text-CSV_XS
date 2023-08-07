#!/usr/bin/perl

use strict;
use warnings;

#use Test::More "no_plan";
 use Test::More tests => 32;
 use Config;

BEGIN {
    use_ok "Text::CSV_XS", "csv";
    plan skip_all => "Cannot load Text::CSV_XS" if $@;
    require "./t/util.pl";
    }

my $tfn = "_68test.csv"; END { unlink $tfn, "_$tfn"; }

my @dta = (
    [qw( foo  bar   zap		)],
    [qw( mars venus pluto	)],
    [qw( 1    2     3		)],
    );
my @dth = (
    { foo => "mars", bar => "venus", zap => "pluto" },
    { foo => 1,      bar => 2,       zap => 3       },
    );

{   open my $fh, ">", $tfn or die "$tfn: $!\n";
    local $" = ",";
    print $fh "@$_\n" for @dta;
    close $fh;
    }

is_deeply (csv (in => $tfn),                              \@dta, "csv ()");
is_deeply (csv (in => $tfn, bom => 1),                    \@dth, "csv (bom)");
is_deeply (csv (in => $tfn,           headers => "auto"), \@dth, "csv (headers)");
is_deeply (csv (in => $tfn, bom => 1, headers => "auto"), \@dth, "csv (bom, headers)");

foreach my $arg ("", "bom", "auto", "bom, auto") {
    open my $fh, "<", $tfn or die "$tfn: $!\n";
    my %attr;
    $arg =~ m/bom/	and $attr{bom}     = 1;
    $arg =~ m/auto/	and $attr{headers} = "auto";
    ok (my $csv = Text::CSV_XS->new (), "New ($arg)");
    is ($csv->record_number, 0, "start");
    if ($arg) {
	is_deeply ([ $csv->header   ($fh, \%attr) ], $dta[0], "Header") if $arg;
	is ($csv->record_number, 1, "first data-record");
	is_deeply ($csv->getline_hr ($fh), $dth[$_], "getline $_") for 0..$#dth;
	}
    else {
	is_deeply ($csv->getline    ($fh), $dta[$_], "getline $_") for 0..$#dta;
	}
    is ($csv->record_number, 3, "done");
    close $fh;
    }

done_testing;
