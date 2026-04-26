#/pro/bin/perl

use 5.040001;
use warnings;
use Text::CSV_XS qw( csv );

#my ($file, $out, $idx, $pat) = @ARGV;
#die "Usage: $0 <file> <outfile> <fieldidx> <pattern>\n"
#  if !$file or !-f $file or !$out or !defined $idx or !$pat;

my $data = join "" => <DATA>;
my $idx  = 3;
my $pat  = shift // ".";

open my $infh,  "<:encoding(utf8)", \$data;
my $csv = Text::CSV_XS->new ({ binary => 1, auto_diag => 1 });
$csv->say (*STDOUT, $csv->getline ($infh)); # get header
while (my $row = $csv->getline ($infh)) {
    $csv->say (*STDOUT, $row) if $row->[$idx] =~ m/$pat/; # field must match
    }
close $infh;

csv (in => \$data, filter => { d => sub { $_[0]->record_number == 1 or m/$pat/ }});
__END__
a,b,c,d
1,2,3,4
foo,bar,,baz
