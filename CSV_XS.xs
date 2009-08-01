/*  Copyright (c) 2007-2009 H.Merijn Brand.  All rights reserved.
 *  Copyright (c) 1998-2001 Jochen Wiedmann. All rights reserved.
 *  This program is free software; you can redistribute it and/or
 *  modify it under the same terms as Perl itself.
 */
#define PERL_NO_GET_CONTEXT
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#define NEED_PL_parser
#define NEED_sv_2pv_flags
#define NEED_load_module
#define NEED_newRV_noinc
#define NEED_vload_module
#include "ppport.h"
#if (PERL_BCDVERSION <= 0x5005005)
#  define SvUTF8_on(sv)	/* no-op */
#  define SvUTF8(sv)	0
#  endif

#define MAINT_DEBUG	0

#define BUFFER_SIZE	1024

#define CSV_XS_TYPE_PV	0
#define CSV_XS_TYPE_IV	1
#define CSV_XS_TYPE_NV	2

/* Keep in sync with .pm! */
#define CACHE_SIZE			32

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
#define CACHE_ID__is_bound		25

#define CSV_FLAGS_QUO	0x0001
#define CSV_FLAGS_BIN	0x0002
#define CSV_FLAGS_EIF	0x0004

#define CH_TAB		'\011'
#define CH_NL		'\012'
#define CH_CR		'\015'
#define CH_SPACE	'\040'
#define CH_DEL		'\177'

#define useIO_EOF	0x10

#define unless(expr)	if (!(expr))

#define _is_arrayref(f) ( f && \
     (SvROK (f) || (SvRMAGICAL (f) && (mg_get (f), 1) && SvROK (f))) && \
      SvOK (f) && SvTYPE (SvRV (f)) == SVt_PVAV )

#define CSV_XS_SELF					\
    if (!self || !SvOK (self) || !SvROK (self) ||	\
	 SvTYPE (SvRV (self)) != SVt_PVHV)		\
        croak ("self is not a hash ref");		\
    hv = (HV*)SvRV (self)

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
    long	is_bound;

    byte	cache[CACHE_SIZE];

    SV *	pself;
    HV *	self;
    SV *	bound;

    char *	eol;
    STRLEN	eol_len;
    char *	types;
    STRLEN	types_len;

    char *	bptr;
    SV *	tmp;
    int		utf8;
    STRLEN	size;
    STRLEN	used;
    char	buffer[BUFFER_SIZE];
    } csv_t;

#define bool_opt(o) \
    (((svp = hv_fetchs (self, o, FALSE)) && *svp) ? SvTRUE (*svp) : 0)

typedef struct {
    int   xs_errno;
    char *xs_errstr;
    } xs_error_t;
xs_error_t xs_errors[] =  {

    /* Generic errors */
    { 1000, "INI - constructor failed"						},
    { 1001, "INI - sep_char is equal to quote_char or escape_char"		},
    { 1002, "INI - allow_whitespace with escape_char or quote_char SP or TAB"	},

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
    { 3007, "EHR - bind_columns needs refs to writeable scalars"		},
    { 3008, "EHR - unexpected error in bound fields"				},

    {    0, "" },
    };

static int  io_handle_loaded = 0;
static SV  *m_getline, *m_print;

