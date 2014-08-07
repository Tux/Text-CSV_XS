/*  Copyright (c) 2007-2014 H.Merijn Brand.  All rights reserved.
 *  Copyright (c) 1998-2001 Jochen Wiedmann. All rights reserved.
 *  This program is free software; you can redistribute it and/or
 *  modify it under the same terms as Perl itself.
 */
#define PERL_NO_GET_CONTEXT
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#define DPPP_PL_parser_NO_DUMMY
#define NEED_my_snprintf
#define NEED_pv_escape
#define	NEED_pv_pretty
#ifndef PERLIO_F_UTF8
#  define PERLIO_F_UTF8	0x00008000
#  endif
#ifndef MAXINT
#  define MAXINT ((int)(~(unsigned)0 >> 1))
#  endif
#include "ppport.h"
#define is_utf8_sv(s) is_utf8_string ((U8 *)SvPV_nolen (s), SvCUR (s))

#define MAINT_DEBUG	0

#define BUFFER_SIZE	1024

#define CSV_XS_TYPE_PV	0
#define CSV_XS_TYPE_IV	1
#define CSV_XS_TYPE_NV	2

#define MAX_SEP_LEN	16
#define MAX_EOL_LEN	16
#define MAX_QUO_LEN	16

#define CSV_FLAGS_QUO		0x0001
#define CSV_FLAGS_BIN		0x0002
#define CSV_FLAGS_EIF		0x0004
#define CSV_FLAGS_MIS		0x0010

#define HOOK_ERROR		0x0001
#define HOOK_AFTER_PARSE	0x0002
#define HOOK_BEFORE_PRINT	0x0004

#define CH_TAB		'\011'
#define CH_NL		'\012'
#define CH_CR		'\015'
#define CH_SPACE	'\040'
#define CH_DEL		'\177'
#define CH_EOLX		1215
#define CH_SEPX		8888
#define CH_SEP		*csv->sep
#define CH_QUOTEX	8889
#define CH_QUOTE	*csv->quo

#define useIO_EOF	0x10

#define unless(expr)	if (!(expr))

#define _is_arrayref(f) ( f && \
     (SvROK (f) || (SvRMAGICAL (f) && (mg_get (f), 1) && SvROK (f))) && \
      SvOK (f) && SvTYPE (SvRV (f)) == SVt_PVAV )
#define _is_hashref(f) ( f && \
     (SvROK (f) || (SvRMAGICAL (f) && (mg_get (f), 1) && SvROK (f))) && \
      SvOK (f) && SvTYPE (SvRV (f)) == SVt_PVHV )
#define _is_coderef(f) ( f && \
     (SvROK (f) || (SvRMAGICAL (f) && (mg_get (f), 1) && SvROK (f))) && \
      SvOK (f) && SvTYPE (SvRV (f)) == SVt_PVCV )

#define CSV_XS_SELF					\
    if (!self || !SvOK (self) || !SvROK (self) ||	\
	 SvTYPE (SvRV (self)) != SVt_PVHV)		\
	croak ("self is not a hash ref");		\
    hv = (HV *)SvRV (self)

/* Keep in sync with .pm! */
#define CACHE_ID_quote_char		0
#define CACHE_ID_escape_char		1
#define CACHE_ID_sep_char		2
#define CACHE_ID_binary			3
#define CACHE_ID_keep_meta_info		4
#define CACHE_ID_always_quote		5
#define CACHE_ID_allow_loose_quotes	6
#define CACHE_ID_allow_loose_escapes	7
#define CACHE_ID_allow_unquoted_escape	8
#define CACHE_ID_allow_whitespace	9
#define CACHE_ID_blank_is_undef		10
#define CACHE_ID_sep			38
#define CACHE_ID_sep_len		37
#define CACHE_ID_eol			11
#define CACHE_ID_eol_len		12
#define CACHE_ID_eol_is_cr		13
#define CACHE_ID_quo			15
#define CACHE_ID_quo_len		16
#define CACHE_ID_verbatim		22
#define CACHE_ID_empty_is_undef		23
#define CACHE_ID_auto_diag		24
#define CACHE_ID_quote_space		25
#define CACHE_ID__is_bound		26
#define CACHE_ID__has_ahead		30
#define CACHE_ID_quote_null		31
#define CACHE_ID_quote_binary		32
#define CACHE_ID_diag_verbose		33
#define CACHE_ID_has_error_input	34
#define CACHE_ID_decode_utf8		35
#define CACHE_ID__has_hooks		36

#define	byte	unsigned char
typedef struct {
    byte	quote_char;
    byte	escape_char;
    byte	sep_char;	/* not used anymore */
    byte	binary;

    byte	keep_meta_info;
    byte	always_quote;
    byte	useIO;		/* Also used to indicate EOF */
    byte	eol_is_cr;

    byte	allow_loose_quotes;
    byte	allow_loose_escapes;
    byte	allow_unquoted_escape;
    byte	allow_whitespace;

    byte	blank_is_undef;
    byte	empty_is_undef;
    byte	verbatim;
    byte	auto_diag;

    byte	quote_space;
    byte	quote_null;
    byte	quote_binary;
    byte	first_safe_char;

    byte	diag_verbose;
    byte	has_error_input;
    byte	decode_utf8;
    byte	has_hooks;

    long	is_bound;

    byte *	cache;

    SV *	pself;
    HV *	self;
    SV *	bound;

    char *	types;

    byte	eol_len;
    byte	sep_len;
    byte	quo_len;
    byte	types_len;

    char *	bptr;
    SV *	tmp;
    int		utf8;
    byte	has_ahead;
    byte	eolx;
    int		eol_pos;
    STRLEN	size;
    STRLEN	used;
    byte	eol[MAX_EOL_LEN];
    byte	sep[MAX_SEP_LEN];
    byte	quo[MAX_QUO_LEN];
    char	buffer[BUFFER_SIZE];
    } csv_t;

#define bool_opt_def(o,d) \
    (((svp = hv_fetchs (self, o, FALSE)) && *svp) ? SvTRUE (*svp) : d)
#define bool_opt(o) bool_opt_def (o, 0)
#define num_opt_def(o,d) \
    (((svp = hv_fetchs (self, o, FALSE)) && *svp) ? SvIV   (*svp) : d)
#define num_opt(o) bool_opt_def (o, 0)

typedef struct {
    int   xs_errno;
    char *xs_errstr;
    } xs_error_t;
xs_error_t xs_errors[] =  {

    /* Generic errors */
    { 1000, "INI - constructor failed"						},
    { 1001, "INI - sep_char is equal to quote_char or escape_char"		},
    { 1002, "INI - allow_whitespace with escape_char or quote_char SP or TAB"	},
    { 1003, "INI - \r or \n in main attr not allowed"				},
    { 1004, "INI - callbacks should be undef or a hashref"			},

    /* Parse errors */
    { 2010, "ECR - QUO char inside quotes followed by CR not part of EOL"	},
    { 2011, "ECR - Characters after end of quoted field"			},
    { 2012, "EOF - End of data in parsing input stream"				},
    { 2013, "ESP - Specification error for fragments RFC7111"			},

    /*  EIQ - Error Inside Quotes */
    { 2021, "EIQ - NL char inside quotes, binary off"				},
    { 2022, "EIQ - CR char inside quotes, binary off"				},
    { 2023, "EIQ - QUO character not allowed"					},
    { 2024, "EIQ - EOF cannot be escaped, not even inside quotes"		},
    { 2025, "EIQ - Loose unescaped escape"					},
    { 2026, "EIQ - Binary character inside quoted field, binary off"		},
    { 2027, "EIQ - Quoted field not terminated"					},

    /* EIF - Error Inside Field */
    { 2030, "EIF - NL char inside unquoted verbatim, binary off"		},
    { 2031, "EIF - CR char is first char of field, not part of EOL"		},
    { 2032, "EIF - CR char inside unquoted, not part of EOL"			},
    { 2034, "EIF - Loose unescaped quote"					},
    { 2035, "EIF - Escaped EOF in unquoted field"				},
    { 2036, "EIF - ESC error"							},
    { 2037, "EIF - Binary character in unquoted field, binary off"		},

    /* Combine errors */
    { 2110, "ECB - Binary character in Combine, binary off"			},

    /* IO errors */
    { 2200, "EIO - print to IO failed. See errno"				},

    /* Hash-Ref errors */
    { 3001, "EHR - Unsupported syntax for column_names ()"			},
    { 3002, "EHR - getline_hr () called before column_names ()"			},
    { 3003, "EHR - bind_columns () and column_names () fields count mismatch"	},
    { 3004, "EHR - bind_columns () only accepts refs to scalars"		},
    { 3006, "EHR - bind_columns () did not pass enough refs for parsed fields"	},
    { 3007, "EHR - bind_columns needs refs to writable scalars"			},
    { 3008, "EHR - unexpected error in bound fields"				},
    { 3009, "EHR - print_hr () called before column_names ()"			},
    { 3010, "EHR - print_hr () called with invalid arguments"			},

    {    0, "" },
    };

