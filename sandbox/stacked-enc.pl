#!/pro/bin/perl

use 5.14.2;
use warnings;
use blib;

our $VERSION = "0.02 - 20190831";
our $CMD = $0 =~ s{.*/}{}r;

use Test::More;

sub usage {
    my $err = shift and select STDERR;
    say "usage: $CMD ...";
    exit $err;
    } # usage

use Text::CSV_XS qw( csv );
use PerlIO::via::gzip;
use PerlIO::gzip;

my @csv = (
    [ "a".."d"         ],
    [ 1..3, "\x{20ac}" ],
    [ 2..4, "\x{263a}" ],
    );

ok (csv (
    in       => \@csv,
    out      => "test.csv:via.gz",
    encoding => ":via(gzip):encoding(utf-8)",
    ), "csv (encoding => :via(gzip))");
ok (csv (
    in       => \@csv,
    out      => "test.csv:gzip.gz",
    encoding => ":gzip:encoding(utf-8)",
    ), "csv (encoding => :gzip)");

is_deeply (csv (in => "test.csv:via.gz",  encoding => ":via(gzip)"), \@csv, "read back :via");
is_deeply (csv (in => "test.csv:gzip.gz", encoding => ":gzip"),      \@csv, "read back :gzip");

done_testing;
