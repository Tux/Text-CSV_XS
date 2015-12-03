#!/pro/bin/perl
use 5.18.2;
use warnings;

use Data::Peek;
use Text::CSV;
use Text::CSV::Separator;
use Text::CSV_XS;

sub parseCSVUpload {
    my $self = shift;
    my $args = {
	filename => undef,
	sep_char => ",",
	@_
	};

    open my $io, "<:encoding(utf8)", $args->{filename}
	or die "$args->{filename}: $!";

    my $sep_char = $args->{sep_char};

    if (!$sep_char) {
	$sep_char = Text::CSV::Separator::get_separator (
	    path  => $args->{filename},
	    lucky => 1,
	    );
	}

    warn "sep_char: $sep_char\n";
    my $csv = Text::CSV_XS->new ({
	allow_loose_quotes  => 1,
	allow_loose_escapes => 1,
	allow_whitespace    => 1,
	auto_diag           => 1,
	diag_verbose        => 9,
	sep_char            => $sep_char,
	binary              => 1,
	});

    my $hdr = $csv->getline ($io);
    DDumper { hdr => $hdr };
    $csv->column_names ($hdr);
    warn "COLS: @{[$csv->column_names]}\n";
    my $result = $csv->getline_hr_all ($io);
    close $io;

    return $result;
    }

parseCSVUpload (undef, filename => "sandbox/basbl-1.csv");
