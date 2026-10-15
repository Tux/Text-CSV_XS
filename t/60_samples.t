#!/usr/bin/perl

use strict;
use warnings;

use Config;
use Test::More tests => 12;

BEGIN {
    use_ok "Text::CSV_XS", ();
    plan skip_all => "Cannot load Text::CSV_XS" if $@;
    }

my $bsdr = eval { require BSD::Resource; 1; };

# Some assorted examples from the modules history and other sources

# "Pavel Kotala" <pkotala@logis.cz>
{   my $csv = Text::CSV_XS->new ({
	quote_char	=> '"',
	escape_char	=> '\\',
	sep_char	=> ';',
	binary		=> 1,
	});
    ok ($csv,				"new (\", \\\\, ;, 1)");

    my @list = ("c:\\winnt", "text");
    ok ($csv->combine (@list),		"combine ()");
    my $line = $csv->string;
    ok ($line,				"string ()");
    ok ($csv->parse ($line),		"parse ()");
    my @olist = $csv->fields;
    is (scalar @list, scalar @olist,	"field count");
    is ($list[0], $olist[0],		"field 1");
    is ($list[1], $olist[1],		"field 2");
    }

if ($bsdr || -e "/proc/self/statm" and
       exists  $Config{useperlio} &&
       defined $Config{useperlio} &&
       $Config{useperlio} eq "define") {
    sub rss {
	if ($bsdr) {
	    my @br = BSD::Resource::getrusage ();
	    return $br[2] * 1000;
	    }
	open my $fh, "<", "/proc/self/statm" or die "$!";
	(split m/\s+/ => scalar <$fh>)[1] * 4096;
	} # rss

    my $csv   = Text::CSV_XS->new ({ binary => 1 });
    my $width = 20_000;
    my $good  = ("," x $width) . "\n";
    my $bad   = ("," x $width) . qq{"a"b\n};

    # Warm up allocator and cache
    for (1 .. 3) {
	open my $fh, "<", \$good or die "$!";
	$csv->getline ($fh);
	open    $fh, "<", \$bad  or die "$!";
	$csv->getline ($fh);
	}

    my $r0 = rss ();
    for (1 .. 40) {
	open my $fh, "<", \$bad or die "$!";
	$csv->getline ($fh);
	}
    my $grow = rss () - $r0;
    is (($csv->error_diag)[0], 2023, "Records fail to parse");
    cmp_ok ($grow, "<", 8_000_000, "Failed getline () calls do not keep the fields");

    $r0 = rss ();
    for (1 .. 40) {
	$csv->getline_all (do { open my $fh, "<", \$good or die "$!"; $fh });
	}
    $grow = rss () - $r0;
    cmp_ok ($grow, "<", 8_000_000, "getline_all () does not keep the trailing row");

    $r0 = rss ();
    my $out = "";
    open my $oh, ">", \$out or die "$!";
    $csv->print ($oh, undef) for 1 .. 200_000;
    $grow = rss () - $r0;
    cmp_ok ($grow, "<", 8_000_000, "print (\$fh, undef) does not keep an array");
    }
else {
    ok (1, "This test only runs on Linux with PerlIO") for 1..4;
    }

1;