static int  io_handle_loaded = 0;
static SV  *m_getline, *m_print, *m_read;
static int  last_error = 0;

#define __is_SEPX(c) (c == CH_SEP && (csv->sep_len == 0 || (\
    csv->size - csv->used >= csv->sep_len - 1				&&\
    !memcmp (csv->bptr + csv->used, csv->sep + 1, csv->sep_len - 1)	&&\
    (csv->used += csv->sep_len - 1)					&&\
    (c = CH_SEPX))))
#if MAINT_DEBUG > 1
static byte _is_SEPX (unsigned int c, csv_t *csv, int line)
{
    unsigned int b = __is_SEPX (c);
    (void)fprintf (stderr, "# %4d - is_SEPX:\t%d (%d)\n", line, b, csv->sep_len);
    if (csv->sep_len)
	(void)fprintf (stderr,
	    "# len: %d, siz: %d, usd: %d, c: %02x, *sep: %02x\n",
	    csv->sep_len, csv->size, csv->used, c, CH_SEP);
    return b;
    } /* _is_SEPX */
#define is_SEP(c)  _is_SEPX (c, csv, __LINE__)
#else
#define is_SEP(c) __is_SEPX (c)
#endif

#define __is_QUOTEX(c) (CH_QUOTE && c == CH_QUOTE && (csv->quo_len == 0 || (\
    csv->size - csv->used >= csv->quo_len - 1				&&\
    !memcmp (csv->bptr + csv->used, csv->quo + 1, csv->quo_len - 1)	&&\
    (csv->used += csv->quo_len - 1)					&&\
    (c = CH_QUOTEX))))
#if MAINT_DEBUG > 1
static byte _is_QUOTEX (unsigned int c, csv_t *csv, int line)
{
    unsigned int b = __is_QUOTEX (c);
    (void)fprintf (stderr, "# %4d - is_QUOTEX:\t%d (%d)\n", line, b, csv->quo_len);

    if (csv->quo_len)
	(void)fprintf (stderr,
	    "# len: %d, siz: %d, usd: %d, c: %02x, *quo: %02x\n",
	    csv->quo_len, csv->size, csv->used, c, CH_QUOTE);
    return b;
    } /* _is_QUOTEX */
#define is_QUOTE(c)  _is_QUOTEX (c, csv, __LINE__)
#else
#define is_QUOTE(c) __is_QUOTEX (c)
#endif

#define require_IO_Handle \
    unless (io_handle_loaded) {\
	ENTER;\
	Perl_load_module (aTHX_ PERL_LOADMOD_NOIMPORT,\
	    newSVpvs ("IO::Handle"), NULL, NULL, NULL);\
	LEAVE;\
	io_handle_loaded = 1;\
	}

#define is_whitespace(ch) \
    ( (ch) != CH_SEP           && \
      (ch) != CH_QUOTE         && \
      (ch) != csv->escape_char && \
    ( (ch) == CH_SPACE || \
      (ch) == CH_TAB \
      ) \
    )

#define SvDiag(xse)		cx_SvDiag (aTHX_ xse)
static SV *cx_SvDiag (pTHX_ int xse)
{
    int   i = 0;
    SV   *err;

    while (xs_errors[i].xs_errno && xs_errors[i].xs_errno != xse) i++;
    if ((err = newSVpv (xs_errors[i].xs_errstr, 0))) {
	(void)SvUPGRADE (err, SVt_PVIV);
	SvIV_set  (err, xse);
	SvIOK_on  (err);
	}
    return (err);
    } /* SvDiag */

#define SetDiag(csv,xse)	cx_SetDiag (aTHX_ csv, xse)
static SV *cx_SetDiag (pTHX_ csv_t *csv, int xse)
{
    dSP;
    SV *err = SvDiag (xse);

    last_error = xse;
	(void)hv_store (csv->self, "_ERROR_DIAG",  11, err,          0);
    if (xse == 0) {
	(void)hv_store (csv->self, "_ERROR_POS",   10, newSViv  (0), 0);
	(void)hv_store (csv->self, "_ERROR_INPUT", 12, &PL_sv_undef, 0);
	csv->has_error_input = 0;
	}
    if (xse == 2012) /* EOF */
	(void)hv_store (csv->self, "_EOF",          4, &PL_sv_yes,   0);
    if (csv->pself && csv->auto_diag) {
	ENTER;
	SAVETMPS;
	PUSHMARK (SP);
	XPUSHs (csv->pself);
	PUTBACK;
	call_pv ("Text::CSV_XS::error_diag", G_VOID | G_DISCARD);
	FREETMPS;
	LEAVE;
	}
    return (err);
    } /* SetDiag */

#define xs_cache_set(hv,idx,val)	cx_xs_cache_set (aTHX_ hv, idx, val)
static void cx_xs_cache_set (pTHX_ HV *hv, int idx, SV *val)
{
    SV    **svp;
    byte   *cache;

    csv_t   csvs;
    csv_t  *csv = &csvs;

    IV      iv;
    char   *cp  = "\0";
    STRLEN  len = 0;

    unless ((svp = hv_fetchs (hv, "_CACHE", FALSE)) && *svp)
	return;

    cache = (byte *)SvPV_nolen (*svp);
    memcpy (csv, cache, sizeof (csv_t));

    if (SvPOK (val))
	cp = SvPV (val, len);
    if (SvIOK (val))
	iv = SvIV (val);
    else if (SvNOK (val))	/* Needed for 5.6.x but safe for 5.8.x+ */
	iv = (IV)SvNV (val);
    else
	iv = *cp;

    switch (idx) {

	/* single char/byte */
	case CACHE_ID_sep_char:
	    CH_SEP			= *cp;
	    csv->sep_len		= 0;
	    break;

	case CACHE_ID_quote_char:
	    CH_QUOTE			= *cp;
	    csv->quo_len		= 0;
	    break;

	case CACHE_ID_escape_char:           csv->escape_char           = *cp; break;

	/* boolean/numeric */
	case CACHE_ID_binary:                csv->binary                = iv; break;
	case CACHE_ID_keep_meta_info:        csv->keep_meta_info        = iv; break;
	case CACHE_ID_always_quote:          csv->always_quote          = iv; break;
	case CACHE_ID_quote_space:           csv->quote_space           = iv; break;
	case CACHE_ID_quote_null:            csv->quote_null            = iv; break;
	case CACHE_ID_quote_binary:          csv->quote_binary          = iv; break;
	case CACHE_ID_decode_utf8:           csv->decode_utf8           = iv; break;
	case CACHE_ID_allow_loose_escapes:   csv->allow_loose_escapes   = iv; break;
	case CACHE_ID_allow_loose_quotes:    csv->allow_loose_quotes    = iv; break;
	case CACHE_ID_allow_unquoted_escape: csv->allow_unquoted_escape = iv; break;
	case CACHE_ID_allow_whitespace:      csv->allow_whitespace      = iv; break;
	case CACHE_ID_blank_is_undef:        csv->blank_is_undef        = iv; break;
	case CACHE_ID_empty_is_undef:        csv->empty_is_undef        = iv; break;
	case CACHE_ID_verbatim:              csv->verbatim              = iv; break;
	case CACHE_ID_auto_diag:             csv->auto_diag             = iv; break;
	case CACHE_ID_diag_verbose:          csv->diag_verbose          = iv; break;
	case CACHE_ID__has_hooks:            csv->has_hooks             = iv; break;
	case CACHE_ID_has_error_input:       csv->has_error_input       = iv; break;

	/* a 4-byte IV */
	case CACHE_ID__is_bound:             csv->is_bound              = iv; break;

	/* string */
	case CACHE_ID_sep:
	    if (len < MAX_SEP_LEN) {
		memcpy (csv->sep, cp, len);
		csv->sep_len = len == 1 ? 0 : len;
		}
	    break;

	case CACHE_ID_quo:
	    if (len < MAX_QUO_LEN) {
		memcpy (csv->quo, cp, len);
		csv->quo_len = len == 1 ? 0 : len;
		}
	    break;

	case CACHE_ID_eol:
	    if (len < MAX_EOL_LEN) {
		memcpy (csv->eol, cp, len);
		csv->eol_len   = len;
		csv->eol_is_cr = len == 1 && *cp == CH_CR ? 1 : 0;
		}
	    break;

	default:
	    warn ("Unknown cache index %d ignored\n", idx);
	}

    csv->cache = cache;
    memcpy (cache, csv, sizeof (csv_t));
    } /* cache_set */

