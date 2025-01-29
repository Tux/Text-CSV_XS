/*  Copyright (c) 2007-2025 H.Merijn Brand.  All rights reserved.
 *  Copyright (c) 1998-2001 Jochen Wiedmann. All rights reserved.
 *  This program is free software; you can redistribute it and/or
 *  modify it under the same terms as Perl itself.
 */
#define PERL_NO_GET_CONTEXT
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#define DPPP_PL_parser_NO_DUMMY
#define NEED_utf8_to_uvchr_buf
#define NEED_my_snprintf
#define NEED_pv_escape
#define NEED_pv_pretty
#ifndef PERLIO_F_UTF8
#  define PERLIO_F_UTF8	0x00008000
#  endif
#ifndef MAXINT
#  define MAXINT ((int)(~(unsigned)0 >> 1))
#  endif
#include "ppport.h"
#define is_utf8_sv(s) is_utf8_string ((U8 *)SvPV_nolen (s), SvCUR (s))

#define MAINT_DEBUG	0
#define MAINT_DEBUG_EOL	0

#define BUFFER_SIZE	1024

#define CSV_XS_TYPE_WARN	1
#define CSV_XS_TYPE_PV		0
#define CSV_XS_TYPE_IV		1
#define CSV_XS_TYPE_NV		2

/* maximum length for EOL, SEP, and QUOTE - keep in sync with .pm */
#define MAX_ATTR_LEN	16

#define CSV_FLAGS_QUO		0x0001
#define CSV_FLAGS_BIN		0x0002
#define CSV_FLAGS_EIF		0x0004
#define CSV_FLAGS_MIS		0x0010

#define HOOK_ERROR		0x0001
#define HOOK_AFTER_PARSE	0x0002
#define HOOK_BEFORE_PRINT	0x0004

#ifdef __THW_370__
/* EBCDIC on os390 z/OS: IS_EBCDIC reads better than __THW_370__ */
#define IS_EBCDIC
#endif

#define CH_TAB		'\t'
#define CH_NL		'\n'
#define CH_CR		'\r'
#define CH_SPACE	' '
#define CH_QUO		'"'

#ifdef IS_EBCDIC
#define CH_DEL		'\007'
static unsigned char ec, ebcdic2ascii[256] = {
    0x00, 0x01, 0x02, 0x03, 0x9c, 0x09, 0x86, 0x7f,
    0x97, 0x8d, 0x8e, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f,
    0x10, 0x11, 0x12, 0x13, 0x9d, 0x0a, 0x08, 0x87,
    0x18, 0x19, 0x92, 0x8f, 0x1c, 0x1d, 0x1e, 0x1f,
    0x80, 0x81, 0x82, 0x83, 0x84, 0x85, 0x17, 0x1b,
    0x88, 0x89, 0x8a, 0x8b, 0x8c, 0x05, 0x06, 0x07,
    0x90, 0x91, 0x16, 0x93, 0x94, 0x95, 0x96, 0x04,
    0x98, 0x99, 0x9a, 0x9b, 0x14, 0x15, 0x9e, 0x1a,
    0x20, 0xa0, 0xe2, 0xe4, 0xe0, 0xe1, 0xe3, 0xe5,
    0xe7, 0xf1, 0xa2, 0x2e, 0x3c, 0x28, 0x2b, 0x7c,
    0x26, 0xe9, 0xea, 0xeb, 0xe8, 0xed, 0xee, 0xef,
    0xec, 0xdf, 0x21, 0x24, 0x2a, 0x29, 0x3b, 0x5e,
    0x2d, 0x2f, 0xc2, 0xc4, 0xc0, 0xc1, 0xc3, 0xc5,
    0xc7, 0xd1, 0xa6, 0x2c, 0x25, 0x5f, 0x3e, 0x3f,
    0xf8, 0xc9, 0xca, 0xcb, 0xc8, 0xcd, 0xce, 0xcf,
    0xcc, 0x60, 0x3a, 0x23, 0x40, 0x27, 0x3d, 0x22,
    0xd8, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67,
    0x68, 0x69, 0xab, 0xbb, 0xf0, 0xfd, 0xfe, 0xb1,
    0xb0, 0x6a, 0x6b, 0x6c, 0x6d, 0x6e, 0x6f, 0x70,
    0x71, 0x72, 0xaa, 0xba, 0xe6, 0xb8, 0xc6, 0xa4,
    0xb5, 0x7e, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78,
    0x79, 0x7a, 0xa1, 0xbf, 0xd0, 0x5b, 0xde, 0xae,
    0xac, 0xa3, 0xa5, 0xb7, 0xa9, 0xa7, 0xb6, 0xbc,
    0xbd, 0xbe, 0xdd, 0xa8, 0xaf, 0x5d, 0xb4, 0xd7,
    0x7b, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47,
    /*          v this 0xa0 really should be 0xad. Needed for UTF = binary */
    0x48, 0x49, 0xa0, 0xf4, 0xf6, 0xf2, 0xf3, 0xf5,
    0x7d, 0x4a, 0x4b, 0x4c, 0x4d, 0x4e, 0x4f, 0x50,
    0x51, 0x52, 0xb9, 0xfb, 0xfc, 0xf9, 0xfa, 0xff,
    0x5c, 0xf7, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58,
    0x59, 0x5a, 0xb2, 0xd4, 0xd6, 0xd2, 0xd3, 0xd5,
    0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37,
    0x38, 0x39, 0xb3, 0xdb, 0xdc, 0xd9, 0xda, 0x9f
    };
#define is_csv_binary(ch) ((((ec = ebcdic2ascii[ch]) < 0x20 || ec >= 0x7f) && ch != CH_TAB) || ch == EOF)
#else
#define CH_DEL		'\177'
#define is_csv_binary(ch) ((ch < CH_SPACE || ch >= CH_DEL) && ch != CH_TAB)
#endif
#define CH_EOLX		1215
#define CH_EOL		*csv->eol
#define CH_SEPX		8888
#define CH_SEP		*csv->sep
#define CH_QUOTEX	8889
#define CH_QUOTE	*csv->quo

#define useIO_EOF	0x10

#define unless(expr)	if (!(expr))

#define _is_reftype(f,x) \
    (f && ((SvGMAGICAL (f) && mg_get (f)) || 1) && SvROK (f) && SvTYPE (SvRV (f)) == x)
#define _is_arrayref(f) _is_reftype (f, SVt_PVAV)
#define _is_hashref(f)  _is_reftype (f, SVt_PVHV)
#define _is_coderef(f)  _is_reftype (f, SVt_PVCV)

#define SvSetUndef(sv)	sv_setpvn    (sv, NULL, 0)
#define SvSetEmpty(sv)	sv_setpvn_mg (sv, "",   0)

#define CSV_XS_SELF					\
    if (!self || !SvOK (self) || !SvROK (self) ||	\
	 SvTYPE (SvRV (self)) != SVt_PVHV)		\
	croak ("self is not a hash ref");		\
    hv = (HV *)SvRV (self)

/* Keep in sync with .pm! */
#define CACHE_ID_quote_char		0
#define CACHE_ID_escape_char		1
#define CACHE_ID_sep_char		2
#define CACHE_ID_always_quote		4
#define CACHE_ID_quote_empty		5
#define CACHE_ID_quote_space		6
#define CACHE_ID_quote_binary		7
#define CACHE_ID_allow_loose_quotes	8
#define CACHE_ID_allow_loose_escapes	9
#define CACHE_ID_allow_unquoted_escape	10
#define CACHE_ID_allow_whitespace	11
#define CACHE_ID_blank_is_undef		12
#define CACHE_ID_empty_is_undef		13
#define CACHE_ID_auto_diag		14
#define CACHE_ID_diag_verbose		15
#define CACHE_ID_escape_null		16
#define CACHE_ID_formula		18
#define CACHE_ID_has_error_input	20
#define CACHE_ID_decode_utf8		21
#define CACHE_ID_verbatim		23
#define CACHE_ID_strict_eol		24
#define CACHE_ID_eol_is_cr		26
#define CACHE_ID_eol_type		27
#define CACHE_ID_strict			28
#define CACHE_ID_skip_empty_rows	29
#define CACHE_ID_binary			30
#define CACHE_ID_keep_meta_info		31
#define CACHE_ID__has_hooks		32
#define CACHE_ID__has_ahead		33
#define CACHE_ID_eol_len		36
#define CACHE_ID_sep_len		37
#define CACHE_ID_quo_len		38
#define CACHE_ID__is_bound		44
#define CACHE_ID_types			92
#define CACHE_ID_eol			100
#define CACHE_ID_sep			116
#define CACHE_ID_quo			132
#define CACHE_ID_undef_str		148
#define CACHE_ID_comment_str		156

#define EOL_TYPE_UNDEF		0
#define EOL_TYPE_NL		1
#define EOL_TYPE_CR		2
#define EOL_TYPE_CRNL		3
#define EOL_TYPE_OTHER		4
#define EOL_TYPE(c) ((((char)c) == CH_NL) ? EOL_TYPE_NL : (((char)c) == CH_CR) ? EOL_TYPE_CR : EOL_TYPE_OTHER)
#define SET_EOL_TYPE(c,t) {		\
    unless (c->eol_type) {		\
	c->eol_type = t;		\
	c->cache[CACHE_ID_eol_type] = t;\
	}				\
    }

#define	byte	unsigned char
#define ulng	unsigned long
typedef struct {
    byte	quote_char;		/*  0 */
    byte	escape_char;		/*  1 */
    byte	_sep_char;		/*  2 : reserved for sep_char */
    byte	fld_idx;		/*  3 */

    byte	always_quote;		/*  4 */
    byte	quote_empty;		/*  5 */
    byte	quote_space;		/*  6 */
    byte	quote_binary;		/*  7 */

    byte	allow_loose_quotes;	/*  8 */
    byte	allow_loose_escapes;	/*  9 */
    byte	allow_unquoted_escape;	/* 10 */
    byte	allow_whitespace;	/* 11 */

    byte	blank_is_undef;		/* 12 */
    byte	empty_is_undef;		/* 13 */
    byte	auto_diag;		/* 14 */
    byte	diag_verbose;		/* 15 */

    byte	escape_null;		/* 16 */
    byte	first_safe_char;	/* 17 */
    byte	formula;		/* 18 */
    byte	utf8;			/* 19 */

    byte	has_error_input;	/* 20 */
    byte	decode_utf8;		/* 21 */
    byte	useIO;			/* 22: Also used to indicate EOF */
    byte	verbatim;		/* 23 */

    byte	strict_eol;		/* 24 */
    byte	eolx;			/* 25 */
    byte	eol_is_cr;		/* 26 */
    byte	eol_type;		/* 27 */

    byte	strict;			/* 28 */
    byte	skip_empty_rows;	/* 29 */
    byte	binary;			/* 30 */
    byte	keep_meta_info;		/* 31 */

    byte	has_hooks;		/* 32 */
    byte	has_ahead;		/* 33 */
    byte	nyi_1;			/* 34 : free */
    byte	nyi_2;			/* 35 : free */

    byte	eol_len;		/* 36 */
    byte	sep_len;		/* 37 */
    byte	quo_len;		/* 38 */
    byte	types_len;		/* 39 */

    short	strict_n;		/* 40.. */
    long	is_bound;		/* 44.. */
    ulng	recno;			/* 52.. */
    byte *	cache;			/* 60.. */
    SV *	pself;			/* 68.. PL_self, for error_diag */
    HV *	self;			/* 76.. */
    SV *	bound;			/* 84.. */
    char *	types;			/* 92.. */

    byte	eol[MAX_ATTR_LEN];	/* 100..115 */
    byte	sep[MAX_ATTR_LEN];	/* 116..131 */
    byte	quo[MAX_ATTR_LEN];	/* 132..147 */

    byte *	undef_str;		/* 148.. */
    byte *	comment_str;		/* 156.. */

    char *	bptr;
    SV *	tmp;
    int		eol_pos;
    STRLEN	size;
    STRLEN	used;
    byte	undef_flg;
    char	buffer[BUFFER_SIZE];
    /* Likely 1240 bytes */
    } csv_t;

