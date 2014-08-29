#!/pro/bin/perl

use 5.16.2;
use warnings;

use Cwd;
use LWP;
use LWP::UserAgent;
use HTML::TreeBuilder;
use CPAN;
use Capture::Tiny qw( :all );
use Term::ANSIColor qw(:constants :constants256);
use Test::More;
use XML::Simple;

my $tm = shift // do {
    (my $d = getcwd) =~ s{.*CPAN/([^/]+)(?:/.*)?}{$1};
    $d;
    } or die "No module to check\n";

diag ("Testing used-by for $tm\n");
my %tm = map { $_ => 1 } qw( );

$| = 1;
$ENV{AUTOMATED_TESTING} = 1;
# Skip all dists that
# - are FAIL but not due to Data::Peek
# - that require interaction (not dealt with in distroprefs)
# - are not proper dists (cannot use CPAN's ->test)
# - require external connections or special devices
my %skip = map { $_ => 1 } @{{
    "Data-Peek"   => [qw( GSM-Gnokii					)],
    "DBD-CSV"     => [qw( ASNMTAP					)],
    "Text-CSV_XS" => [qw( App-Framework CGI-Application-Framework
                          RT-Extension-Assets-Import-CSV
                          RT-View-ConciseSpreadsheet Text-ECSV Text-MeCab
                          Tripletail chart dbMan hwd xDash xls2csv	)],
    }->{$tm} // []};

my $ua  = LWP::UserAgent->new (agent => "Opera/12.15");

sub get_from_cpantesters
{
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

foreach my $h (get_from_cpants (), get_from_cpantesters ()) {
    exists $skip{$h} || $h =~ m{^( $tm (?: $ | / )
				 | Task-
				 | Bundle-
				 | Win32-
				 )\b}x and next;
    (my $m = $h) =~ s/-/::/g;
    $tm{$m} = 1;
    }

unless (keys %tm) {
    ok (1, "No dependents found");
    done_testing;
    exit 0;
    }

my %rslt;
foreach my $m (sort keys %tm) {
    my $mod = CPAN::Shell->expand ("Module", "/$m/") or next;
    # diag $m;
    $rslt{$m}    = [ [], capture { $mod->test } ];
    $rslt{$m}[0] = [ $?, $!, $@ ];
    # say $? ? RED."FAIL".RESET : GREEN."PASS".RESET;
    is ($?, 0, $m);
    }

done_testing;