#define _pretty_str(csv,xse)	cx_pretty_str (aTHX_ csv, xse)
static char *cx_pretty_str (pTHX_ byte *s, STRLEN l)
{
    SV *dsv = sv_2mortal (newSVpvs (""));
    return (pv_pretty (dsv, (char *)s, l, 0, NULL, NULL,
	    (PERL_PV_PRETTY_DUMP | PERL_PV_ESCAPE_UNI_DETECT)));
    } /* _pretty_str */

#define _cache_show_byte(trim,c) \
    warn ("  %-21s %02x:%3d\n", trim, c, c)
#define _cache_show_char(trim,c) \
    warn ("  %-21s %02x:%s\n",  trim, c, _pretty_str (&c, 1))
#define _cache_show_str(trim,l,str) \
    warn ("  %-21s %02d:%s\n",  trim, l, _pretty_str (str, l))

#define xs_cache_diag(hv)	cx_xs_cache_diag (aTHX_ hv)
static void cx_xs_cache_diag (pTHX_ HV *hv)
{
    SV   **svp;
    byte  *cache;
    csv_t  csvs;
    csv_t *csv = &csvs;

    unless ((svp = hv_fetchs (hv, "_CACHE", FALSE)) && *svp) {
	warn ("CACHE: invalid\n");
	return;
	}

    cache = (byte *)SvPV_nolen (*svp);
    memcpy (csv, cache, sizeof (csv_t));
    warn ("CACHE:\n");
    _cache_show_char ("quote_char",		CH_QUOTE);
    _cache_show_char ("escape_char",		csv->escape_char);
    _cache_show_char ("sep_char",		CH_SEP);
    _cache_show_byte ("binary",			csv->binary);
    _cache_show_byte ("decode_utf8",		csv->decode_utf8);

    _cache_show_byte ("allow_loose_escapes",	csv->allow_loose_escapes);
    _cache_show_byte ("allow_loose_quotes",	csv->allow_loose_quotes);
    _cache_show_byte ("allow_unquoted_escape",	csv->allow_unquoted_escape);
    _cache_show_byte ("allow_whitespace",	csv->allow_whitespace);
    _cache_show_byte ("always_quote",		csv->always_quote);
    _cache_show_byte ("quote_space",		csv->quote_space);
    _cache_show_byte ("quote_null",		csv->quote_null);
    _cache_show_byte ("quote_binary",		csv->quote_binary);
    _cache_show_byte ("auto_diag",		csv->auto_diag);
    _cache_show_byte ("diag_verbose",		csv->diag_verbose);
    _cache_show_byte ("has_error_input",	csv->has_error_input);
    _cache_show_byte ("blank_is_undef",		csv->blank_is_undef);
    _cache_show_byte ("empty_is_undef",		csv->empty_is_undef);
    _cache_show_byte ("has_ahead",		csv->has_ahead);
    _cache_show_byte ("keep_meta_info",		csv->keep_meta_info);
    _cache_show_byte ("verbatim",		csv->verbatim);

    _cache_show_byte ("has_hooks",		csv->has_hooks);
    _cache_show_byte ("eol_is_cr",		csv->eol_is_cr);
    _cache_show_byte ("eol_len",		csv->eol_len);
    _cache_show_str  ("eol", csv->eol_len,	csv->eol);
    _cache_show_byte ("sep_len",		csv->sep_len);
    if (csv->sep_len > 1)
	_cache_show_str ("sep", csv->sep_len,	csv->sep);
    _cache_show_byte ("quo_len",		csv->quo_len);
    if (csv->quo_len > 1)
	_cache_show_str ("quote", csv->quo_len,	csv->quo);
    } /* xs_cache_diag */

#define set_eol_is_cr(csv)	cx_set_eol_is_cr (aTHX_ csv)
static void cx_set_eol_is_cr (pTHX_ csv_t *csv)
{
    csv->eol[0]    = CH_CR;
    csv->eol_is_cr = 1;
    csv->eol_len   = 1;
    memcpy (csv->cache, csv, sizeof (csv_t));

    (void)hv_store (csv->self, "eol",  3, newSVpvn ((char *)csv->eol, 1), 0);
    } /* set_eol_is_cr */

#define SetupCsv(csv,self,pself)	cx_SetupCsv (aTHX_ csv, self, pself)
static void cx_SetupCsv (pTHX_ csv_t *csv, HV *self, SV *pself)
{
    SV	       **svp;
    STRLEN	 len;
    char	*ptr;

    last_error = 0;

    if ((svp = hv_fetchs (self, "_CACHE", FALSE)) && *svp) {
	byte *cache = (byte *)SvPVX (*svp);
	memcpy (csv, cache, sizeof (csv_t));
	}
    else {
	SV *sv_cache;

	memset (csv, 0, sizeof (csv_t)); /* Reset everything */

	csv->self  = self;
	csv->pself = pself;

	CH_SEP = ',';
	if ((svp = hv_fetchs (self, "sep_char",       FALSE)) && *svp && SvOK (*svp))
	    CH_SEP = *SvPV (*svp, len);
	if ((svp = hv_fetchs (self, "sep",            FALSE)) && *svp && SvOK (*svp)) {
	    ptr = SvPV (*svp, len);
	    if (len < MAX_SEP_LEN) {
		memcpy (csv->sep, ptr, len);
		if (len > 1)
		    csv->sep_len = len;
		}
	    }

	CH_QUOTE = '"';
	if ((svp = hv_fetchs (self, "quote_char",     FALSE)) && *svp) {
	    if (SvOK (*svp)) {
		ptr = SvPV (*svp, len);
		CH_QUOTE = len ? *ptr : (char)0;
		}
	    else
		CH_QUOTE = (char)0;
	    }
	if ((svp = hv_fetchs (self, "quote",          FALSE)) && *svp && SvOK (*svp)) {
	    ptr = SvPV (*svp, len);
	    if (len < MAX_QUO_LEN) {
		memcpy (csv->quo, ptr, len);
		if (len > 1)
		    csv->quo_len = len;
		}
	    }

	csv->escape_char = '"';
	if ((svp = hv_fetchs (self, "escape_char",    FALSE)) && *svp) {
	    if (SvOK (*svp)) {
		ptr = SvPV (*svp, len);
		csv->escape_char = len ? *ptr : (char)0;
		}
	    else
		csv->escape_char = (char)0;
	    }

	if ((svp = hv_fetchs (self, "eol",            FALSE)) && *svp && SvOK (*svp)) {
	    char *eol = SvPV (*svp, len);
	    if (len < MAX_EOL_LEN) {
		memcpy (csv->eol, eol, len);
		csv->eol_len = len;
		if (len == 1 && *csv->eol == CH_CR)
		    csv->eol_is_cr = 1;
		}
	    }

	if ((svp = hv_fetchs (self, "_types",         FALSE)) && *svp && SvOK (*svp)) {
	    csv->types = SvPV (*svp, len);
	    csv->types_len = len;
	    }

	if ((svp = hv_fetchs (self, "_is_bound",      FALSE)) && *svp && SvOK (*svp))
	    csv->is_bound = SvIV(*svp);
	if ((svp = hv_fetchs (self, "callbacks",      FALSE)) && _is_hashref (*svp)) {
	    HV *cb = (HV *)SvRV (*svp);
	    if ((svp = hv_fetchs (cb, "after_parse",  FALSE)) && _is_coderef (*svp))
		csv->has_hooks |= HOOK_AFTER_PARSE;
	    if ((svp = hv_fetchs (cb, "before_print", FALSE)) && _is_coderef (*svp))
		csv->has_hooks |= HOOK_BEFORE_PRINT;
	    }

	csv->binary			= bool_opt ("binary");
	csv->decode_utf8		= bool_opt ("decode_utf8");
	csv->keep_meta_info		= bool_opt ("keep_meta_info");
	csv->always_quote		= bool_opt ("always_quote");
	csv->quote_space		= bool_opt_def ("quote_space",  1);
	csv->quote_null			= bool_opt_def ("quote_null",   1);
	csv->quote_binary		= bool_opt_def ("quote_binary", 1);
	csv->allow_loose_quotes		= bool_opt ("allow_loose_quotes");
	csv->allow_loose_escapes	= bool_opt ("allow_loose_escapes");
	csv->allow_unquoted_escape	= bool_opt ("allow_unquoted_escape");
	csv->allow_whitespace		= bool_opt ("allow_whitespace");
	csv->blank_is_undef		= bool_opt ("blank_is_undef");
	csv->empty_is_undef		= bool_opt ("empty_is_undef");
	csv->verbatim			= bool_opt ("verbatim");

	csv->auto_diag			= num_opt ("auto_diag");
	csv->diag_verbose		= num_opt ("diag_verbose");

	sv_cache = newSVpvn ((char *)csv, sizeof (csv_t));
	csv->cache = (byte *)SvPVX (sv_cache);
	SvREADONLY_on (sv_cache);

	memcpy (csv->cache, csv, sizeof (csv_t));

	(void)hv_store (self, "_CACHE", 6, sv_cache, 0);
	}

    csv->utf8 = 0;
    csv->size = 0;
    csv->used = 0;

    csv->first_safe_char = csv->quote_space ? 0x21 : 0x20;

    if (csv->is_bound) {
	if ((svp = hv_fetchs (self, "_BOUND_COLUMNS", FALSE)) && _is_arrayref (*svp))
	    csv->bound = *svp;
	else
	    csv->is_bound = 0;
	}

    csv->eol_pos = -1;
    csv->eolx = csv->eol_len 
	? csv->verbatim || csv->eol_len >= 2
	    ? 1
	    : csv->eol[0] == CH_CR || csv->eol[0] == CH_NL
		? 0
		: 1
	: 0;
    if (csv->sep_len && is_utf8_string ((U8 *)(csv->sep), csv->sep_len))
	csv->utf8 = 1;
    if (csv->quo_len && is_utf8_string ((U8 *)(csv->quo), csv->quo_len))
	csv->utf8 = 1;
    } /* SetupCsv */

