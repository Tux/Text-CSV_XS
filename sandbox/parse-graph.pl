#!/pro/bin/perl

use strict;
use warnings;

use File::Copy;
use Tk;
use Tk::WinPhoto;

use Getopt::Long;
my $opt_xs = 0;
GetOptions (
    "x|xs|xs-only|xs_only!"	=> \$opt_xs,
    ) or die "usage: $0 [--xs-only]\n";

my @id = (
    [ "xs perl", "Black"  ],
    [ "xs gtln", "Blue"   ],
    [ "xs bndc", "Green"  ],
    [ "xs splt", "Purple" ],
    [ "pp perl", "Navy"   ],
    [ "pp gtln", "Cyan"   ],
    [ "pp bndc", "Red"    ],
    );

my %set = (
       4 => [ 100, 76, 33,  552,  659,  723 ],
       8 => [ 100, 46, 29,  640,  747,  809 ],
      16 => [ 100, 43, 25,  754,  836,  933 ],
      32 => [ 100, 30, 16,  707,  692,  754 ],
      64 => [ 100, 39, 18,  888,  938,  869 ],
     128 => [ 100, 36, 20,  661,  680,  711 ],
     256 => [ 100, 33, 13, 1015, 1001, 1093 ],
     512 => [ 100, 37, 15, 1001, 1004, 1126 ],
    1024 => [ 100, 36, 15,  925,  880,  940 ],
    2048 => [ 100, 34, 15, 1035, 1054, 1174 ],
    );
my %vsn;
{   my ($p, $cols) = (0);
    my %pos = map { $_ => $p++ }
	"xs perl", "xs gtln", "xs bndc", "xs splt",
	"pp perl", "pp gtln", "pp bndc";
    while (<>) {
	if (m/^((?|perl()|Text::CSV_(..))-[0-9.]+)/) {
	    $opt_xs && $2 eq "PP" and next;
	    $vsn{$1} = 1;
	    next;
	    }
	if (m/^--+\s+.*?\s+x\s+([0-9]+)\s+/) {
	    $cols = $1;
	    next;
	    }
	m/^((?:xs|pp) (?:perl|gtln|bndc|splt)):.*-\s*([0-9]+)$/ and
	    $set{$cols}[$pos{$1}] = $2;
	}
    }

my @rs = sort { $a <=> $b } keys %set;

my ($cx, $cy) = (950, 550);
$cx -= 150; # Legend

my $title = "Speed comp";
my ($y_min, $y_max) = (0, $opt_xs ? 120 : 1300);

my $w = MainWindow->new;
$w->title ($title);
$w->bind ("<Key-q>" => sub { exit (0); });
my $c = $w->Canvas (
    -background		=> "White", # $w->cget (-background),
    -width		=> $cx + 150,
    -height		=> $cy,
    -relief		=> "flat",
    -borderwidth	=>   0,
    -highlightthickness => 0)->pack (-expand => 1);

my $tickLineColor = "Gray90";
my $scoreColor    = "Blue4";
my $dateColor     = "Green4";
my $date_dens = 10;	# Show a date every n tick marks. Too low gets crowded
my $x_ticks   = @rs;
my $y_ticks   = 10;
my $y_dif     = $y_max - $y_min;
my $y_int     = $y_dif / $y_ticks;
my ($fx, $fy) = ($cx / @rs, $cy / $y_dif);

foreach my $y (1 .. ($y_ticks - 1)) {
    my $py = $cy - $y * ($cy / $y_ticks);
    $c->createLine (0, $py, $cx, $py,
	-tags	=> "tick-y",
	-fill	=> $tickLineColor,
	-width	=> 1);
    }
$c->update;

foreach my $i (0 .. $x_ticks) {
    my $x = $cx * $i / $x_ticks;
    $c->createLine ($x, 0, $x, $cy,
	-tags	=> "tick-x",
	-fill	=> $tickLineColor,
	-width	=> 1);
    $c->update;

    $c->createText (5 + $i * $fx, 5,
	-text   => $rs[$i],
	-tags   => "tick-t",	# Time
	-fill   => $dateColor,
	-font	=> "{DejaVu Sans Mono} 10",
	-anchor => "nw");
    }
$c->update;

foreach my $r (0 .. $#id) {
    my ($key, $color) = @{$id[$r]};
    $opt_xs && $key =~ m/^pp/ and next;
    my @line;
    foreach my $rs (0 .. $#rs) {
	my $v = $set{$rs[$rs]}[$r];
	push @line, $rs * $fx, $cy - (($v // 0) - $y_min) * $fy;
	}
    $c->createLine (@line,
	-smooth => 0,
	-fill   => $color,
	-width  => 3);
    $key =~ s/xs splt/split/;
    $c->createText ($cx + 5, 40 + $r * 30,
	-text	=> $key,
	-fill	=> $color,
	-anchor	=> "w",
	-font	=> "{DejaVu Sans Mono} 12",
	);
    }
$c->createText ($cx - 72, $cy - 280,
    -text	=> (join "\n" => reverse sort keys %vsn),
    -fill	=> "Blue4",
    -anchor	=> "w",
    -font	=> "{DejaVu Sans Mono} 11",
    );
$c->createText ($cx - 72, 50,
    -text	=> "slow",
    -fill	=> "Red4",
    -anchor	=> "sw",
    -font	=> "{DejaVo Sans} 9",
    );
$c->createText ($cx - 72, $cy - 50,
    -text	=> "fast",
    -fill	=> "Red4",
    -anchor	=> "nw",
    -font	=> "{DejaVo Sans} 9",
    );
$c->update;

my $img = $w->Photo (-format => "Window", -data => oct ($w->id));
my $fn = $opt_xs ? "parse-xs" : "parse-pp";
$img->write ("$fn.xpm", -format => "xpm");
system "convert $fn.xpm $fn.png";
unlink "$fn.xpm";
$w->bell;

MainLoop;
