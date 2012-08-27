#!/pro/bin/perl

use 5.14.1;
use warnings;

use Text::CSV_XS;
use Benchmark qw(:all);

our $csv = Text::CSV_XS->new ({ eol => "\n" });

my $duration = int (shift || 10);
my $bigfile = "_file.csv";
my @fields1 = (
    "Wiedmann", "Jochen",
    "Am Eisteich 9",
    "72555 Metzingen",
    "Germany",
    "+49 7123 14881",
    "joe\@ispsoft,de");
my @fields10  = (@fields1) x 10;
my @fields100 = (@fields1) x 100;

$csv->combine (@fields1  ); my $str1   = $csv->string;
$csv->combine (@fields10 ); my $str10  = $csv->string;
$csv->combine (@fields100); my $str100 = $csv->string;

timethese (-$duration, {

    "combine   1"	=> sub { $csv->combine (@fields1  ) },
    "combine  10"	=> sub { $csv->combine (@fields10 ) },
    "combine 100"	=> sub { $csv->combine (@fields100) },

    "parse     1"	=> sub { $csv->parse   ($str1     ) },
    "parse    10"	=> sub { $csv->parse   ($str10    ) },
    "parse   100"	=> sub { $csv->parse   ($str100   ) },

    });

print "-- ref\n";
my $line_count = 50_000 * $duration;
open my $io, ">", $bigfile;
$csv->print ($io, \@fields10) or die "Cannot print ()\n";
timethese ($line_count, { "print    io" => sub { $csv->print ($io, \@fields10) }});
close   $io;
-s $bigfile or die "File is empty!\n";
open    $io, "<", $bigfile;
timethese ($line_count, { "getline  io" => sub { my $ref = $csv->getline ($io) }});
close   $io;
print "File was ", -s $bigfile, " bytes long, line length ", length ($str10), "\n";

print "-- copy\n";
open $io, ">", $bigfile;
$csv->print ($io, [ @fields10 ]) or die "Cannot print ()\n";
timethese ($line_count, { "print    io" => sub { $csv->print ($io, [ @fields10 ]) }});
close   $io;
-s $bigfile or die "File is empty!\n";
open    $io, "<", $bigfile;
timethese ($line_count, { "getline  io" => sub { my $ref = $csv->getline ($io) }});
close   $io;
print "File was ", -s $bigfile, " bytes long, line length ", length ($str10), "\n";

print "-- bind/undef\n";
$csv->bind_columns (\(@fields10));
open $io, ">", $bigfile;
$csv->print ($io, undef) or die "Cannot print ()\n";
timethese ($line_count, { "print    io" => sub { $csv->print ($io, undef) }});
close   $io;
-s $bigfile or die "File is empty!\n";
open    $io, "<", $bigfile;
timethese ($line_count, { "getline  io" => sub { $csv->getline ($io) }});
close   $io;
print "File was ", -s $bigfile, " bytes long, line length ", length ($str10), "\n";

$line_count /= 10;
$csv->bind_columns (undef);

print "--\n";
open $io, ">", $bigfile;
$csv->print ($io, \@fields100) or die "Cannot print ()\n";
timethese ($line_count, { "print    io" => sub { $csv->print ($io, \@fields100) }});
close   $io;
-s $bigfile or die "File is empty!\n";
open    $io, "<", $bigfile;
timethese ($line_count, { "getline  io" => sub { my $ref = $csv->getline ($io) }});
close   $io;
print "File was ", -s $bigfile, " bytes long, line length ", length ($str100), "\n";

print "--\n";
$csv->bind_columns (\(@fields100));
open $io, ">", $bigfile;
$csv->print ($io, undef) or die "Cannot print ()\n";
timethese ($line_count, { "print    io" => sub { $csv->print ($io, undef) }});
close   $io;
-s $bigfile or die "File is empty!\n";
open    $io, "<", $bigfile;
timethese ($line_count, { "getline  io" => sub { $csv->getline ($io) }});
close   $io;
print "File was ", -s $bigfile, " bytes long, line length ", length ($str100), "\n";

unlink $bigfile;

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
