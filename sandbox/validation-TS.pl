#!/pro/bin/perl

use 5.014002;
use warnings;

our $VERSION = "0.01 - 20191213";
our $CMD = $0 =~ s{.*/}{}r;

sub usage {
    my $err = shift and select STDERR;
    say "usage: $CMD ...";
    exit $err;
    } # usage

use Data::Peek;
use Text::CSV_XS qw( csv );
use Types::Standard -types;

use Getopt::Long qw(:config bundling);
GetOptions (
    "help|?"		=> sub { usage (0); },
    "V|version"		=> sub { say "$CMD [$VERSION]"; exit 0; },

    "v|verbose:1"	=> \(my $opt_v = 0),
    ) or usage (1);


my $data = <<"EOD";
foo,bar,42,1,0.01
\xcf\x80,pi,-3,,-3.141592653589793
foo,bar,x,1,
foo,bar,,2,
EOD

my $filter = \&{ +Tuple[Str, Str, Int, Bool, Optional[Num]] };
my $type   =      Tuple[Str, Str, Int, Bool, Optional[Num]];
my $check  = $type->compiled_check;

say "PART 1 - no filter";
DDumper csv (
    in     => \$data, 
    );

say "PART 2 - filter with compiled check";
DDumper csv (
    in     => \$data,
    filter => { 0 => sub {         $check->($_[1])    }},
    );

say "PART 3 - filter with compiled check with warnings";
DDumper csv (
    in     => \$data,
    filter => { 0 => sub { my $x = $check->($_[1]) or
			       warn $type->get_message ($_[1]), "\n";
			   $x;
			   }},
    );

# PART 3 makes $filter unusable for the next calls
   $filter = \&{ +Tuple[Str, Str, Int, Bool, Optional[Num]] };
say "PART 4 - filter with callback + eval";
DDumper csv (
    in     => \$data,
    filter => { 0 => sub { eval {  $filter->($_[1]) } }},
    );

say "PART 5 - filter with callback will die";
DDumper csv (
    in     => \$data,
    filter => { 0 => sub {         $filter->($_[1])   }},
    );
