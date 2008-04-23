#!/pro/bin/perl

# This script can be used as a base to parse unreliable CSV streams
# Modify to your own needs

use strict;
use warnings;

use Text::CSV_XS;

my $csv = Text::CSV_XS->new ({ binary             => 1,
			       blank_is_undef     => 1,
			       eol                => $/,
			       });
my $csa = Text::CSV_XS->new ({ binary             => 1,
			       allow_loose_quotes => 1,
			       blank_is_undef     => 1,
			       escape_char        => undef,
			       });

my $file = @ARGV ? shift : "test.csv";
open my $fh, "<", $file or die "$file: $!\n";

my %err_eol = map { $_ => 1 } 2010, 2027, 2031, 2032;

print STDERR "Reading $file with Text::CSV_XS $Text::CSV_XS::VERSION\n";
while (1) {
    my $row = $csv->getline ($fh);

    unless ($row) {	# Parsing failed

	# Could be end of file
	$csv->eof and last;

	# Diagnose and show what was wrong
	my @diag = $csv->error_diag;
	print STDERR "$file line $./$diag[2] - $diag[0] - $diag[1]\n";
	my $ep  = $diag[2] - 1; # diag[2] is 1-based
	my $ein = $csv->error_input;	# The line scanned so far
	my $err = $ein . "         ";
	substr $err, $ep + 1, 0, "*";	# Bad character marked between **
	substr $err, $ep,     0, "*";
	($err = substr $err, $ep - 5, 12) =~ s/ +$//;
	print STDERR "    |$err|\n";

	REPARSE: {	# Now retry with allowed options
	    if ($csa->parse ($ein)) {
		print STDERR "Accepted in allow mode ...\n";
		$row = [ $csa->fields ];
		}
	    else {	# Still fails
		my @diag = $csa->error_diag;
		if (exists $err_eol{$diag[0]}) { # \r or \n inside field
		    print STDERR "  Extending line with next chunk\n";
		    $ein .= scalar <$fh>;
		    goto REPARSE;
		    }

		print STDERR "  Also could not parse it in allow mode\n";
		print STDERR "  $./$diag[2] - $diag[0] - $diag[1]\n";
		print STDERR "  Line skipped\n";
		next;
		}
	    }
	}

    # Data was fine, print data properly quoted
    $csv->print (*STDOUT, $row);
    }
