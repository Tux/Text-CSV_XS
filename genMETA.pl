#!/pro/bin/perl

use strict;
use warnings;

my $version;
open my $pm, "<", "CSV_XS.pm" or die "Cannot read CSV_XS>PM";
while (<$pm>) {
    m/^.VERSION\s*=\s*"?([-0-9._]+)"?\s*;\s*$/ or next;
    $version = $1;
    last;
    }
close $pm;

my @my = glob <*/META.yml>;
@my == 1 && open my $my, ">", $my[0] or die "Cannot update META.yml|n";
while (<DATA>) {
    s/VERSION/$version/o;
    print $my $_;
    }
close $my;

__END__
--- #YAML:1.0
name:              Text-CSV_XS
version:           VERSION
abstract:          Comma-Separated Values manipulation routines
license:           perl
author:              
    - H.Merijn Brand <h.merijn@xs4all.nl>
generated_by:      Author
distribution_type: module
provides:
    Text::CSV_XS:
        file:      CSV_XS.pm
        version:   VERSION
requires:     
    perl:          5.005
    DynaLoader:    0
    IO::Handle:    0
build_requires:
    perl:          5.005
    Config:        0
    Test::Harness: 0
    Test::More:    0
resources:
    license:       http://dev.perl.org/licenses/
meta-spec:
    url:           http://module-build.sourceforge.net/META-spec-v1.3.html
    version:       1.3
