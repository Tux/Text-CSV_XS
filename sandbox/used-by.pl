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
	"ACME-QuoteDB",				# ::CSV Possible precedence issues
	"App-Framework",			# Questions
	"ASNMTAP",				# Questions
	"Business-Shipping-DataTools",		# Questions and unmet prereqs
	"CGI-Application-Framework",		# Unmet prerequisites
	"chart",				# Questions (in Apache-Wyrd)
	"CohortExplorer",			# Unmet prerequisites
	"Connector",				# No Makefile.PL (in Annelidous)
	"DBIx-Class-FilterColumn-ByType",	# ::CSV - unmet prereqs
	"DBIx-Class-FormTools",			# ::CSV POD
	"DBIx-Class-FromSledge",		# ::CSV Spelling
	"DBIx-Class-InflateColumn-Serializer-CompressJSON",	# ::CSV POD
	"DBIx-Class-Loader",			# ::CSV Deprecated
	"DBIx-Class-QueryProfiler",		# ::CSV - Kwalitee test (2011)
	"DBIx-Class-RDBOHelpers",		# ::CSV - Unmet prereqs
	"DBIx-Class-Schema-Slave",		# ::CSV - Tests br0ken
	"DBIx-Class-Snowflake",			# ::CSV - Bad tests. SQLite fail
	"DBIx-Class-StorageReadOnly",		# ::CSV - POD coverage
	"DBIx-NoSQL",				# ::CSV - Syntax
	"DBIx-Patcher",				# ::CSV - Own tests fail
	"dbMan",				# Questions
	"Finance-Bank-DE-NetBank",		# Module signatures
	"FormValidator-Nested",			# ::CSV - Questions
	"FreeRADIUS-Database",			# ::CSV - Questions
	"Fsdb",					# ::CSV -
	"Gtk2-Ex-DBITableFilter",		# Unmet prerequisites
	"Gtk2-Ex-Threads-DBI",			# Distribution is incomplete
	"hwd",					# Own tests fail
	"Iterator-BreakOn",			# ::CSV - Syntax, POD, badness
	"Mail-Karmasphere-Client",		# ::CSV - No karmaclient
	"Module-CPANTS-ProcessCPAN",		# ::CSV - Questions
	"Module-CPANTS-Site",			# ::CSV - Unmet prerequisites
	"Net-IPFromZip",			# Missing zip file(s)
	"Parse-CSV-Colnames",			# ::CSV - Fails because of Parse::CSV
	"RDF-RDB2RDF",				# ::CSV - Bad tests
	"RT-Extension-Assets-Import-CSV",	# Questions
	"RT-View-ConciseSpreadsheet",		# Questions
	"Test-DBIC",				# ::CSV - Insecure -T in C3
#	"Text-CSV-Encoded",			# ::CSV - Encoding, patch filed at RT
	"Text-CSV_PP-Simple",			# ::CSV - Syntax errors, bad archive
#	"Text-CSV-Track",			# Encoding, patch filed at RT
	"Text-ECSV",				# POD, spelling
	"Text-MeCab",				# Questions
	"Text-TEI-Collate",			# Unmet prerequisites
	"Text-Tradition",			# Unmet prerequisites
	"Tripletail",				# Makefile.PL broken
	"VANAMBURG-SEMPROG-SimpleGraph",	# Own tests fail
	"WebService-FuncNet",			# ::CSV - WSDL 404, POD
	"Webservice-InterMine",			# Unmet prerequisites
	"WWW-Analytics-MultiTouch",		# Unmet prerequisites
	"XAS",					# ::CSV - No STOMP MQ
	"XAS-Model",				# ::CSV - No STOMP MQ
	"XAS-Spooler",				# ::CSV - No STOMP MQ
	"xDash",				# Questions
#	"xls2csv",
	"Xymon-DB-Schema",			# ::CSV - Bad prereqs
	"Xymon-Server-ExcelOutages",		# ::CSV - Questions
	"YamlTime",				# Unmet prerequisites
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
    my $m = shift // $tm;
    warn "Get from cpantesters ...\n";
    my $url = "http://deps.cpantesters.org/depended-on-by.pl?dist=$m";
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
    my $m = shift // $tm;
    warn "Get from cpants ...\n";
    my $url = "http://cpants.cpanauthors.org/dist/$m/used_by";
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
	$h =~ m{^$m\b} and next;
	push @h, $h;
	}
    @h or diag ("$url might be rebuilding");
    return @h;
    } # get_from_cpants

sub get_from_meta
{
    my $m = shift // $tm;
    warn "Get from meta ...\n";
    my $url = "https://metacpan.org/requires/distribution/$m";
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
	$h =~ m{^$m\b} and next;
	push @h, $h;
	}
    return @h;
    } # get_from_meta

my @h = ( get_from_cpants (),
	  get_from_cpantesters (),
	  get_from_meta (),
	  @{$add{$tm} || []});

$tm eq "Text-CSV_XS" and push @h,
          get_from_cpants ("Text-CSV"),
          get_from_cpantesters ("Text-CSV"),
          get_from_meta ("Text-CSV");

foreach my $h (@h) {
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
