#!/pro/bin/perl

use 5.014002;
use warnings;

our $VERSION = "0.01 - 20241224";
our $CMD = $0 =~ s{.*/}{}r;

sub usage {
    my $err = shift and select STDERR;
    say "usage: $CMD ...";
    exit $err;
    } # usage

use CSV;
use Test::More;
use Getopt::Long qw(:config bundling);
GetOptions (
    "help|?"		=> sub { usage (0); },
    "V|version"		=> sub { say "$CMD [$VERSION]"; exit 0; },

    "s|stream!"		=> \ my $opt_s,

    "v|verbose:1"	=> \(my $opt_v = 0),
    ) or usage (1);

my $fni = "csv-io-i-$$.csv";
my $fno = "csv-io-o-$$.csv";
{   open my $fh, ">", $fni or die  "$fni: $!\n";
    say $fh "id,desc,class";
    say $fh "1,foo,A";
    say $fh "2,bar,B";
    close $fh;
    }

sub io_test {
    my ($tag, $in, $out, @err, @wrn) = @_;

    ok (1, $tag);
    my %attr = (
	in       => $in,
	out      => $out,
	on_error => sub { push @err => @_ },
	);
    $opt_s and $attr{stream} = sub { say "Hi!" };
    eval {
	local $SIG{__WARN__} = sub { push @wrn => [ @_ ] };
	csv (%attr);
	};
    diag __LINE__, " ", "$@" =~ s/[\s\r\n]*at\s+\S+\s+line\s+\d+.*\z//sr;
    diag __LINE__, " ", DDumper \@wrn;
    diag __LINE__, " @err";
    } # io_test

    io_test ("FN -> FN", $fni, $fno);
{   open my $fi, "<", $fni;
    io_test ("fh -> FN", $fi,  $fno);
    close $fi;
    }
{   open my $fo, ">", $fno;
    io_test ("fh -> FN", $fni, $fo);
    close $fo;
    }
{   open my $fi, "<", $fni;
    open my $fo, ">", $fno;
    io_test ("fh -> FN", $fi,  $fo);
    close $fi;
    close $fo;
    }

unlink $fni, $fno;

done_testing;
