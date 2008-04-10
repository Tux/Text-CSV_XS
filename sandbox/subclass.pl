#!/pro/bin/perl

package Text::CSV_XS::Encoded;

use strict;
use warnings;

use base "Text::CSV_XS";

sub new
{
    my $proto = shift;
    my $attr  = shift || {};
    my $class = ref ($proto) || $proto	or return;

    my $self = Text::CSV_XS->new ({ binary => 1, %$attr }) or return;
    bless $self, $class;
    $self->{Encoding} = "utf8";
    $self;
    } # new

1;

package main;

my $csve;

$csve = Text::CSV_XS::Encoded->new () or
    Text::CSV_XS::Encoded->error_diag ();

$csve = Text::CSV_XS::Encoded->new ({ frokost => "Haring in tomatensaus" }) or
    Text::CSV_XS::Encoded->error_diag ();
