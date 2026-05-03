#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;
use Text::CSV_XS;

foreach my $key (qw( sep quote eol )) {
    my $csv = Text::CSV_XS->new ({ binary => 1 });
    $csv->{$key} = "X" x 8000;
    my $input = "a,b,c\n";
    open my $fh, "<", \$input;
    eval {
	my $rv = $csv->getline ($fh);
	diag "  $key: rv=", (defined $rv ? "OK" : "undef"), "\n";
	};
    like ($@, qr{INI - \U$key\E too long},
	"Cannot set $key to a value longer than 16");
    }
