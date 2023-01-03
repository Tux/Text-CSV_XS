#!/pro/bin/perl

# Read the export from Thumbs Plus including keywords from filename given. Make a useful
# in-memory data structure and then store that in some useful format (JSON?).

use 5.018002;	# or later to get "unicode_strings" feature
use warnings  qw(FATAL utf8);	# fatalize encoding glitches
use utf8;	# so literals and identifiers can be in UTF-8
use open      qw(:std :utf8);	# undeclared streams in UTF-8
use Text::CSV;
use Data::Peek;	# debug

# Take keywords field from extract and turn it into an array.
# Input is semicolon-separated and terminated.
sub keywords {
    my $res = [];
    for my $kw (split /;/ => $_[0]) {
	length $kw and push @$res, $kw;
	}
    return $res;
    } # keywords

my $csv = Text::CSV->new ({ binary => 1, auto_diag => 1 });

my $fn = "pm-1192449.csv";
-d "sandbox" and substr $fn, 0, 0, "sandbox/";
say $fn;
open my $fh, "<:encoding(utf-8)", $fn or die "$fn: $!\n";

# Types and names, together and in order. 
my $types = [];
my $names = [];
my $ix = 0;
$types->[$ix] = Text::CSV::PV; $names->[$ix++] = "vollabel"; # Volume.label",
$types->[$ix] = Text::CSV::PV; $names->[$ix++] = "skip001"; # Missing in label row
$types->[$ix] = Text::CSV::IV; $names->[$ix++] = "Volume.serialno"; # Volume.serialno",
$types->[$ix] = Text::CSV::IV; $names->[$ix++] = "vtype"; # Volume.vtype",
$types->[$ix] = Text::CSV::PV; $names->[$ix++] = "vnetname"; # Volume.netname",
$types->[$ix] = Text::CSV::PV; $names->[$ix++] = "Volume.filesystem"; # Volume.filesystem",
$types->[$ix] = Text::CSV::PV; $names->[$ix++] = "path"; # Path.name",
$types->[$ix] = Text::CSV::IV; $names->[$ix++] = "skip002"; # unknown, "1"
$types->[$ix] = Text::CSV::IV; $names->[$ix++] = "skip003"; # unknown, '0'"
$types->[$ix] = Text::CSV::IV; $names->[$ix++] = "skip004"; # unknown, "0"
$types->[$ix] = Text::CSV::PV; $names->[$ix++] = "date 1"; # date 1"
$types->[$ix] = Text::CSV::PV; $names->[$ix++] = "date 2"; # date 2"
$types->[$ix] = Text::CSV::IV; $names->[$ix++] = "skip005"; # unkown large int"
$types->[$ix] = Text::CSV::IV; $names->[$ix++] = "skip006"; # unkown int"
$types->[$ix] = Text::CSV::IV; $names->[$ix++] = "Thumbnail.width"; # Thumbnail.width",
$types->[$ix] = Text::CSV::IV; $names->[$ix++] = "Thumbnail.height"; # Thumbnail.height",
$types->[$ix] = Text::CSV::IV; $names->[$ix++] = "skip007"; # unknown int"
$types->[$ix] = Text::CSV::IV; $names->[$ix++] = "skip008"; # unknown int"
$types->[$ix] = Text::CSV::IV; $names->[$ix++] = "skip009"; # unknown int"
$types->[$ix] = Text::CSV::IV; $names->[$ix++] = "skip010"; # unknown int"
$types->[$ix] = Text::CSV::IV; $names->[$ix++] = "skip011"; # unknown int"
$types->[$ix] = Text::CSV::IV; $names->[$ix++] = "skip012"; # unknown int"
$types->[$ix] = Text::CSV::IV; $names->[$ix++] = "skip013"; # unknown int"
$types->[$ix] = Text::CSV::IV; $names->[$ix++] = "skip014"; # unknown int"
$types->[$ix] = Text::CSV::IV; $names->[$ix++] = "skip015"; # unknown int"
$types->[$ix] = Text::CSV::PV; $names->[$ix++] = "imagename"; # Thumbnail.name",
$types->[$ix] = Text::CSV::PV; $names->[$ix++] = "Thumbnail.metric1"; # Thumbnail.metric1",
$types->[$ix] = Text::CSV::PV; $names->[$ix++] = "Thumbnail.metric2"; # Thumbnail.metric2",
$types->[$ix] = Text::CSV::PV; $names->[$ix++] = "skip016"; # unknown empty"
$types->[$ix] = Text::CSV::IV; $names->[$ix++] = "skip017"; # unknown, '0'"
$types->[$ix] = Text::CSV::PV; $names->[$ix++] = "keywords"; # Keywords.pkeywords",
$types->[$ix] = Text::CSV::PV; $names->[$ix++] = "skip018"; # nothing.nothing"

$csv->types ($types);
$csv->column_names ($names);

my $tokeep = {
    imagename => 1,
    keywords  => 1,
    path      => 1,
    vnetname  => 1,
    vollabel  => 1,
    vtype     => 1,
    };

my $tpdb = [];

while (my $colref = $csv->getline_hr ($fh)) {
    say "New line";
    my $err = $csv->status ();
    say "status: ", ref $err;
    $err			and warn "On line $. status is non-zero\n";
    $err = $csv->error_input ();
    say "error_input: ", ref $err;
    defined $err		and warn "On line $. parse error in $err";
    $err = $csv->error_diag ();
    say "error_diag:  ", ref $err;
    $err ne ""			and warn "error_diag $err\n";

    push @$tpdb, $colref;
    say "$_ $names->[$_]\t$colref->{$names->[$_]}" for
	grep { $types->[$_] == Text::CSV_XS::IV } 0 .. $#$types;

    # Remove columns we don't care about
    foreach my $cn (keys %$colref) {
	exists $tokeep->{$cn} or delete $colref->{$cn};
	}
    # Process keywords
    $colref->{keywords} = keywords ($colref->{keywords});

    # Do something
    print "End of line processing\n";
    }