#define Print(csv,dst)		cx_Print (aTHX_ csv, dst)
static int cx_Print (pTHX_ csv_t *csv, SV *dst)
{
    int result;
    int keep = 0;

    if (csv->useIO) {
	SV *tmp = newSVpv (csv->buffer, csv->used);
	dSP;
	require_IO_Handle;
	PUSHMARK (sp);
	EXTEND (sp, 2);
	PUSHs ((dst));
	if (csv->utf8) {
	    STRLEN	 len;
	    char	*ptr;
	    int		 j;

	    ptr = SvPV (tmp, len);
	    while (len > 0 && !is_utf8_sv (tmp) && keep < 16) {
		ptr[--len] = (char)0;
		SvCUR_set (tmp, len);
		keep++;
		}
	    for (j = 0; j < keep; j++)
		csv->buffer[j] = csv->buffer[csv->used - keep + j];
	    SvUTF8_on (tmp);
	    }
	PUSHs (tmp);
	PUTBACK;
	result = call_sv (m_print, G_SCALAR | G_METHOD);
	SPAGAIN;
	if (result) {
	    result = POPi;
	    unless (result)
		(void)SetDiag (csv, 2200);
	    }
	PUTBACK;
	SvREFCNT_dec (tmp);
	}
    else {
	sv_catpvn (SvRV (dst), csv->buffer, csv->used);
	result = TRUE;
	}
    if (csv->utf8 && !csv->useIO && csv->decode_utf8
		  && SvROK (dst) && is_utf8_sv (SvRV (dst)))
	SvUTF8_on (SvRV (dst));
    csv->used = keep;
    return result;
    } /* Print */

#define CSV_PUT(csv,dst,c) {				\
    if ((csv)->used == sizeof ((csv)->buffer) - 1) {	\
	unless (Print ((csv), (dst)))			\
	    return FALSE;				\
	}						\
    (csv)->buffer[(csv)->used++] = (c);			\
    }

#define bound_field(csv,i,keep)	cx_bound_field (aTHX_ csv, i, keep)
static SV *cx_bound_field (pTHX_ csv_t *csv, int i, int keep)
{
    SV *sv = csv->bound;
    AV *av;

    /* fprintf (stderr, "# New bind %d/%d\n", i, csv->is_bound);\ */
    if (i >= csv->is_bound) {
	(void)SetDiag (csv, 3006);
	return (NULL);
	}

    if (sv && SvROK (sv)) {
	av = (AV *)(SvRV (sv));
	/* fprintf (stderr, "# Bind %d/%d/%d\n", i, csv->is_bound, av_len (av)); */
	sv = *av_fetch (av, i, FALSE);
	if (sv && SvROK (sv)) {
	    sv = SvRV (sv);
	    if (keep)
		return (sv);

	    unless (SvREADONLY (sv)) {
		sv_setpvn (sv, "", 0);
		return (sv);
		}
	    }
	}
    (void)SetDiag (csv, 3008);
    return (NULL);
    } /* bound_field */

/* Should be extended for EBCDIC ? */
#define is_csv_binary(ch) ((ch < CH_SPACE || ch >= CH_DEL) && ch != CH_TAB)

#define Combine(csv,dst,fields)	cx_Combine (aTHX_ csv, dst, fields)
static int cx_Combine (pTHX_ csv_t *csv, SV *dst, AV *fields)
{
    int		i, n, bound = 0;

    n = av_len (fields);
    if (n < 0 && csv->is_bound) {
	n = csv->is_bound - 1;
	bound = 1;
	}

    for (i = 0; i <= n; i++) {
	SV    *sv;

	if (i > 0) {
	    CSV_PUT (csv, dst, CH_SEP);
	    if (csv->sep_len) {
		int x;
		for (x = 1; x < (int)csv->sep_len; x++)
		    CSV_PUT (csv, dst, csv->sep[x]);
		}
	    }

	if (bound)
	    sv = bound_field (csv, i, 1);
	else {
	    SV **svp = av_fetch (fields, i, 0);
	    sv = svp && *svp ? *svp : NULL;
	    }

	if (sv) {
	    STRLEN	 len;
	    char	*ptr;
	    int		 quoteMe = csv->always_quote;

	    unless ((SvOK (sv) || (
		    (SvGMAGICAL (sv) && (mg_get (sv), 1) && SvOK (sv)))
		    )) continue;
	    ptr = SvPV (sv, len);
	    if (len && SvUTF8 (sv))  {
		csv->utf8   = 1;
		csv->binary = 1;
		}
	    /* Do we need quoting? We do quote, if the user requested
	     * (always_quote), if binary or blank characters are found
	     * and if the string contains quote or escape characters.
	     */
	    if (!quoteMe &&
	       ( quoteMe = (!SvIOK (sv) && !SvNOK (sv) && CH_QUOTE))) {
		char	*ptr2;
		STRLEN	 l;

		for (ptr2 = ptr, l = len; l; ++ptr2, --l) {
		    byte c = *ptr2;

		    if (c < csv->first_safe_char ||
		       (csv->quote_binary && c >= 0x7f && c <= 0xa0) ||
		       (CH_QUOTE          && c == CH_QUOTE)          ||
		       (CH_SEP            && c == CH_SEP)            ||
		       (csv->escape_char  && c == csv->escape_char)) {
			/* Binary character */
			break;
			}
		    }
		quoteMe = (l > 0);
		}
	    if (quoteMe) {
		CSV_PUT (csv, dst, CH_QUOTE);
		if (csv->quo_len) {
		    int x;
		    for (x = 1; x < (int)csv->quo_len; x++)
			CSV_PUT (csv, dst, csv->quo[x]);
		    }
		}
	    while (len-- > 0) {
		char	c = *ptr++;
		int	e = 0;

		if (!csv->binary && is_csv_binary (c)) {
		    SvREFCNT_inc (sv);
		    csv->has_error_input = 1;
		    unless (hv_store (csv->self, "_ERROR_INPUT", 12, sv, 0))
/* uncovered */		SvREFCNT_dec (sv);
		    (void)SetDiag (csv, 2110);
		    return FALSE;
		    }
		if (CH_QUOTE && (byte)c == CH_QUOTE && (csv->quo_len == 0 ||
			 memcmp (ptr, csv->quo +1, csv->quo_len - 1) == 0))
		    e = 1;
		else
		if (c == csv->escape_char && csv->escape_char)
		    e = 1;
		else
		if (c == (char)0          && csv->quote_null) {
		    e = 1;
		    c = '0';
		    }
		if (e && csv->escape_char)
		    CSV_PUT (csv, dst, csv->escape_char);
		CSV_PUT (csv, dst, c);
		}
	    if (quoteMe) {
		CSV_PUT (csv, dst, CH_QUOTE);
		if (csv->quo_len) {
		    int x;
		    for (x = 1; x < (int)csv->quo_len; x++)
			CSV_PUT (csv, dst, csv->quo[x]);
		    }
		}
	    }
	}
    if (csv->eol_len) {
	STRLEN	len = csv->eol_len;
	byte   *ptr = csv->eol;

	while (len--)
	    CSV_PUT (csv, dst, *ptr++);
	}
    if (csv->used)
	return Print (csv, dst);
    return TRUE;
    } /* Combine */

