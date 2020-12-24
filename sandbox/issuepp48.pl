#!/pro/bin/perl

use 5.14.2;
use warnings;

use Data::Peek;
use Text::CSV_XS qw( csv );

my $strip = shift;

my @h;
DDumper csv (in => *DATA, headers => "auto", kh => \@h, on_in => sub {
    $strip or return;
    delete $_{$_} for grep { !length $_{$_} } @h;
    });

__END__
a,b,c,d
1,2,3,4
1,,3,4
1,2,,4
1,2,3,
1,,,
,,,4
,,3,
