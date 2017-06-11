#!/pro/bin/perl

use 5.18.2;
use warnings;

use Data::Peek;
use Text::CSV_XS qw(csv);

my $file = "pm-1192516.csv";

sub make_list_2 {
    my %opt = @_;

    my $headers = $opt{headings};

    my %foo;
    my $list = csv (
	in               => $opt{file},
	headers          => $headers,
	sep_char         => "|",
	quote_char       => undef,
	empty_is_undef   => 1,
	allow_whitespace => 1,
	auto_diag        => 1,
	on_in            => sub {
	    push @{$foo{$_{item}}}, split m/;\s*/ => $_{"seen in+"} },
	);

    return \%foo;
    }

DDumper make_list_2 (file => $file, headings => [ "item", "seen in+" ]);