#define ParseError(csv,xse,pos)	cx_ParseError (aTHX_ csv, xse, pos)
static void cx_ParseError (pTHX_ csv_t *csv, int xse, int pos)
{
    (void)hv_store (csv->self, "_ERROR_POS", 10, newSViv (pos), 0);
    if (csv->tmp) {
	csv->has_error_input = 1;
	if (hv_store (csv->self, "_ERROR_INPUT", 12, csv->tmp, 0))
	    SvREFCNT_inc (csv->tmp);
	}
    (void)SetDiag (csv, xse);
    } /* ParseError */

#define CsvGet(csv,src)		cx_CsvGet (aTHX_ csv, src)
static int cx_CsvGet (pTHX_ csv_t *csv, SV *src)
{
    unless (csv->useIO)
	return EOF;

    if (csv->tmp && csv->eol_pos >= 0) {
	csv->eol_pos = -2;
	sv_setpvn (csv->tmp, (char *)csv->eol, csv->eol_len);
	csv->bptr = SvPV (csv->tmp, csv->size);
	csv->used = 0;
	return CH_EOLX;
	}

    {	STRLEN		result;
	dSP;

	require_IO_Handle;

	PUSHMARK (sp);
	EXTEND (sp, 1);
	PUSHs (src);
	PUTBACK;
	result = call_sv (m_getline, G_SCALAR | G_METHOD);
	SPAGAIN;
	csv->eol_pos = -1;
	csv->tmp = result ? POPs : NULL;
	PUTBACK;

#if MAINT_DEBUG > 4
	fprintf (stderr, "getline () returned:\n");
	sv_dump (csv->tmp);
#endif
	}
    if (csv->tmp && SvOK (csv->tmp)) {
	STRLEN tmp_len;
	csv->bptr = SvPV (csv->tmp, tmp_len);
	csv->used = 0;
	csv->size = tmp_len;
	if (csv->eolx && csv->size >= csv->eol_len) {
	    int i, match = 1;
	    for (i = 1; i <= (int)csv->eol_len; i++) {
		unless (csv->bptr[csv->size - i] == csv->eol[csv->eol_len - i]) {
		    match = 0;
		    break;
		    }
		}
	    if (match) {
#if MAINT_DEBUG > 4
		fprintf (stderr, "# EOLX match, size: %d\n", csv->size);
#endif
		csv->size -= csv->eol_len;
		unless (csv->verbatim)
		    csv->eol_pos = csv->size;
		csv->bptr[csv->size] = (char)0;
		SvCUR_set (csv->tmp, csv->size);
		unless (csv->verbatim || csv->size)
		    return CH_EOLX;
		}
	    }
	if (SvUTF8 (csv->tmp)) csv->utf8 = 1;
	if (tmp_len)
	    return ((byte)csv->bptr[csv->used++]);
	}
    csv->useIO |= useIO_EOF;
    return EOF;
    } /* CsvGet */

#define ERROR_INSIDE_QUOTES(diag_code) {	\
    SvREFCNT_dec (sv);				\
    ParseError (csv, diag_code, csv->used - 1);	\
    return FALSE;				\
    }
#define ERROR_INSIDE_FIELD(diag_code) {		\
    SvREFCNT_dec (sv);				\
    ParseError (csv, diag_code, csv->used - 1);	\
    return FALSE;				\
    }

#if MAINT_DEBUG > 4
#define PUT_RPT       fprintf (stderr, "# CSV_PUT  @ %4d: 0x%02x '%c'\n", __LINE__, c, isprint (c) ? c : '?')
#define PUT_SEPX_RPT1 fprintf (stderr, "# PUT SEPX @ %4d\n", __LINE__)
#define PUT_SEPX_RPT2 fprintf (stderr, "# Done putting SEPX\n")
#define PUT_QUOX_RPT1 fprintf (stderr, "# PUT QUOX @ %4d\n", __LINE__)
#define PUT_QUOX_RPT2 fprintf (stderr, "# Done putting QUOX\n")
#define PUT_EOLX_RPT1 fprintf (stderr, "# PUT EOLX @ %4d\n", __LINE__)
#define PUT_EOLX_RPT2 fprintf (stderr, "# Done putting EOLX\n")
#define PUSH_RPT      fprintf (stderr, "# AV_PUSHd @ %4d\n", __LINE__); sv_dump (sv)
#else
#define PUT_RPT
#define PUT_SEPX_RPT1
#define PUT_SEPX_RPT2
#define PUT_QUOX_RPT1
#define PUT_QUOX_RPT2
#define PUT_EOLX_RPT1
#define PUT_EOLX_RPT2
#define PUSH_RPT
#endif
#define CSV_PUT_SV1(c) {			\
    len = SvCUR ((sv));				\
    SvGROW ((sv), len + 2);			\
    *SvEND ((sv)) = c;				\
    PUT_RPT;					\
    SvCUR_set ((sv), len + 1);			\
    }
#define CSV_PUT_SV(c) {				\
    if (c == CH_EOLX) {				\
	int x; PUT_EOLX_RPT1;			\
	if (csv->eol_pos == -2)			\
	    csv->size = 0;			\
	for (x = 0; x < (int)csv->eol_len; x++)	\
	    CSV_PUT_SV1 (csv->eol[x]);		\
	csv->eol_pos = -1;			\
	PUT_EOLX_RPT2;				\
	}					\
    else if (c == CH_SEPX) {			\
	int x; PUT_SEPX_RPT1;			\
	for (x = 0; x < (int)csv->sep_len; x++)	\
	    CSV_PUT_SV1 (csv->sep[x]);		\
	PUT_SEPX_RPT2;				\
	}					\
    else if (c == CH_QUOTEX) {			\
	int x; PUT_QUOX_RPT1;			\
	for (x = 0; x < (int)csv->quo_len; x++)	\
	    CSV_PUT_SV1 (csv->quo[x]);		\
	PUT_QUOX_RPT2;				\
	}					\
    else					\
	CSV_PUT_SV1 (c);			\
    }

#define CSV_GET1				\
    ((csv->used < csv->size)			\
	? ((byte)csv->bptr[csv->used++])	\
	: CsvGet (csv, src))
#if MAINT_DEBUG > 3
int CSV_GET_ (csv_t *csv, SV *src, int l)
{
    int c;
    fprintf (stderr, "# 1-CSV_GET @ %4d: (used: %d, size: %d, eol_pos: %d, eolx = %d)\n", l, csv->used, csv->size, csv->eol_pos, csv->eolx);
    c = CSV_GET1;
    fprintf (stderr, "# 2-CSV_GET @ %4d: 0x%02x '%c'\n", l, c, isprint (c) ? c : '?');
    return (c);
    } /* CSV_GET_ */
#define CSV_GET CSV_GET_ (csv, src, __LINE__)
#else
#define CSV_GET CSV_GET1
#endif

#define AV_PUSH { \
    *SvEND (sv) = (char)0;						\
    SvUTF8_off (sv);							\
    if (SvCUR (sv) == 0 && (						\
	    csv->empty_is_undef ||					\
	    (!(f & CSV_FLAGS_QUO) && csv->blank_is_undef)))		\
	sv_setpvn (sv, NULL, 0);					\
    else {								\
	if (csv->allow_whitespace && ! (f & CSV_FLAGS_QUO))		\
	    strip_trail_whitespace (sv);				\
	if (f & CSV_FLAGS_BIN && csv->decode_utf8			\
			      && (csv->utf8 || is_utf8_sv (sv)))	\
	    SvUTF8_on (sv);						\
	}								\
    SvSETMAGIC (sv);							\
    unless (csv->is_bound) av_push (fields, sv);			\
    PUSH_RPT;								\
    sv = NULL;								\
    if (csv->keep_meta_info && fflags)					\
	av_push (fflags, newSViv (f));					\
    waitingForField = 1;						\
    }

