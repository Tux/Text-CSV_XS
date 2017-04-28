#!/pro/bin/perl

use 5.18.2;
use warnings;

use Text::CSV_XS qw (csv );

my @foo = map { [ 0 .. 5 ] } 0 .. 3;
csv (in => \@foo, out => \my $file);

print $file;

__END__

shortened 1

use Text::CSV_XS;

my $csv = Text::CSV_XS->new ({ binary => 1, auto_diag => 2, eol => "\r\n" });
open my $fh, ">", \my $file;

my @foo = map { [ 0 .. 5 ] } 0 .. 3;
$csv->print ($fh, $_) for @foo;

close $fh;
print $file;

original (reformatted)

use Text::CSV_XS;

my $csv = Text::CSV_XS->new ({ binary => 1, auto_diag => 2, eol => "\r\n" });
my $file;
open my $fh, ">", \$file;

my @foo = map { [ 0 .. 5 ] } 0 .. 3;

for my $line (@foo) {
    $csv->print ($fh, $line);
    }

close $fh;
print $file;
