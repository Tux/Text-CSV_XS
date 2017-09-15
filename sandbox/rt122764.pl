#!/pro/bin/perl

use 5.18.2;
use Data::Peek;
use Text::CSV_XS;

foreach my $eol ("\n", "\r", "\r\n") {
    my $data = join $eol =>
	"foo,BAR,baz",
	"ONE,two,Three",
	"Four,FIVE,six",
	"";

    open my $fh, "<", \$data;
    my $csv = Text::CSV_XS->new ({binary => 1});
    my @hdr = $csv->header ($fh);
    DDumper { head => \@hdr, rest => DDisplay ($csv->{_AHEAD}), eol => DDisplay ($eol) };

    while (my $rec = $csv->getline_hr ($fh)) {
	DDumper $rec;
	}
    }

warn "Now WITH file\n";

my $fn = "eol$$.csv";

foreach my $eol ("\n", "\r", "\r\n") {
    my $data = join $eol =>
	"foo,BAR,baz",
	"ONE,two,Three",
	"Four,FIVE,six",
	"";

    open my $fh, ">", $fn;
    binmode $fn;
    print $fh $data;
    close $fh;

    open $fh, "<", $fn;
    my $csv = Text::CSV_XS->new ({binary => 1});
    my @hdr = $csv->header ($fh);
    DDumper { head => \@hdr, rest => DDisplay ($csv->{_AHEAD}), eol => DDisplay ($eol) };

    while (my $rec = $csv->getline_hr ($fh)) {
	DDumper $rec;
	}
    }

warn "Now with BOM\n";

foreach my $eol ("\n", "\r", "\r\n") {
    my $data = join $eol =>
	"\x{feff}foo,BAR,baz",
	"ONE,two,Three",
	"Four,FIVE,six",
	"";

    open my $fh, ">:encoding(utf-8)", $fn;
    print $fh $data;
    close $fh;

    open $fh, "<", $fn;
    my $csv = Text::CSV_XS->new ({binary => 1});
    my @hdr = $csv->header ($fh);
    DDumper { head => \@hdr, rest => DDisplay ($csv->{_AHEAD}), eol => DDisplay ($eol) };

    while (my $rec = $csv->getline_hr ($fh)) {
	DDumper $rec;
	}
    }
