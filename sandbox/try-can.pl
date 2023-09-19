#!pro/bin/perl

use v5.14.1;
use warnings;

tie my $foo, "Foo";

say tied $foo;
say ref  $foo;
say $foo->can ("FETCH");

package Foo;

use strict;
use warnings;

require Tie::Scalar;
use vars qw( @ISA );
@ISA = qw(Tie::Scalar);

sub FETCH
{
    [ "#", 1 .. 3 ];
    } # FETCH

sub TIESCALAR
{
    bless [], "Foo";
    } # TIESCALAR

1;
