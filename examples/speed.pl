#!/usr/bin/perl -w

# speed.pl: compare different versions of Text-CSV* modules
#	   (m)'08 [07 Apr 2008] Copyright H.M.Brand 2007-2014

require 5.006001;
use strict;

use IO::Handle;
use Text::CSV_XS;
use Benchmark qw(:all :hireswallclock);

our $csv = Text::CSV_XS->new ({ eol => "\n" });

my $duration = int (shift || 2);
my  @fields = (
    "Wiedmann", "Jochen",
    "Am Eisteich 9",
    "72555 Metzingen",
    "Germany",
    "+49 7123 14881",
    "joe\@ispsoft,de");
our @fields2   = (@fields) x 2;
our @fields20  = (@fields) x 20;
our @fields200 = (@fields) x 200;

$csv->combine (@fields2  ); our $str2   = $csv->string;
$csv->combine (@fields20 ); our $str20  = $csv->string;
$csv->combine (@fields200); our $str200 = $csv->string;

timethese (-1.5,{

    "combine   2"	=> q{ $csv->combine (@fields2  ) },
    "combine  20"	=> q{ $csv->combine (@fields20 ) },
    "combine 200"	=> q{ $csv->combine (@fields200) },

    "parse     2"	=> q{ $csv->parse   ($str2     ) },
    "parse    20"	=> q{ $csv->parse   ($str20    ) },
    "parse   200"	=> q{ $csv->parse   ($str200   ) },

    });

sub max { $_[0] >= $_[1] ? $_[0] : $_[1] }
my $line_count = max (200_000, 20_000 * $duration);

our $io;
my $mem = "";
my $bigfile = "_file.csv";
if ($] >= 5.010) {
    eval "use Sys::MemInfo qw( freemem );";
    unless ($@) {
	my $need = $line_count * (1 + length $str20);
	if (freemem () > $need) {
	    $mem = "";
	    open $io, ">", \$mem;
	    }
	}
    }
$io or open $io, ">", $bigfile;

$csv->print ($io, \@fields20) or die "Cannot print ()\n";
timethese ($line_count, { "print    io" => q{ $csv->print ($io, \@fields20) }});
close   $io;
my $l = $mem ? length ($mem) : -s $bigfile;
$l or die "Buffer/file is empty!\n";
my @f = @fields20;
$csv->can ("bind_columns") and $csv->bind_columns (\(@f));
open    $io, "<", ($mem ? \$mem : $bigfile);
timethese ($line_count, { "getline  io" => q{ my $ref = $csv->getline ($io) }});
close   $io;
print "Data was $l bytes long, line length ", length ($str20), "\n";
$mem or unlink $bigfile;

__END__
# The examples from the docs

{ $csv = Text::CSV_XS->new ({ keep_meta_info => 1, binary => 1 });

  my $sample_input_string =
      qq{"I said, ""Hi!""",Yes,"",2.34,,"1.09","\x{20ac}",};
  if ($csv->parse ($sample_input_string)) {
      my @field = $csv->fields;
      foreach my $col (0 .. $#field) {
          my $quo = $csv->is_quoted ($col) ? $csv->{quote_char} : "";
          printf "%2d: %s%s%s\n", $col, $quo, $field[$col], $quo;
          }
      }
  else {
      my $err = $csv->error_input;
      print "parse () failed on argument: ", $err, "\n";
      }
  }