#define bool_opt_def(o,d) \
    (((svp = hv_fetchs (self, o, FALSE)) && *svp) ? SvTRUE (*svp) : d)
#define bool_opt(o) bool_opt_def (o, 0)
#define num_opt_def(o,d) \
    (((svp = hv_fetchs (self, o, FALSE)) && *svp) ? SvIV   (*svp) : d)
#define num_opt(o)  num_opt_def  (o, 0)

typedef struct {
    int   xs_errno;
    const char *xs_errstr;
    } xs_error_t;
static const xs_error_t xs_errors[] =  {

    /* Generic errors */
    { 1000, "INI - constructor failed"						},
    { 1001, "INI - sep_char is equal to quote_char or escape_char"		},
    { 1002, "INI - allow_whitespace with escape_char or quote_char SP or TAB"	},
    { 1003, "INI - \\r or \\n in main attr not allowed"				},
    { 1004, "INI - callbacks should be undef or a hashref"			},
    { 1005, "INI - EOL too long"						},
    { 1006, "INI - SEP too long"						},
    { 1007, "INI - QUOTE too long"						},
    { 1008, "INI - SEP undefined"						},

    { 1010, "INI - the header is empty"						},
    { 1011, "INI - the header contains more than one valid separator"		},
    { 1012, "INI - the header contains an empty field"				},
    { 1013, "INI - the header contains nun-unique fields"			},
    { 1014, "INI - header called on undefined stream"				},

    /* Syntax errors */
    { 1500, "PRM - Invalid/unsupported argument(s)"				},
    { 1501, "PRM - The key attribute is passed as an unsupported type"		},
    { 1502, "PRM - The value attribute is passed without the key attribute"	},
    { 1503, "PRM - The value attribute is passed as an unsupported type"	},

    /* Parse errors */
    { 2010, "ECR - QUO char inside quotes followed by CR not part of EOL"	},
    { 2011, "ECR - Characters after end of quoted field"			},
    { 2012, "EOF - End of data in parsing input stream"				},
    { 2013, "ESP - Specification error for fragments RFC7111"			},
    { 2014, "ENF - Inconsistent number of fields"				},
    { 2015, "ERW - Empty row"							},
    { 2016, "EOL - Inconsistent EOL"						},

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

    { 4001, "PRM - The key does not exist as field in the data"			},

    { 5001, "PRM - The result does not match the output to append to"		},
    { 5002, "PRM - Unsupported output"						},

    {    0, "" },
    };

static int last_error = 0;
static SV *m_getline, *m_print;

#define is_EOL(c) (c == CH_EOLX)

#define __is_SEPX(c) (c == CH_SEP && (csv->sep_len == 0 || (\
    csv->size - csv->used >= (STRLEN)csv->sep_len - 1			&&\
    !memcmp (csv->bptr + csv->used, csv->sep + 1, csv->sep_len - 1)	&&\
    (csv->used += csv->sep_len - 1)					&&\
    (c = CH_SEPX))))
#if MAINT_DEBUG > 1
static byte _is_SEPX (unsigned int c, csv_t *csv, int line) {
    unsigned int b = __is_SEPX (c);
    (void)fprintf (stderr, "# %4d - is_SEPX:\t%d (%d)\n", line, b, csv->sep_len);
    if (csv->sep_len)
	(void)fprintf (stderr,
	    "# len: %d, siz: %d, usd: %d, c: %03x, *sep: %03x\n",
	    csv->sep_len, csv->size, csv->used, c, CH_SEP);
    return b;
    } /* _is_SEPX */
#define is_SEP(c)  _is_SEPX (c, csv, __LINE__)
#else
#define is_SEP(c) __is_SEPX (c)
#endif

#define __is_QUOTEX(c) (CH_QUOTE && c == CH_QUOTE && (csv->quo_len == 0 || (\
    csv->size - csv->used >= (STRLEN)csv->quo_len - 1			&&\
    !memcmp (csv->bptr + csv->used, csv->quo + 1, csv->quo_len - 1)	&&\
    (csv->used += csv->quo_len - 1)					&&\
    (c = CH_QUOTEX))))
#if MAINT_DEBUG > 1
static byte _is_QUOTEX (unsigned int c, csv_t *csv, int line) {
    unsigned int b = __is_QUOTEX (c);
    (void)fprintf (stderr, "# %4d - is_QUOTEX:\t%d (%d)\n", line, b, csv->quo_len);

    if (csv->quo_len)
	(void)fprintf (stderr,
	    "# len: %d, siz: %d, usd: %d, c: %03x, *quo: %03x\n",
	    csv->quo_len, csv->size, csv->used, c, CH_QUOTE);
    return b;
    } /* _is_QUOTEX */
#define is_QUOTE(c)  _is_QUOTEX (c, csv, __LINE__)
#else
#define is_QUOTE(c) __is_QUOTEX (c)
#endif

#define is_whitespace(ch) \
    ( (ch) != CH_SEP           && \
      (ch) != CH_QUOTE         && \
      (ch) != csv->escape_char && \
    ( (ch) == CH_SPACE || \
      (ch) == CH_TAB \
      ) \
    )

#define _pretty_strl(cp)	cx_pretty_str (aTHX_ cp, strlen (cp))
#define _pretty_str(cp,xse)	cx_pretty_str (aTHX_ cp, xse)
static char *cx_pretty_str (pTHX_ byte *s, STRLEN l) {
    SV *dsv = newSVpvs_flags ("", SVs_TEMP);
    return (pv_pretty (dsv, (char *)s, l, 0, NULL, NULL,
	    (PERL_PV_PRETTY_DUMP | PERL_PV_ESCAPE_UNI_DETECT)));
    } /* _pretty_str */
#if MAINT_DEBUG > 4
#define _pretty_sv(cp)		cx_pretty_sv  (aTHX_ cp)
static char *cx_pretty_sv (pTHX_ SV *sv) {
    if (SvOK (sv) && SvPOK (sv)) {
	STRLEN l;
	char *s = SvPV (sv, l);
	return _pretty_str ((byte *)s, l);
	}
    return ("");
    } /* _pretty_sv */
#endif

#define SvDiag(xse)		cx_SvDiag (aTHX_ xse)
static SV *cx_SvDiag (pTHX_ int xse) {
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

/* This function should be altered to deal with the optional extra argument
 * that holds the replacement message */
#define SetDiag(csv,xse)	cx_SetDiag (aTHX_ csv, xse, __LINE__)
#define SetDiagL(csv,xse,line)	cx_SetDiag (aTHX_ csv, xse, line)
static SV *cx_SetDiag (pTHX_ csv_t *csv, int xse, int line) {
    dSP;
    SV *err   = SvDiag (xse);
    SV *pself = csv->pself;

    last_error = xse;
	(void)hv_store (csv->self, "_ERROR_DIAG",  11, err,          0);
    if (xse == 0) {
	(void)hv_store (csv->self, "_ERROR_POS",   10, newSViv  (0), 0);
	(void)hv_store (csv->self, "_ERROR_FLD",   10, newSViv  (0), 0);
	(void)hv_store (csv->self, "_ERROR_INPUT", 12, &PL_sv_undef, 0);
	csv->has_error_input = 0;
	}
    if (line)
	(void)hv_store (csv->self, "_ERROR_SRC",   10, newSViv  (line), 0);
    if (xse == 2012) /* EOF */
	(void)hv_store (csv->self, "_EOF",          4, &PL_sv_yes,   0);
    if (csv->auto_diag) {
	unless (_is_hashref (pself))
	    pself = newRV_inc ((SV *)csv->self);
	ENTER;
	PUSHMARK (SP);
	XPUSHs (pself);
	PUTBACK;
	call_pv ("Text::CSV_XS::error_diag", G_VOID | G_DISCARD);
	LEAVE;
	unless (pself == csv->pself)
	    sv_free (pself);
	}
    return (err);
    } /* SetDiag */

#define xs_cache_get_eolt(hv)	cx_xs_cache_get_eolt (aTHX_ hv)
static char *cx_xs_cache_get_eolt (pTHX_ HV *hv) {
    SV    **svp;
    csv_t  *csvs;

    unless ((svp = hv_fetchs (hv, "_CACHE", FALSE)) && *svp)
	return NULL;

    csvs = (csv_t *)SvPV_nolen (*svp);
    if (csvs->eol_type == EOL_TYPE_NL)		return "\n";
    if (csvs->eol_type == EOL_TYPE_CR)		return "\r";
    if (csvs->eol_type == EOL_TYPE_CRNL)	return "\r\n";
    if (csvs->eol_type == EOL_TYPE_OTHER)	return (char *)(csvs->eol);
    return NULL;
    } /* cx_xs_cache_get_eolt */

#define xs_cache_set(hv,idx,val)	cx_xs_cache_set (aTHX_ hv, idx, val)
static void cx_xs_cache_set (pTHX_ HV *hv, int idx, SV *val) {
    SV    **svp;
    byte   *cache;

    csv_t   csvs;
    csv_t  *csv = &csvs;

    IV      iv;
    byte    bv;
    char   *cp  = "\0";
    STRLEN  len = 0;

    unless ((svp = hv_fetchs (hv, "_CACHE", FALSE)) && *svp)
	return;

    cache = (byte *)SvPV_nolen (*svp);
    (void)memcpy (csv, cache, sizeof (csv_t));

    if (SvPOK (val))
	cp = SvPV (val, len);
    if (SvIOK (val))
	iv = SvIV (val);
    else if (SvNOK (val))	/* Needed for 5.6.x but safe for 5.8.x+ */
	iv = (IV)SvNV (val);	/* uncoverable statement ancient perl required */
    else
	iv = *cp;
    bv = (unsigned)iv & 0xff;

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
	case CACHE_ID_binary:                csv->binary                = bv; break;
	case CACHE_ID_keep_meta_info:        csv->keep_meta_info        = bv; break;
	case CACHE_ID_always_quote:          csv->always_quote          = bv; break;
	case CACHE_ID_quote_empty:           csv->quote_empty           = bv; break;
	case CACHE_ID_quote_space:           csv->quote_space           = bv; break;
	case CACHE_ID_escape_null:           csv->escape_null           = bv; break;
	case CACHE_ID_quote_binary:          csv->quote_binary          = bv; break;
	case CACHE_ID_decode_utf8:           csv->decode_utf8           = bv; break;
	case CACHE_ID_allow_loose_escapes:   csv->allow_loose_escapes   = bv; break;
	case CACHE_ID_allow_loose_quotes:    csv->allow_loose_quotes    = bv; break;
	case CACHE_ID_allow_unquoted_escape: csv->allow_unquoted_escape = bv; break;
	case CACHE_ID_allow_whitespace:      csv->allow_whitespace      = bv; break;
	case CACHE_ID_blank_is_undef:        csv->blank_is_undef        = bv; break;
	case CACHE_ID_empty_is_undef:        csv->empty_is_undef        = bv; break;
	case CACHE_ID_formula:               csv->formula               = bv; break;
	case CACHE_ID_strict:                csv->strict                = bv; break;
	case CACHE_ID_verbatim:              csv->verbatim              = bv; break;
	case CACHE_ID_strict_eol:            csv->strict_eol            = bv; break;
	case CACHE_ID_eol_type:              csv->eol_type              = bv; break;
	case CACHE_ID_skip_empty_rows:       csv->skip_empty_rows       = bv; break;
	case CACHE_ID_auto_diag:             csv->auto_diag             = bv; break;
	case CACHE_ID_diag_verbose:          csv->diag_verbose          = bv; break;
	case CACHE_ID__has_ahead:            csv->has_ahead             = bv; break;
	case CACHE_ID__has_hooks:            csv->has_hooks             = bv; break;
	case CACHE_ID_has_error_input:       csv->has_error_input       = bv; break;

	/* a 4-byte IV */
	case CACHE_ID__is_bound:             csv->is_bound              = iv; break;

	/* string */
	case CACHE_ID_sep:
	    (void)memcpy (csv->sep, cp, len);
	    csv->sep_len = len == 1 ? 0 : len;
	    break;

	case CACHE_ID_quo:
	    (void)memcpy (csv->quo, cp, len);
	    csv->quo_len = len == 1 ? 0 : len;
	    break;

	case CACHE_ID_eol:
	    (void)memcpy (csv->eol, cp, len);
	    csv->eol_len   =  len;
	    csv->eol_type  =  len == 0                 ? EOL_TYPE_UNDEF
	                    : len == 1 && *cp == CH_NL ? EOL_TYPE_NL
	                    : len == 1 && *cp == CH_CR ? EOL_TYPE_CR
	                    : len == 2 && *cp == CH_CR
	                             && cp[1] == CH_NL ? EOL_TYPE_CRNL
	                    :                            EOL_TYPE_OTHER;
	    csv->strict_eol &= 0x3F;
	    csv->eol_is_cr = csv->eol_type == EOL_TYPE_CR ? 1 : 0;
#if MAINT_DEBUG_EOL > 0
	    (void)fprintf (stderr, "# %04d cache set eol: '%s'\t(len: %d, is_cr: %d, tp: %02x)\n",
		__LINE__, _pretty_str (cp, len), len, csv->eol_is_cr, csv->eol_type);
#endif
	    break;

	case CACHE_ID_undef_str:
	    if (*cp) {
		csv->undef_str = (byte *)cp;
		if (SvUTF8 (val))
		    csv->undef_flg = 3;
		}
	    else {
		csv->undef_str = NULL;
		csv->undef_flg = 0;
		}
	    break;

	case CACHE_ID_comment_str:
	    csv->comment_str = *cp ? (byte *)cp : NULL;
	    break;

	case CACHE_ID_types:
	    if (cp && len) {
		csv->types     = cp;
		csv->types_len = len;
		}
	    else {
		csv->types     = NULL;
		csv->types_len = 0;
		}
	    break;

	default:
	    warn ("Unknown cache index %d ignored\n", idx);
	}

    csv->cache = cache;
    (void)memcpy (cache, csv, sizeof (csv_t));
    } /* cache_set */

