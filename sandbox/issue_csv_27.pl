#!/pro/bin/perl

use 5.018002;
use warnings;

use Data::Peek;
use Test::More;
use Text::CSV_XS;

my $data = <<"EOD";
a,b

2
EOD

diag "Init";
open my $fh, "<", \$data;
ok (my $csv = Text::CSV_XS->new (), "new");
is ($csv->is_missing (0), undef, "is_missing ()");
close $fh;

diag "No meta";
open $fh, "<", \$data;
ok ($csv->column_names ("code", "foo"), "set column names");
ok (my $hr = $csv->getline_hr ($fh), "get header line");
is ($csv->is_missing (0), undef, "not is_missing () - no meta");
is ($csv->is_missing (1), undef, "not is_missing () - no meta");
ok ($hr = $csv->getline_hr ($fh), "get empty line");
is ($csv->is_missing (0), undef, "not is_missing () - no meta");
is ($csv->is_missing (1), undef, "not is_missing () - no meta");
ok ($hr = $csv->getline_hr ($fh), "get partial data line");
is (int $hr->{code}, 2, "code == 2");
is ($csv->is_missing (0), undef, "not is_missing () - no meta");
is ($csv->is_missing (1), undef, "not is_missing () - no meta");
close $fh;

diag "Meta";
open $fh, "<", \$data;
$csv->keep_meta_info (1);
ok ($csv->column_names ("code", "foo"), "set column names");
ok (my $hr = $csv->getline_hr ($fh), "get header line");
is ($csv->is_missing (0), 0, "not is_missing () - with meta");
is ($csv->is_missing (1), 0, "not is_missing () - with meta");
ok ($hr = $csv->getline_hr ($fh), "get empty line");
is ($csv->is_missing (0), 1, "not is_missing () - with meta");
is ($csv->is_missing (1), 1, "not is_missing () - with meta");
ok ($hr = $csv->getline_hr ($fh), "get partial data line");
is (int $hr->{code}, 2, "code == 2");
is ($csv->is_missing (0), 0, "not is_missing () - with meta");
is ($csv->is_missing (1), 1, "not is_missing () - with meta");
close $fh;

done_testing;
