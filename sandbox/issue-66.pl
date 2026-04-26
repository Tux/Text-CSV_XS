#!/pro/bin/perl

use 5.040001;
use warnings;
use Text::CSV_XS;
use IO::String;
use Data::Peek;

my $str = IO::String->new (my $out);

#"ah"0j",2
Text::CSV_XS->new ({ binary => 1})->print ($str, [ "ah\0j", 2]);
say $out;

my $out = "";
open my $fh, ">", \$out;
Text::CSV_XS->new ({ binary => 1})->print ($fh,  [ "ah\0j", 2]);
say $out;