#define strip_trail_whitespace(sv)	cx_strip_trail_whitespace (aTHX_ sv)
static void cx_strip_trail_whitespace (pTHX_ SV *sv)
{
    STRLEN len;
    char   *s = SvPV (sv, len);
    unless (s && len) return;
    while (s[len - 1] == CH_SPACE || s[len - 1] == CH_TAB)
	s[--len] = (char)0;
    SvCUR_set (sv, len);
    } /* strip_trail_whitespace */

#define NewField				\
    unless (sv) {				\
	if (csv->is_bound)			\
	    sv = bound_field (csv, fnum++, 0);	\
	else					\
	    sv = newSVpvs ("");			\
	unless (sv) return FALSE;		\
	f = 0;					\
	}

#if MAINT_DEBUG
static char str_parsed[40];
#endif

#if MAINT_DEBUG > 1
static char *_sep_string (csv_t *csv)
{
    char sep[64];
    if (csv->sep_len) {
	int x;
	for (x = 0; x < csv->sep_len; x++)
	    sprintf (sep + x * x, "%02x ", csv->sep[x]);
	}
    else
	sprintf (sep, "'%c' (0x%02x)", CH_SEP, CH_SEP);
    return sep;
    } /* _sep_string */
#endif

#define Parse(csv,src,fields,fflags)	cx_Parse (aTHX_ csv, src, fields, fflags)
static int cx_Parse (pTHX_ csv_t *csv, SV *src, AV *fields, AV *fflags)
{
    int		 c, f = 0;
    int		 waitingForField	= 1;
    SV		*sv			= NULL;
    STRLEN	 len;
    int		 seenSomething		= FALSE;
    int		 fnum			= 0;
    int		 spl			= -1;
#if MAINT_DEBUG
    memset (str_parsed, 0, 40);
#endif

    while ((c = CSV_GET) != EOF) {

	NewField;

	seenSomething = TRUE;
	spl++;
#if MAINT_DEBUG
	if (spl < 39) str_parsed[spl] = c;
#endif
restart:
	if (is_SEP (c)) {
#if MAINT_DEBUG > 1
	    fprintf (stderr, "# %d/%d/%02x pos %d = SEP %s\n",
		waitingForField ? 1 : 0, sv ? 1 : 0, f, spl, _sep_string (csv));
#endif
	    if (waitingForField) {
		if (csv->blank_is_undef || csv->empty_is_undef)
		    sv_setpvn (sv, NULL, 0);
		else
		    sv_setpvn (sv, "", 0);
		unless (csv->is_bound)
		    av_push (fields, sv);
		sv = NULL;
		if (csv->keep_meta_info && fflags)
		    av_push (fflags, newSViv (f));
		}
	    else
	    if (f & CSV_FLAGS_QUO)
		CSV_PUT_SV (c)
	    else
		AV_PUSH;
	    } /* SEP char */
	else
	if (c == CH_NL || c == CH_EOLX) {
#if MAINT_DEBUG > 1
	    fprintf (stderr, "# %d/%d/%02x pos %d = NL\n",
		waitingForField ? 1 : 0, sv ? 1 : 0, f, spl);
#endif
	    if (waitingForField) {
		if (csv->blank_is_undef || csv->empty_is_undef)
		    sv_setpvn (sv, NULL, 0);
		else
		    sv_setpvn (sv, "", 0);
		unless (csv->is_bound)
		    av_push (fields, sv);
		if (csv->keep_meta_info && fflags)
		    av_push (fflags, newSViv (f));
		return TRUE;
		}

	    if (f & CSV_FLAGS_QUO) {
		f |= CSV_FLAGS_BIN;
		unless (csv->binary)
		    ERROR_INSIDE_QUOTES (2021);

		CSV_PUT_SV (c);
		}
	    else
	    if (csv->verbatim) {
		f |= CSV_FLAGS_BIN;
		unless (csv->binary)
		    ERROR_INSIDE_FIELD (2030);

		CSV_PUT_SV (c);
		}
	    else {
		AV_PUSH;
		return TRUE;
		}
	    } /* CH_NL */
	else
	if (c == CH_CR && !(csv->verbatim)) {
#if MAINT_DEBUG > 1
	    fprintf (stderr, "# %d/%d/%02x pos %d = CR\n",
		waitingForField ? 1 : 0, sv ? 1 : 0, f, spl);
#endif
	    if (waitingForField) {
		int	c2;

		waitingForField = 0;

		if (csv->eol_is_cr) {
		    c = CH_NL;
		    goto restart;
		    }

		c2 = CSV_GET;

		if (c2 == EOF) {
		    c = EOF;
		    goto restart;
		    }

		if (c2 == CH_NL) {
		    c = c2;
		    goto restart;
		    }

		if (csv->useIO && csv->eol_len == 0 && !is_csv_binary (c2)) {
		    set_eol_is_cr (csv);
		    csv->used--;
		    csv->has_ahead++;
		    AV_PUSH;
		    return TRUE;
		    }

		csv->used--;
		ERROR_INSIDE_FIELD (2031);
		}

	    if (f & CSV_FLAGS_QUO) {
		f |= CSV_FLAGS_BIN;
		unless (csv->binary)
		    ERROR_INSIDE_QUOTES (2022);

		CSV_PUT_SV (c);
		}
	    else {
		int	c2;

		if (csv->eol_is_cr) {
		    AV_PUSH;
		    return TRUE;
		    }

		c2 = CSV_GET;

		if (c2 == CH_NL || c2 == CH_EOLX) {
		    AV_PUSH;
		    return TRUE;
		    }

		if (csv->useIO && csv->eol_len == 0 && !is_csv_binary (c2)) {
		    set_eol_is_cr (csv);
		    csv->used--;
		    csv->has_ahead++;
		    AV_PUSH;
		    return TRUE;
		    }

		ERROR_INSIDE_FIELD (2032);
		}
	    } /* CH_CR */
	else
	if (is_QUOTE (c)) {
#if MAINT_DEBUG > 1
	    fprintf (stderr, "# %d/%d/%02x pos %d = QUO '%c'\n",
		waitingForField ? 1 : 0, sv ? 1 : 0, f, spl, c);
#endif
	    if (waitingForField) {
		f |= CSV_FLAGS_QUO;
		waitingForField = 0;
		}
	    else
	    if (f & CSV_FLAGS_QUO) {
		int	c2;

		if (!csv->escape_char || c != csv->escape_char) {
		    /* Field is terminated */
		    c2 = CSV_GET;

		    if (csv->allow_whitespace) {
			while (is_whitespace (c2))
			    c2 = CSV_GET;
			}

		    if (is_SEP (c2)) {
			AV_PUSH;
			continue;
			}

		    if (c2 == EOF) {
			AV_PUSH;
			return TRUE;
			}

		    if (c2 == CH_CR) {
			int	c3;

			if (csv->eol_is_cr) {
			    AV_PUSH;
			    return TRUE;
			    }

			c3 = CSV_GET;
			if (c3 == CH_NL || c3 == CH_EOLX) {
			    AV_PUSH;
			    return TRUE;
			    }

			ParseError (csv, 2010, csv->used - 2);
			return FALSE;
			}

		    if (c2 == CH_NL) {
			AV_PUSH;
			return TRUE;
			}

		    if (csv->allow_loose_quotes) {
			CSV_PUT_SV (c);
			c = c2;
			goto restart;
			}

		    ParseError (csv, 2011, csv->used - 1);
		    return FALSE;
		    }

		c2 = CSV_GET;

		if (csv->allow_whitespace) {
		    while (is_whitespace (c2))
			c2 = CSV_GET;
		    }

		if (c2 == EOF) {
		    AV_PUSH;
		    return TRUE;
		    }

		if (is_SEP (c2)) {
		    AV_PUSH;
		    }
		else
		if (c2 == '0')
		    CSV_PUT_SV (0)
		else
		if (is_QUOTE (c2)) {
		    if (csv->utf8)
			f |= CSV_FLAGS_BIN;
		    CSV_PUT_SV (c2)
		    }
		else
		if (c2 == CH_NL    || c2 == CH_EOLX) {
		    AV_PUSH;
		    return TRUE;
		    }

		else {
		    if (c2 == CH_CR) {
			int	c3;

			if (csv->eol_is_cr) {
			    AV_PUSH;
			    return TRUE;
			    }

			c3 = CSV_GET;

			if (c3 == CH_NL || c3 == CH_EOLX) {
			    AV_PUSH;
			    return TRUE;
			    }

			if (csv->useIO && csv->eol_len == 0 && !is_csv_binary (c3)) {
			    set_eol_is_cr (csv);
			    csv->used--;
			    csv->has_ahead++;
			    AV_PUSH;
			    return TRUE;
			    }
			}

		    if (csv->allow_loose_escapes && csv->escape_char == CH_QUOTE) {
			CSV_PUT_SV (c);
			c = c2;
			goto restart;
			}

		    csv->used--;
		    ERROR_INSIDE_QUOTES (2023);
		    }
		}
	    else
	    /* !waitingForField, !InsideQuotes */
	    if (csv->allow_loose_quotes) { /* 1,foo "boo" d'uh,1 */
		f |= CSV_FLAGS_EIF;	/* Mark as error-in-field */
		CSV_PUT_SV (c);
		}
	    else
		ERROR_INSIDE_FIELD (2034);
	    } /* QUO char */
	else
	if (c == csv->escape_char && csv->escape_char) {
#if MAINT_DEBUG > 1
	    fprintf (stderr, "# %d/%d/%02x pos %d = ESC '%c'\n",
		waitingForField ? 1 : 0, sv ? 1 : 0, f, spl, c);
#endif
	    /* This means quote_char != escape_char */
	    if (waitingForField) {
		waitingForField = 0;
		if (csv->allow_unquoted_escape) {
		    /* The escape character is the first character of an
		     * unquoted field */
		    /* ... get and store next character */
		    int c2 = CSV_GET;

		    sv_setpvn (sv, "", 0);

		    if (c2 == EOF) {
			csv->used--;
			ERROR_INSIDE_FIELD (2035);
			}

		    if (c2 == '0')
			CSV_PUT_SV (0)
		    else
		    if ( is_QUOTE (c2) || is_SEP (c2) ||
			 c2 == csv->escape_char || csv->allow_loose_escapes) {
			if (csv->utf8)
			    f |= CSV_FLAGS_BIN;
			CSV_PUT_SV (c2)
			}
		    else {
			csv->used--;
			ERROR_INSIDE_QUOTES (2025);
			}
		    }
		}
	    else
	    if (f & CSV_FLAGS_QUO) {
		int c2 = CSV_GET;

		if (c2 == EOF) {
		    csv->used--;
		    ERROR_INSIDE_QUOTES (2024);
		    }

		if (c2 == '0')
		    CSV_PUT_SV (0)
		else
		if ( is_QUOTE (c2) || is_SEP (c2) ||
		     c2 == csv->escape_char || csv->allow_loose_escapes) {
		    if (csv->utf8)
			f |= CSV_FLAGS_BIN;
		    CSV_PUT_SV (c2)
		    }
		else {
		    csv->used--;
		    ERROR_INSIDE_QUOTES (2025);
		    }
		}
	    else
	    if (sv) {
		int c2 = CSV_GET;

		if (c2 == EOF) {
		    csv->used--;
		    ERROR_INSIDE_FIELD (2035);
		    }

		CSV_PUT_SV (c2);
		}
	    else
/* uncovered */	ERROR_INSIDE_FIELD (2036); /* I think there's no way to get here */
	    } /* ESC char */
	else {
#if MAINT_DEBUG > 1
	    fprintf (stderr, "# %d/%d/%02x pos %d = === '%c'\n",
		waitingForField ? 1 : 0, sv ? 1 : 0, f, spl, c);
#endif
	    if (waitingForField) {
		if (csv->allow_whitespace && is_whitespace (c)) {
		    do {
			c = CSV_GET;
			} while (is_whitespace (c));
		    if (c == EOF)
			break;
		    goto restart;
		    }
		waitingForField = 0;
		goto restart;
		}

	    if (f & CSV_FLAGS_QUO) {
		if (is_csv_binary (c)) {
		    f |= CSV_FLAGS_BIN;
		    unless (csv->binary || csv->utf8)
			ERROR_INSIDE_QUOTES (2026);
		    }
		CSV_PUT_SV (c);
		}
	    else {
		if (is_csv_binary (c)) {
		    f |= CSV_FLAGS_BIN;
		    unless (csv->binary || csv->utf8)
			ERROR_INSIDE_FIELD (2037);
		    }
		CSV_PUT_SV (c);
		}
	    }

	/* continue */
	if (csv->verbatim && csv->useIO && csv->used == csv->size)
	    break;
	}

    if (waitingForField) {
	if (seenSomething || !csv->useIO) {
	    unless (sv) NewField;
	    if (csv->blank_is_undef || csv->empty_is_undef)
		sv_setpvn (sv, NULL, 0);
	    else
		sv_setpvn (sv, "", 0);
	    unless (csv->is_bound)
		av_push (fields, sv);
	    if (csv->keep_meta_info && fflags)
		av_push (fflags, newSViv (f));
	    return TRUE;
	    }

	(void)SetDiag (csv, 2012);
	return FALSE;
	}

    if (f & CSV_FLAGS_QUO) {
	ERROR_INSIDE_QUOTES (2027);
	}
    else
    if (sv)
	AV_PUSH;
    return TRUE;
    } /* Parse */

