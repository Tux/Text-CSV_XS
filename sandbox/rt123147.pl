#!/pro/bin/perl

use 5.018002;
use warnings;

use CSV;

DDumper csv (in => "rt123147.csv", headers  => "auto");
DDumper csv (in => "rt123147.csv", encoding => "auto");
DDumper csv (in => "rt123147.csv", bom      => 1);
