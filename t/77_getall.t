#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 31;

BEGIN {
    require_ok "Text::CSV_XS";
    plan skip_all => "Cannot load Text::CSV_XS" if $@;
    require "t/util.pl";
    }

$| = 1;

my @list = (
    [ 1, "a", "\x01", "A" ],
    [ 2, "b", "\x02", "B" ],
    [ 3, "c", "\x03", "C" ],
    [ 4, "d", "\x04", "D" ],
    );

{   ok (my $csv = Text::CSV_XS->new ({ binary => 1, eol => "\n" }), "csv out");
    open my $fh, ">", "_77test.csv" or die "_77test.csv: $!";
    ok ($csv->print ($fh, $_), "write $_->[0]") for @list;
    close $fh;
    }

sub do_tests
{
    my $sub = shift;

    $sub->(\@list);
    $sub->(\@list,         0);
    $sub->([@list[2,3]],   2);
    $sub->([],             0,  0);
    $sub->(\@list,         0, 10);
    $sub->([@list[0,1]],   0,  2);
    $sub->([@list[1,2]],   1,  2);
    $sub->([@list[1..3]], -3);
    $sub->([@list[1,2]],  -3,  2);
    $sub->([@list[1..3]], -3,  3);
    } # do_tests

{   ok (my $csv = Text::CSV_XS->new ({ binary => 1 }), "csv in");

    do_tests (sub {
	my ($expect, @args) = @_;
	open my $fh, "<", "_77test.csv" or die "_77test.csv: $!";
	my $s_args = join ", " => @args;
	is_deeply ($csv->getline_all ($fh, @args), $expect, "getline_all ($s_args)");
	close $fh;
	});
    }

{   ok (my $csv = Text::CSV_XS->new ({ binary => 1 }), "csv in");
    ok ($csv->column_names (my @cn = qw( foo bar bin baz )), "Set column names");
    @list = map { my %h; @h{@cn} = @$_; \%h } @list;

    do_tests (sub {
	my ($expect, @args) = @_;
	open my $fh, "<", "_77test.csv" or die "_77test.csv: $!";
	my $s_args = join ", " => @args;
	is_deeply ($csv->getline_hr_all ($fh, @args), $expect, "getline_hr_all ($s_args)");
	close $fh;
	});
    }

{   ok (my $csv = Text::CSV_XS->new ({ binary => 1 }), "csv in");
    open my $fh, "<", "_77test.csv" or die "_77test.csv: $!";
    eval { my $row = $csv->getline_hr_all ($fh); };
    is ($csv->error_diag () + 0, 3002, "Use _hr before colnames ()");
    }

unlink "_77test.csv";