#define c_xsParse(csv,hv,av,avf,src,useIO)	cx_c_xsParse (aTHX_ csv, hv, av, avf, src, useIO)
static int cx_c_xsParse (pTHX_ csv_t csv, HV *hv, AV *av, AV *avf, SV *src, bool useIO)
{
    int	result, ahead = 0;
    SV	*pos = NULL;

    ENTER;
    if (csv.eolx || csv.eol_is_cr) {
	/* local $\ = $eol */
	SAVEGENERICSV (PL_rs);
	PL_rs = newSVpvn ((char *)csv.eol, csv.eol_len);
	}

    if ((csv.useIO = useIO)) {
	require_IO_Handle;

	csv.tmp = NULL;

	if ((ahead = csv.has_ahead)) {
	    SV **svp;
	    if ((svp = hv_fetchs (hv, "_AHEAD", FALSE)) && *svp) {
		csv.bptr = SvPV (csv.tmp = *svp, csv.size);
		csv.used = 0;
		if (pos && SvIV (pos) > csv.size)
		    sv_setiv (pos, SvIV (pos) - csv.size);
		}
	    }
	}
    else {
	csv.tmp  = src;
	csv.utf8 = SvUTF8 (src);
	csv.bptr = SvPV (src, csv.size);
	}
    if (csv.has_error_input) {
	(void)hv_store (hv, "_ERROR_INPUT", 12, &PL_sv_undef, 0);
	csv.has_error_input = 0;
	}

    result = Parse (&csv, src, av, avf);
    sv_inc (*(hv_fetchs (hv, "_RECNO", FALSE)));

    (void)hv_store (hv, "_EOF", 4, &PL_sv_no,  0);
    if (csv.useIO) {
	if (csv.tmp && csv.used < csv.size && csv.has_ahead) {
	    SV *sv = newSVpvn (csv.bptr + csv.used, csv.size - csv.used);
	    (void)hv_store  (hv, "_AHEAD", 6, sv, 0);
	    }
	else {
	    csv.has_ahead = 0;
	    if (csv.useIO & useIO_EOF)
		(void)hv_store (hv, "_EOF", 4, &PL_sv_yes, 0);
	    }
	/* csv.cache[CACHE_ID__has_ahead] = csv.has_ahead; */
	memcpy (csv.cache, &csv, sizeof (csv_t));

	if (avf) {
	    if (csv.keep_meta_info) {
		(void)hv_store  (hv, "_FFLAGS", 7, newRV_noinc ((SV *)avf), 0);
		}
	    else {
		av_undef (avf);
		sv_free ((SV *)avf);
		}
	    }
	}
    if (result && csv.types) {
	I32	i;
	STRLEN	len = av_len (av);
	SV    **svp;

	for (i = 0; i <= (I32)len && i <= (I32)csv.types_len; i++) {
	    if ((svp = av_fetch (av, i, 0)) && *svp && SvOK (*svp)) {
		switch (csv.types[i]) {
		    case CSV_XS_TYPE_IV:
			sv_setiv (*svp, SvIV (*svp));
			break;

		    case CSV_XS_TYPE_NV:
			sv_setnv (*svp, SvNV (*svp));
			break;

		    default:
			break;
		    }
		}
	    }
	}

    LEAVE;

    return result;
    } /* c_xsParse */

