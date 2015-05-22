#!/pro/bin/perl

use 5.16.2;
use warnings;

sub usage
{
    my $err = shift and select STDERR;
    say "usage: $0 [--list]";
    exit $err;
    } # usage

use Cwd;
use LWP;
use LWP::UserAgent;
use HTML::TreeBuilder;
use CPAN;
use Capture::Tiny qw( :all );
use Term::ANSIColor qw(:constants :constants256);
use Test::More;

use Getopt::Long qw(:config bundling passthrough);
GetOptions (
    "help|?"	=> sub { usage (0); },
    "a|all!"	=> \my $opt_a,	# Also build for known FAIL (they might have fixed it)
    "l|list!"	=> \my $opt_l,
    ) or usage (1);

my $tm = shift // do {
    (my $d = getcwd) =~ s{.*CPAN/([^/]+)(?:/.*)?}{$1};
    $d;
    } or die "No module to check\n";

diag ("Testing used-by for $tm\n");
my %tm = map { $_ => 1 } qw( );

$| = 1;
$ENV{AUTOMATED_TESTING} = 1;
# Skip all dists that
# - are FAIL not due to the mudule being tested (e.g. POD or signature mismatch)
# - that require interaction (not dealt with in distroprefs or %ENV)
# - are not proper dists (cannot use CPAN's ->test)
# - require external connections or special devices
my %skip = $opt_a ? () : map { $_ => 1 } @{{
    "Data-Peek"   => [
	"GSM-Gnokii",				# External device
	],
    "DBD-CSV"     => [
	"ASNMTAP",
	"Gtk2-Ex-DBITableFilter",		# Unmet prerequisites
	],
    "Text-CSV_XS" => [
	"ASNMTAP",				# Questions
	"App-Framework",			# Questions
	"Business-Shipping-DataTools",		# Questions and unmet prereqs
	"CGI-Application-Framework",		# Unmet prerequisites
	"CohortExplorer",			# Unmet prerequisites
	"Connector",				# no Makefile.PL (in Annelidous)
	"Finance-Bank-DE-NetBank",		# Module signatures
	"Gtk2-Ex-DBITableFilter",		# Unmet prerequisites
	"Gtk2-Ex-Threads-DBI",			# distribution is incomplete
	"Net-IPFromZip",			# missing zip file(s)
	"RT-Extension-Assets-Import-CSV",	# Questions
	"RT-View-ConciseSpreadsheet",		# Questions
#	"Text-CSV-Track",			# encoding, patch filed at RT
	"Text-ECSV",				# POD, spelling
	"Text-MeCab",				# Questions
	"Text-TEI-Collate",			# Unmet prerequisites
	"Text-Tradition",			# Unmet prerequisites
	"Tripletail",				# Makefile.PL broken
	"WWW-Analytics-MultiTouch",		# Unmet prerequisites
	"Webservice-InterMine",			# Unmet prerequisites
	"YamlTime",				# Unmet prerequisites
	"chart",				# Questions (in Apache::Wyrd)
	"dbMan",				# Questions
	"hwd",					# Own tests fail
	"xDash",				# Questions
#	"xls2csv",
	],
    }->{$tm} // []};
my %add = (
    "Text-CSV_XS"  => [				# Using Text::CSV, thus
	"Text-CSV-Auto",			# optionally _XS
	"Text-CSV-R",
	"Text-CSV-Slurp",
	],
    );

my $ua  = LWP::UserAgent->new (agent => "Opera/12.15");

sub get_from_cpantesters
{
    warn "Get from cpantesters ...\n";
    my $url = "http://deps.cpantesters.org/depended-on-by.pl?dist=$tm";
    my $rsp = $ua->request (HTTP::Request->new (GET => $url));
    unless ($rsp->is_success) {
	warn "deps failed: ", $rsp->status_line, "\n";
	return;
	}
    my $tree = HTML::TreeBuilder->new;
       $tree->parse_content ($rsp->content);
    my @h;
    foreach my $a ($tree->look_down (_tag => "a", href => qr{query=})) {
	(my $h = $a->attr ("href")) =~ s{.*=}{};
	push @h, $h;
	}
    return @h;
    } # get_from_cpantesters

sub get_from_cpants
{
    warn "Get from cpants ...\n";
    my $url = "http://cpants.cpanauthors.org/dist/$tm/used_by";
    my $rsp = $ua->request (HTTP::Request->new (GET => $url));
    unless ($rsp->is_success) {
	warn "cpants failed: ", $rsp->status_line, "\n";
	return;
	}
    my $tree = HTML::TreeBuilder->new;
       $tree->parse_content ($rsp->content);
    my @h;
    foreach my $a ($tree->look_down (_tag => "a", href => qr{/dist/})) {
	(my $h = $a->attr ("href")) =~ s{.*dist/}{};
	$h =~ m{^$tm\b} and next;
	push @h, $h;
	}
    @h or diag ("$url might be rebuilding");
    return @h;
    } # get_from_cpants

sub get_from_meta
{
    warn "Get from meta ...\n";
    my $url = "https://metacpan.org/requires/distribution/$tm";
    my $rsp = $ua->request (HTTP::Request->new (GET => $url));
    unless ($rsp->is_success) {
	warn "meta failed: ", $rsp->status_line, "\n";
	return;
	}
    my $tree = HTML::TreeBuilder->new;
       $tree->parse_content ($rsp->content);
    my @h;
    foreach my $a ($tree->look_down (_tag => "a", class => "ellipsis",
					href => qr{/release/})) {
	(my $h = $a->attr ("href")) =~ s{.*release/}{};
	$h =~ m{^$tm\b} and next;
	push @h, $h;
	}
    return @h;
    } # get_from_meta

foreach my $h ( get_from_cpants (),
		get_from_cpantesters (),
		get_from_meta (),
		@{$add{$tm} || []},
		) {
    exists $skip{$h} || $h =~ m{^( $tm (?: $ | / )
				 | Task-
				 | Bundle-
				 | Win32-
				 )\b}x and next;
    (my $m = $h) =~ s/-/::/g;
    $tm{$m} = 1;
    }

warn "fetched ", scalar keys %tm, " keys\n";

unless (keys %tm) {
    ok (1, "No dependents found");
    done_testing;
    exit 0;
    }

if ($opt_l) {
    ok (1, $_) for sort keys %tm;
    done_testing;
    exit 0;
    }

my %rslt;
#$ENV{AUTOMATED_TESTING} = 1;
foreach my $m (sort keys %tm) {
    my $mod = CPAN::Shell->expand ("Module", "/$m/") or next;
    # diag $m;
    $rslt{$m}    = [ [], capture { $mod->test } ];
    $rslt{$m}[0] = [ $?, $!, $@ ];
    # say $? ? RED."FAIL".RESET : GREEN."PASS".RESET;
    is ($?, 0, $m);
    }

done_testing;