#define _cache_show_byte(trim,c) \
    warn ("  %-21s  %02x:%3d\n", trim, c, c)
#define _cache_show_char(trim,c) \
    warn ("  %-21s  %02x:%s\n",  trim, c, _pretty_str (&c, 1))
#define _cache_show_str(trim,l,str) \
    warn ("  %-21s %3d:%s\n",  trim, l, _pretty_str (str, l))

#define _csv_diag(csv)	_xs_csv_diag (aTHX_ csv)
static void _xs_csv_diag (pTHX_ csv_t *csv) {
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
    _cache_show_byte ("quote_empty",		csv->quote_empty);
    _cache_show_byte ("quote_space",		csv->quote_space);
    _cache_show_byte ("escape_null",		csv->escape_null);
    _cache_show_byte ("quote_binary",		csv->quote_binary);
    _cache_show_byte ("auto_diag",		csv->auto_diag);
    _cache_show_byte ("diag_verbose",		csv->diag_verbose);
    _cache_show_byte ("formula",		csv->formula);
    _cache_show_byte ("strict",			csv->strict);
    _cache_show_byte ("strict_n",		csv->strict_n);
    _cache_show_byte ("strict_eol",		csv->strict_eol);
    _cache_show_byte ("eol_type",		csv->eol_type);
    _cache_show_byte ("skip_empty_rows",	csv->skip_empty_rows);
    _cache_show_byte ("has_error_input",	csv->has_error_input);
    _cache_show_byte ("blank_is_undef",		csv->blank_is_undef);
    _cache_show_byte ("empty_is_undef",		csv->empty_is_undef);
    _cache_show_byte ("has_ahead",		csv->has_ahead);
    _cache_show_byte ("keep_meta_info",		csv->keep_meta_info);
    _cache_show_byte ("verbatim",		csv->verbatim);

    _cache_show_byte ("useIO",			csv->useIO);
    _cache_show_byte ("has_hooks",		csv->has_hooks);
    _cache_show_byte ("eol_is_cr",		csv->eol_is_cr);
    _cache_show_byte ("eol_len",		csv->eol_len);
    _cache_show_str  ("eol",      csv->eol_len,	csv->eol);
    _cache_show_byte ("sep_len",		csv->sep_len);
    if (csv->sep_len > 1)
	_cache_show_str ("sep",   csv->sep_len,	csv->sep);
    _cache_show_byte ("quo_len",		csv->quo_len);
    if (csv->quo_len > 1)
	_cache_show_str ("quote", csv->quo_len,	csv->quo);
    if (csv->types_len)
	_cache_show_str ("types", csv->types_len, (byte *)csv->types);
    else
	_cache_show_str ("types", 0, (byte *)"");

    if (csv->bptr)
	_cache_show_str ("bptr", (int)strlen (csv->bptr), (byte *)csv->bptr);
    if (csv->tmp && SvPOK (csv->tmp)) {
	char *s = SvPV_nolen (csv->tmp);
	_cache_show_str ("tmp",  (int)strlen (s), (byte *)s);
	}
    if (csv->cache)
	warn ("  %-20s %4d:0x%08lx\n", "cache", (int)sizeof (csv_t), (unsigned long)csv->cache);
    else
	warn ("  %-22s --:no cache yet\n", "cache");
    } /* _csv_diag */

#define xs_cache_diag(hv)	cx_xs_cache_diag (aTHX_ hv)
static void cx_xs_cache_diag (pTHX_ HV *hv) {
    SV   **svp;
    byte  *cache;
    csv_t  csvs;
    csv_t *csv = &csvs;

    unless ((svp = hv_fetchs (hv, "_CACHE", FALSE)) && *svp) {
	warn ("CACHE: invalid\n");
	return;
	}

    cache = (byte *)SvPV_nolen (*svp);
    (void)memcpy (csv, cache, sizeof (csv_t));
    _csv_diag (csv);
    } /* xs_cache_diag */

#define set_eol_is_cr(csv)	cx_set_eol_is_cr (aTHX_ csv)
static void cx_set_eol_is_cr (pTHX_ csv_t *csv) {
    csv->eol_is_cr = 1;
    csv->eol_len   = 1;
    csv->eol[0]    = CH_CR;
    csv->eol_type  = EOL_TYPE_CR;
    (void)memcpy (csv->cache, csv, sizeof (csv_t));

    (void)hv_store (csv->self, "eol",  3, newSVpvn ((char *)csv->eol, 1), 0);
#if MAINT_DEBUG_EOL > 0
    (void)fprintf (stderr, "# %04d set eol is CR: '%s'\t(len: %d, is_cr: %d, tp: %02x)\n",
	__LINE__, _pretty_str (csv->eol, csv->eol_len), csv->eol_len, csv->eol_is_cr, csv->eol_type);
#endif
    } /* set_eol_is_cr */

