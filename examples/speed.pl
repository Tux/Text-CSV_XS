#!/usr/bin/perl -w

# speed.pl: compare different versions of Text-CSV* modules
#	   (m)'08 [07 Apr 2008] Copyright H.M.Brand 2007-2013

require 5.006001;
use strict;

use IO::Handle;
use Text::CSV_XS;
use Benchmark qw(:all :hireswallclock);

our $csv = Text::CSV_XS->new ({ eol => "\n" });

my $duration = int (shift || 2);
our @fields1 = (
    "Wiedmann", "Jochen",
    "Am Eisteich 9",
    "72555 Metzingen",
    "Germany",
    "+49 7123 14881",
    "joe\@ispsoft,de");
our @fields10  = (@fields1) x 10;
our @fields100 = (@fields1) x 100;

$csv->combine (@fields1  ); our $str1   = $csv->string;
$csv->combine (@fields10 ); our $str10  = $csv->string;
$csv->combine (@fields100); our $str100 = $csv->string;

timethese (-1.2,{

    "combine   1"	=> q{ $csv->combine (@fields1  ) },
    "combine  10"	=> q{ $csv->combine (@fields10 ) },
    "combine 100"	=> q{ $csv->combine (@fields100) },

    "parse     1"	=> q{ $csv->parse   ($str1     ) },
    "parse    10"	=> q{ $csv->parse   ($str10    ) },
    "parse   100"	=> q{ $csv->parse   ($str100   ) },

    });

sub max { $_[0] >= $_[1] ? $_[0] : $_[1] }
my $line_count = max (200_000, 20_000 * $duration);

our $io;
my $mem = "";
my $bigfile = "_file.csv";
if ($] >= 5.010) {
    eval "use Sys::MemInfo qw( freemem );";
    unless ($@) {
	my $need = $line_count * (1 + length $str10);
	if (freemem () > $need) {
	    $mem = "";
	    open $io, ">", \$mem;
	    }
	}
    }
$io or open $io, ">", $bigfile;

$csv->print ($io, \@fields10) or die "Cannot print ()\n";
timethese ($line_count, { "print    io" => q{ $csv->print ($io, \@fields10) }});
close   $io;
my $l = $mem ? length ($mem) : -s $bigfile;
$l or die "Buffer/file is empty!\n";
my @f = @fields10;
$csv->can ("bind_columns") and $csv->bind_columns (\(@f));
open    $io, "<", ($mem ? \$mem : $bigfile);
timethese ($line_count, { "getline  io" => q{ my $ref = $csv->getline ($io) }});
close   $io;
print "Data was $l bytes long, line length ", length ($str10), "\n";
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
