#!/usr/bin/perl

# Copyright PROCURA B.V. (c) 2006-2013 H.Merijn Brand

require 5.006001; # <- also see postamble at the bottom for META.yml
use strict;

use ExtUtils::MakeMaker;

my %wm = (
    NAME         => "Text::CSV_XS",
    DISTNAME     => "Text-CSV_XS",
    ABSTRACT     => "Comma-Separated Values manipulation routines",
    AUTHOR       => "H.Merijn Brand <h.m.brand\@xs4all.nl>",
    VERSION_FROM => "CSV_XS.pm",
    PREREQ_PM	 => { "DynaLoader"	=> 0,
		      "Config"		=> 0,
		      "IO::Handle"	=> 0,
		      "Test::More"	=> 0,
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

    macro        => { GCC_WALL => (join " " => qw(
			-Wall -Wextra -Wbad-function-cast -Wcomment -Wcomments
			-Wformat -Wdisabled-optimization -Wmissing-prototypes
			-Werror-implicit-function-declaration -Wmissing-noreturn
			-Wmissing-format-attribute -Wno-cast-qual -Wunused-value
			-Wno-sign-compare -Wpointer-arith -Wreturn-type -Wshadow
			-Wswitch-default -Wuninitialized -Wunreachable-code
			-Wundef
			)),
		      TARFLAGS   => "--format=ustar -c -v -f",
		     "#OPTIMIZE" => "-O2 \$(GCC_WALL)",
		    },
    );
$ExtUtils::MakeMaker::VERSION > 6.30 and $wm{LICENSE} = "perl";

my $rv = WriteMakefile (%wm);

1;

package MY;

sub postamble
{
    my $make_sep = $^O eq "VMS" ? "," : "";
    my $valgrind = join " ", qw(
	PERL_DESTRUCT_LEVEL=2 PERL_DL_NONLAZY=1
	    valgrind
		--suppressions=sandbox/perl.supp
		--leak-check=yes
		--leak-resolution=high
		--show-reachable=yes
		--num-callers=50
		--log-fd=3
		$(FULLPERLRUN)
		    "-MPerl::Destruct::Level=level,2"
		    "-MExtUtils::Command::MM" "-e"
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
	'cover $make_sep test_cover:',
	'	ccache -C',
	'	-@rm -f *.gc??',
	'	cover -test',
	'',
	'leakrun:',
	'	env HARNESS_PERL=sandbox/leakperl make test',
	'	-@tail -14 valgrind.log',
	'',
	'leakcheck:',
	"	$valgrind",
	'	-@tail -14 valgrind.log',
	'',
	'leaktest:',
	q{	sandbox/leaktest  $(FULLPERLRUN) "test_harness($(TEST_VERBOSE), '$(INST_LIB)', '$(INST_ARCHLIB)')" $(TEST_FILES)},
	'',
	'leaktrace:',
	q{	sandbox/leaktrace $(FULLPERLRUN) "test_harness($(TEST_VERBOSE), '$(INST_LIB)', '$(INST_ARCHLIB)')" $(TEST_FILES)},
	'',
	'spellcheck:',
	'	pod-spell-check --aspell --ispell',
	'',
	'checkmeta:	spellcheck',
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
