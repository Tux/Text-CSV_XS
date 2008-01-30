#!/usr/bin/perl

# Copyright PROCURA B.V. (c) 2006-2008 H.Merijn Brand

require 5.005;
use strict;

use ExtUtils::MakeMaker;

eval { require Text::CSV_XS };
if (!$@ && $Text::CSV_XS::VERSION < 0.15) {
    print <<'MSG';

You seem to have installed a previous version of the Text::CSV_XS module.
Note that you might encounter problems in existing applications (not the
DBD::CSV driver) due to incompatible changes in the print and getline
methods. See "perldoc CSV_XS.pm" for details.

MSG
    sleep 5;
    }

my %wm = (
    NAME         => "Text::CSV_XS",
    ABSTRACT     => "Comma-Separated Values manipulation routines",
    AUTHOR       => "H.Merijn Brand <h.merijn\@xs4all.nl>",
    VERSION_FROM => "CSV_XS.pm",
    PREREQ_PM	 => { "DynaLoader"	=> 0,
		      "Config"		=> 0,
		      "IO::Handle"	=> 0,
		      "Test::More"	=> 0,
		      "Test::Harness"	=> 0,
		      },
    clean        => { FILES => join " ", qw(
			 CSV_XS.c.gcov
			 CSV_XS.gcda
			 CSV_XS.gcno
			 CSV_XS.xs.gcov
			 cover_db
			 )
		      },
    );
$ExtUtils::MakeMaker::VERSION > 6.30 and $wm{LICENSE} = "perl";

my $rv = WriteMakefile (%wm);

1;

package MY;

sub postamble
{
    my $pa = join "\n" =>
	'cover test_cover:',
	'	cover -delete',
	'	make',
	'	HARNESS_PERL_SWITCHES=-MDevel::Cover $(MAKE) test',
	'	gcov CSV_XS.c 2>/dev/null',
	'	find * -name \*.gcov -exec gcov2perl {} \;',
	'	cover',
	'',
	'test_speed: pure_all',
	'	PERL_DL_NONLAZY=1 $(FULLPERLRUN) -I"$(INST_LIB)" -I"$(INST_ARCHLIB)" examples/speed.pl',
	'';
    $] < 5.006 and $pa .= join "\n" => '',
	'pure_all ::',
	'	rm -f blib/lib/Text/CSV_XS.pm',
	q{	$(PERL) -p -e 's/^use warnings;/local \\044^W = 1;/' CSV_XS.pm > blib/lib/Text/CSV_XS.pm},
	'	chmod -w blib/lib/Text/CSV_XS.pm',
	'';
    $pa;
    } # postamble