static void hook (pTHX_ HV *hv, char *cb_name, AV *av)
{
    SV **svp;
    HV *cb;

#if MAINT_DEBUG > 1
    fprintf (stderr, "# HOOK %s %x\n", cb_name, av);
#endif
    unless ((svp = hv_fetchs (hv, "callbacks", FALSE)) && _is_hashref (*svp))
	return;

    cb  = (HV *)SvRV (*svp);
    svp = hv_fetch (cb, cb_name, strlen (cb_name), FALSE);
    unless (svp && _is_coderef (*svp))
	return;

    {   dSP;
	ENTER;
	SAVETMPS;
	PUSHMARK (SP);
	XPUSHs (newRV_noinc ((SV *)hv));
	XPUSHs (newRV_noinc ((SV *)av));
	PUTBACK;
	call_sv (*svp, G_VOID | G_DISCARD);
	FREETMPS;
	LEAVE;
	}
    } /* hook */

#define xsParse(self,hv,av,avf,src,useIO)	cx_xsParse (aTHX_ self, hv, av, avf, src, useIO)
static int cx_xsParse (pTHX_ SV *self, HV *hv, AV *av, AV *avf, SV *src, bool useIO)
{
    csv_t	csv;
    int		state;
    SetupCsv (&csv, hv, self);
    state = c_xsParse (csv, hv, av, avf, src, useIO);
    if (state && csv.has_hooks & HOOK_AFTER_PARSE)
	hook (aTHX_ hv, "after_parse", av);
    return (state || !last_error);
    } /* xsParse */

#define av_empty(av)	cx_av_empty (aTHX_ av)
static void cx_av_empty (pTHX_ AV *av)
{
    while (av_len (av) >= 0)
	sv_free (av_pop (av));
    } /* av_empty */

#define xsParse_all(self,hv,io,off,len)		cx_xsParse_all (aTHX_ self, hv, io, off, len)
static SV *cx_xsParse_all (pTHX_ SV *self, HV *hv, SV *io, SV *off, SV *len)
{
    csv_t	csv;
    int		n = 0, skip = 0, length = MAXINT, tail = MAXINT;
    AV		*avr = newAV ();
    AV		*row = newAV ();

    SetupCsv (&csv, hv, self);
    csv.keep_meta_info = 0;

    if (SvIOK (off)) {
	skip = SvIV (off);
	if (skip < 0) {
	    tail = -skip;
	    skip = -1;
	    }
	}
    if (SvIOK (len))
	length = SvIV (len);

    while (c_xsParse (csv, hv, row, NULL, io, 1)) {

	SetupCsv (&csv, hv, self);

	if (skip > 0) {
	    skip--;
	    av_empty (row); /* re-use */
	    continue;
	    }

	if (n++ >= tail) {
	    SvREFCNT_dec (av_shift (avr));
	    n--;
	    }

	if (csv.has_hooks & HOOK_AFTER_PARSE)
	    hook (aTHX_ hv, "after_parse", row);
	av_push (avr, newRV_noinc ((SV *)row));

	if (n >= length && skip >= 0)
	    break; /* We have enough */

	row = newAV ();
	}
    while (n > length) {
	SvREFCNT_dec (av_pop (avr));
	n--;
	}

    return (SV *)sv_2mortal (newRV_noinc ((SV *)avr));
    } /* xsParse_all */

#define xsCombine(self,hv,av,io,useIO)	cx_xsCombine (aTHX_ self, hv, av, io, useIO)
static int cx_xsCombine (pTHX_ SV *self, HV *hv, AV *av, SV *io, bool useIO)
{
    csv_t	csv;
    int		result;
#if (PERL_BCDVERSION >= 0x5008000)
    SV		*ors = PL_ors_sv;
#endif

    SetupCsv (&csv, hv, self);
    csv.useIO = useIO;
#if (PERL_BCDVERSION >= 0x5008000)
    if (*csv.eol)
	PL_ors_sv = NULL;
#endif
    if (useIO && csv.has_hooks & HOOK_BEFORE_PRINT)
	hook (aTHX_ hv, "before_print", av);
    result = Combine (&csv, io, av);
#if (PERL_BCDVERSION >= 0x5008000)
    PL_ors_sv = ors;
#endif
    if (result && !useIO && csv.utf8)
	sv_utf8_upgrade (io);
    return result;
    } /* xsCombine */

MODULE = Text::CSV_XS		PACKAGE = Text::CSV_XS

PROTOTYPES: DISABLE

BOOT:
    m_getline = newSVpvs ("getline");
    m_print   = newSVpvs ("print");
    m_read    = newSVpvs ("read");

void
SetDiag (self, xse, ...)
    SV		*self
    int		 xse

  PPCODE:
    HV		*hv;
    csv_t	csv;

    if (SvOK (self) && SvROK (self)) {
	CSV_XS_SELF;
	SetupCsv (&csv, hv, self);
	ST (0) = SetDiag (&csv, xse);
	}
    else
	ST (0) = sv_2mortal (SvDiag (xse));

    if (xse && items > 1 && SvPOK (ST (2))) {
	sv_setpvn (ST (0),  SvPVX (ST (2)), SvCUR (ST (2)));
	SvIOK_on  (ST (0));
	}

    XSRETURN (1);
    /* XS SetDiag */

void
error_input (self)
    SV		*self

  PPCODE:
    if (self && SvOK (self) && SvROK (self) && SvTYPE (SvRV (self)) == SVt_PVHV) {
	HV  *hv = (HV *)SvRV (self);
	SV **sv = hv_fetchs (hv, "_ERROR_INPUT", FALSE);
	if (SvOK (*sv))
	    ST (0) = *sv;
	else
	    ST (0) = newSV (0);
	}
    else
	ST (0) = newSV (0);

    XSRETURN (1);
    /* XS error_input */

void
Combine (self, dst, fields, useIO)
    SV		*self
    SV		*dst
    SV		*fields
    bool	 useIO

  PPCODE:
    HV	*hv;
    AV	*av;

    CSV_XS_SELF;
    av = (AV *)SvRV (fields);
    ST (0) = xsCombine (self, hv, av, dst, useIO) ? &PL_sv_yes : &PL_sv_undef;
    XSRETURN (1);
    /* XS Combine */

void
Parse (self, src, fields, fflags)
    SV		*self
    SV		*src
    SV		*fields
    SV		*fflags

  PPCODE:
    HV	*hv;
    AV	*av;
    AV	*avf;

    CSV_XS_SELF;
    av  = (AV *)SvRV (fields);
    avf = (AV *)SvRV (fflags);

    ST (0) = xsParse (self, hv, av, avf, src, 0) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN (1);
    /* XS Parse */

void
print (self, io, fields)
    SV		*self
    SV		*io
    SV		*fields

  PPCODE:
    HV	 *hv;
    AV	 *av;

    CSV_XS_SELF;
    if (fields == &PL_sv_undef)
	av = newAV ();
    else {
	unless (_is_arrayref (fields))
	    croak ("Expected fields to be an array ref");

	av = (AV *)SvRV (fields);
	}

    ST (0) = xsCombine (self, hv, av, io, 1) ? &PL_sv_yes : &PL_sv_no;
    XSRETURN (1);
    /* XS print */

void
getline (self, io)
    SV		*self
    SV		*io

  PPCODE:
    HV	*hv;
    AV	*av;
    AV	*avf;

    CSV_XS_SELF;
    av  = newAV ();
    avf = newAV ();
    ST (0) = xsParse (self, hv, av, avf, io, 1)
	? sv_2mortal (newRV_noinc ((SV *)av))
	: &PL_sv_undef;
    XSRETURN (1);
    /* XS getline */

void
getline_all (self, io, ...)
    SV		*self
    SV		*io

  PPCODE:
    HV	*hv;
    SV  *offset, *length;

    CSV_XS_SELF;

    offset = items > 2 ? ST (2) : &PL_sv_undef;
    length = items > 3 ? ST (3) : &PL_sv_undef;

    ST (0) = xsParse_all (self, hv, io, offset, length);
    XSRETURN (1);
    /* XS getline_all */

void
_cache_set (self, idx, val)
    SV		*self
    int		 idx
    SV		*val

  PPCODE:
    HV	*hv;

    CSV_XS_SELF;
    xs_cache_set (hv, idx, val);
    XSRETURN (1);
    /* XS _cache_set */

void
_cache_diag (self)
    SV		*self

  PPCODE:
    HV	*hv;

    CSV_XS_SELF;
    xs_cache_diag (hv);
    XSRETURN (1);
    /* XS _cache_diag */
