#!/pro/bin/perl

use 5.026001;
use warnings;

use Data::Peek;
use Text::CSV_XS qw( csv );

my $csv = "\x{FEFF}Foo,Bar\none,two\n";
utf8::encode ($csv);
DDumper (csv (in => \$csv ));
DDumper (csv (in => \$csv, detect_bom => 1));
DDumper (csv (in => \$csv, detect_bom => 1, set_column_names => 0));
