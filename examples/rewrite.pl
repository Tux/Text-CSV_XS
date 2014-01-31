#!/pro/bin/perl

use strict;
use warnings;

use Text::CSV_XS qw( csv );

my $io = shift || \*DATA;

csv (in => csv (in => $io, sep_char => ";"), out => \*STDOUT);

__END__
a;b;c;d;e;f
1;2;3;4;5;6
2;3;4;5;6;7
3;4;5;6;7;8
4;5;6;7;8;9
