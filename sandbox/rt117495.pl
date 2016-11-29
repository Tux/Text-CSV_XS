#!/pro/bin/perl

use 5.18.2;
use warnings;

use Test::More;

BEGIN {
    use_ok "Text::CSV_XS";
    plan skip_all => "Cannot load Text::CSV_XS" if $@;
    require "t/util.pl";
    }

my $data = <<"EOD";

1,2
3
EOD

my $csv = Text::CSV_XS->new ({
    keep_meta_info => 1,
    blank_is_undef => 1,
    empty_is_undef => 1,
    });
is $csv->is_missing (0), undef, "is_missing () is not defined yet";

open my $fh, "<", \$data;
$csv->column_names (qw/first second/);
{   my $hr = $csv->getline_hr ($fh);
    ok  $csv->is_missing (0), "empty line: is_missing (0) should     return true";
    ok  $csv->is_missing (1), "empty line: is_missing (1) should     return true";
    ok exists $hr->{first}  && !defined $hr->{first};
    ok exists $hr->{second} && !defined $hr->{second};
    }
{   my $hr = $csv->getline_hr ($fh);
    ok !$csv->is_missing (0), "not empty: is_missing (0) should not return true";
    ok exists $hr->{first}  &&  defined $hr->{first};
    ok exists $hr->{second} &&  defined $hr->{second};
    }
{   my $hr = $csv->getline_hr ($fh);
    ok !$csv->is_missing (0), "not empty column: is_missing () should not return true";
    ok  $csv->is_missing (1), "empty column: is_missing (1) should return true";
    ok exists $hr->{first}  &&  defined $hr->{first};
    ok exists $hr->{second} && !defined $hr->{second};
    }

done_testing ();
