#!/pro/bin/perl

use strict;
use warnings;

sub usage {
    my $err = shift and select STDERR;
    print "usage: $0 [--ms] [--confuse] [--invisible]\n";
    exit $err;
    } # usage

use Getopt::Long qw(:config bundling);
GetOptions (
    "help|?"		=> sub { usage (0); },
    "s|sep=s"		=> \my $in_sep,
    "m|ms!"		=> \my $ms,
    "c|confuse!"	=> \my $confuse,
    "i|invisible!"	=> \my $invis,
    ) or usage (1);
$invis and $confuse++;

use Text::CSV_XS qw( csv );

# U+0022 "	QUOTATION MARK			"
# U+002c ,	COMMA				,
# U+037e ;	GREEK QUESTION MARK		;
# U+201a ‚	SINGLE LOW-9 QUOTATION MARK	,
# U+2033 ″	DOUBLE PRIME			"
# U+2063	INVISIBLE SEPARATOR

my $io  = shift || \*DATA;
my $eol = $ms ? "\r\n" : "\n";
my $sep = $confuse ? $ms ? "\x{037e}" : $invis ? "\x{2063}" : "\x{201a}"
		   : $ms ? ";" : ",";
my $quo = $confuse ? "\x{2033}" : '"';

binmode STDOUT, ":encoding(utf-8)";

csv (in  => csv (in => $io, sep => $in_sep // ";"),
     out => \*STDOUT,
     eol => $eol,
     sep => $sep,
     quo => $quo);

__END__
a;b;c;d;e;f
1;2;3;4;5;6
2;3;4;5;6;7
3;4;5;6;7;8
4;5;6;7;8;9
