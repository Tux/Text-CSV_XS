#!/pro/bin/perl

use strict;
use warnings;

our $VERSION = "0.05 - 20170920";

sub usage {
    my $err = shift and select STDERR;
    print <<"EOH";
usage: $0 [-o file] [-s S] [-m] [-c] [-i] [file]
    -o F  --out=F     output to file F (default STDOUT)
    -s S  --sep=S     set input separator to S (default ; , TAB or |)
    -m    --ms        output Dutch style MicroSoft CSV (; and \\r\\n)
    -n    --no-header CSV has no header line. If selected
                      - default input sep = ;
                      - BOM is not used/recognized
    -c    --confuse   Use confusing separation and quoting characters
    -i    --invisible Use invisible separation and quotation sequences
EOH
    exit $err;
    } # usage

use Getopt::Long qw(:config bundling);
GetOptions (
    "help|?"		=> sub { usage (0); },
    "s|sep=s"		=> \my $in_sep,
    "m|ms!"		=> \my $ms,
    "c|confuse!"	=> \my $confuse,
    "i|invisible!"	=> \my $invis,
    "n|no-header!"	=> \my $opt_n,
    "o|out=s"		=> \my $opt_o,
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

my @hdr;
my @opt_i = (in  => $io);
my @opt_o = (out => \*STDOUT, eol => $eol, sep => $sep, quo => $quo);
if ($opt_n) {
    push @opt_i,
	sep          => $in_sep // ";";
    }
else {
    push @opt_i,
	bom          => 1,
	sep_set      => [ $in_sep ? $in_sep : (";", ",", "|", "\t") ],
	keep_headers => \@hdr;
    push @opt_o,
	headers      => \@hdr;
    }
csv (in => csv (@opt_i), @opt_o);

__END__
a;b;c;d;e;f
1;2;3;4;5;6
2;3;4;5;6;7
3;4;5;6;7;8
4;5;6;7;8;9
