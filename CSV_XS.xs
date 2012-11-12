/*  Copyright (c) 2007-2012 H.Merijn Brand.  All rights reserved.
 *  Copyright (c) 1998-2001 Jochen Wiedmann. All rights reserved.
 *  This program is free software; you can redistribute it and/or
 *  modify it under the same terms as Perl itself.
 */
#define PERL_NO_GET_CONTEXT
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#define NEED_PL_parser
#define DPPP_PL_parser_NO_DUMMY
#define NEED_load_module
#define NEED_my_snprintf
#define NEED_newRV_noinc
#define NEED_pv_escape
#define	NEED_pv_pretty
#define NEED_sv_2pv_flags
#define NEED_vload_module
#include "ppport.h"
#define is_utf8_sv(s) is_utf8_string ((U8 *)SvPV_nolen (s), 0)
#ifndef PERLIO_F_UTF8
#  define PERLIO_F_UTF8	0x00008000
#  endif
#ifndef MAXINT
#  define MAXINT ((int)(~(unsigned)0 >> 1))
#  endif

#define MAINT_DEBUG	0

#define BUFFER_SIZE	65536

#define CSV_XS_TYPE_PV	0
#define CSV_XS_TYPE_IV	1
#define CSV_XS_TYPE_NV	2

/* Keep in sync with .pm! */
#define CACHE_SIZE			40

#define CACHE_ID_quote_char		0
#define CACHE_ID_escape_char		1
#define CACHE_ID_sep_char		2
#define CACHE_ID_binary			3
#define CACHE_ID_keep_meta_info		4
#define CACHE_ID_always_quote		5
#define CACHE_ID_allow_loose_quotes	6
#define CACHE_ID_allow_loose_escapes	7
#define CACHE_ID_allow_double_quoted	8
#define CACHE_ID_allow_whitespace	9
#define CACHE_ID_blank_is_undef		10
#define CACHE_ID_eol			11
#define CACHE_ID_eol_len		19
#define CACHE_ID_eol_is_cr		20
#define CACHE_ID_has_types		21
#define CACHE_ID_verbatim		22
#define CACHE_ID_empty_is_undef		23
#define CACHE_ID_auto_diag		24
#define CACHE_ID_quote_space		25
#define CACHE_ID__is_bound		26
#define CACHE_ID__has_ahead		30
#define CACHE_ID_quote_null		31
#define CACHE_ID_quote_binary		32

#define CSV_FLAGS_QUO	0x0001
#define CSV_FLAGS_BIN	0x0002
#define CSV_FLAGS_EIF	0x0004
#define CSV_FLAGS_MIS	0x0010

#define CH_TAB		'\011'
#define CH_NL		'\012'
#define CH_CR		'\015'
#define CH_SPACE	'\040'
#define CH_DEL		'\177'
#define CH_EOLX		1215

#define useIO_EOF	0x10

#define unless(expr)	if (!(expr))

#define _is_arrayref(f) ( f && \
     (SvROK (f) || (SvRMAGICAL (f) && (mg_get (f), 1) && SvROK (f))) && \
      SvOK (f) && SvTYPE (SvRV (f)) == SVt_PVAV )

#define CSV_XS_SELF					\
    if (!self || !SvOK (self) || !SvROK (self) ||	\
	 SvTYPE (SvRV (self)) != SVt_PVHV)		\
        croak ("self is not a hash ref");		\
    hv = (HV *)SvRV (self)

#define	byte	unsigned char
typedef struct {
    byte	quote_char;
    byte	escape_char;
    byte	sep_char;
    byte	binary;

    byte	keep_meta_info;
    byte	always_quote;
    byte	useIO;		/* Also used to indicate EOF */
    byte	eol_is_cr;

    byte	allow_loose_quotes;
    byte	allow_loose_escapes;
    byte	allow_double_quoted;
    byte	allow_whitespace;

    byte	blank_is_undef;
    byte	empty_is_undef;
    byte	verbatim;
    byte	auto_diag;

    byte	quote_space;
    byte	quote_null;
    byte	quote_binary;
    byte	first_safe_char;

    long	is_bound;

    byte *	cache;

    SV *	pself;
    HV *	self;
    SV *	bound;

    byte *	eol;
    STRLEN	eol_len;
    char *	types;
    STRLEN	types_len;

    char *	bptr;
    SV *	tmp;
    int		utf8;
    byte	has_ahead;
    byte	eolx;
    int		eol_pos;
    STRLEN	size;
    STRLEN	used;
    char	buffer[BUFFER_SIZE];
    } csv_t;

