#!/pro/bin/perl

use strict;
use warnings;

use Getopt::Long qw(:config bundling nopermute);
my $check = 0;
my $opt_v = 0;
GetOptions (
    "c|check"		=> \$check,
    "v|verbose:1"	=> \$opt_v,
    ) or die "usage: $0 [--check]\n";

use lib "sandbox";
use genMETA;
my $meta = genMETA->new (
    from    => "CSV_XS.pm",
    verbose => $opt_v,
    );

$meta->from_data (<DATA>);
$meta->gen_cpanfile ();

if ($check) {
    $meta->check_encoding ();
    $meta->check_required ();
    my %ex;
    for ( [qw( csv2xls		5.012	)], # //=
	  [qw( csv2xlsx		5.014	)], # s///r
	  [qw( csv-check	5.012	)], # //=
	  [qw( csvdiff		5.010	)], # //=
	  [qw( parser-xs.pl	5.006	)], #
	  [qw( rewrite.pl	5.010	)], # //=
	  [qw( speed.pl		5.008	)], # open "<", \$
	  ) {
	substr $_->[0], 0, 0, "examples/";
	$ex{$_->[1]}{$_->[0]}++;
	$ex{$_->[0]} = $_->[1];
	}
    for (grep { !$ex{$_} } glob "examples/*") {
	$ex{$_} = "5.006";
	$ex{"5.006"}{$_}++;
	}

    $meta->check_minimum (s/\.0+/./r, [ sort keys %{$ex{$_}} ]) for
	sort { $a <=> $b } grep m/^5/ => keys %ex;
    $meta->done_testing ();
    }
elsif ($opt_v) {
    $meta->print_yaml ();
    }
else {
    $meta->fix_meta ();
    }

__END__
--- #YAML:1.0
name:                    Text-CSV_XS
version:                 VERSION
abstract:                Comma-Separated Values manipulation routines
license:                 perl
author:
    - H.Merijn Brand <h.m.brand@xs4all.nl>
generated_by:            Author
distribution_type:       module
provides:
    Text::CSV_XS:
        file:            CSV_XS.pm
        version:         VERSION
requires:
    perl:                5.006001
    XSLoader:            0
    IO::Handle:          0
recommends:
    Encode:              3.05
configure_requires:
    ExtUtils::MakeMaker: 0
build_requires:
    Config:              0
test_requires:
    Test::More:          0
    Tie::Scalar:         0
resources:
    license:             http://dev.perl.org/licenses/
    repository:          https://github.com/Tux/Text-CSV_XS
    homepage:            https://metacpan.org/pod/Text::CSV_XS
    bugtracker:          http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-CSV_XS
    IRC:                 irc://irc.perl.org/#csv
meta-spec:
    version:             1.4
    url:                 http://module-build.sourceforge.net/META-spec-v1.4.html