#define SetupCsv(csv,self,pself)	cx_SetupCsv (aTHX_ csv, self, pself)
static void cx_SetupCsv (pTHX_ csv_t *csv, HV *self, SV *pself) {
    SV	       **svp;
    STRLEN	 len;
    char	*ptr;

    last_error = 0;

    if ((svp = hv_fetchs (self, "_CACHE", FALSE)) && *svp) {
	byte *cache = (byte *)SvPVX (*svp);
	(void)memcpy (csv, cache, sizeof (csv_t));
	}
    else {
	SV *sv_cache;

	(void)memset (csv, 0, sizeof (csv_t)); /* Reset everything */

	csv->self  = self;
	csv->pself = pself;

	CH_SEP = ',';
	if ((svp = hv_fetchs (self, "sep_char",       FALSE)) && *svp && SvOK (*svp))
	    CH_SEP = *SvPV (*svp, len);
	if ((svp = hv_fetchs (self, "sep",            FALSE)) && *svp && SvOK (*svp)) {
	    ptr = SvPV (*svp, len);
	    (void)memcpy (csv->sep, ptr, len);
	    if (len > 1)
		csv->sep_len = len;
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
	    (void)memcpy (csv->quo, ptr, len);
	    if (len > 1)
		csv->quo_len = len;
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
	    (void)memcpy (csv->eol, eol, len);
	    csv->eol_len = len;
	    if (len == 1 && *eol == CH_CR) {
		csv->eol_is_cr = 1;
		csv->eol_type  = EOL_TYPE_CR;
		}
	    else if (len == 1 && *eol == CH_NL)
		csv->eol_type  = EOL_TYPE_NL;
	    else if (len == 2 && *eol == CH_CR && eol[1] == CH_NL)
		csv->eol_type  = EOL_TYPE_CRNL;
	    }

	csv->undef_flg = 0;
	if ((svp = hv_fetchs (self, "undef_str",      FALSE)) && *svp && SvOK (*svp)) {
		/*if (sv && (SvOK (sv) || (
			(SvGMAGICAL (sv) && (mg_get (sv), 1) && SvOK (sv))))) {*/
	    csv->undef_str = (byte *)SvPV_nolen (*svp);
	    if (SvUTF8 (*svp))
		csv->undef_flg = 3;
	    }
	else
	    csv->undef_str = NULL;

	if ((svp = hv_fetchs (self, "comment_str",    FALSE)) && *svp && SvOK (*svp))
	    csv->comment_str = (byte *)SvPV_nolen (*svp);
	else
	    csv->comment_str = NULL;

	if ((svp = hv_fetchs (self, "_types",         FALSE)) && *svp && SvOK (*svp)) {
	    csv->types = SvPV (*svp, len);
	    csv->types_len = len;
	    }

	if ((svp = hv_fetchs (self, "_is_bound",      FALSE)) && *svp && SvOK (*svp))
	    csv->is_bound = SvIV (*svp);
	if ((svp = hv_fetchs (self, "callbacks",      FALSE)) && _is_hashref (*svp)) {
	    HV *cb = (HV *)SvRV (*svp);
	    if ((svp = hv_fetchs (cb, "after_parse",  FALSE)) && _is_coderef (*svp))
		csv->has_hooks |= HOOK_AFTER_PARSE;
	    if ((svp = hv_fetchs (cb, "before_print", FALSE)) && _is_coderef (*svp))
		csv->has_hooks |= HOOK_BEFORE_PRINT;
	    }

	csv->binary			= bool_opt ("binary");
	csv->decode_utf8		= bool_opt ("decode_utf8");
	csv->always_quote		= bool_opt ("always_quote");
	csv->strict			= bool_opt ("strict");
	csv->strict_eol			= num_opt  ("strict_eol");
	csv->quote_empty		= bool_opt ("quote_empty");
	csv->quote_space		= bool_opt_def ("quote_space",  1);
	csv->escape_null		= bool_opt_def ("escape_null",  1);
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
	csv->keep_meta_info		= num_opt ("keep_meta_info");
	csv->skip_empty_rows		= num_opt ("skip_empty_rows");
	csv->formula			= num_opt ("formula");

	unless (csv->escape_char) csv->escape_null = 0;

	sv_cache = newSVpvn ((char *)csv, sizeof (csv_t));
	csv->cache = (byte *)SvPVX (sv_cache);
	SvREADONLY_on (sv_cache);

	(void)memcpy (csv->cache, csv, sizeof (csv_t));

	(void)hv_store (self, "_CACHE", 6, sv_cache, 0);
	}

    csv->utf8 = 0;
    csv->size = 0;
    csv->used = 0;

    /* This is EBCDIC-safe, as it is used after translation */
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
    if (csv->eol_type > 0 && csv->strict_eol > 0 && !*csv->eol)
	csv->eol_is_cr = 0;
#if MAINT_DEBUG_EOL > 0
    (void)fprintf (stderr, "# %04d setup eol: '%s'\t(len: %d, is_cr: %d, x: %d, pos: %d, tp: %02x)\n",
	__LINE__, _pretty_str (csv->eol, csv->eol_len), csv->eol_len, csv->eol_is_cr, csv->eolx, csv->eol_pos, csv->eol_type);
#endif
    if (csv->sep_len > 1 && is_utf8_string ((U8 *)(csv->sep), csv->sep_len))
	csv->utf8 = 1;
    if (csv->quo_len > 1 && is_utf8_string ((U8 *)(csv->quo), csv->quo_len))
	csv->utf8 = 1;

    if (csv->strict
	  && !csv->strict_n
	  && (svp = hv_fetchs (self, "_COLUMN_NAMES", FALSE))
	  && _is_arrayref (*svp))
	csv->strict_n = av_len ((AV *)(SvRV (*svp)));
    } /* SetupCsv */

#define Print(csv,dst)		cx_Print (aTHX_ csv, dst)
static int cx_Print (pTHX_ csv_t *csv, SV *dst) {
    int result;
    int keep = 0;

    if (csv->useIO) {
	SV *tmp = newSVpvn_flags (csv->buffer, csv->used, SVs_TEMP);
	dSP;
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
	result = call_sv (m_print, G_METHOD);
	SPAGAIN;
	if (result) {
	    result = POPi;
	    unless (result)
		(void)SetDiag (csv, 2200);
	    }
	PUTBACK;
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
static SV *cx_bound_field (pTHX_ csv_t *csv, SSize_t i, int keep) {
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
		SvSetEmpty (sv);
		return (sv);
		}
	    }
	}
    (void)SetDiag (csv, 3008);
    return (NULL);
    } /* bound_field */

#define was_quoted(mf,idx)	cx_was_quoted (aTHX_ mf, idx)
static int cx_was_quoted (pTHX_ AV *mf, int idx) {
    SV **x = av_fetch (mf, idx, FALSE);
    return (x && SvIOK (*x) && SvIV (*x) & CSV_FLAGS_QUO ? 1 : 0);
    } /* was_quoted */

#define _formula(csv,sv,len,f) cx_formula (aTHX_ csv, sv, len, f)
static char *cx_formula (pTHX_ csv_t *csv, SV *sv, STRLEN *len, int f) {

    int fa = csv->formula;

    if (fa == 1) die   ("Formulas are forbidden\n");
    if (fa == 2) croak ("Formulas are forbidden\n");

    if (fa == 3) {
	char *ptr = SvPV_nolen (sv);
	char  rec[40];
	char  field[128];
	SV  **svp;

	if (csv->recno) (void)sprintf (rec, " in record %lu", csv->recno + 1);
	else           *rec = (char)0;

	*field = (char)0;
	if ((svp = hv_fetchs (csv->self, "_COLUMN_NAMES", FALSE)) && _is_arrayref (*svp)) {
	    AV *avp = (AV *)SvRV (*svp);
	    if (avp && av_len (avp) >= (f - 1)) {
		SV **fnm = av_fetch (avp, f - 1, FALSE);
		if (fnm && *fnm && SvOK (*fnm))
		    (void)sprintf (field, " (column: '%.100s')", SvPV_nolen (*fnm));
		}
	    }

	warn ("Field %d%s%s contains formula '%s'\n", f, field, rec, ptr);
	return ptr;
	}

    if (len) *len = 0;

    if (fa == 4) {
	unless (SvREADONLY (sv)) SvSetEmpty (sv);
	return "";
	}

    if (fa == 5) {
	unless (SvREADONLY (sv)) SvSetUndef (sv);
	return NULL;
	}

    if (fa == 6) {
	int result;
	SV **svp = hv_fetchs (csv->self, "_FORMULA_CB", FALSE);
	if (svp && _is_coderef (*svp)) {
	    dSP;
	    ENTER;
	    SAVE_DEFSV; /* local $_ */
	    DEFSV = sv;
	    PUSHMARK (SP);
	    PUTBACK;
	    result = call_sv (*svp, G_SCALAR);
	    SPAGAIN;
	    if (result)
		sv_setsv (sv, POPs);
	    PUTBACK;
	    LEAVE;
	    }
	return len ? SvPV (sv, *len) : SvPV_nolen (sv);
	}

    /* So far undefined behavior */
    return NULL;
    } /* _formula */

#define SkipEmptyRow	{\
    int ser = csv->skip_empty_rows;					\
									\
    if (ser == 3) { (void)SetDiag (csv, 2015); die   ("Empty row"); }	\
    if (ser == 4) { (void)SetDiag (csv, 2015); croak ("Empty row"); }	\
    if (ser == 5) { (void)SetDiag (csv, 2015); return FALSE;        }	\
									\
    if (ser <= 2) {	/* skip & eof */				\
	csv->fld_idx = 0;						\
	c = CSV_GET;							\
	if (c == EOF || ser == 2) {					\
	    sv_free (sv);						\
	    sv = NULL;							\
	    seenSomething = FALSE;						\
	    if (ser == 2) return FALSE;					\
	    break;							\
	    }								\
	}								\
									\
    if (ser == 6) {							\
	int  result, n, i;						\
	SV  *rv, **svp = hv_fetchs (csv->self, "_EMPTROW_CB", FALSE);	\
	AV  *avp;							\
	unless (svp && _is_coderef (*svp))				\
	    return FALSE; /* A callback is wanted, but none found */	\
									\
	dSP;								\
	ENTER;								\
	SAVE_DEFSV; /* local $_ */					\
	DEFSV = sv;							\
	PUSHMARK (SP);							\
	PUTBACK;							\
	result = call_sv (*svp, G_SCALAR);				\
	SPAGAIN;							\
	unless (result) {						\
	    /* A false return will stop the parsing */			\
	    sv_free (sv);						\
	    sv = NULL;							\
	    waitingForField = 0;					\
	    return FALSE;						\
	    }								\
									\
	PUTBACK;							\
	LEAVE;								\
									\
	rv = POPs;							\
	/* Result should be a ref to a list. */				\
	unless (_is_arrayref (rv))					\
	    return FALSE;						\
									\
	avp = (AV *)SvRV (rv);						\
									\
	unless (avp) return FALSE;					\
	n = av_len (avp);						\
	if (n <= 0)  return TRUE;					\
									\
	if (csv->is_bound && csv->is_bound < n)				\
	    n = csv->is_bound - 1;					\
									\
	for (i = 0; i <= n; i++) {					\
	    SV **svp = av_fetch (avp, i, FALSE);			\
	    sv = svp && *svp ? *svp : NULL;				\
	    if (sv) {							\
		SvREFCNT_inc (sv);					\
		/* upgrade IV to IVPV if needed */			\
		(void)SvPV_nolen (sv);					\
		}							\
	    AV_PUSH;							\
	    }								\
	return TRUE;							\
	}								\
    }