#define require_IO_Handle				\
    unless (io_handle_loaded) {				\
	ENTER;						\
	load_module (PERL_LOADMOD_NOIMPORT,		\
	    newSVpvs ("IO::Handle"), NULL, NULL, NULL);	\
	LEAVE;						\
	io_handle_loaded = 1;				\
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
    SV   *err = SvDiag (xse);

    if (err)
	hv_store (csv->self, "_ERROR_DIAG",  11, err,           0);
    if (xse == 0) {
	hv_store (csv->self, "_ERROR_POS",   10, newSViv  (0),  0);
	hv_store (csv->self, "_ERROR_INPUT", 12, newSVpvs (""), 0);
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

#define SetupCsv(csv,self,pself)	cx_SetupCsv (aTHX_ csv, self, pself)
static void cx_SetupCsv (pTHX_ csv_t *csv, HV *self, SV *pself)
{
    SV	       **svp;
    STRLEN	 len;
    char	*ptr;

    csv->self  = self;
    csv->pself = pself;

    if ((svp = hv_fetchs (self, "_CACHE", FALSE)) && *svp) {
	memcpy (csv->cache, SvPV (*svp, len), CACHE_SIZE);

	csv->quote_char			= csv->cache[CACHE_ID_quote_char	];
	csv->escape_char		= csv->cache[CACHE_ID_escape_char	];
	csv->sep_char			= csv->cache[CACHE_ID_sep_char		];
	csv->binary			= csv->cache[CACHE_ID_binary		];

	csv->keep_meta_info		= csv->cache[CACHE_ID_keep_meta_info	];
	csv->always_quote		= csv->cache[CACHE_ID_always_quote	];
	csv->auto_diag			= csv->cache[CACHE_ID_auto_diag	];

	csv->allow_loose_quotes		= csv->cache[CACHE_ID_allow_loose_quotes];
	csv->allow_loose_escapes	= csv->cache[CACHE_ID_allow_loose_escapes];
	csv->allow_double_quoted	= csv->cache[CACHE_ID_allow_double_quoted];
	csv->allow_whitespace		= csv->cache[CACHE_ID_allow_whitespace	];
	csv->blank_is_undef		= csv->cache[CACHE_ID_blank_is_undef	];
	csv->empty_is_undef		= csv->cache[CACHE_ID_empty_is_undef	];
	csv->verbatim			= csv->cache[CACHE_ID_verbatim		];
	csv->eol_is_cr			= csv->cache[CACHE_ID_eol_is_cr		];
	csv->eol_len			= csv->cache[CACHE_ID_eol_len		];
	if (csv->eol_len < 8)
	    csv->eol = (char *)&csv->cache[CACHE_ID_eol];
	else {
	    /* Was too long to cache. must re-fetch */
	    csv->eol       = NULL;
	    csv->eol_is_cr = 0;
	    csv->eol_len   = 0;
	    if ((svp = hv_fetchs (self, "eol",     FALSE)) && *svp && SvOK (*svp)) {
		csv->eol = SvPV (*svp, len);
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

	csv->eol       = "";
	csv->eol_is_cr = 0;
	csv->eol_len   = 0;
	if ((svp = hv_fetchs (self, "eol",         FALSE)) && *svp && SvOK (*svp)) {
	    csv->eol = SvPV (*svp, len);
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
	if ((svp = hv_fetchs (self, "_is_bound", FALSE)) && *svp && SvOK(*svp)) {
	    csv->is_bound = SvIV(*svp);
	    }

	csv->binary			= bool_opt ("binary");
	csv->keep_meta_info		= bool_opt ("keep_meta_info");
	csv->always_quote		= bool_opt ("always_quote");
	csv->allow_loose_quotes		= bool_opt ("allow_loose_quotes");
	csv->allow_loose_escapes	= bool_opt ("allow_loose_escapes");
	csv->allow_double_quoted	= bool_opt ("allow_double_quoted");
	csv->allow_whitespace		= bool_opt ("allow_whitespace");
	csv->blank_is_undef		= bool_opt ("blank_is_undef");
	csv->empty_is_undef		= bool_opt ("empty_is_undef");
	csv->verbatim			= bool_opt ("verbatim");
	csv->auto_diag			= bool_opt ("auto_diag");

	csv->cache[CACHE_ID_quote_char]			= csv->quote_char;
	csv->cache[CACHE_ID_escape_char]		= csv->escape_char;
	csv->cache[CACHE_ID_sep_char]			= csv->sep_char;
	csv->cache[CACHE_ID_binary]			= csv->binary;

	csv->cache[CACHE_ID_keep_meta_info]		= csv->keep_meta_info;
	csv->cache[CACHE_ID_always_quote]		= csv->always_quote;

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
	    strcpy ((char *)&csv->cache[CACHE_ID_eol], csv->eol);
	csv->cache[CACHE_ID_has_types]			= csv->types ? 1 : 0;
	csv->cache[CACHE_ID__is_bound    ] = (csv->is_bound & 0xFF000000) >> 24;
	csv->cache[CACHE_ID__is_bound + 1] = (csv->is_bound & 0x00FF0000) >> 16;
	csv->cache[CACHE_ID__is_bound + 2] = (csv->is_bound & 0x0000FF00) >>  8;
	csv->cache[CACHE_ID__is_bound + 3] = (csv->is_bound & 0x000000FF);

	if ((csv->tmp = newSVpvn ((char *)csv->cache, CACHE_SIZE)))
	    hv_store (self, "_CACHE", 6, csv->tmp, 0);
	}

    if (csv->is_bound) {
	if ((svp = hv_fetchs (self, "_BOUND_COLUMNS", FALSE)) && _is_arrayref (*svp))
	    csv->bound = *svp;
	else
	    csv->is_bound = 0;
	}
    csv->utf8 = 0;
    csv->used = 0;
    } /* SetupCsv */

#define Print(csv,dst)		cx_Print (aTHX_ csv, dst)
static int cx_Print (pTHX_ csv_t *csv, SV *dst)
{
    int result;

    if (csv->useIO) {
	SV *tmp = newSVpv (csv->buffer, csv->used);
	dSP;
	require_IO_Handle;
	PUSHMARK (sp);
	EXTEND (sp, 2);
	PUSHs ((dst));
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
    if (csv->utf8 && SvROK (dst))
	SvUTF8_on (SvRV (dst));
    csv->used = 0;
    return result;
    } /* Print */

#define CSV_PUT(csv,dst,c) {				\
    if ((csv)->used == sizeof ((csv)->buffer) - 1) {	\
        unless (Print ((csv), (dst)))			\
	    return FALSE;				\
        }						\
    (csv)->buffer[(csv)->used++] = (c);			\
    }

/* Should be extended for EBCDIC ? */
#define is_csv_binary(ch) ((ch < CH_SPACE || ch >= CH_DEL) && ch != CH_TAB)

#define Combine(csv,dst,fields)	cx_Combine (aTHX_ csv, dst, fields)
static int cx_Combine (pTHX_ csv_t *csv, SV *dst, AV *fields)
{
    int		i;

    if (csv->sep_char == csv->quote_char || csv->sep_char == csv->escape_char) {
	(void)SetDiag (csv, 1001);
	return FALSE;
	}

    for (i = 0; i <= av_len (fields); i++) {
	SV    **svp;

	if (i > 0)
	    CSV_PUT (csv, dst, csv->sep_char);
	if ((svp = av_fetch (fields, i, 0)) && *svp) {
	    STRLEN	 len;
	    char	*ptr;
	    int		 quoteMe = csv->always_quote;

	    unless ((SvOK (*svp) || (
		    (SvGMAGICAL (*svp) && (mg_get (*svp), 1) && SvOK (*svp)))
		    )) continue;
	    ptr = SvPV (*svp, len);
	    if (len && SvUTF8 (*svp)) csv->utf8 = 1;
	    /* Do we need quoting? We do quote, if the user requested
	     * (always_quote), if binary or blank characters are found
	     * and if the string contains quote or escape characters.
	     */
	    if (!quoteMe &&
	       ( quoteMe = (!SvIOK (*svp) && !SvNOK (*svp) && csv->quote_char))) {
		char	*ptr2;
		STRLEN	 l;

		for (ptr2 = ptr, l = len; l; ++ptr2, --l) {
		    byte	c = *ptr2;

		    if (c <= 0x20 || (c >= 0x7f && c <= 0xa0)  ||
		       (csv->quote_char  && c == csv->quote_char) ||
		       (csv->sep_char    && c == csv->sep_char)   ||
		       (csv->escape_char && c == csv->escape_char)) {
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
		    if (SvUTF8 (*svp))
			csv->binary = 1;
		    else {
			SvREFCNT_inc (*svp);
			unless (hv_store (csv->self, "_ERROR_INPUT", 12, *svp, 0))
			    SvREFCNT_dec (*svp);
			(void)SetDiag (csv, 2110);
			return FALSE;
			}
		    }
		if (c == csv->quote_char  && csv->quote_char)
		    e = 1;
		else
		if (c == csv->escape_char && csv->escape_char)
		    e = 1;
		else
		if (c == (char)0) {
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
	char   *ptr = csv->eol;

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
    hv_store (csv->self, "_ERROR_POS", 10, newSViv (pos), 0);
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

    {   int	result;

	dSP;

	require_IO_Handle;

	PUSHMARK (sp);
	EXTEND (sp, 1);
	PUSHs (src);
	PUTBACK;
	result = call_sv (m_getline, G_SCALAR | G_METHOD);
	SPAGAIN;
	csv->tmp = result ? POPs : NULL;
	PUTBACK;
	}
    if (csv->tmp && SvOK (csv->tmp)) {
	csv->bptr = SvPV (csv->tmp, csv->size);
	csv->used = 0;
	if (csv->verbatim && csv->eol_len && csv->size >= csv->eol_len) {
	    int i, match = 1;
	    for (i = 1; i <= (int)csv->eol_len; i++) {
		unless (csv->bptr[csv->size - i] == csv->eol[csv->eol_len - i]) {
		    match = 0;
		    break;
		    }
		}
	    if (match) {
		csv->size -= csv->eol_len;
		csv->bptr[csv->size] = (char)0;
		SvCUR_set (csv->tmp, csv->size);
		}
	    }
	if (SvUTF8 (csv->tmp)) csv->utf8 = 1;
	if (csv->size) 
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

#define CSV_PUT_SV(c) {				\
    len = SvCUR ((sv));				\
    SvGROW ((sv), len + 2);			\
    *SvEND ((sv)) = c;				\
    SvCUR_set ((sv), len + 1);			\
    }

#define CSV_GET					\
    ((c_ungetc != EOF)				\
	? c_ungetc				\
	: ((csv->used < csv->size)		\
	    ? ((byte)csv->bptr[(csv)->used++])	\
	    : CsvGet (csv, src)))

#define AV_PUSH {						\
    *SvEND (sv) = (char)0;					\
    if (SvCUR (sv) == 0 && (csv->empty_is_undef || (!(f & CSV_FLAGS_QUO) && csv->blank_is_undef))) {\
	sv_setpvn (sv, NULL, 0);				\
	unless (csv->is_bound) av_push (fields, sv);		\
	}							\
    else {							\
	if (csv->allow_whitespace && ! (f & CSV_FLAGS_QUO))	\
	    strip_trail_whitespace (sv);			\
	if (f & CSV_FLAGS_BIN && csv->utf8)			\
	    SvUTF8_on (sv);					\
	unless (csv->is_bound) av_push (fields, sv);		\
	}							\
    sv = NULL;							\
    if (csv->keep_meta_info)					\
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

#define bound_field(csv,i)	cx_bound_field (aTHX_ csv, i)
static SV *cx_bound_field (pTHX_ csv_t *csv, int i)
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
	    unless (SvREADONLY (sv)) {
		sv_setpvn (sv, "", 0);
		return (sv);
		}
	    }
	}
    (void)SetDiag (csv, 3008);
    return (NULL);
    } /* bound_field */

#define NewField				\
    unless (sv) {				\
	if (csv->is_bound)			\
	    sv = bound_field (csv, fnum++);	\
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
    int		 c_ungetc		= EOF;
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
		if (csv->keep_meta_info)
		    av_push (fflags, newSViv (f));
		}
	    else
	    if (f & CSV_FLAGS_QUO)
		CSV_PUT_SV (c)
	    else {
		AV_PUSH;
		}
	    } /* SEP char */
	else
	if (c == CH_NL) {
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
		if (csv->keep_meta_info)
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
		    c = CH_NL;
		    goto restart;
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

		if (c2 == CH_NL) {
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
			if (c3 == CH_NL) {
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
		if (c2 == CH_NL) {
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

			if (c3 == CH_NL) {
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
		f |= CSV_FLAGS_EIF;
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
		int	c2 = CSV_GET;

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
		int	c2 = CSV_GET;

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
	    fprintf (stderr, "# %d/%d/%02x pos %d = === '%c' '%c'\n",
		waitingForField ? 1 : 0, sv ? 1 : 0, f, spl, c, c_ungetc);
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
	    if (csv->keep_meta_info)
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

#define xsParse(self,hv,av,avf,src,useIO)	cx_xsParse (aTHX_ self, hv, av, avf, src, useIO)
static int cx_xsParse (pTHX_ SV *self, HV *hv, AV *av, AV *avf, SV *src, bool useIO)
{
    csv_t	csv;
    int		result;

    SetupCsv (&csv, hv, self);
    if ((csv.useIO = useIO)) {
	csv.tmp  = NULL;
	csv.size = 0;
	}
    else {
	csv.tmp  = src;
	csv.utf8 = SvUTF8 (src);
	csv.bptr = SvPV (src, csv.size);
	}
    hv_delete (hv, "_ERROR_INPUT", 12, G_DISCARD);
    result = Parse (&csv, src, av, avf);
    if (csv.useIO & useIO_EOF)
	hv_store (hv, "_EOF", 4, &PL_sv_yes, 0);
    else
	hv_store (hv, "_EOF", 4, &PL_sv_no,  0);
    if (csv.useIO) {
	if (csv.keep_meta_info) {
	    hv_delete (hv, "_FFLAGS", 7, G_DISCARD);
	    hv_store  (hv, "_FFLAGS", 7, newRV_noinc ((SV *)avf), 0);
	    }
	else {
	    av_undef (avf);
	    sv_free ((SV *)avf);
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
    return result;
    } /* xsParse */

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
	PL_ors_sv = &PL_sv_undef;
#endif
    result = Combine (&csv, io, av);
#if (PERL_BCDVERSION >= 0x5008000)
    PL_ors_sv = ors;
#endif
    return result;
    } /* xsCombine */

MODULE = Text::CSV_XS		PACKAGE = Text::CSV_XS

PROTOTYPES: DISABLE

BOOT:
    m_getline = newSVpvs ("getline");
    m_print   = newSVpvs ("print");

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
	ST (0) = SvDiag (xse);

    if (xse && items > 1 && SvPOK (ST (2))) {
	STRLEN len;
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
    av  = (AV*)SvRV (fields);
    avf = (AV*)SvRV (fflags);

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
    unless (_is_arrayref (fields))
	croak ("Expected fields to be an array ref");

    av = (AV*)SvRV (fields);

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
