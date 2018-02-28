#!/pro/bin/perl

use 5.18.2;
use warnings;

use CSV;
use Devel::Size qw( size total_size );

my $data = <<"EOD";
foo,bar,baz
1,,3
0,"d
€",4
999,999,
EOD

{   my $n = 0;
    open my $fh, "<", \$data;
    my $csv = Text::CSV_XS->new ({ binary => 1 });
    while (my $row = $csv->getline ($fh)) { $n++; }
    close $fh;
    say $n;
    }

{   my $n = 0;
    my $aoa = csv (in => \$data, on_in => sub { $n++ });
    say $n;
    say total_size $aoa;
    }

{   my $n = 0;
    my $aoa = csv (in => \$data, filter => { 0 => sub { $n++; 0; }});
    say $n;
    say total_size $aoa;
    }

{   my $n = 0;
    my $aoa = csv (in => \$data, filter => sub { $n++; 0; });
    say $n;
    say total_size $aoa;
    }

{   my $n = 0;
    csv (in => \$data, on_in => sub { $n++; 0; }, out => \"skip");
    say $n;
    }
