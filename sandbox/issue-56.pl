m!/pro/bin/perl

use 5.026002;
use warnings;

use Test::More;
use Data::Peek;
use Text::CSV_XS;

note $Text::CSV_XS::VERSION;

foreach my $strict (0, 1) {
    my $csv = Text::CSV_XS->new ({
	binary      => 1,
	comment_str => "#",
	eol         => "\n",
	escape_char => '"',
	quote_char  => '"',
	sep_char    => "|",
	strict      => $strict,
	});

    my $status = $csv->parse ('a|b|"d"');
    is (0 + $csv->error_diag,    0);	# No error
    note DDumper { strict => $strict, diag => [ $csv->error_diag ] };
    $status = $csv->parse ('a|b|c"d"e');
    is (0 + $csv->error_diag, 2034);	# Loose unescaped quote
    note DDumper { strict => $strict, diag => [ $csv->error_diag ] };
    }

done_testing;
