#!/pro/bin/perl

use 5.18.2;
use warnings;

use Data::Peek;
use Encode qw( from_to );

# In EBCDIC 1047, only these bytes map to the same character as in ASCII:
# \x00..\x03, \x0b..\x13, \x18, \x19, \x1c..\x1f, \xb6
my $ascii = pack "C*" => 0..255;

DHexDump $ascii;

my $ebcdic = $ascii;
from_to ($ebcdic, "latin1", "cp1047");

DHexDump $ebcdic;

my @ascii  = unpack "C*" => $ascii;
my @ebcdic = unpack "C*" => $ebcdic;

my @e2a;
@e2a[@ebcdic] = @ascii;

DDumper \@e2a;

say "unsigned char ebcdic2ascii[256] = {";
say join ", " => map { sprintf "0x%02x", $e2a[$_] } 0..255;
say "    };";
for (0..255) {
    my $ba = $ascii[$_];
    my $be = $ebcdic[$_];
    my $ca = chr $ba;
    my $ce = chr $be;
    my $ec = $e2a[$be];
    my $pa = $ba >= 0x20 && $ba < 0x7F ? $ca : ".";
    my $pe = $be >= 0x20 && $be < 0x7F ? $ce : ".";
    printf "%3d %02x %03o %s -> %s %02x %03o  %02x %03o\n",
	$_, $_, $_, $pa, $pe, $be, $be, $ec, $ec;
    }
