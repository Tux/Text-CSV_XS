#!/usr/bin/perl

# Copyright PROCURA B.V. (c) 2006-2009 H.Merijn Brand

require 5.005; # <- also see postamble at the bottom for META.yml
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
			 valgrind.log
			 )
		      },
    );
$ExtUtils::MakeMaker::VERSION > 6.30 and $wm{LICENSE} = "perl";

my $rv = WriteMakefile (%wm);

1;

package MY;

sub postamble
{
    my $valgrind = join " ", qw(
	PERL_DESTRUCT_LEVEL=2 PERL_DL_NONLAZY=1
	    valgrind
		--suppressions=sandbox/perl.supp
		--leak-check=yes
		--leak-resolution=high
		--show-reachable=yes
		--num-callers=50
		--log-fd=3
		$(FULLPERLRUN) "-MExtUtils::Command::MM" "-e"
		    "test_harness($(TEST_VERBOSE), '$(INST_LIB)', '$(INST_ARCHLIB)')"
		    $(TEST_FILES) 3>valgrind.log
		    );

    my $min_vsn = ($] >= 5.010 && -d "xt" && -d "tmp" && ($ENV{AUTOMATED_TESTING} || 0) != 1)
	? join "\n" =>
	    'test ::',
	    '	-@env TEST_FILES="xt/*.t" make -e test_dynamic',
	    ''
	: "";
    join "\n" =>
	'cover test_cover:',
	'	ccache -C',
	'	-@rm -f *.gc??',
	'	cover -test',
	'',
	'leakcheck:',
	"	$valgrind",
	'	-@tail -5 valgrind.log',
	'',
	'leaktest:',
	q{	sandbox/leaktest  $(FULLPERLRUN) "test_harness($(TEST_VERBOSE), '$(INST_LIB)', '$(INST_ARCHLIB)')" $(TEST_FILES)},
	'',
	'leaktrace:',
	q{	sandbox/leaktrace $(FULLPERLRUN) "test_harness($(TEST_VERBOSE), '$(INST_LIB)', '$(INST_ARCHLIB)')" $(TEST_FILES)},
	'',
	'checkmeta:',
	'	perl sandbox/genPPPort_h.pl',
	'	perl sandbox/genMETA.pl -c',
	'',
	'fixmeta:	distmeta',
	'	perl sandbox/genMETA.pl',
	'',
	'tgzdist:	checkmeta fixmeta $(DISTVNAME).tar.gz distcheck',
	'	-@mv -f $(DISTVNAME).tar.gz $(DISTVNAME).tgz',
	'	-@cpants_lint.pl $(DISTVNAME).tgz',
	'	-@rm -f Debian_CPANTS.txt',
	'',
	'test_speed: pure_all',
	'	PERL_DL_NONLAZY=1 $(FULLPERLRUN) -I"$(INST_LIB)" -I"$(INST_ARCHLIB)" examples/speed.pl',
	'',
	$min_vsn;
    } # postamble