#define Combine(csv,dst,fields)	cx_Combine (aTHX_ csv, dst, fields)
static int cx_Combine (pTHX_ csv_t *csv, SV *dst, AV *fields) {
    SSize_t i, n;
    int     bound = 0;
    int     aq  = (int)csv->always_quote;
    int     qe  = (int)csv->quote_empty;
    int     kmi = (int)csv->keep_meta_info;
    AV     *qm  = NULL;

    n = (IV)av_len (fields);
    if (n < 0 && csv->is_bound) {
	n = csv->is_bound - 1;
	bound = 1;
	}

    if (kmi >= 10) {
	SV **svp;
	if ((svp = hv_fetchs (csv->self, "_FFLAGS", FALSE)) && _is_arrayref (*svp)) {
	    AV *avp = (AV *)SvRV (*svp);
	    if (avp && av_len (avp) >= n)
		qm = avp;
	    }
	}

    for (i = 0; i <= n; i++) {
	SV     *sv;
	STRLEN  len = 0;
	char   *ptr = NULL;

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
	    SV **svp = av_fetch (fields, i, FALSE);
	    sv = svp && *svp ? *svp : NULL;
	    }

	if (sv && (SvOK (sv) || (
		(SvGMAGICAL (sv) && (mg_get (sv), 1) && SvOK (sv))))) {

	    int	    quoteMe;

	    ptr = SvPV (sv, len);

	    if (*ptr == '=' && csv->formula) {
		unless (ptr = _formula (csv, sv, &len, i))
		    continue;
		}
	    if (len == 0)
		quoteMe = aq ? 1 : qe ? 1 : qm ? was_quoted (qm, i) : 0;
	    else {

		if (SvUTF8 (sv))  {
		    csv->utf8   = 1;
		    csv->binary = 1;
		    }

		quoteMe = aq ? 1 : qm ? was_quoted (qm, i) : 0;

		/* Do we need quoting? We do quote, if the user requested
		 * (always_quote), if binary or blank characters are found
		 * and if the string contains quote or escape characters.
		 */
		if (!quoteMe &&
		   ( quoteMe = (!SvIOK (sv) && !SvNOK (sv) && CH_QUOTE))) {
		    char	*ptr2;
		    STRLEN	 l;

#if MAINT_DEBUG > 6
		    (void)fprintf (stderr, "# %04d Combine:\n", __LINE__);
		    sv_dump (sv);
#else
#if MAINT_DEBUG > 4
		    (void)fprintf (stderr, "# %04d Combine: '%s'\n", __LINE__, _pretty_sv (sv));
#endif
#endif
		    for (ptr2 = ptr, l = len; l; ++ptr2, --l) {
			byte c = *ptr2;
#ifdef IS_EBCDIC
			byte x = ebcdic2ascii[c];
#if MAINT_DEBUG > 4
			(void)fprintf (stderr, " %02x", x);
#endif
#else
			byte x = c;
#endif

			if ((CH_QUOTE          && c == CH_QUOTE)          ||
			    (CH_SEP            && c == CH_SEP)            ||
			    (csv->escape_char  && c == csv->escape_char)  ||
			    (csv->quote_binary ? (x >= 0x7f && x <= 0xa0) ||
						  x < csv->first_safe_char
					       :  c == CH_NL || c == CH_CR ||
						 (csv->quote_space && (
						  c == CH_SPACE || c == CH_TAB)))) {
			    /* Binary character */
			    break;
			    }
			}
#if defined(IS_EBCDIC) && MAINT_DEBUG > 4
		    (void)fprintf (stderr, "\n");
#endif
		    quoteMe = (l > 0);
		    }
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
			SvREFCNT_dec (sv); /* uncoverable statement memory fail */
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
		if (c == (char)0          && csv->escape_null) {
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
	else {
	    if (csv->undef_str) {
		byte  *ptr = csv->undef_str;
		STRLEN len = strlen ((char *)ptr);

		if (csv->undef_flg) {
		    csv->utf8   = 1;
		    csv->binary = 1;
		    }

		while (len--)
		    CSV_PUT (csv, dst, *ptr++);
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

#if MAINT_DEBUG > 6
#define ErrorDiag(csv)	cx_ErrorDiag (aTHX_ csv)
static void cx_ErrorDiag (pTHX_ csv_t *csv) {
    SV **svp;

    if ((svp = hv_fetchs (csv->self, "_ERROR_DIAG", FALSE)) && *svp) {
	if (SvIOK (*svp)) (void)fprintf (stderr, "ERR: %d\n", SvIV (*svp));
	if (SvPOK (*svp)) (void)fprintf (stderr, "ERR: %s\n", SvPV_nolen (*svp));
	}
    if ((svp = hv_fetchs (csv->self, "_ERROR_POS", FALSE)) && *svp) {
	if (SvIOK (*svp)) (void)fprintf (stderr, "POS: %d\n", SvIV (*svp));
	}
    if ((svp = hv_fetchs (csv->self, "_ERROR_FLD", FALSE)) && *svp) {
	if (SvIOK (*svp)) (void)fprintf (stderr, "FLD: %d\n", SvIV (*svp));
	}
    if ((svp = hv_fetchs (csv->self, "_ERROR_SRC", FALSE)) && *svp) {
	if (SvIOK (*svp)) (void)fprintf (stderr, "SRC: XS#%d\n", SvIV (*svp));
	}
    } /* ErrorDiag */
#endif

#define ParseError(csv,xse,pos)	cx_ParseError (aTHX_ csv, xse, pos, __LINE__)
static void cx_ParseError (pTHX_ csv_t *csv, int xse, STRLEN pos, int line) {
    (void)hv_store (csv->self, "_ERROR_POS", 10, newSViv (pos), 0);
    (void)hv_store (csv->self, "_ERROR_FLD", 10, newSViv (csv->fld_idx), 0);
    if (csv->tmp) {
	csv->has_error_input = 1;
	if (hv_store (csv->self, "_ERROR_INPUT", 12, csv->tmp, 0))
	    SvREFCNT_inc (csv->tmp);
	}
    (void)SetDiagL (csv, xse, line);
    } /* ParseError */

#define CsvGet(csv,src)		cx_CsvGet (aTHX_ csv, src)
static int cx_CsvGet (pTHX_ csv_t *csv, SV *src) {
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

	PUSHMARK (sp);
	EXTEND (sp, 1);
	PUSHs (src);
	PUTBACK;
	result = call_sv (m_getline, G_METHOD);
	SPAGAIN;
	csv->eol_pos = -1;
	csv->tmp = result ? POPs : NULL;
	PUTBACK;

#if MAINT_DEBUG > 6
	(void)fprintf (stderr, "# %04d getline () returned:\n", __LINE__);
	sv_dump (csv->tmp);
#else
#if MAINT_DEBUG > 4
	(void)fprintf (stderr, "# %04d getline () returned: '%s'\n", __LINE__, _pretty_sv (csv->tmp));
#endif
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
#if MAINT_DEBUG > 4 || MAIN_DEBUG_EOL > 0
		(void)fprintf (stderr, "# %04d EOLX match, size: %d\n", __LINE__, csv->size);
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
    unless (csv->is_bound) SvREFCNT_dec (sv);	\
    ParseError (csv, diag_code, csv->used - 1);	\
    return FALSE;				\
    }
#define ERROR_INSIDE_FIELD(diag_code) {		\
    unless (csv->is_bound) SvREFCNT_dec (sv);	\
    ParseError (csv, diag_code, csv->used - 1);	\
    return FALSE;				\
    }
#define ERROR_EOL {				\
    unless (csv->strict_eol & 0x40)		\
	ParseError (csv, 2016, csv->used - 1);	\
    if (csv->strict_eol & 0x0e) {		\
	if (!csv->is_bound) SvREFCNT_dec (sv);	\
	return FALSE;				\
	}					\
    csv->strict_eol |= 0x40;			\
    }

#if MAINT_DEBUG > 4
#define PUT_RPT       (void)fprintf (stderr, "# %04d CSV_PUT: 0x%02x '%c'\n", __LINE__, c, isprint (c) ? c : '?')
#define PUT_SEPX_RPT1 (void)fprintf (stderr, "# %04d PUT SEPX\n", __LINE__)
#define PUT_SEPX_RPT2 (void)fprintf (stderr, "# %04d Done putting SEPX\n")
#define PUT_QUOX_RPT1 (void)fprintf (stderr, "# %04d PUT QUOX\n", __LINE__)
#define PUT_QUOX_RPT2 (void)fprintf (stderr, "# %04d Done putting QUOX\n")
#define PUT_EOLX_RPT1 (void)fprintf (stderr, "# %04d PUT EOLX\n", __LINE__)
#define PUT_EOLX_RPT2 (void)fprintf (stderr, "# %04d Done putting EOLX\n")
#if MAINT_DEBUG > 6
#define PUSH_RPT      (void)fprintf (stderr, "# %04d AV_PUSHd\n", __LINE__); sv_dump (sv)
#else
#define PUSH_RPT      (void)fprintf (stderr, "# %04d AV_PUSHd '%s'\n", __LINE__, _pretty_sv (sv))
#endif
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

#define CSV_GET1 \
    (csv->used < csv->size ? (byte)csv->bptr[csv->used++] : CsvGet (csv, src))

#if MAINT_DEBUG > 3
int CSV_GET_ (pTHX_ csv_t *csv, SV *src, int l) {
    int c;
    (void)fprintf (stderr, "# %04d 1-CSV_GET: (used: %d, size: %d, eol_pos: %d, eolx = %d)\n", l, csv->used, csv->size, csv->eol_pos, csv->eolx);
    c = CSV_GET1;
    (void)fprintf (stderr, "# %04d 2-CSV_GET: 0x%02x '%c'\n", l, c, isprint (c) ? c : '?');
    return (c);
    } /* CSV_GET_ */
#define CSV_GET CSV_GET_ (aTHX_ csv, src, __LINE__)
#else
#define CSV_GET CSV_GET1
#endif

#define AV_PUSH { \
    int svc;								\
    *SvEND (sv) = (char)0;						\
    svc = SvCUR (sv);							\
    SvUTF8_off (sv);							\
    if (svc && csv->formula && *(SvPV_nolen (sv)) == '=')		\
	(void)_formula (csv, sv, NULL, fnum);				\
    if (svc == 0 && (							\
	    csv->empty_is_undef ||					\
	    (!(f & CSV_FLAGS_QUO) && csv->blank_is_undef)))		\
	SvSetUndef (sv);						\
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
static void cx_strip_trail_whitespace (pTHX_ SV *sv) {
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
	    sv = bound_field (csv, fnum, 0);	\
	else					\
	    sv = newSVpvs ("");			\
	fnum++;					\
	unless (sv) return FALSE;		\
	f = 0; csv->fld_idx++; c0 = 0;		\
	}

#if MAINT_DEBUG
static char str_parsed[40];
#endif

#if MAINT_DEBUG > 1
static char _sep[64];
static char *_sep_string (csv_t *csv) {
    if (csv->sep_len) {
	int x;
	for (x = 0; x < csv->sep_len; x++)
	    (void)sprintf (_sep + x * x, "%02x ", csv->sep[x]);
	}
    else
	(void)sprintf (_sep, "'%c' (0x%02x)", CH_SEP, CH_SEP);
    return _sep;
    } /* _sep_string */
#endif

#define Parse(csv,src,fields,fflags)	cx_Parse (aTHX_ csv, src, fields, fflags)
static int cx_Parse (pTHX_ csv_t *csv, SV *src, AV *fields, AV *fflags) {
    int		 c, c0, f = 0;
    int		 waitingForField	= 1;
    SV		*sv			= NULL;
    STRLEN	 len;
    int		 seenSomething		= FALSE;
    int		 fnum			= 0;
    int		 spl			= -1;
#if MAINT_DEBUG
    (void)memset (str_parsed, 0, 40);
#endif

    csv->fld_idx = 0;

    while ((c = CSV_GET) != EOF) {

	NewField;

	seenSomething = TRUE;
	spl++;
#if MAINT_DEBUG
	if (spl < 39) str_parsed[spl] = c;
#endif
restart:
#if MAINT_DEBUG > 9
	(void)fprintf (stderr, "# %04d at restart: %d/%d/%03x pos %d = 0x%02x\n",
	    __LINE__, waitingForField ? 1 : 0, sv ? 1 : 0, f, spl, c);
#endif
	if (is_SEP (c)) {
#if MAINT_DEBUG > 1
	    (void)fprintf (stderr, "# %04d %d/%d/%03x pos %d = SEP %s\t%s\n",
		__LINE__, waitingForField ? 1 : 0, sv ? 1 : 0, f, spl,
		_sep_string (csv), _pretty_strl (csv->bptr + csv->used));
#endif
	    if (waitingForField) {
		/* ,1,"foo, 3",,bar,
		 * ^           ^
		 */
		if (csv->blank_is_undef || csv->empty_is_undef)
		    SvSetUndef (sv);
		else
		    SvSetEmpty (sv);
		unless (csv->is_bound)
		    av_push (fields, sv);
		sv = NULL;
		if (csv->keep_meta_info && fflags)
		    av_push (fflags, newSViv (f));
		}
	    else
	    if (f & CSV_FLAGS_QUO) {
		/* ,1,"foo, 3",,bar,
		 *        ^
		 */
		CSV_PUT_SV (c)
		}
	    else {
		/* ,1,"foo, 3",,bar,
		 *   ^        ^    ^
		 */
		AV_PUSH;
		}
	    } /* SEP char */
	else
	if (is_QUOTE (c)) {
#if MAINT_DEBUG > 1
	    (void)fprintf (stderr, "# %04d %d/%d/%03x pos %d = QUO '%c'\t\t%s\n",
		__LINE__, waitingForField ? 1 : 0, sv ? 1 : 0, f, spl, c,
		_pretty_strl (csv->bptr + csv->used));
#endif
	    if (waitingForField) {
		/* ,1,"foo, 3",,bar,\r\n
		 *    ^
		 */
		f |= CSV_FLAGS_QUO;
		waitingForField = 0;
		continue;
		}

	    if (f & CSV_FLAGS_QUO) {

		/* ,1,"foo, 3",,bar,\r\n
		 *           ^
		 */

		int quoesc = 0;
		int c2 = CSV_GET;

		if (csv->allow_whitespace) {
		    /* , 1 , "foo, 3" , , bar , \r\n
		     *               ^
		     */
		    while (is_whitespace (c2)) {
			if (csv->allow_loose_quotes &&
				!(csv->escape_char && c2 == csv->escape_char)) {
			    /* This feels like a brittle fix for RT115953, where
			     *  ["foo "bar" baz"] got parsed as [foo "bar"baz]
			     * when both allow_whitespace and allow_loose_quotes
			     * are true and escape does not equal quote
			     */
			    CSV_PUT_SV (c);
			    c = c2;
			    }
			c2 = CSV_GET;
			}
		    }

		if (is_SEP (c2)) {
		    /* ,1,"foo, 3",,bar,\r\n
		     *            ^
		     */
		    AV_PUSH;
		    continue;
		    }

		if (c2 == CH_NL || c2 == CH_EOLX) {
		    unsigned short eolt = EOL_TYPE (c2);
		    /* ,1,"foo, 3",,"bar"\n
		     *                   ^
		     */
#if MAINT_DEBUG_EOL > 0
    (void)fprintf (stderr, "# %04d parse eol NL/EOLX: '%s'\t(len: %d, is_cr: %d, x: %d, pos: %d, tp: %02x, c: %d, c2: %d)\n",
	__LINE__, _pretty_str (csv->eol, csv->eol_len), csv->eol_len, csv->eol_is_cr, csv->eolx, csv->eol_pos, csv->eol_type, c, c2);
#endif
		    if (csv->strict_eol && csv->eol_type && csv->eol_type != eolt)
			ERROR_EOL;
		    SET_EOL_TYPE (csv, eolt);

		    AV_PUSH;
		    return TRUE;
		    }

		/* ---
		 * if      QUOTE eq ESCAPE
		 *    AND (    c2  eq QUOTE	1,"abc""def",2
		 *         OR  c2  eq ESCAPE	1,"abc""def",2 (QUO eq ESC)
		 *         OR  c2  eq NULL )	1,"abc"0def",2
		 * ---
		 */
		if (csv->escape_char && c == csv->escape_char) {

		    quoesc = 1;
		    if (c2 == '0') {
			/* ,1,"foo, 3"056",,bar,\r\n
			 *            ^
			 */
			CSV_PUT_SV (0)
			continue;
			}

		    if (is_QUOTE (c2)) {
			/* ,1,"foo, 3""56",,bar,\r\n
			 *            ^
			 */
			if (csv->utf8)
			    f |= CSV_FLAGS_BIN;
			CSV_PUT_SV (c2)
			continue;
			}

		    if (csv->allow_loose_escapes && c2 != CH_CR) {
			/* ,1,"foo, 3"56",,bar,\r\n
			 *            ^
			 */
			CSV_PUT_SV (c);
			c = c2;
			goto restart;
			}
		    }

		if (c2 == CH_CR) {
		    int	c3;

		    if (csv->eol_is_cr) {
			/* ,1,"foo, 3"\r
			 *            ^
			 */
#if MAINT_DEBUG_EOL > 0
    (void)fprintf (stderr, "# %04d parse eol CR: '%s'\t(len: %d, is_cr: %d, x: %d, pos: %d, tp: %02x, c: %d, c2: %d, c3: %d)\n",
	__LINE__, _pretty_str (csv->eol, csv->eol_len), csv->eol_len, csv->eol_is_cr, csv->eolx, csv->eol_pos, csv->eol_type, c, c2);
#endif
			AV_PUSH;
			return TRUE;
			}

		    c3 = CSV_GET;

		    if (c3 == CH_NL) { /* \r is not optional before EOLX! */
			/* ,1,"foo, 3"\r\n
			 *              ^
			 */
#if MAINT_DEBUG_EOL > 0
    (void)fprintf (stderr, "# %04d parse eol CRNL: '%s'\t(len: %d, is_cr: %d, x: %d, pos: %d, tp: %02x, c: %d, c2: %d, c3: %d)\n",
	__LINE__, _pretty_str (csv->eol, csv->eol_len), csv->eol_len, csv->eol_is_cr, csv->eolx, csv->eol_pos, csv->eol_type, c, c2, c3);
#endif
			if (csv->strict_eol && csv->eol_type && csv->eol_type != EOL_TYPE_CRNL)
			    ERROR_EOL;
			SET_EOL_TYPE (csv, EOL_TYPE_CRNL);

			AV_PUSH;
			return TRUE;
			}

		    if (csv->useIO && csv->eol_len == 0) {
			if (c3 == CH_CR) { /* \r followed by an empty line */
			    /* ,1,"foo, 3"\r\r
			     *              ^
			     */
#if MAINT_DEBUG_EOL > 0
    (void)fprintf (stderr, "# %04d parse set CR: '%s'\t(len: %d, is_cr: %d, x: %d, pos: %d, tp: %02x, c: %d, c2: %d, c3: %d)\n",
	__LINE__, _pretty_str (csv->eol, csv->eol_len), csv->eol_len, csv->eol_is_cr, csv->eolx, csv->eol_pos, csv->eol_type, c, c2, c3);
#endif
			    if (csv->strict_eol && csv->eol_type) {
				unless (csv->eol_type == EOL_TYPE_CR)
				    ERROR_EOL;
				csv->used--;
				csv->has_ahead++;
				AV_PUSH;
				return TRUE;
				}

			    set_eol_is_cr (csv);
			    if (f & CSV_FLAGS_QUO) f ^= CSV_FLAGS_QUO;
			    c = c0 = CH_CR;
			    goto EOLX;
			    }

			if (!is_csv_binary (c3)) {
			    /* ,1,"foo\n 3",,"bar"\r
			     * baz,4
			     * ^
			     */
#if MAINT_DEBUG_EOL > 0
    (void)fprintf (stderr, "# %04d parse set CR/BIN: '%s'\t(len: %d, is_cr: %d, x: %d, pos: %d, tp: %02x, c: %d, c2: %d, c3: %d)\n",
	__LINE__, _pretty_str (csv->eol, csv->eol_len), csv->eol_len, csv->eol_is_cr, csv->eolx, csv->eol_pos, csv->eol_type, c, c2, c3);
#endif
			    if (csv->strict_eol && csv->eol_type) {
				unless (csv->eol_type == EOL_TYPE_CR)
				    ERROR_EOL;
				csv->eol_is_cr = 1;
				}
			    else
				set_eol_is_cr (csv);
			    csv->used--;
			    csv->has_ahead++;
			    AV_PUSH;
			    return TRUE;
			    }
			}

		    ParseError (csv, quoesc ? 2023 : 2010, csv->used - 2);
		    return FALSE;
		    }

		if (c2 == EOF) {
		    /* ,1,"foo, 3"
		     *            ^
		     */
		    AV_PUSH;
		    return TRUE;
		    }

		if (csv->allow_loose_quotes && !quoesc) {
		    /* ,1,"foo, 3"456",,bar,\r\n
		     *            ^
		     */
		    CSV_PUT_SV (c);
		    c = c2;
		    goto restart;
		    }

		/* 1,"foo" ",3
		 *        ^
		 */
		if (quoesc) {
		    csv->used--;
		    ERROR_INSIDE_QUOTES (2023);
		    }

		ERROR_INSIDE_QUOTES (2011);
		}

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
	    (void)fprintf (stderr, "# %04d %d/%d/%03x pos %d = ESC '%c'\t%s\n",
		__LINE__, waitingForField ? 1 : 0, sv ? 1 : 0, f, spl, c,
		_pretty_strl (csv->bptr + csv->used));
#endif
	    /* This means quote_char != escape_char */
	    if (waitingForField) {
		waitingForField = 0;
		if (csv->allow_unquoted_escape) {
		    /* The escape character is the first character of an
		     * unquoted field */
		    /* ... get and store next character */
		    int c2 = CSV_GET;

		    SvSetEmpty (sv);

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
		ERROR_INSIDE_FIELD (2036); /* uncoverable statement I think there's no way to get here */
	    } /* ESC char */
	else
	if (c == CH_NL || is_EOL (c)) {
	    unsigned short eolt;
EOLX:
	    eolt = ((c == CH_NL || c == CH_CR) && c0 == CH_CR) ? EOL_TYPE_CRNL : EOL_TYPE (c);
#if MAINT_DEBUG > 1 || MAINT_DEBUG_EOL > 0
	    (void)fprintf (stderr, "# %04d EOLX: %d/%d/%03x pos %d = NL, eolx = %d, eol_pos = %d, tp: %02x/%02x\t%s (eol = %s, strict_eol = %d, c = 0x%04x, c0 = 0x%04x)\n",
		__LINE__, waitingForField ? 1 : 0, sv ? 1 : 0, f, spl, csv->eolx, csv->eol_pos, csv->eol_type, eolt,
		_pretty_strl (csv->bptr + csv->used), _pretty_strl (csv->eol), csv->strict_eol, c, c0);
#endif
	    c0 = 0;
	    unless (f & CSV_FLAGS_QUO) {
		if (csv->strict_eol && csv->eol_type && csv->eol_type != eolt)
		    ERROR_EOL;
		SET_EOL_TYPE (csv, eolt);
		}

	    if (fnum == 1 && f == 0 && SvCUR (sv) == 0 && csv->skip_empty_rows) {
		SkipEmptyRow;
		goto restart;
		}

	    if (waitingForField) {
		/* ,1,"foo, 3",,bar,
		 *                  ^
		 */
		if (csv->blank_is_undef || csv->empty_is_undef)
		    SvSetUndef (sv);
		else
		    SvSetEmpty (sv);
		unless (csv->is_bound)
		    av_push (fields, sv);
		if (csv->keep_meta_info && fflags)
		    av_push (fflags, newSViv (f));
		return TRUE;
		}

	    if (f & CSV_FLAGS_QUO) {
		/* ,1,"foo\n 3",,bar,
		 *        ^
		 */
		f |= CSV_FLAGS_BIN;
		unless (csv->binary)
		    ERROR_INSIDE_QUOTES (2021);

		CSV_PUT_SV (c);
		}
	    else
	    if (csv->verbatim) {
		/* ,1,foo\n 3,,bar,
		 * This feature should be deprecated
		 */
		f |= CSV_FLAGS_BIN;
		unless (csv->binary)
		    ERROR_INSIDE_FIELD (2030);

		CSV_PUT_SV (c);
		}
	    else {
		/* sep=,
		 *      ^
		 */
		if (csv->recno == 0 && csv->fld_idx == 1 && csv->useIO &&
			(csv->bptr[0] == 's' || csv->bptr[0] == 'S') &&
			(csv->bptr[1] == 'e' || csv->bptr[1] == 'E') &&
			(csv->bptr[2] == 'p' || csv->bptr[2] == 'P') &&
			 csv->bptr[3] == '=') {
		    char *sep = csv->bptr + 4;
		    int   lnu = csv->used - 5;
		    if (lnu <= MAX_ATTR_LEN) {
			sep[lnu] = (char)0;
			(void)memcpy (csv->sep, sep, lnu);
			csv->sep_len = lnu == 1 ? 0 : lnu;
			return Parse (csv, src, fields, fflags);
			}
		    }

		/* ,1,"foo\n 3",,bar
		 *                  ^
		 */
		AV_PUSH;
		return TRUE;
		}
	    } /* CH_NL */
	else
	if (c == CH_CR && !(csv->verbatim)) {
#if MAINT_DEBUG > 1 || MAINT_DEBUG_EOL > 0
	    (void)fprintf (stderr, "# %04d %d/%d/%03x pos %d = CR, eolx = %d, eol_pos = %d, tp: %02x (cr: %d)\t%s (eol = %s)\n",
		__LINE__, waitingForField ? 1 : 0, sv ? 1 : 0, f, spl, csv->eolx, csv->eol_pos, csv->eol_type, csv->eol_is_cr,
		_pretty_strl (csv->bptr + csv->used), _pretty_strl (csv->eol));
#endif
	    c0 = CH_CR;
	    if (waitingForField) {
		int	c2;

		if (csv->eol_is_cr) {
		    /* ,1,"foo\n 3",,bar,\r
		     *                   ^
		     */
		    c = CH_NL;
		    goto EOLX;
		    }

		c2 = CSV_GET;

		if (c2 == EOF) {
		    /* ,1,"foo\n 3",,bar,\r
		     *                     ^
		     */
		    c = EOF;

#if MAINT_DEBUG > 9
		    (void)fprintf (stderr, "# %04d (%d) ... CR EOF 0x%x\n",
			__LINE__, seenSomething, c);
#endif
		    unless (seenSomething)
			break;
		    goto restart;
		    }

		if (c2 == CH_NL) { /* \r is not optional before EOLX! */
		    /* ,1,"foo\n 3",,bar,\r\n
		     *                     ^
		     */
		    if (csv->strict_eol && csv->eol_type && csv->eol_type != EOL_TYPE_CRNL)
			ERROR_EOL;
		    SET_EOL_TYPE (csv, EOL_TYPE_CRNL);

#if MAINT_DEBUG > 1 || MAINT_DEBUG_EOL > 0
	    (void)fprintf (stderr, "# %04d %d/%d/%03x pos %d = CRNL, eolx = %d, eol_pos = %d, tp: %02x (cr: %d, c0: %d)\t%s (eol = %s)\n",
		__LINE__, waitingForField ? 1 : 0, sv ? 1 : 0, f, spl, csv->eolx, csv->eol_pos, csv->eol_type, csv->eol_is_cr, c0,
		_pretty_strl (csv->bptr + csv->used), _pretty_strl (csv->eol));
#endif
		    c = c2;
		    goto EOLX;
		    }

		if (csv->useIO && csv->eol_len == 0) {
		    if (c2 == CH_CR) { /* \r followed by an empty line */
			/* ,1,"foo\n 3",,bar,\r\r
			 *                     ^
			 */
			if (csv->strict_eol && csv->eol_type) {
			    unless (csv->eol_type == EOL_TYPE_CR)
				ERROR_EOL;
			    csv->eol_is_cr = 1;
			    }
			else
			    set_eol_is_cr (csv);
			goto EOLX;
			}

		    waitingForField = 0;

		    if (!is_csv_binary (c2)) {
			/* ,1,"foo\n 3",,bar,\r
			 * baz,4
			 * ^
			 */
			if (csv->strict_eol && csv->eol_type) {
			    unless (csv->eol_type == EOL_TYPE_CR)
				ERROR_EOL;
			    }
			else
			    set_eol_is_cr (csv);
			csv->used--;
			csv->has_ahead++;
			if (fnum == 1 && f == 0 && SvCUR (sv) == 0 && csv->skip_empty_rows) {
			    SkipEmptyRow;
			    goto restart;
			    }
			AV_PUSH;
			return TRUE;
			}
		    }

		/* ,1,"foo\n 3",,bar,\r\t
		 *                     ^
		 */
		csv->used--;
		ERROR_INSIDE_FIELD (2031);
		}

	    if (f & CSV_FLAGS_QUO) {
		/* ,1,"foo\r 3",,bar,\r\t
		 *        ^
		 */
		f |= CSV_FLAGS_BIN;
		unless (csv->binary)
		    ERROR_INSIDE_QUOTES (2022);

		CSV_PUT_SV (c);
		}
	    else {
		int	c2;

		if (csv->eol_is_cr) {
		    /* ,1,"foo\n 3",,bar\r
		     *                  ^
		     */
		    goto EOLX;
		    }

		c2 = CSV_GET;

		if (c2 == CH_NL) { /* \r is not optional before EOLX! */
		    /* ,1,"foo\n 3",,bar\r\n
		     *                    ^
		     */
		    if (csv->strict_eol && csv->eol_type && csv->eol_type != EOL_TYPE_CRNL)
			ERROR_EOL;
		    SET_EOL_TYPE (csv, EOL_TYPE_CRNL);

#if MAINT_DEBUG > 1 || MAINT_DEBUG_EOL > 0
	    (void)fprintf (stderr, "# %04d %d/%d/%03x pos %d = CRNL, eolx = %d, eol_pos = %d, tp: %02x (cr: %d, c0: %d)\t%s (eol = %s)\n",
		__LINE__, waitingForField ? 1 : 0, sv ? 1 : 0, f, spl, csv->eolx, csv->eol_pos, csv->eol_type, csv->eol_is_cr, c0,
		_pretty_strl (csv->bptr + csv->used), _pretty_strl (csv->eol));
#endif
		    goto EOLX;
		    }

		if (csv->useIO && csv->eol_len == 0) {
		    if (!is_csv_binary (c2)
			    /* ,1,"foo\n 3",,bar\r
			     * baz,4
			     * ^
			     */
			|| c2 == CH_CR) {
			    /* ,1,"foo\n 3",,bar,\r\r
			     *                     ^
			     */
#if MAINT_DEBUG_EOL > 0
    (void)fprintf (stderr, "# %04d parse eol CR/IO: '%s'\t(len: %d, is_cr: %d, x: %d, pos: %d, tp: %02x, c: %d, c2: %d)\n",
	__LINE__, _pretty_str (csv->eol, csv->eol_len), csv->eol_len, csv->eol_is_cr, csv->eolx, csv->eol_pos, csv->eol_type, c, c2);
#endif
			if (csv->strict_eol && csv->eol_type) {
			    unless (csv->eol_type == EOL_TYPE_CR)
				ERROR_EOL;
			    }
			else
			    set_eol_is_cr (csv);
			csv->used--;
			csv->has_ahead++;
			if (fnum == 1 && f == 0 && SvCUR (sv) == 0 && csv->skip_empty_rows) {
			    SkipEmptyRow;
			    goto restart;
			    }
			AV_PUSH;
			return TRUE;
			}
		    }

		/* ,1,"foo\n 3",,bar\r\t
		 *                    ^
		 */
		ERROR_INSIDE_FIELD (2032);
		}
	    } /* CH_CR */
	else {
#if MAINT_DEBUG > 1
	    (void)fprintf (stderr, "# %04d %d/%d/%03x pos %d = CCC '%c'\t\t%s\n",
		__LINE__, waitingForField ? 1 : 0, sv ? 1 : 0, f, spl, c,
		_pretty_strl (csv->bptr + csv->used));
#endif
	    /* Needed for non-IO parse, where EOL is not set during read */
	    if (csv->eolx && c == CH_EOL &&
		 csv->size - csv->used >= (STRLEN)csv->eol_len - 1 &&
		 !memcmp (csv->bptr + csv->used, csv->eol + 1, csv->eol_len - 1) &&
		 (csv->used += csv->eol_len - 1)) {
		c = CH_EOLX;
#if MAINT_DEBUG > 5 || MAINT_DEBUG_EOL > 0
		(void)fprintf (stderr, "# %04d -> EOLX (0x%x)\n", __LINE__, c);
#endif
		goto EOLX;
		}

	    if (waitingForField) {
		if (csv->comment_str && !f && !spl && c == *csv->comment_str) {
		    STRLEN cl = strlen ((char *)csv->comment_str);

#if MAINT_DEBUG > 5
		    (void)fprintf (stderr,
			"# %04d COMMENT? cl = %d, size = %d, used = %d\n",
			__LINE__, cl, csv->size, csv->used);
#endif
		    if (cl == 1 || (
		       (csv->size - csv->used >= cl - 1 &&
			 !memcmp (csv->bptr + csv->used, csv->comment_str + 1, cl - 1) &&
			 (csv->used += cl - 1)))) {
			csv->used     = csv->size;
			csv->fld_idx  = csv->strict_n ? csv->strict_n - 1 : 0;
			c             = CSV_GET;
			seenSomething = FALSE;
#if MAINT_DEBUG > 5
			(void)fprintf (stderr, "# %04d COMMENT, SKIPPED\n", __LINE__);
#endif
			unless (csv->useIO)
			    csv->has_ahead = 214;	/* abuse */
			if (c == EOF)
			    break;
			goto restart;
			}
		    }

		if (csv->allow_whitespace && is_whitespace (c)) {
		    do {
			c = CSV_GET;
#if MAINT_DEBUG > 5
			(void)fprintf (stderr, "# %04d WS next got (0x%x)\n", __LINE__, c);
#endif
			} while (is_whitespace (c));
		    if (c == EOF)
			break;
		    goto restart;
		    }
		waitingForField = 0;
		goto restart;
		}

#if MAINT_DEBUG > 5
	    (void)fprintf (stderr, "# %04d %sc 0x%x is%s binary %s utf8\n",
		__LINE__, f & CSV_FLAGS_QUO ? "quoted " : "", c,
		is_csv_binary (c) ? "" : " not",
		csv->utf8 ? "is" : "not");
#endif
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
		    if (csv->useIO && c == EOF)
			break;
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
	unless (csv->useIO) {
	    if (csv->has_ahead == 214)
		return TRUE;
	    seenSomething++;
	    }
	if (seenSomething) {
	    NewField;
	    if (csv->blank_is_undef || csv->empty_is_undef)
		SvSetUndef (sv);
	    else
		SvSetEmpty (sv);
	    unless (csv->is_bound)
		av_push (fields, sv);
	    if (csv->keep_meta_info && fflags)
		av_push (fflags, newSViv (f));
	    return TRUE;
	    }

	(void)SetDiag (csv, 2012);
	return FALSE;
	}

    if (f & CSV_FLAGS_QUO)
	ERROR_INSIDE_QUOTES (2027);

    if (sv) {
	AV_PUSH;
	}
    else if (f == 0 && fnum == 1 && csv->skip_empty_rows == 1)
	return FALSE;
    return TRUE;
    } /* Parse */

static int hook (pTHX_ HV *hv, const char *cb_name, AV *av) {
    SV **svp;
    HV *cb;
    int res;

#if MAINT_DEBUG > 1
    (void)fprintf (stderr, "# %04d HOOK %s %x\n", __LINE__, cb_name, av);
#endif
    unless ((svp = hv_fetchs (hv, "callbacks", FALSE)) && _is_hashref (*svp))
	return 0; /* uncoverable statement defensive programming */

    cb  = (HV *)SvRV (*svp);
    svp = hv_fetch (cb, cb_name, strlen (cb_name), FALSE);
    unless (svp && _is_coderef (*svp))
	return 0;

    {   dSP;
	ENTER;
	SAVETMPS;
	PUSHMARK (SP);
	mXPUSHs (newRV_inc ((SV *)hv));
	mXPUSHs (newRV_inc ((SV *)av));
	PUTBACK;
	res = call_sv (*svp, G_SCALAR);
	SPAGAIN;
	if (res) {
	    SV *rv = POPs;
	    if (SvROK (rv) && (rv = SvRV (rv)) && SvPOK (rv)) {
		if (strcmp (SvPV_nolen (rv), "skip") == 0)
		    res = 0;
		}
	    }
	PUTBACK;
	FREETMPS;
	LEAVE;
	}
    return res;
    } /* hook */

#define c_xsParse(csv,hv,av,avf,src,useIO)	cx_c_xsParse (aTHX_ csv, hv, av, avf, src, useIO)
static int cx_c_xsParse (pTHX_ csv_t csv, HV *hv, AV *av, AV *avf, SV *src, bool useIO) {
    int	result, ahead = 0;
    SV	*pos = NULL;

    ENTER;
    if (csv.eolx || csv.eol_is_cr) {
	/* local $/ = $eol */
#if MAINT_DEBUG_EOL > 0
    (void)fprintf (stderr, "# %04d Parse EOLX/RS: '%s'\t(len: %d, is_cr: %d, x: %d, pos: %d, tp: %02x)\n",
	__LINE__, _pretty_str (csv.eol, csv.eol_len), csv.eol_len, csv.eol_is_cr, csv.eolx, csv.eol_pos, csv.eol_type);
#endif
	SAVEGENERICSV (PL_rs);
	PL_rs = newSVpvn ((char *)csv.eol, csv.eol_len);
	}

    if ((csv.useIO = useIO)) {
	csv.tmp = NULL;

	if ((ahead = csv.has_ahead)) {
	    SV **svp;
	    if ((svp = hv_fetchs (hv, "_AHEAD", FALSE)) && *svp) {
		csv.bptr = SvPV (csv.tmp = *svp, csv.size);
		csv.used = 0;
		if (pos && SvIV (pos) > (IV)csv.size)
		    sv_setiv (pos, SvIV (pos) - csv.size);
		}
	    }
	}
    else {
	csv.tmp  = src;
	csv.utf8 = SvUTF8 (src) ? 1 : 0;
	csv.bptr = SvPV (src, csv.size);
	}
    if (csv.has_error_input) {
	(void)hv_store (hv, "_ERROR_INPUT", 12, &PL_sv_undef, 0);
	csv.has_error_input = 0;
	}

    result = Parse (&csv, src, av, avf);
    (void)hv_store (hv, "_RECNO", 6, newSViv (++csv.recno), 0);
    (void)hv_store (hv, "_EOF",   4, &PL_sv_no,             0);

    if (csv.strict) {
	STRLEN nf = csv.is_bound ? csv.fld_idx ? csv.fld_idx - 1 : 0 : av_len (av);
#if MAINT_DEBUG > 6
	(void)fprintf (stderr, "# %04d Strict nf = %2d, n = %2d, idx = %2d, recno = %2d, res = %d\n",
	    __LINE__, nf, csv.strict_n, csv.fld_idx, csv.recno, result);
#endif

	if (nf && !csv.strict_n) csv.strict_n = (short)nf;
	if (csv.strict_n > 0 && nf != (STRLEN)csv.strict_n) {
	    unless (csv.useIO & useIO_EOF) {
#if MAINT_DEBUG > 6
		ErrorDiag (&csv);
#endif
		unless (last_error || (!csv.useIO && csv.has_ahead))
		    ParseError (&csv, 2014, csv.used);
		}
	    if (last_error) /* an error callback can reset and accept */
		result = FALSE;
	    }
	}

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
	(void)memcpy (csv.cache, &csv, sizeof (csv_t));

	if (avf) {
	    if (csv.keep_meta_info)
		(void)hv_store  (hv, "_FFLAGS", 7, newRV_noinc ((SV *)avf), 0);
	    else {
		av_undef (avf);
		sv_free ((SV *)avf);
		}
	    }
	}
    else { /* just copy to the cache */
	SV **svp = hv_fetchs (hv, "_CACHE", FALSE);

	if (svp && *svp)
	    csv.cache = (byte *)SvPV_nolen (*svp);
	(void)memcpy (csv.cache, &csv, sizeof (csv_t));
	}

    if (result && csv.types) {
	STRLEN	i;
	STRLEN	len = av_len (av);
	SV    **svp;

	for (i = 0; i <= len && i <= csv.types_len; i++) {
	    if ((svp = av_fetch (av, i, FALSE)) && *svp && SvOK (*svp)) {
		switch (csv.types[i]) {
		    case CSV_XS_TYPE_IV:
#ifdef CSV_XS_TYPE_WARN
			sv_setiv (*svp, SvIV (*svp));
#else
			if (SvTRUE (*svp))
			    sv_setiv (*svp, SvIV (*svp));
			else
			    sv_setiv (*svp, 0);
#endif
			break;

		    case CSV_XS_TYPE_NV:
#ifdef CSV_XS_TYPE_WARN
			sv_setnv (*svp, SvNV (*svp));
#else
			if (SvTRUE (*svp))
			    sv_setnv (*svp, SvNV (*svp));
			else
			    sv_setnv (*svp, 0.0);
#endif
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
static int cx_xsParse (pTHX_ SV *self, HV *hv, AV *av, AV *avf, SV *src, bool useIO) {
    csv_t	csv;
    int		state;
    SetupCsv (&csv, hv, self);
    state = c_xsParse (csv, hv, av, avf, src, useIO);
    if (state && csv.has_hooks & HOOK_AFTER_PARSE)
	(void)hook (aTHX_ hv, "after_parse", av);
    return (state || !last_error);
    } /* xsParse */

/* API also offers av_clear and av_undef, but they have more overhead */
#define av_empty(av)	cx_av_empty (aTHX_ av)
static void cx_av_empty (pTHX_ AV *av) {
    while (av_len (av) >= 0)
	sv_free (av_pop (av));
    } /* av_empty */

#define xsParse_all(self,hv,io,off,len)		cx_xsParse_all (aTHX_ self, hv, io, off, len)
static SV *cx_xsParse_all (pTHX_ SV *self, HV *hv, SV *io, SV *off, SV *len) {
    csv_t	csv;
    int		n = 0, skip = 0, length = MAXINT, tail = MAXINT;
    AV		*avr = newAV ();
    AV		*row = newAV ();

    SetupCsv (&csv, hv, self);

    if (SvOK (off)) {
	skip = SvIV (off);
	if (skip < 0) {
	    tail = -skip;
	    skip = -1;
	    }
	}
    if (SvOK (len))
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

	if (csv.has_hooks & HOOK_AFTER_PARSE) {
	    unless (hook (aTHX_ hv, "after_parse", row)) {
		av_empty (row); /* re-use */
		continue;
		}
	    }
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
static int cx_xsCombine (pTHX_ SV *self, HV *hv, AV *av, SV *io, bool useIO) {
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
	(void)hook (aTHX_ hv, "before_print", av);
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
    Perl_load_module (aTHX_ PERL_LOADMOD_NOIMPORT, newSVpvs ("IO::Handle"), NULL, NULL, NULL);

void
SetDiag (SV *self, int xse, ...)

  PPCODE:
    HV		*hv;
    csv_t	csv;

    if (SvOK (self) && SvROK (self)) {
	CSV_XS_SELF;
	SetupCsv (&csv, hv, self);
	ST (0) = SetDiag (&csv, xse);
	}
    else {
	last_error = xse;
	ST (0) = sv_2mortal (SvDiag (xse));
	}

    if (xse && items > 2 && SvPOK (ST (2))) {
	sv_setpvn (ST (0),  SvPVX (ST (2)), SvCUR (ST (2)));
	SvIOK_on  (ST (0));
	}

    XSRETURN (1);
    /* XS SetDiag */

void
error_input (SV *self)

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
Combine (SV *self, SV *dst, SV *fields, bool useIO)

  PPCODE:
    HV	*hv;
    AV	*av;

    CSV_XS_SELF;
    av = (AV *)SvRV (fields);
    ST (0) = xsCombine (self, hv, av, dst, useIO) ? &PL_sv_yes : &PL_sv_undef;
    XSRETURN (1);
    /* XS Combine */

void
Parse (SV *self, SV *src, SV *fields, SV *fflags)

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
print (SV *self, SV *io, SV *fields)

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
getline (SV *self, SV *io)

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
getline_all (SV *self, SV *io, ...)

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
_cache_get_eolt (SV *self)

  PPCODE:
    HV	 *hv;
    SV   *sve;
    char *eol;

    CSV_XS_SELF;
    sve = newSVpvs_flags ("", SVs_TEMP);
    eol = xs_cache_get_eolt (hv);
    if (eol)
	sv_setpvn (sve, eol, strlen (eol));
    else
	sv_setpvn (sve, NULL, 0);
    ST (0) = sve;
    XSRETURN (1);
    /* XS _cache_get_eolt */

void
_cache_set (SV *self, int idx, SV *val)

  PPCODE:
    HV	*hv;

    CSV_XS_SELF;
    xs_cache_set (hv, idx, val);
    XSRETURN (1);
    /* XS _cache_set */

void
_cache_diag (SV *self)

  PPCODE:
    HV	*hv;

    CSV_XS_SELF;
    xs_cache_diag (hv);
    XSRETURN (1);
    /* XS _cache_diag */