#define bool_opt_def(o,d) \
    (((svp = hv_fetchs (self, o, FALSE)) && *svp) ? SvTRUE (*svp) : d)
#define bool_opt(o) bool_opt_def (o, 0)

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

    /* Parse errors */
    { 2010, "ECR - QUO char inside quotes followed by CR not part of EOL"	},
    { 2011, "ECR - Characters after end of quoted field"			},
    { 2012, "EOF - End of data in parsing input stream"				},

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

    {    0, "" },
    };

static int  io_handle_loaded = 0;
static SV  *m_getline, *m_print, *m_read;

#define require_IO_Handle \
    unless (io_handle_loaded) {\
	ENTER;\
	Perl_load_module (aTHX_ PERL_LOADMOD_NOIMPORT,\
	    newSVpvs ("IO::Handle"), NULL, NULL, NULL);\
	LEAVE;\
	io_handle_loaded = 1;\
	}

#define is_whitespace(ch) \
    ( (ch) != csv->sep_char    && \
      (ch) != csv->quote_char  && \
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
	SvUPGRADE (err, SVt_PVIV);
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

    if (err)
	(void)hv_store (csv->self, "_ERROR_DIAG",  11, err,           0);
    if (xse == 0) {
	(void)hv_store (csv->self, "_ERROR_POS",   10, newSViv  (0),  0);
	(void)hv_store (csv->self, "_ERROR_INPUT", 12, newSVpvs (""), 0);
	}
    if (err && csv->pself && csv->auto_diag) {
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
    SV **svp;
    byte *cp;

    unless ((svp = hv_fetchs (hv, "_CACHE", FALSE)) && *svp)
	return;

    cp = (byte *)SvPV_nolen (*svp);

    /* single char/byte */
    if ( idx == CACHE_ID_quote_char	||
	 idx == CACHE_ID_escape_char	||
	 idx == CACHE_ID_sep_char) {
	cp[idx] = SvPOK (val) ? *(SvPVX (val)) : 0;
	return;
	}

    /* boolean/numeric */
    if ( idx == CACHE_ID_binary			||
         idx == CACHE_ID_keep_meta_info		||
         idx == CACHE_ID_always_quote		||
         idx == CACHE_ID_quote_space		||
         idx == CACHE_ID_quote_null		||
         idx == CACHE_ID_quote_binary		||
         idx == CACHE_ID_allow_loose_quotes	||
         idx == CACHE_ID_allow_loose_escapes	||
         idx == CACHE_ID_allow_double_quoted	||
         idx == CACHE_ID_allow_whitespace	||
         idx == CACHE_ID_blank_is_undef		||
	 idx == CACHE_ID_empty_is_undef		||
	 idx == CACHE_ID_verbatim		||
	 idx == CACHE_ID_auto_diag) {
	cp[idx] = (byte)SvIV (val);
	return;
	}

    /* a 4-byte IV */
    if (idx == CACHE_ID__is_bound) {
	long v = SvIV (val);

	cp[idx    ] = (v & 0xFF000000) >> 24;
	cp[idx + 1] = (v & 0x00FF0000) >> 16;
	cp[idx + 2] = (v & 0x0000FF00) >>  8;
	cp[idx + 3] = (v & 0x000000FF);
	return;
	}

    if (idx == CACHE_ID_eol) {
	STRLEN len = 0;
	char  *eol = SvPOK (val) ? SvPV (val, len) : "";

	memset (cp + CACHE_ID_eol, 0, 8);
	cp[CACHE_ID_eol_len]   = len;
	cp[CACHE_ID_eol_is_cr] = len == 1 && *eol == CH_CR ? 1 : 0;
	if (len > 0 && len < 8)
	    memcpy (cp + CACHE_ID_eol, eol, len);
	}
    } /* cache_set */

#define _pretty_str(csv,xse)	cx_pretty_str (aTHX_ csv, xse)
static char *cx_pretty_str (pTHX_ byte *s, STRLEN l)
{
    SV *dsv = sv_2mortal (newSVpvs (""));
    return (pv_pretty (dsv, (char *)s, l, 0, NULL, NULL,
	    (PERL_PV_PRETTY_DUMP | PERL_PV_ESCAPE_UNI_DETECT)));
    } /* _pretty_str */

#define _cache_show_byte(trim,idx) \
    c = cp[idx]; warn ("  %-20s %02x:%3d\n", trim, c, c)
#define _cache_show_char(trim,idx) \
    c = cp[idx]; warn ("  %-20s %02x:%s\n",  trim, c, _pretty_str (&c, 1))
#define _cache_show_str(trim,l,str) \
    warn ("  %-20s %02d:%s\n",  trim, l, _pretty_str (str, l))
#define _cache_show_cstr(trim,l,idx) _cache_show_str (trim, l, cp + idx)

#define xs_cache_diag(hv)	cx_xs_cache_diag (aTHX_ hv)
static void cx_xs_cache_diag (pTHX_ HV *hv)
{
    SV **svp;
    byte *cp, c;

    unless ((svp = hv_fetchs (hv, "_CACHE", FALSE)) && *svp) {
	warn ("CACHE: invalid\n");
	return;
	}

    cp = (byte *)SvPV_nolen (*svp);
    warn ("CACHE:\n");
    _cache_show_char ("quote",			CACHE_ID_quote_char);
    _cache_show_char ("escape",			CACHE_ID_escape_char);
    _cache_show_char ("sep",			CACHE_ID_sep_char);
    _cache_show_byte ("binary",			CACHE_ID_binary);

    _cache_show_byte ("allow_double_quoted",	CACHE_ID_allow_double_quoted);
    _cache_show_byte ("allow_loose_escapes",	CACHE_ID_allow_loose_escapes);
    _cache_show_byte ("allow_loose_quotes",	CACHE_ID_allow_loose_quotes);
    _cache_show_byte ("allow_whitespace",	CACHE_ID_allow_whitespace);
    _cache_show_byte ("always_quote",		CACHE_ID_always_quote);
    _cache_show_byte ("quote_space",		CACHE_ID_quote_space);
    _cache_show_byte ("quote_null",		CACHE_ID_quote_null);
    _cache_show_byte ("quote_binary",		CACHE_ID_quote_binary);
    _cache_show_byte ("auto_diag",		CACHE_ID_auto_diag);
    _cache_show_byte ("blank_is_undef",		CACHE_ID_blank_is_undef);
    _cache_show_byte ("empty_is_undef",		CACHE_ID_empty_is_undef);
    _cache_show_byte ("has_ahead",		CACHE_ID__has_ahead);
    _cache_show_byte ("has_types",		CACHE_ID_has_types);
    _cache_show_byte ("keep_meta_info",		CACHE_ID_keep_meta_info);
    _cache_show_byte ("verbatim",		CACHE_ID_verbatim);

    _cache_show_byte ("eol_is_cr",		CACHE_ID_eol_is_cr);
    _cache_show_byte ("eol_len",		CACHE_ID_eol_len);
    if (c < 8)
	_cache_show_cstr ("eol", c,		CACHE_ID_eol);
    else if ((svp = hv_fetchs (hv, "eol", FALSE)) && *svp && SvOK (*svp)) {
	STRLEN len;
	byte *eol = (byte *)SvPV (*svp, len);
	_cache_show_str  ("eol", (int)len,	eol);
	}
    else
	_cache_show_str  ("eol", 8,		(byte *)"<broken>");

    /* csv->is_bound			=
	    (csv->cache[CACHE_ID__is_bound    ] << 24) |
	    (csv->cache[CACHE_ID__is_bound + 1] << 16) |
	    (csv->cache[CACHE_ID__is_bound + 2] <<  8) |
	    (csv->cache[CACHE_ID__is_bound + 3]);
    */
    } /* xs_cache_diag */

#define set_eol_is_cr(csv)	cx_set_eol_is_cr (aTHX_ csv)
static void cx_set_eol_is_cr (pTHX_ csv_t *csv)
{
		      csv->cache[CACHE_ID_eol    ]   = CH_CR;
		      csv->cache[CACHE_ID_eol + 1]   = 0;
    csv->eol_is_cr =  csv->cache[CACHE_ID_eol_is_cr] = 1;
    csv->eol_len   =  csv->cache[CACHE_ID_eol_len]   = 1;
    csv->eol       = &csv->cache[CACHE_ID_eol];
    (void)hv_store (csv->self, "eol",  3, newSVpvn ((char *)csv->eol, 1), 0);
    } /* set_eol_is_cr */

#define SetupCsv(csv,self,pself)	cx_SetupCsv (aTHX_ csv, self, pself)
static void cx_SetupCsv (pTHX_ csv_t *csv, HV *self, SV *pself)
{
    SV	       **svp;
    STRLEN	 len;
    char	*ptr;

    csv->self  = self;
    csv->pself = pself;

    if ((svp = hv_fetchs (self, "_CACHE", FALSE)) && *svp) {
	csv->cache = (byte *)SvPVX (*svp);

	csv->quote_char			= csv->cache[CACHE_ID_quote_char	];
	csv->escape_char		= csv->cache[CACHE_ID_escape_char	];
	csv->sep_char			= csv->cache[CACHE_ID_sep_char		];
	csv->binary			= csv->cache[CACHE_ID_binary		];

	csv->keep_meta_info		= csv->cache[CACHE_ID_keep_meta_info	];
	csv->always_quote		= csv->cache[CACHE_ID_always_quote	];
	csv->auto_diag			= csv->cache[CACHE_ID_auto_diag	];
	csv->quote_space		= csv->cache[CACHE_ID_quote_space	];
	csv->quote_null			= csv->cache[CACHE_ID_quote_null	];
	csv->quote_binary		= csv->cache[CACHE_ID_quote_binary	];

	csv->allow_loose_quotes		= csv->cache[CACHE_ID_allow_loose_quotes];
	csv->allow_loose_escapes	= csv->cache[CACHE_ID_allow_loose_escapes];
	csv->allow_double_quoted	= csv->cache[CACHE_ID_allow_double_quoted];
	csv->allow_whitespace		= csv->cache[CACHE_ID_allow_whitespace	];
	csv->blank_is_undef		= csv->cache[CACHE_ID_blank_is_undef	];
	csv->empty_is_undef		= csv->cache[CACHE_ID_empty_is_undef	];
	csv->verbatim			= csv->cache[CACHE_ID_verbatim		];
	csv->has_ahead			= csv->cache[CACHE_ID__has_ahead	];
	csv->eol_is_cr			= csv->cache[CACHE_ID_eol_is_cr		];
	csv->eol_len			= csv->cache[CACHE_ID_eol_len		];
	if (csv->eol_len < 8)
	    csv->eol = &csv->cache[CACHE_ID_eol];
	else {
	    /* Was too long to cache. must re-fetch */
	    csv->eol       = NULL;
	    csv->eol_is_cr = 0;
	    csv->eol_len   = 0;
	    if ((svp = hv_fetchs (self, "eol",     FALSE)) && *svp && SvOK (*svp)) {
		csv->eol = (byte *)SvPV (*svp, len);
		csv->eol_len = len;
		}
	    }
	csv->is_bound			=
	    (csv->cache[CACHE_ID__is_bound    ] << 24) |
	    (csv->cache[CACHE_ID__is_bound + 1] << 16) |
	    (csv->cache[CACHE_ID__is_bound + 2] <<  8) |
	    (csv->cache[CACHE_ID__is_bound + 3]);

	csv->types = NULL;
	if (csv->cache[CACHE_ID_has_types]) {
	    if ((svp = hv_fetchs (self, "_types",  FALSE)) && *svp && SvOK (*svp)) {
		csv->types = SvPV (*svp, len);
		csv->types_len = len;
		}
	    }
	}
    else {
	SV *sv_cache;

	csv->quote_char = '"';
	if ((svp = hv_fetchs (self, "quote_char",  FALSE)) && *svp) {
	    if (SvOK (*svp)) {
		ptr = SvPV (*svp, len);
		csv->quote_char = len ? *ptr : (char)0;
		}
	    else
		csv->quote_char = (char)0;
	    }

	csv->escape_char = '"';
	if ((svp = hv_fetchs (self, "escape_char", FALSE)) && *svp) {
	    if (SvOK (*svp)) {
		ptr = SvPV (*svp, len);
		csv->escape_char = len ? *ptr : (char)0;
		}
	    else
		csv->escape_char = (char)0;
	    }
	csv->sep_char = ',';
	if ((svp = hv_fetchs (self, "sep_char",    FALSE)) && *svp && SvOK (*svp)) {
	    ptr = SvPV (*svp, len);
	    if (len)
		csv->sep_char = *ptr;
	    }

	csv->eol       = (byte *)"";
	csv->eol_is_cr = 0;
	csv->eol_len   = 0;
	if ((svp = hv_fetchs (self, "eol",         FALSE)) && *svp && SvOK (*svp)) {
	    csv->eol = (byte *)SvPV (*svp, len);
	    csv->eol_len = len;
	    if (len == 1 && *csv->eol == CH_CR)
		csv->eol_is_cr = 1;
	    }

	csv->types = NULL;
	if ((svp = hv_fetchs (self, "_types", FALSE)) && *svp && SvOK (*svp)) {
	    csv->types = SvPV (*svp, len);
	    csv->types_len = len;
	    }

	csv->is_bound = 0;
	if ((svp = hv_fetchs (self, "_is_bound", FALSE)) && *svp && SvOK(*svp))
	    csv->is_bound = SvIV(*svp);

	csv->binary			= bool_opt ("binary");
	csv->keep_meta_info		= bool_opt ("keep_meta_info");
	csv->always_quote		= bool_opt ("always_quote");
	csv->quote_space		= bool_opt_def ("quote_space",  1);
	csv->quote_null			= bool_opt_def ("quote_null",   1);
	csv->quote_binary		= bool_opt_def ("quote_binary", 1);
	csv->allow_loose_quotes		= bool_opt ("allow_loose_quotes");
	csv->allow_loose_escapes	= bool_opt ("allow_loose_escapes");
	csv->allow_double_quoted	= bool_opt ("allow_double_quoted");
	csv->allow_whitespace		= bool_opt ("allow_whitespace");
	csv->blank_is_undef		= bool_opt ("blank_is_undef");
	csv->empty_is_undef		= bool_opt ("empty_is_undef");
	csv->verbatim			= bool_opt ("verbatim");
	csv->auto_diag			= bool_opt ("auto_diag");

	sv_cache = newSVpvn ("", CACHE_SIZE);
	csv->cache = (byte *)SvPVX (sv_cache);
	memset (csv->cache, 0, CACHE_SIZE);
	SvREADONLY_on (sv_cache);

	csv->cache[CACHE_ID_quote_char]			= csv->quote_char;
	csv->cache[CACHE_ID_escape_char]		= csv->escape_char;
	csv->cache[CACHE_ID_sep_char]			= csv->sep_char;
	csv->cache[CACHE_ID_binary]			= csv->binary;

	csv->cache[CACHE_ID_keep_meta_info]		= csv->keep_meta_info;
	csv->cache[CACHE_ID_always_quote]		= csv->always_quote;
	csv->cache[CACHE_ID_quote_space]		= csv->quote_space;
	csv->cache[CACHE_ID_quote_null]			= csv->quote_null;
	csv->cache[CACHE_ID_quote_binary]		= csv->quote_binary;

	csv->cache[CACHE_ID_allow_loose_quotes]		= csv->allow_loose_quotes;
	csv->cache[CACHE_ID_allow_loose_escapes]	= csv->allow_loose_escapes;
	csv->cache[CACHE_ID_allow_double_quoted]	= csv->allow_double_quoted;
	csv->cache[CACHE_ID_allow_whitespace]		= csv->allow_whitespace;
	csv->cache[CACHE_ID_blank_is_undef]		= csv->blank_is_undef;
	csv->cache[CACHE_ID_empty_is_undef]		= csv->empty_is_undef;
	csv->cache[CACHE_ID_verbatim]			= csv->verbatim;
	csv->cache[CACHE_ID_auto_diag]			= csv->auto_diag;
	csv->cache[CACHE_ID_eol_is_cr]			= csv->eol_is_cr;
	csv->cache[CACHE_ID_eol_len]			= csv->eol_len;
	if (csv->eol_len > 0 && csv->eol_len < 8 && csv->eol)
	    memcpy ((char *)&csv->cache[CACHE_ID_eol], csv->eol, csv->eol_len);
	csv->cache[CACHE_ID_has_types]			= csv->types ? 1 : 0;
	csv->cache[CACHE_ID__has_ahead]			= csv->has_ahead = 0;
	csv->cache[CACHE_ID__is_bound    ] = (csv->is_bound & 0xFF000000) >> 24;
	csv->cache[CACHE_ID__is_bound + 1] = (csv->is_bound & 0x00FF0000) >> 16;
	csv->cache[CACHE_ID__is_bound + 2] = (csv->is_bound & 0x0000FF00) >>  8;
	csv->cache[CACHE_ID__is_bound + 3] = (csv->is_bound & 0x000000FF);

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
	PUSHs (tmp);
	PUTBACK;
	if (csv->utf8) {
	    STRLEN	 len;
	    char	*ptr;
	    int		 j, l;

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
    if (csv->utf8 && SvROK (dst) && is_utf8_sv (SvRV (dst)))
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

    if (csv->sep_char == csv->quote_char || csv->sep_char == csv->escape_char) {
	(void)SetDiag (csv, 1001);
	return FALSE;
	}

    n = av_len (fields);
    if (n < 0 && csv->is_bound) {
	n = csv->is_bound - 1;
	bound = 1;
	}

    for (i = 0; i <= n; i++) {
	SV    *sv;

	if (i > 0)
	    CSV_PUT (csv, dst, csv->sep_char);

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
	       ( quoteMe = (!SvIOK (sv) && !SvNOK (sv) && csv->quote_char))) {
		char	*ptr2;
		STRLEN	 l;

		for (ptr2 = ptr, l = len; l; ++ptr2, --l) {
		    byte c = *ptr2;

		    if (c < csv->first_safe_char ||
		       (csv->quote_binary && c >= 0x7f && c <= 0xa0) ||
		       (csv->quote_char   && c == csv->quote_char)   ||
		       (csv->sep_char     && c == csv->sep_char)     ||
		       (csv->escape_char  && c == csv->escape_char)) {
			/* Binary character */
			break;
			}
		    }
		quoteMe = (l > 0);
		}
	    if (quoteMe)
		CSV_PUT (csv, dst, csv->quote_char);
	    while (len-- > 0) {
		char	c = *ptr++;
		int	e = 0;

		if (!csv->binary && is_csv_binary (c)) {
		    SvREFCNT_inc (sv);
		    unless (hv_store (csv->self, "_ERROR_INPUT", 12, sv, 0))
/* uncovered */	    SvREFCNT_dec (sv);
		    (void)SetDiag (csv, 2110);
		    return FALSE;
		    }
		if (c == csv->quote_char  && csv->quote_char)
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
	    if (quoteMe)
		CSV_PUT (csv, dst, csv->quote_char);
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
#define PUT_EOLX_RPT1 fprintf (stderr, "# PUT EOLX @ %4d\n", __LINE__)
#define PUT_EOLX_RPT2 fprintf (stderr, "# Done putting EOLX\n")
#define PUSH_RPT      fprintf (stderr, "# AV_PUSHd @ %4d\n", __LINE__); sv_dump (sv)
#else
#define PUT_RPT
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
    *SvEND (sv) = (char)0;					\
    SvUTF8_off (sv);						\
    if (SvCUR (sv) == 0 && (csv->empty_is_undef || (!(f & CSV_FLAGS_QUO) && csv->blank_is_undef)))\
	sv_setpvn (sv, NULL, 0);				\
    else {							\
	if (csv->allow_whitespace && ! (f & CSV_FLAGS_QUO))	\
	    strip_trail_whitespace (sv);			\
	if (f & CSV_FLAGS_BIN && csv->utf8)			\
	    SvUTF8_on (sv);					\
	}							\
    SvSETMAGIC (sv);						\
    unless (csv->is_bound) av_push (fields, sv);		\
    PUSH_RPT;							\
    sv = NULL;							\
    if (csv->keep_meta_info && fflags)				\
	av_push (fflags, newSViv (f));				\
    waitingForField = 1;					\
    }

#define strip_trail_whitespace(sv)	cx_strip_trail_whitespace (aTHX_ sv)
static void cx_strip_trail_whitespace (pTHX_ SV *sv)
{
    STRLEN len;
    char   *s = SvPV (sv, len);
    unless (s && len) return;
    while (s[len - 1] == CH_SPACE || s[len - 1] == CH_TAB) {
	s[--len] = (char)0;
	}
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

    if (csv->sep_char == csv->quote_char || csv->sep_char == csv->escape_char) {
	(void)SetDiag (csv, 1001);
	return FALSE;
	}

    while ((c = CSV_GET) != EOF) {

	NewField;

	seenSomething = TRUE;
	spl++;
#if MAINT_DEBUG
	if (spl < 39) str_parsed[spl] = c;
#endif
restart:
	if (c == csv->sep_char) {
#if MAINT_DEBUG > 1
	    fprintf (stderr, "# %d/%d/%02x pos %d = SEP '%c'\n",
		waitingForField ? 1 : 0, sv ? 1 : 0, f, spl, c);
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
	if (c == csv->quote_char && csv->quote_char) {
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

		    if (c2 == csv->sep_char) {
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

		if (c2 == csv->sep_char) {
		    AV_PUSH;
		    }
		else
		if (c2 == '0')
		    CSV_PUT_SV (0)
		else
		if (c2 == csv->quote_char  ||  c2 == csv->sep_char)
		    CSV_PUT_SV (c2)
		else
		if (c2 == CH_NL || c2 == CH_EOLX) {
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

		    if (csv->allow_loose_escapes && csv->escape_char == csv->quote_char) {
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
	    /*  This means quote_char != escape_char  */
	    if (waitingForField)
		waitingForField = 0;
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
		if ( c2 == csv->quote_char  || c2 == csv->sep_char ||
		     c2 == csv->escape_char || csv->allow_loose_escapes)
		    CSV_PUT_SV (c2)
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
	if (seenSomething) {
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
	if (csv->useIO) {
	    (void)SetDiag (csv, 2012);
	    return FALSE;
	    }
	}
    else
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
	dSP;
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
    (void)hv_delete (hv, "_ERROR_INPUT", 12, G_DISCARD);

    result = Parse (&csv, src, av, avf);
    sv_inc (*(hv_fetchs (hv, "_RECNO", FALSE)));

    (void)hv_store (hv, "_EOF", 4, &PL_sv_no,  0);
    if (csv.useIO) {
	if (csv.tmp && csv.used < csv.size && csv.has_ahead) {
	    SV *sv = newSVpvn (csv.bptr + csv.used, csv.size - csv.used);
	    (void)hv_delete (hv, "_AHEAD", 6, G_DISCARD);
	    (void)hv_store  (hv, "_AHEAD", 6, sv, 0);
	    }
	else {
	    csv.has_ahead = 0;
	    if (csv.useIO & useIO_EOF)
		(void)hv_store (hv, "_EOF", 4, &PL_sv_yes, 0);
	    }
	csv.cache[CACHE_ID__has_ahead] = csv.has_ahead;

	if (avf) {
	    if (csv.keep_meta_info) {
		(void)hv_delete (hv, "_FFLAGS", 7, G_DISCARD);
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

#define xsParse(self,hv,av,avf,src,useIO)	cx_xsParse (aTHX_ self, hv, av, avf, src, useIO)
static int cx_xsParse (pTHX_ SV *self, HV *hv, AV *av, AV *avf, SV *src, bool useIO)
{
    csv_t	csv;
    SetupCsv (&csv, hv, self);
    return (c_xsParse (csv, hv, av, avf, src, useIO));
    } /* xsParse */

#define av_empty(av)	cx_av_empty (aTHX_ av)
static void cx_av_empty (pTHX_ AV *av)
{
    while (av_len (av) >= 0)
	sv_free (av_pop (av));
    } /* av_empty */

#define av_free(av)	cx_av_free (aTHX_ av)
static void cx_av_free (pTHX_ AV *av)
{
    av_empty (av);
    sv_free ((SV *)av);
    } /* av_free */

#define rav_free(rv)	cx_rav_free (aTHX_ rv)
static void cx_rav_free (pTHX_ SV *rv)
{
    av_free ((AV *)SvRV (rv));
    sv_free (rv);
    } /* rav_free */

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
	if (skip > 0) {
	    skip--;
	    av_empty (row); /* re-use */
	    continue;
	    }

	if (n++ >= tail) {
	    rav_free (av_shift (avr));
	    n--;
	    }

	av_push (avr, newRV ((SV *)row));

	if (n >= length && skip >= 0)
	    break; /* We have enough */

	row = newAV ();
	}
    while (n > length) {
	rav_free (av_pop (avr));
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
    if (csv.eol && *csv.eol)
	PL_ors_sv = NULL;
#endif
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
	?  sv_2mortal (newRV_noinc ((SV *)av))
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
