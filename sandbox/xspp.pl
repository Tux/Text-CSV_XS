#!/pro/bin/perl

BEGIN {
    my $xspp;
    if    ( grep {$_ eq "--xs"} @ARGV) { $xspp = 2; }
    elsif ( grep {$_ eq "--pp"} @ARGV) { $xspp = 0; }
    $ENV{PERL_TEXT_CSV} = $xspp if defined $xspp;
    }

use Text::CSV;

my $opts  = {
    auto_diag	=> 1,
    binary      => 1, 
    eol         => "\n", 
    sep_char    => "\t",
    escape_char => undef,
    quote_char  => undef,
    };

my $csv = Text::CSV->new ($opts) or
    die "Cannot use CSV: " . Text::CSV->error_diag ();

binmode STDOUT, ":utf8";
printf "Backend: %s-%s\n", $csv->backend, $csv->version;

-d "sandbox" and chdir "sandbox";

my $file = "xspp.txt";
open my $fh, "<:encoding(utf8)", $file or die "$file: $!";
my $iline;
while (my $row = $csv->getline ($fh)) {
    my $ncol = scalar @$row;
    my $s = join "/", @$row;
    length ($s) > 73 and
	$s = substr ($s, 0, 60)."..."; # shorten long lines for display
    printf "%4d (%4d): '%s'\n", $iline++, $ncol, $s;
    }

close $fh;
