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

if ($check) {
    $meta->check_encoding ();
    $meta->check_required ();
    $meta->check_minimum ("5.008004", [ "examples" ]);
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
    DynaLoader:          0
    IO::Handle:          0
recommends:     
    perl:                5.018001
    Encode:              2.57
configure_requires:
    ExtUtils::MakeMaker: 0
build_requires:
    Config:              0
test_requires:
    Test::More:          0
    Tie::Scalar:         0
resources:
    license:             http://dev.perl.org/licenses/
    repository:          http://repo.or.cz/w/Text-CSV_XS.git
meta-spec:
    version:             1.4
    url:                 http://module-build.sourceforge.net/META-spec-v1.4.html
