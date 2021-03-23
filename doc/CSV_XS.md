# NAME

Text::CSV\_XS - comma-separated values manipulation routines

# SYNOPSIS

    # Functional interface
    use Text::CSV_XS qw( csv );

    # Read whole file in memory
    my $aoa = csv (in => "data.csv");    # as array of array
    my $aoh = csv (in => "data.csv",
                   headers => "auto");   # as array of hash

    # Write array of arrays as csv file
    csv (in => $aoa, out => "file.csv", sep_char=> ";");

    # Only show lines where "code" is odd
    csv (in => "data.csv", filter => { code => sub { $_ % 2 }});


    # Object interface
    use Text::CSV_XS;

    my @rows;
    # Read/parse CSV
    my $csv = Text::CSV_XS->new ({ binary => 1, auto_diag => 1 });
    open my $fh, "<:encoding(utf8)", "test.csv" or die "test.csv: $!";
    while (my $row = $csv->getline ($fh)) {
        $row->[2] =~ m/pattern/ or next; # 3rd field should match
        push @rows, $row;
        }
    close $fh;

    # and write as CSV
    open $fh, ">:encoding(utf8)", "new.csv" or die "new.csv: $!";
    $csv->say ($fh, $_) for @rows;
    close $fh or die "new.csv: $!";

# DESCRIPTION

Text::CSV\_XS  provides facilities for the composition  and decomposition of
comma-separated values.  An instance of the Text::CSV\_XS class will combine
fields into a `CSV` string and parse a `CSV` string into fields.

The module accepts either strings or files as input  and support the use of
user-specified characters for delimiters, separators, and escapes.

## Embedded newlines

**Important Note**:  The default behavior is to accept only ASCII characters
in the range from `0x20` (space) to `0x7E` (tilde).   This means that the
fields can not contain newlines. If your data contains newlines embedded in
fields, or characters above `0x7E` (tilde), or binary data, you **_must_**
set `binary => 1` in the call to ["new"](#new). To cover the widest range of
parsing options, you will always want to set binary.

But you still have the problem  that you have to pass a correct line to the
["parse"](#parse) method, which is more complicated from the usual point of usage:

    my $csv = Text::CSV_XS->new ({ binary => 1, eol => $/ });
    while (<>) {           #  WRONG!
        $csv->parse ($_);
        my @fields = $csv->fields ();
        }

this will break, as the `while` might read broken lines:  it does not care
about the quoting. If you need to support embedded newlines,  the way to go
is to  **not**  pass [`eol`](#eol) in the parser  (it accepts `\n`, `\r`,
**and** `\r\n` by default) and then

    my $csv = Text::CSV_XS->new ({ binary => 1 });
    open my $fh, "<", $file or die "$file: $!";
    while (my $row = $csv->getline ($fh)) {
        my @fields = @$row;
        }

The old(er) way of using global file handles is still supported

    while (my $row = $csv->getline (*ARGV)) { ... }

## Unicode

Unicode is only tested to work with perl-5.8.2 and up.

See also ["BOM"](#bom).

The simplest way to ensure the correct encoding is used for  in- and output
is by either setting layers on the filehandles, or setting the ["encoding"](#encoding)
argument for ["csv"](#csv).

    open my $fh, "<:encoding(UTF-8)", "in.csv"  or die "in.csv: $!";
   or
    my $aoa = csv (in => "in.csv",     encoding => "UTF-8");

    open my $fh, ">:encoding(UTF-8)", "out.csv" or die "out.csv: $!";
   or
    csv (in => $aoa, out => "out.csv", encoding => "UTF-8");

On parsing (both for  ["getline"](#getline) and  ["parse"](#parse)),  if the source is marked
being UTF8, then all fields that are marked binary will also be marked UTF8.

On combining (["print"](#print)  and  ["combine"](#combine)):  if any of the combining fields
was marked UTF8, the resulting string will be marked as UTF8.  Note however
that all fields  _before_  the first field marked UTF8 and contained 8-bit
characters that were not upgraded to UTF8,  these will be  `bytes`  in the
resulting string too, possibly causing unexpected errors.  If you pass data
of different encoding,  or you don't know if there is  different  encoding,
force it to be upgraded before you pass them on:

    $csv->print ($fh, [ map { utf8::upgrade (my $x = $_); $x } @data ]);

For complete control over encoding, please use [Text::CSV::Encoded](https://metacpan.org/pod/Text%3A%3ACSV%3A%3AEncoded):

    use Text::CSV::Encoded;
    my $csv = Text::CSV::Encoded->new ({
        encoding_in  => "iso-8859-1", # the encoding comes into   Perl
        encoding_out => "cp1252",     # the encoding comes out of Perl
        });

    $csv = Text::CSV::Encoded->new ({ encoding  => "utf8" });
    # combine () and print () accept *literally* utf8 encoded data
    # parse () and getline () return *literally* utf8 encoded data

    $csv = Text::CSV::Encoded->new ({ encoding  => undef }); # default
    # combine () and print () accept UTF8 marked data
    # parse () and getline () return UTF8 marked data

## BOM

BOM  (or Byte Order Mark)  handling is available only inside the ["header"](#header)
method.   This method supports the following encodings: `utf-8`, `utf-1`,
`utf-32be`, `utf-32le`, `utf-16be`, `utf-16le`, `utf-ebcdic`, `scsu`,
`bocu-1`, and `gb-18030`. See [Wikipedia](https://en.wikipedia.org/wiki/Byte_order_mark).

If a file has a BOM, the easiest way to deal with that is

    my $aoh = csv (in => $file, detect_bom => 1);

All records will be encoded based on the detected BOM.

This implies a call to the  ["header"](#header)  method,  which defaults to also set
the ["column\_names"](#column_names). So this is **not** the same as

    my $aoh = csv (in => $file, headers => "auto");

which only reads the first record to set  ["column\_names"](#column_names)  but ignores any
meaning of possible present BOM.

# SPECIFICATION

While no formal specification for CSV exists, [RFC 4180](https://tools.ietf.org/html/rfc4180)
(_1_) describes the common format and establishes  `text/csv` as the MIME
type registered with the IANA. [RFC 7111](http://tools.ietf.org/html/rfc7111)
(_2_) adds fragments to CSV.

Many informal documents exist that describe the `CSV` format.   ["How To:
The Comma Separated Value (CSV) File Format"](http://www.creativyst.com/Doc/Articles/CSV/CSV01.htm)
(_3_)  provides an overview of the  `CSV`  format in the most widely used
applications and explains how it can best be used and supported.

    1) https://tools.ietf.org/html/rfc4180
    2) https://tools.ietf.org/html/rfc7111
    3) http://www.creativyst.com/Doc/Articles/CSV/CSV01.htm

The basic rules are as follows:

**CSV**  is a delimited data format that has fields/columns separated by the
comma character and records/rows separated by newlines. Fields that contain
a special character (comma, newline, or double quote),  must be enclosed in
double quotes. However, if a line contains a single entry that is the empty
string, it may be enclosed in double quotes.  If a field's value contains a
double quote character it is escaped by placing another double quote
character next to it. The `CSV` file format does not require a specific
character encoding, byte order, or line terminator format.

- Each record is a single line ended by a line feed  (ASCII/`LF`=`0x0A`) or
a carriage return and line feed pair (ASCII/`CRLF`=`0x0D 0x0A`), however,
line-breaks may be embedded.
- Fields are separated by commas.
- Allowable characters within a `CSV` field include `0x09` (`TAB`) and the
inclusive range of `0x20` (space) through `0x7E` (tilde).  In binary mode
all characters are accepted, at least in quoted fields.
- A field within  `CSV`  must be surrounded by  double-quotes to  contain  a
separator character (comma).

Though this is the most clear and restrictive definition,  Text::CSV\_XS  is
way more liberal than this, and allows extension:

- Line termination by a single carriage return is accepted by default
- The separation-, escape-, and escape- characters can be any ASCII character
in the range from  `0x20` (space) to  `0x7E` (tilde).  Characters outside
this range may or may not work as expected.  Multibyte characters, like UTF
`U+060C` (ARABIC COMMA),   `U+FF0C` (FULLWIDTH COMMA),  `U+241B` (SYMBOL
FOR ESCAPE), `U+2424` (SYMBOL FOR NEWLINE), `U+FF02` (FULLWIDTH QUOTATION
MARK), and `U+201C` (LEFT DOUBLE QUOTATION MARK) (to give some examples of
what might look promising) work for newer versions of perl for `sep_char`,
and `quote_char` but not for `escape_char`.

    If you use perl-5.8.2 or higher these three attributes are utf8-decoded, to
    increase the likelihood of success. This way `U+00FE` will be allowed as a
    quote character.

- A field in  `CSV`  must be surrounded by double-quotes to make an embedded
double-quote, represented by a pair of consecutive double-quotes, valid. In
binary mode you may additionally use the sequence  `"0` for representation
of a NULL byte. Using `0x00` in binary mode is just as valid.
- Several violations of the above specification may be lifted by passing some
options as attributes to the object constructor.

# METHODS

## version


(Class method) Returns the current module version.

## new


(Class method) Returns a new instance of class Text::CSV\_XS. The attributes
are described by the (optional) hash ref `\%attr`.

    my $csv = Text::CSV_XS->new ({ attributes ... });

The following attributes are available:

### eol


    my $csv = Text::CSV_XS->new ({ eol => $/ });
              $csv->eol (undef);
    my $eol = $csv->eol;

The end-of-line string to add to rows for ["print"](#print) or the record separator
for ["getline"](#getline).

When not passed in a **parser** instance,  the default behavior is to accept
`\n`, `\r`, and `\r\n`, so it is probably safer to not specify `eol` at
all. Passing `undef` or the empty string behave the same.

When not passed in a **generating** instance,  records are not terminated at
all, so it is probably wise to pass something you expect. A safe choice for
`eol` on output is either `$/` or `\r\n`.

Common values for `eol` are `"\012"` (`\n` or Line Feed),  `"\015\012"`
(`\r\n` or Carriage Return, Line Feed),  and `"\015"`  (`\r` or Carriage
Return). The [`eol`](#eol) attribute cannot exceed 7 (ASCII) characters.

If both `$/` and [`eol`](#eol) equal `"\015"`, parsing lines that end on
only a Carriage Return without Line Feed, will be ["parse"](#parse)d correct.

### sep\_char


    my $csv = Text::CSV_XS->new ({ sep_char => ";" });
            $csv->sep_char (";");
    my $c = $csv->sep_char;

The char used to separate fields, by default a comma. (`,`).  Limited to a
single-byte character, usually in the range from `0x20` (space) to `0x7E`
(tilde). When longer sequences are required, use [`sep`](#sep).

The separation character can not be equal to the quote character  or to the
escape character.

See also ["CAVEATS"](#caveats)

### sep


    my $csv = Text::CSV_XS->new ({ sep => "\N{FULLWIDTH COMMA}" });
              $csv->sep (";");
    my $sep = $csv->sep;

The chars used to separate fields, by default undefined. Limited to 8 bytes.

When set, overrules [`sep_char`](#sep_char).  If its length is one byte it
acts as an alias to [`sep_char`](#sep_char).

See also ["CAVEATS"](#caveats)

### quote\_char


    my $csv = Text::CSV_XS->new ({ quote_char => "'" });
            $csv->quote_char (undef);
    my $c = $csv->quote_char;

The character to quote fields containing blanks or binary data,  by default
the double quote character (`"`).  A value of undef suppresses quote chars
(for simple cases only). Limited to a single-byte character, usually in the
range from  `0x20` (space) to  `0x7E` (tilde).  When longer sequences are
required, use [`quote`](#quote).

`quote_char` can not be equal to [`sep_char`](#sep_char).

### quote


    my $csv = Text::CSV_XS->new ({ quote => "\N{FULLWIDTH QUOTATION MARK}" });
                $csv->quote ("'");
    my $quote = $csv->quote;

The chars used to quote fields, by default undefined. Limited to 8 bytes.

When set, overrules [`quote_char`](#quote_char). If its length is one byte
it acts as an alias to [`quote_char`](#quote_char).

This method does not support `undef`.  Use [`quote_char`](#quote_char) to
disable quotation.

See also ["CAVEATS"](#caveats)

### escape\_char


    my $csv = Text::CSV_XS->new ({ escape_char => "\\" });
            $csv->escape_char (":");
    my $c = $csv->escape_char;

The character to  escape  certain characters inside quoted fields.  This is
limited to a  single-byte  character,  usually  in the  range from  `0x20`
(space) to `0x7E` (tilde).

The `escape_char` defaults to being the double-quote mark (`"`). In other
words the same as the default [`quote_char`](#quote_char). This means that
doubling the quote mark in a field escapes it:

    "foo","bar","Escape ""quote mark"" with two ""quote marks""","baz"

If  you  change  the   [`quote_char`](#quote_char)  without  changing  the
`escape_char`,  the  `escape_char` will still be the double-quote (`"`).
If instead you want to escape the  [`quote_char`](#quote_char) by doubling
it you will need to also change the  `escape_char`  to be the same as what
you have changed the [`quote_char`](#quote_char) to.

Setting `escape_char` to &lt;undef> or `""` will disable escaping completely
and is greatly discouraged. This will also disable `escape_null`.

The escape character can not be equal to the separation character.

### binary


    my $csv = Text::CSV_XS->new ({ binary => 1 });
            $csv->binary (0);
    my $f = $csv->binary;

If this attribute is `1`,  you may use binary characters in quoted fields,
including line feeds, carriage returns and `NULL` bytes. (The latter could
be escaped as `"0`.) By default this feature is off.

If a string is marked UTF8,  `binary` will be turned on automatically when
binary characters other than `CR` and `NL` are encountered.   Note that a
simple string like `"\x{00a0}"` might still be binary, but not marked UTF8,
so setting `{ binary => 1 }` is still a wise option.

### strict


    my $csv = Text::CSV_XS->new ({ strict => 1 });
            $csv->strict (0);
    my $f = $csv->strict;

If this attribute is set to `1`, any row that parses to a different number
of fields than the previous row will cause the parser to throw error 2014.

### skip\_empty\_rows


    my $csv = Text::CSV_XS->new ({ skip_empty_rows => 1 });
            $csv->skip_empty_rows (0);
    my $f = $csv->skip_empty_rows;

If this attribute is set to `1`,  any row that has an  ["eol"](#eol) immediately
following the start of line will be skipped.  Default behavior is to return
one single empty field.

This attribute is only used in parsing.

### formula\_handling

### formula



    my $csv = Text::CSV_XS->new ({ formula => "none" });
            $csv->formula ("none");
    my $f = $csv->formula;

This defines the behavior of fields containing _formulas_. As formulas are
considered dangerous in spreadsheets, this attribute can define an optional
action to be taken if a field starts with an equal sign (`=`).

For purpose of code-readability, this can also be written as

    my $csv = Text::CSV_XS->new ({ formula_handling => "none" });
            $csv->formula_handling ("none");
    my $f = $csv->formula_handling;

Possible values for this attribute are

- none

    Take no specific action. This is the default.

        $csv->formula ("none");

- die

    Cause the process to `die` whenever a leading `=` is encountered.

        $csv->formula ("die");

- croak

    Cause the process to `croak` whenever a leading `=` is encountered.  (See
    [Carp](https://metacpan.org/pod/Carp))

        $csv->formula ("croak");

- diag

    Report position and content of the field whenever a leading  `=` is found.
    The value of the field is unchanged.

        $csv->formula ("diag");

- empty

    Replace the content of fields that start with a `=` with the empty string.

        $csv->formula ("empty");
        $csv->formula ("");

- undef

    Replace the content of fields that start with a `=` with `undef`.

        $csv->formula ("undef");
        $csv->formula (undef);

- a callback

    Modify the content of fields that start with a  `=`  with the return-value
    of the callback.  The original content of the field is available inside the
    callback as `$_`;

        # Replace all formula's with 42
        $csv->formula (sub { 42; });

        # same as $csv->formula ("empty") but slower
        $csv->formula (sub { "" });

        # Allow =4+12
        $csv->formula (sub { s/^=(\d+\+\d+)$/$1/eer });

        # Allow more complex calculations
        $csv->formula (sub { eval { s{^=([-+*/0-9()]+)$}{$1}ee }; $_ });

All other values will give a warning and then fallback to `diag`.

### decode\_utf8


    my $csv = Text::CSV_XS->new ({ decode_utf8 => 1 });
            $csv->decode_utf8 (0);
    my $f = $csv->decode_utf8;

This attributes defaults to TRUE.

While _parsing_,  fields that are valid UTF-8, are automatically set to be
UTF-8, so that

    $csv->parse ("\xC4\xA8\n");

results in

    PV("\304\250"\0) [UTF8 "\x{128}"]

Sometimes it might not be a desired action.  To prevent those upgrades, set
this attribute to false, and the result will be

    PV("\304\250"\0)

### auto\_diag


    my $csv = Text::CSV_XS->new ({ auto_diag => 1 });
            $csv->auto_diag (2);
    my $l = $csv->auto_diag;

Set this attribute to a number between `1` and `9` causes  ["error\_diag"](#error_diag)
to be automatically called in void context upon errors.

In case of error `2012 - EOF`, this call will be void.

If `auto_diag` is set to a numeric value greater than `1`, it will `die`
on errors instead of `warn`.  If set to anything unrecognized,  it will be
silently ignored.

Future extensions to this feature will include more reliable auto-detection
of  `autodie`  being active in the scope of which the error occurred which
will increment the value of `auto_diag` with  `1` the moment the error is
detected.

### diag\_verbose


    my $csv = Text::CSV_XS->new ({ diag_verbose => 1 });
            $csv->diag_verbose (2);
    my $l = $csv->diag_verbose;

Set the verbosity of the output triggered by `auto_diag`.   Currently only
adds the current  input-record-number  (if known)  to the diagnostic output
with an indication of the position of the error.

### blank\_is\_undef


    my $csv = Text::CSV_XS->new ({ blank_is_undef => 1 });
            $csv->blank_is_undef (0);
    my $f = $csv->blank_is_undef;

Under normal circumstances, `CSV` data makes no distinction between quoted-
and unquoted empty fields.  These both end up in an empty string field once
read, thus

    1,"",," ",2

is read as

    ("1", "", "", " ", "2")

When _writing_  `CSV` files with either  [`always_quote`](#always_quote)
or  [`quote_empty`](#quote_empty) set, the unquoted  _empty_ field is the
result of an undefined value.   To enable this distinction when  _reading_
`CSV`  data,  the  `blank_is_undef`  attribute will cause  unquoted empty
fields to be set to `undef`, causing the above to be parsed as

    ("1", "", undef, " ", "2")

Note that this is specifically important when loading  `CSV` fields into a
database that allows `NULL` values,  as the perl equivalent for `NULL` is
`undef` in [DBI](https://metacpan.org/pod/DBI) land.

### empty\_is\_undef


    my $csv = Text::CSV_XS->new ({ empty_is_undef => 1 });
            $csv->empty_is_undef (0);
    my $f = $csv->empty_is_undef;

Going one  step  further  than  [`blank_is_undef`](#blank_is_undef),  this
attribute converts all empty fields to `undef`, so

    1,"",," ",2

is read as

    (1, undef, undef, " ", 2)

Note that this affects only fields that are  originally  empty,  not fields
that are empty after stripping allowed whitespace. YMMV.

### allow\_whitespace


    my $csv = Text::CSV_XS->new ({ allow_whitespace => 1 });
            $csv->allow_whitespace (0);
    my $f = $csv->allow_whitespace;

When this option is set to true,  the whitespace  (`TAB`'s and `SPACE`'s)
surrounding  the  separation character  is removed when parsing.  If either
`TAB` or `SPACE` is one of the three characters [`sep_char`](#sep_char),
[`quote_char`](#quote_char), or [`escape_char`](#escape_char) it will not
be considered whitespace.

Now lines like:

    1 , "foo" , bar , 3 , zapp

are parsed as valid `CSV`, even though it violates the `CSV` specs.

Note that  **all**  whitespace is stripped from both  start and  end of each
field.  That would make it  _more_ than a _feature_ to enable parsing bad
`CSV` lines, as

    1,   2.0,  3,   ape  , monkey

will now be parsed as

    ("1", "2.0", "3", "ape", "monkey")

even if the original line was perfectly acceptable `CSV`.

### allow\_loose\_quotes


    my $csv = Text::CSV_XS->new ({ allow_loose_quotes => 1 });
            $csv->allow_loose_quotes (0);
    my $f = $csv->allow_loose_quotes;

By default, parsing unquoted fields containing [`quote_char`](#quote_char)
characters like

    1,foo "bar" baz,42

would result in parse error 2034.  Though it is still bad practice to allow
this format,  we  cannot  help  the  fact  that  some  vendors  make  their
applications spit out lines styled this way.

If there is **really** bad `CSV` data, like

    1,"foo "bar" baz",42

or

    1,""foo bar baz"",42

there is a way to get this data-line parsed and leave the quotes inside the
quoted field as-is.  This can be achieved by setting  `allow_loose_quotes`
**AND** making sure that the [`escape_char`](#escape_char) is  _not_ equal
to [`quote_char`](#quote_char).

### allow\_loose\_escapes


    my $csv = Text::CSV_XS->new ({ allow_loose_escapes => 1 });
            $csv->allow_loose_escapes (0);
    my $f = $csv->allow_loose_escapes;

Parsing fields  that  have  [`escape_char`](#escape_char)  characters that
escape characters that do not need to be escaped, like:

    my $csv = Text::CSV_XS->new ({ escape_char => "\\" });
    $csv->parse (qq{1,"my bar\'s",baz,42});

would result in parse error 2025.   Though it is bad practice to allow this
format,  this attribute enables you to treat all escape character sequences
equal.

### allow\_unquoted\_escape


    my $csv = Text::CSV_XS->new ({ allow_unquoted_escape => 1 });
            $csv->allow_unquoted_escape (0);
    my $f = $csv->allow_unquoted_escape;

A backward compatibility issue where [`escape_char`](#escape_char) differs
from [`quote_char`](#quote_char)  prevents  [`escape_char`](#escape_char)
to be in the first position of a field.  If [`quote_char`](#quote_char) is
equal to the default `"` and [`escape_char`](#escape_char) is set to `\`,
this would be illegal:

    1,\0,2

Setting this attribute to `1`  might help to overcome issues with backward
compatibility and allow this style.

### always\_quote


    my $csv = Text::CSV_XS->new ({ always_quote => 1 });
            $csv->always_quote (0);
    my $f = $csv->always_quote;

By default the generated fields are quoted only if they _need_ to be.  For
example, if they contain the separator character. If you set this attribute
to `1` then _all_ defined fields will be quoted. (`undef` fields are not
quoted, see ["blank\_is\_undef"](#blank_is_undef)). This makes it quite often easier to handle
exported data in external applications.   (Poor creatures who are better to
use Text::CSV\_XS. :)

### quote\_space


    my $csv = Text::CSV_XS->new ({ quote_space => 1 });
            $csv->quote_space (0);
    my $f = $csv->quote_space;

By default,  a space in a field would trigger quotation.  As no rule exists
this to be forced in `CSV`,  nor any for the opposite, the default is true
for safety.   You can exclude the space  from this trigger  by setting this
attribute to 0.

### quote\_empty


    my $csv = Text::CSV_XS->new ({ quote_empty => 1 });
            $csv->quote_empty (0);
    my $f = $csv->quote_empty;

By default the generated fields are quoted only if they _need_ to be.   An
empty (defined) field does not need quotation. If you set this attribute to
`1` then _empty_ defined fields will be quoted.  (`undef` fields are not
quoted, see ["blank\_is\_undef"](#blank_is_undef)). See also [`always_quote`](#always_quote).

### quote\_binary


    my $csv = Text::CSV_XS->new ({ quote_binary => 1 });
            $csv->quote_binary (0);
    my $f = $csv->quote_binary;

By default,  all "unsafe" bytes inside a string cause the combined field to
be quoted.  By setting this attribute to `0`, you can disable that trigger
for bytes >= `0x7F`.

### escape\_null



    my $csv = Text::CSV_XS->new ({ escape_null => 1 });
            $csv->escape_null (0);
    my $f = $csv->escape_null;

By default, a `NULL` byte in a field would be escaped. This option enables
you to treat the  `NULL`  byte as a simple binary character in binary mode
(the `{ binary => 1 }` is set).  The default is true.  You can prevent
`NULL` escapes by setting this attribute to `0`.

When the `escape_char` attribute is set to undefined,  this attribute will
be set to false.

The default setting will encode "=\\x00=" as

    "="0="

With `escape_null` set, this will result in

    "=\x00="

The default when using the `csv` function is `false`.

For backward compatibility reasons,  the deprecated old name  `quote_null`
is still recognized.

### keep\_meta\_info


    my $csv = Text::CSV_XS->new ({ keep_meta_info => 1 });
            $csv->keep_meta_info (0);
    my $f = $csv->keep_meta_info;

By default, the parsing of input records is as simple and fast as possible.
However,  some parsing information - like quotation of the original field -
is lost in that process.  Setting this flag to true enables retrieving that
information after parsing with  the methods  ["meta\_info"](#meta_info),  ["is\_quoted"](#is_quoted),
and ["is\_binary"](#is_binary) described below.  Default is false for performance.

If you set this attribute to a value greater than 9,   then you can control
output quotation style like it was used in the input of the the last parsed
record (unless quotation was added because of other reasons).

    my $csv = Text::CSV_XS->new ({
       binary         => 1,
       keep_meta_info => 1,
       quote_space    => 0,
       });

    my $row = $csv->parse (q{1,,"", ," ",f,"g","h""h",help,"help"});

    $csv->print (*STDOUT, \@row);
    # 1,,, , ,f,g,"h""h",help,help
    $csv->keep_meta_info (11);
    $csv->print (*STDOUT, \@row);
    # 1,,"", ," ",f,"g","h""h",help,"help"

### undef\_str


    my $csv = Text::CSV_XS->new ({ undef_str => "\\N" });
            $csv->undef_str (undef);
    my $s = $csv->undef_str;

This attribute optionally defines the output of undefined fields. The value
passed is not changed at all, so if it needs quotation, the quotation needs
to be included in the value of the attribute.  Use with caution, as passing
a value like  `",",,,,"""`  will for sure mess up your output. The default
for this attribute is `undef`, meaning no special treatment.

This attribute is useful when exporting  CSV data  to be imported in custom
loaders, like for MySQL, that recognize special sequences for `NULL` data.

This attribute has no meaning when parsing CSV data.

### comment\_str


    my $csv = Text::CSV_XS->new ({ comment_str => "#" });
            $csv->comment_str (undef);
    my $s = $csv->comment_str;

This attribute optionally defines a string to be recognized as comment.  If
this attribute is defined,   all lines starting with this sequence will not
be parsed as CSV but skipped as comment.

This attribute has no meaning when generating CSV.

Comment strings that start with any of the special characters/sequences are
not supported (so it cannot start with any of ["sep\_char"](#sep_char), ["quote\_char"](#quote_char),
["escape\_char"](#escape_char), ["sep"](#sep), ["quote"](#quote), or ["eol"](#eol)).

For convenience, `comment` is an alias for `comment_str`.

### verbatim


    my $csv = Text::CSV_XS->new ({ verbatim => 1 });
            $csv->verbatim (0);
    my $f = $csv->verbatim;

This is a quite controversial attribute to set,  but makes some hard things
possible.

The rationale behind this attribute is to tell the parser that the normally
special characters newline (`NL`) and Carriage Return (`CR`)  will not be
special when this flag is set,  and be dealt with  as being ordinary binary
characters. This will ease working with data with embedded newlines.

When  `verbatim`  is used with  ["getline"](#getline),  ["getline"](#getline)  auto-`chomp`'s
every line.

Imagine a file format like

    M^^Hans^Janssen^Klas 2\n2A^Ja^11-06-2007#\r\n

where, the line ending is a very specific `"#\r\n"`, and the sep\_char is a
`^` (caret).   None of the fields is quoted,   but embedded binary data is
likely to be present. With the specific line ending, this should not be too
hard to detect.

By default,  Text::CSV\_XS'  parse function is instructed to only know about
`"\n"` and `"\r"`  to be legal line endings,  and so has to deal with the
embedded newline as a real `end-of-line`,  so it can scan the next line if
binary is true, and the newline is inside a quoted field. With this option,
we tell ["parse"](#parse) to parse the line as if `"\n"` is just nothing more than
a binary character.

For ["parse"](#parse) this means that the parser has no more idea about line ending
and ["getline"](#getline) `chomp`s line endings on reading.

### types

A set of column types; the attribute is immediately passed to the ["types"](#types)
method.

### callbacks


See the ["Callbacks"](#callbacks) section below.

### accessors

To sum it up,

    $csv = Text::CSV_XS->new ();

is equivalent to

    $csv = Text::CSV_XS->new ({
        eol                   => undef, # \r, \n, or \r\n
        sep_char              => ',',
        sep                   => undef,
        quote_char            => '"',
        quote                 => undef,
        escape_char           => '"',
        binary                => 0,
        decode_utf8           => 1,
        auto_diag             => 0,
        diag_verbose          => 0,
        blank_is_undef        => 0,
        empty_is_undef        => 0,
        allow_whitespace      => 0,
        allow_loose_quotes    => 0,
        allow_loose_escapes   => 0,
        allow_unquoted_escape => 0,
        always_quote          => 0,
        quote_empty           => 0,
        quote_space           => 1,
        escape_null           => 1,
        quote_binary          => 1,
        keep_meta_info        => 0,
        strict                => 0,
        skip_empty_rows       => 0,
        formula               => 0,
        verbatim              => 0,
        undef_str             => undef,
        comment_str           => undef,
        types                 => undef,
        callbacks             => undef,
        });

For all of the above mentioned flags, an accessor method is available where
you can inquire the current value, or change the value

    my $quote = $csv->quote_char;
    $csv->binary (1);

It is not wise to change these settings halfway through writing `CSV` data
to a stream. If however you want to create a new stream using the available
`CSV` object, there is no harm in changing them.

If the ["new"](#new) constructor call fails,  it returns `undef`,  and makes the
fail reason available through the ["error\_diag"](#error_diag) method.

    $csv = Text::CSV_XS->new ({ ecs_char => 1 }) or
        die "".Text::CSV_XS->error_diag ();

["error\_diag"](#error_diag) will return a string like

    "INI - Unknown attribute 'ecs_char'"

## known\_attributes


    @attr = Text::CSV_XS->known_attributes;
    @attr = Text::CSV_XS::known_attributes;
    @attr = $csv->known_attributes;

This method will return an ordered list of all the supported  attributes as
described above.   This can be useful for knowing what attributes are valid
in classes that use or extend Text::CSV\_XS.

## print


    $status = $csv->print ($fh, $colref);

Similar to  ["combine"](#combine) + ["string"](#string) + ["print"](#print),  but much more efficient.
It expects an array ref as input  (not an array!)  and the resulting string
is not really  created,  but  immediately  written  to the  `$fh`  object,
typically an IO handle or any other object that offers a ["print"](#print) method.

For performance reasons  `print`  does not create a result string,  so all
["string"](#string), ["status"](#status), ["fields"](#fields), and ["error\_input"](#error_input) methods will return
undefined information after executing this method.

If `$colref` is `undef`  (explicit,  not through a variable argument) and
["bind\_columns"](#bind_columns)  was used to specify fields to be printed,  it is possible
to make performance improvements, as otherwise data would have to be copied
as arguments to the method call:

    $csv->bind_columns (\($foo, $bar));
    $status = $csv->print ($fh, undef);

A short benchmark

    my @data = ("aa" .. "zz");
    $csv->bind_columns (\(@data));

    $csv->print ($fh, [ @data ]);   # 11800 recs/sec
    $csv->print ($fh,  \@data  );   # 57600 recs/sec
    $csv->print ($fh,   undef  );   # 48500 recs/sec

## say


    $status = $csv->say ($fh, $colref);

Like [`print`](#print), but [`eol`](#eol) defaults to `$\`.

## print\_hr


    $csv->print_hr ($fh, $ref);

Provides an easy way  to print a  `$ref`  (as fetched with ["getline\_hr"](#getline_hr))
provided the column names are set with ["column\_names"](#column_names).

It is just a wrapper method with basic parameter checks over

    $csv->print ($fh, [ map { $ref->{$_} } $csv->column_names ]);

## combine


    $status = $csv->combine (@fields);

This method constructs a `CSV` record from  `@fields`,  returning success
or failure.   Failure can result from lack of arguments or an argument that
contains an invalid character.   Upon success,  ["string"](#string) can be called to
retrieve the resultant `CSV` string.  Upon failure,  the value returned by
["string"](#string) is undefined and ["error\_input"](#error_input) could be called to retrieve the
invalid argument.

## string


    $line = $csv->string ();

This method returns the input to  ["parse"](#parse)  or the resultant `CSV` string
of ["combine"](#combine), whichever was called more recently.

## getline


    $colref = $csv->getline ($fh);

This is the counterpart to  ["print"](#print),  as ["parse"](#parse)  is the counterpart to
["combine"](#combine):  it parses a row from the `$fh`  handle using the ["getline"](#getline)
method associated with `$fh`  and parses this row into an array ref.  This
array ref is returned by the function or `undef` for failure.  When `$fh`
does not support `getline`, you are likely to hit errors.

When fields are bound with ["bind\_columns"](#bind_columns) the return value is a reference
to an empty list.

The ["string"](#string), ["fields"](#fields), and ["status"](#status) methods are meaningless again.

## getline\_all


    $arrayref = $csv->getline_all ($fh);
    $arrayref = $csv->getline_all ($fh, $offset);
    $arrayref = $csv->getline_all ($fh, $offset, $length);

This will return a reference to a list of [getline ($fh)](#getline) results.
In this call, `keep_meta_info` is disabled.  If `$offset` is negative, as
with `splice`, only the last  `abs ($offset)` records of `$fh` are taken
into consideration.

Given a CSV file with 10 lines:

    lines call
    ----- ---------------------------------------------------------
    0..9  $csv->getline_all ($fh)         # all
    0..9  $csv->getline_all ($fh,  0)     # all
    8..9  $csv->getline_all ($fh,  8)     # start at 8
    -     $csv->getline_all ($fh,  0,  0) # start at 0 first 0 rows
    0..4  $csv->getline_all ($fh,  0,  5) # start at 0 first 5 rows
    4..5  $csv->getline_all ($fh,  4,  2) # start at 4 first 2 rows
    8..9  $csv->getline_all ($fh, -2)     # last 2 rows
    6..7  $csv->getline_all ($fh, -4,  2) # first 2 of last  4 rows

## getline\_hr


The ["getline\_hr"](#getline_hr) and ["column\_names"](#column_names) methods work together  to allow you
to have rows returned as hashrefs.  You must call ["column\_names"](#column_names) first to
declare your column names.

    $csv->column_names (qw( code name price description ));
    $hr = $csv->getline_hr ($fh);
    print "Price for $hr->{name} is $hr->{price} EUR\n";

["getline\_hr"](#getline_hr) will croak if called before ["column\_names"](#column_names).

Note that  ["getline\_hr"](#getline_hr)  creates a hashref for every row and will be much
slower than the combined use of ["bind\_columns"](#bind_columns)  and ["getline"](#getline) but still
offering the same easy to use hashref inside the loop:

    my @cols = @{$csv->getline ($fh)};
    $csv->column_names (@cols);
    while (my $row = $csv->getline_hr ($fh)) {
        print $row->{price};
        }

Could easily be rewritten to the much faster:

    my @cols = @{$csv->getline ($fh)};
    my $row = {};
    $csv->bind_columns (\@{$row}{@cols});
    while ($csv->getline ($fh)) {
        print $row->{price};
        }

Your mileage may vary for the size of the data and the number of rows. With
perl-5.14.2 the comparison for a 100\_000 line file with 14 columns:

               Rate hashrefs getlines
    hashrefs 1.00/s       --     -76%
    getlines 4.15/s     313%       --

## getline\_hr\_all


    $arrayref = $csv->getline_hr_all ($fh);
    $arrayref = $csv->getline_hr_all ($fh, $offset);
    $arrayref = $csv->getline_hr_all ($fh, $offset, $length);

This will return a reference to a list of   [getline\_hr ($fh)](#getline_hr)
results.  In this call, [`keep_meta_info`](#keep_meta_info) is disabled.

## parse


    $status = $csv->parse ($line);

This method decomposes a  `CSV`  string into fields,  returning success or
failure.   Failure can result from a lack of argument  or the given  `CSV`
string is improperly formatted.   Upon success, ["fields"](#fields) can be called to
retrieve the decomposed fields. Upon failure calling ["fields"](#fields) will return
undefined data and  ["error\_input"](#error_input)  can be called to retrieve  the invalid
argument.

You may use the ["types"](#types)  method for setting column types.  See ["types"](#types)'
description below.

The `$line` argument is supposed to be a simple scalar. Everything else is
supposed to croak and set error 1500.

## fragment


This function tries to implement RFC7111  (URI Fragment Identifiers for the
text/csv Media Type) - http://tools.ietf.org/html/rfc7111

    my $AoA = $csv->fragment ($fh, $spec);

In specifications,  `*` is used to specify the _last_ item, a dash (`-`)
to indicate a range.   All indices are `1`-based:  the first row or column
has index `1`. Selections can be combined with the semi-colon (`;`).

When using this method in combination with  ["column\_names"](#column_names),  the returned
reference  will point to a  list of hashes  instead of a  list of lists.  A
disjointed  cell-based combined selection  might return rows with different
number of columns making the use of hashes unpredictable.

    $csv->column_names ("Name", "Age");
    my $AoH = $csv->fragment ($fh, "col=3;8");

If the ["after\_parse"](#after_parse) callback is active,  it is also called on every line
parsed and skipped before the fragment.

- row

        row=4
        row=5-7
        row=6-*
        row=1-2;4;6-*

- col

        col=2
        col=1-3
        col=4-*
        col=1-2;4;7-*

- cell

    In cell-based selection, the comma (`,`) is used to pair row and column

        cell=4,1

    The range operator (`-`) using `cell`s can be used to define top-left and
    bottom-right `cell` location

        cell=3,1-4,6

    The `*` is only allowed in the second part of a pair

        cell=3,2-*,2    # row 3 till end, only column 2
        cell=3,2-3,*    # column 2 till end, only row 3
        cell=3,2-*,*    # strip row 1 and 2, and column 1

    Cells and cell ranges may be combined with `;`, possibly resulting in rows
    with different numbers of columns

        cell=1,1-2,2;3,3-4,4;1,4;4,1

    Disjointed selections will only return selected cells.   The cells that are
    not  specified  will  not  be  included  in the  returned set,  not even as
    `undef`.  As an example given a `CSV` like

        11,12,13,...19
        21,22,...28,29
        :            :
        91,...97,98,99

    with `cell=1,1-2,2;3,3-4,4;1,4;4,1` will return:

        11,12,14
        21,22
        33,34
        41,43,44

    Overlapping cell-specs will return those cells only once, So
    `cell=1,1-3,3;2,2-4,4;2,3;4,2` will return:

        11,12,13
        21,22,23,24
        31,32,33,34
        42,43,44

[RFC7111](http://tools.ietf.org/html/rfc7111) does  **not**  allow different
types of specs to be combined   (either `row` _or_ `col` _or_ `cell`).
Passing an invalid fragment specification will croak and set error 2013.

## column\_names


Set the "keys" that will be used in the  ["getline\_hr"](#getline_hr)  calls.  If no keys
(column names) are passed, it will return the current setting as a list.

["column\_names"](#column_names) accepts a list of scalars  (the column names)  or a single
array\_ref, so you can pass the return value from ["getline"](#getline) too:

    $csv->column_names ($csv->getline ($fh));

["column\_names"](#column_names) does **no** checking on duplicates at all, which might lead
to unexpected results.   Undefined entries will be replaced with the string
`"\cAUNDEF\cA"`, so

    $csv->column_names (undef, "", "name", "name");
    $hr = $csv->getline_hr ($fh);

will set `$hr->{"\cAUNDEF\cA"}` to the 1st field,  `$hr->{""}` to
the 2nd field, and `$hr->{name}` to the 4th field,  discarding the 3rd
field.

["column\_names"](#column_names) croaks on invalid arguments.

## header

This method does NOT work in perl-5.6.x

Parse the CSV header and set [`sep`](#sep), column\_names and encoding.

    my @hdr = $csv->header ($fh);
    $csv->header ($fh, { sep_set => [ ";", ",", "|", "\t" ] });
    $csv->header ($fh, { detect_bom => 1, munge_column_names => "lc" });

The first argument should be a file handle.

This method resets some object properties,  as it is supposed to be invoked
only once per file or stream.  It will leave attributes `column_names` and
`bound_columns` alone if setting column names is disabled. Reading headers
on previously process objects might fail on perl-5.8.0 and older.

Assuming that the file opened for parsing has a header, and the header does
not contain problematic characters like embedded newlines,   read the first
line from the open handle then auto-detect whether the header separates the
column names with a character from the allowed separator list.

If any of the allowed separators matches,  and none of the _other_ allowed
separators match,  set  [`sep`](#sep)  to that  separator  for the current
CSV\_XS instance and use it to parse the first line, map those to lowercase,
and use that to set the instance ["column\_names"](#column_names):

    my $csv = Text::CSV_XS->new ({ binary => 1, auto_diag => 1 });
    open my $fh, "<", "file.csv";
    binmode $fh; # for Windows
    $csv->header ($fh);
    while (my $row = $csv->getline_hr ($fh)) {
        ...
        }

If the header is empty,  contains more than one unique separator out of the
allowed set,  contains empty fields,   or contains identical fields  (after
folding), it will croak with error 1010, 1011, 1012, or 1013 respectively.

If the header contains embedded newlines or is not valid  CSV  in any other
way, this method will croak and leave the parse error untouched.

A successful call to `header`  will always set the  [`sep`](#sep)  of the
`$csv` object. This behavior can not be disabled.

### return value

On error this method will croak.

In list context,  the headers will be returned whether they are used to set
["column\_names"](#column_names) or not.

In scalar context, the instance itself is returned.  **Note**: the values as
found in the header will effectively be  **lost** if  `set_column_names` is
false.

### Options

- sep\_set


        $csv->header ($fh, { sep_set => [ ";", ",", "|", "\t" ] });

    The list of legal separators defaults to `[ ";", "," ]` and can be changed
    by this option.  As this is probably the most often used option,  it can be
    passed on its own as an unnamed argument:

        $csv->header ($fh, [ ";", ",", "|", "\t", "::", "\x{2063}" ]);

    Multi-byte  sequences are allowed,  both multi-character and  Unicode.  See
    [`sep`](#sep).

- detect\_bom


        $csv->header ($fh, { detect_bom => 1 });

    The default behavior is to detect if the header line starts with a BOM.  If
    the header has a BOM, use that to set the encoding of `$fh`.  This default
    behavior can be disabled by passing a false value to `detect_bom`.

    Supported encodings from BOM are: UTF-8, UTF-16BE, UTF-16LE, UTF-32BE,  and
    UTF-32LE. BOM also supports UTF-1, UTF-EBCDIC, SCSU, BOCU-1,  and GB-18030
    but [Encode](https://metacpan.org/pod/Encode) does not (yet). UTF-7 is not supported.

    If a supported BOM was detected as start of the stream, it is stored in the
    object attribute `ENCODING`.

        my $enc = $csv->{ENCODING};

    The encoding is used with `binmode` on `$fh`.

    If the handle was opened in a (correct) encoding,  this method will  **not**
    alter the encoding, as it checks the leading **bytes** of the first line. In
    case the stream starts with a decoded BOM (`U+FEFF`), `{ENCODING}` will be
    `""` (empty) instead of the default `undef`.

- munge\_column\_names


    This option offers the means to modify the column names into something that
    is most useful to the application.   The default is to map all column names
    to lower case.

        $csv->header ($fh, { munge_column_names => "lc" });

    The following values are available:

        lc     - lower case
        uc     - upper case
        db     - valid DB field names
        none   - do not change
        \%hash - supply a mapping
        \&cb   - supply a callback

    - Lower case

            $csv->header ($fh, { munge_column_names => "lc" });

        The header is changed to all lower-case

            $_ = lc;

    - Upper case

            $csv->header ($fh, { munge_column_names => "uc" });

        The header is changed to all upper-case

            $_ = uc;

    - Literal

            $csv->header ($fh, { munge_column_names => "none" });

    - Hash

            $csv->header ($fh, { munge_column_names => { foo => "sombrero" });

        if a value does not exist, the original value is used unchanged

    - Database

            $csv->header ($fh, { munge_column_names => "db" });

        - -

            lower-case

        - -

            all sequences of non-word characters are replaced with an underscore

        - -

            all leading underscores are removed

            $_ = lc (s/\W+/_/gr =~ s/^_+//r);

    - Callback

            $csv->header ($fh, { munge_column_names => sub { fc } });
            $csv->header ($fh, { munge_column_names => sub { "column_".$col++ } });
            $csv->header ($fh, { munge_column_names => sub { lc (s/\W+/_/gr) } });

        As this callback is called in a `map`, you can use `$_` directly.

- set\_column\_names


        $csv->header ($fh, { set_column_names => 1 });

    The default is to set the instances column names using  ["column\_names"](#column_names) if
    the method is successful,  so subsequent calls to ["getline\_hr"](#getline_hr) can return
    a hash. Disable setting the header can be forced by using a false value for
    this option.

    As described in ["return value"](#return-value) above, content is lost in scalar context.

### Validation

When receiving CSV files from external sources,  this method can be used to
protect against changes in the layout by restricting to known headers  (and
typos in the header fields).

    my %known = (
        "record key" => "c_rec",
        "rec id"     => "c_rec",
        "id_rec"     => "c_rec",
        "kode"       => "code",
        "code"       => "code",
        "vaule"      => "value",
        "value"      => "value",
        );
    my $csv = Text::CSV_XS->new ({ binary => 1, auto_diag => 1 });
    open my $fh, "<", $source or die "$source: $!";
    $csv->header ($fh, { munge_column_names => sub {
        s/\s+$//;
        s/^\s+//;
        $known{lc $_} or die "Unknown column '$_' in $source";
        }});
    while (my $row = $csv->getline_hr ($fh)) {
        say join "\t", $row->{c_rec}, $row->{code}, $row->{value};
        }

## bind\_columns


Takes a list of scalar references to be used for output with  ["print"](#print)  or
to store in the fields fetched by ["getline"](#getline).  When you do not pass enough
references to store the fetched fields in, ["getline"](#getline) will fail with error
`3006`.  If you pass more than there are fields to return,  the content of
the remaining references is left untouched.

    $csv->bind_columns (\$code, \$name, \$price, \$description);
    while ($csv->getline ($fh)) {
        print "The price of a $name is \x{20ac} $price\n";
        }

To reset or clear all column binding, call ["bind\_columns"](#bind_columns) with the single
argument `undef`. This will also clear column names.

    $csv->bind_columns (undef);

If no arguments are passed at all, ["bind\_columns"](#bind_columns) will return the list of
current bindings or `undef` if no binds are active.

Note that in parsing with  `bind_columns`,  the fields are set on the fly.
That implies that if the third field of a row causes an error  (or this row
has just two fields where the previous row had more),  the first two fields
already have been assigned the values of the current row, while the rest of
the fields will still hold the values of the previous row.  If you want the
parser to fail in these cases, use the [`strict`](#strict) attribute.

## eof


    $eof = $csv->eof ();

If ["parse"](#parse) or  ["getline"](#getline)  was used with an IO stream,  this method will
return true (1) if the last call hit end of file,  otherwise it will return
false ('').  This is useful to see the difference between a failure and end
of file.

Note that if the parsing of the last line caused an error,  `eof` is still
true.  That means that if you are _not_ using ["auto\_diag"](#auto_diag), an idiom like

    while (my $row = $csv->getline ($fh)) {
        # ...
        }
    $csv->eof or $csv->error_diag;

will _not_ report the error. You would have to change that to

    while (my $row = $csv->getline ($fh)) {
        # ...
        }
    +$csv->error_diag and $csv->error_diag;

## types


    $csv->types (\@tref);

This method is used to force that  (all)  columns are of a given type.  For
example, if you have an integer column,  two  columns  with  doubles  and a
string column, then you might do a

    $csv->types ([Text::CSV_XS::IV (),
                  Text::CSV_XS::NV (),
                  Text::CSV_XS::NV (),
                  Text::CSV_XS::PV ()]);

Column types are used only for _decoding_ columns while parsing,  in other
words by the ["parse"](#parse) and ["getline"](#getline) methods.

You can unset column types by doing a

    $csv->types (undef);

or fetch the current type settings with

    $types = $csv->types ();

- IV


    Set field type to integer.

- NV


    Set field type to numeric/float.

- PV


    Set field type to string.

## fields


    @columns = $csv->fields ();

This method returns the input to   ["combine"](#combine)  or the resultant decomposed
fields of a successful ["parse"](#parse), whichever was called more recently.

Note that the return value is undefined after using ["getline"](#getline), which does
not fill the data structures returned by ["parse"](#parse).

## meta\_info


    @flags = $csv->meta_info ();

This method returns the "flags" of the input to ["combine"](#combine) or the flags of
the resultant  decomposed fields of  ["parse"](#parse),   whichever was called more
recently.

For each field,  a meta\_info field will hold  flags that  inform  something
about  the  field  returned  by  the  ["fields"](#fields)  method or  passed to  the
["combine"](#combine) method. The flags are bit-wise-`or`'d like:

- ` `0x0001

    The field was quoted.

- ` `0x0002

    The field was binary.

See the `is_***` methods below.

## is\_quoted


    my $quoted = $csv->is_quoted ($column_idx);

where  `$column_idx` is the  (zero-based)  index of the column in the last
result of ["parse"](#parse).

This returns a true value  if the data in the indicated column was enclosed
in [`quote_char`](#quote_char) quotes.  This might be important for fields
where content `,20070108,` is to be treated as a numeric value,  and where
`,"20070108",` is explicitly marked as character string data.

This method is only valid when ["keep\_meta\_info"](#keep_meta_info) is set to a true value.

## is\_binary


    my $binary = $csv->is_binary ($column_idx);

where  `$column_idx` is the  (zero-based)  index of the column in the last
result of ["parse"](#parse).

This returns a true value if the data in the indicated column contained any
byte in the range `[\x00-\x08,\x10-\x1F,\x7F-\xFF]`.

This method is only valid when ["keep\_meta\_info"](#keep_meta_info) is set to a true value.

## is\_missing


    my $missing = $csv->is_missing ($column_idx);

where  `$column_idx` is the  (zero-based)  index of the column in the last
result of ["getline\_hr"](#getline_hr).

    $csv->keep_meta_info (1);
    while (my $hr = $csv->getline_hr ($fh)) {
        $csv->is_missing (0) and next; # This was an empty line
        }

When using  ["getline\_hr"](#getline_hr),  it is impossible to tell if the  parsed fields
are `undef` because they where not filled in the `CSV` stream  or because
they were not read at all, as **all** the fields defined by ["column\_names"](#column_names)
are set in the hash-ref.    If you still need to know if all fields in each
row are provided, you should enable [`keep_meta_info`](#keep_meta_info) so
you can check the flags.

If  [`keep_meta_info`](#keep_meta_info)  is `false`,  `is_missing`  will
always return `undef`, regardless of `$column_idx` being valid or not. If
this attribute is `true` it will return either `0` (the field is present)
or `1` (the field is missing).

A special case is the empty line.  If the line is completely empty -  after
dealing with the flags - this is still a valid CSV line:  it is a record of
just one single empty field. However, if `keep_meta_info` is set, invoking
`is_missing` with index `0` will now return true.

## status


    $status = $csv->status ();

This method returns the status of the last invoked ["combine"](#combine) or ["parse"](#parse)
call. Status is success (true: `1`) or failure (false: `undef` or `0`).

Note that as this only keeps track of the status of above mentioned methods,
you are probably looking for [`error_diag`](#error_diag) instead.

## error\_input


    $bad_argument = $csv->error_input ();

This method returns the erroneous argument (if it exists) of ["combine"](#combine) or
["parse"](#parse),  whichever was called more recently.  If the last invocation was
successful, `error_input` will return `undef`.

Depending on the type of error, it _might_ also hold the data for the last
error-input of ["getline"](#getline).

## error\_diag


    Text::CSV_XS->error_diag ();
    $csv->error_diag ();
    $error_code               = 0  + $csv->error_diag ();
    $error_str                = "" . $csv->error_diag ();
    ($cde, $str, $pos, $rec, $fld) = $csv->error_diag ();

If (and only if) an error occurred,  this function returns  the diagnostics
of that error.

If called in void context,  this will print the internal error code and the
associated error message to STDERR.

If called in list context,  this will return  the error code  and the error
message in that order.  If the last error was from parsing, the rest of the
values returned are a best guess at the location  within the line  that was
being parsed. Their values are 1-based.  The position currently is index of
the byte at which the parsing failed in the current record. It might change
to be the index of the current character in a later release. The records is
the index of the record parsed by the csv instance. The field number is the
index of the field the parser thinks it is currently  trying to  parse. See
`examples/csv-check` for how this can be used.

If called in  scalar context,  it will return  the diagnostics  in a single
scalar, a-la `$!`.  It will contain the error code in numeric context, and
the diagnostics message in string context.

When called as a class method or a  direct function call,  the  diagnostics
are that of the last ["new"](#new) call.

## record\_number


    $recno = $csv->record_number ();

Returns the records parsed by this csv instance.  This value should be more
accurate than `$.` when embedded newlines come in play. Records written by
this instance are not counted.

## SetDiag


    $csv->SetDiag (0);

Use to reset the diagnostics if you are dealing with errors.

# FUNCTIONS

## csv


This function is not exported by default and should be explicitly requested:

    use Text::CSV_XS qw( csv );

This is a high-level function that aims at simple (user) interfaces.  This
can be used to read/parse a `CSV` file or stream (the default behavior) or
to produce a file or write to a stream (define the  `out`  attribute).  It
returns an array- or hash-reference on parsing (or `undef` on fail) or the
numeric value of  ["error\_diag"](#error_diag)  on writing.  When this function fails you
can get to the error using the class call to ["error\_diag"](#error_diag)

    my $aoa = csv (in => "test.csv") or
        die Text::CSV_XS->error_diag;

This function takes the arguments as key-value pairs. This can be passed as
a list or as an anonymous hash:

    my $aoa = csv (  in => "test.csv", sep_char => ";");
    my $aoh = csv ({ in => $fh, headers => "auto" });

The arguments passed consist of two parts:  the arguments to ["csv"](#csv) itself
and the optional attributes to the  `CSV`  object used inside the function
as enumerated and explained in ["new"](#new).

If not overridden, the default option used for CSV is

    auto_diag   => 1
    escape_null => 0

The option that is always set and cannot be altered is

    binary      => 1

As this function will likely be used in one-liners,  it allows  `quote` to
be abbreviated as `quo`,  and  `escape_char` to be abbreviated as  `esc`
or `escape`.

Alternative invocations:

    my $aoa = Text::CSV_XS::csv (in => "file.csv");

    my $csv = Text::CSV_XS->new ();
    my $aoa = $csv->csv (in => "file.csv");

In the latter case, the object attributes are used from the existing object
and the attribute arguments in the function call are ignored:

    my $csv = Text::CSV_XS->new ({ sep_char => ";" });
    my $aoh = $csv->csv (in => "file.csv", bom => 1);

will parse using `;` as `sep_char`, not `,`.

### in


Used to specify the source.  `in` can be a file name (e.g. `"file.csv"`),
which will be  opened for reading  and closed when finished,  a file handle
(e.g.  `$fh` or `FH`),  a reference to a glob (e.g. `\*ARGV`),  the glob
itself (e.g. `*STDIN`), or a reference to a scalar (e.g. `\q{1,2,"csv"}`).

When used with ["out"](#out), `in` should be a reference to a CSV structure (AoA
or AoH)  or a CODE-ref that returns an array-reference or a hash-reference.
The code-ref will be invoked with no arguments.

    my $aoa = csv (in => "file.csv");

    open my $fh, "<", "file.csv";
    my $aoa = csv (in => $fh);

    my $csv = [ [qw( Foo Bar )], [ 1, 2 ], [ 2, 3 ]];
    my $err = csv (in => $csv, out => "file.csv");

If called in void context without the ["out"](#out) attribute, the resulting ref
will be used as input to a subsequent call to csv:

    csv (in => "file.csv", filter => { 2 => sub { length > 2 }})

will be a shortcut to

    csv (in => csv (in => "file.csv", filter => { 2 => sub { length > 2 }}))

where, in the absence of the `out` attribute, this is a shortcut to

    csv (in  => csv (in => "file.csv", filter => { 2 => sub { length > 2 }}),
         out => *STDOUT)

### out


    csv (in => $aoa, out => "file.csv");
    csv (in => $aoa, out => $fh);
    csv (in => $aoa, out =>   STDOUT);
    csv (in => $aoa, out =>  *STDOUT);
    csv (in => $aoa, out => \*STDOUT);
    csv (in => $aoa, out => \my $data);
    csv (in => $aoa, out =>  undef);
    csv (in => $aoa, out => \"skip");

    csv (in => $fh,  out => \@aoa);
    csv (in => $fh,  out => \@aoh, bom => 1);
    csv (in => $fh,  out => \%hsh, key => "key");

In output mode, the default CSV options when producing CSV are

    eol       => "\r\n"

The ["fragment"](#fragment) attribute is ignored in output mode.

`out` can be a file name  (e.g.  `"file.csv"`),  which will be opened for
writing and closed when finished,  a file handle (e.g. `$fh` or `FH`),  a
reference to a glob (e.g. `\*STDOUT`),  the glob itself (e.g. `*STDOUT`),
or a reference to a scalar (e.g. `\my $data`).

    csv (in => sub { $sth->fetch },            out => "dump.csv");
    csv (in => sub { $sth->fetchrow_hashref }, out => "dump.csv",
         headers => $sth->{NAME_lc});

When a code-ref is used for `in`, the output is generated  per invocation,
so no buffering is involved. This implies that there is no size restriction
on the number of records. The `csv` function ends when the coderef returns
a false value.

If `out` is set to a reference of the literal string `"skip"`, the output
will be suppressed completely,  which might be useful in combination with a
filter for side effects only.

    my %cache;
    csv (in    => "dump.csv",
         out   => \"skip",
         on_in => sub { $cache{$_[1][1]}++ });

Currently,  setting `out` to any false value  (`undef`, `""`, 0) will be
equivalent to `\"skip"`.

If the `in` argument point to something to parse, and the `out` is set to
a reference to an `ARRAY` or a `HASH`, the output is appended to the data
in the existing reference. The result of the parse should match what exists
in the reference passed. This might come handy when you have to parse a set
of files with similar content (like data stored per period) and you want to
collect that into a single data structure:

    my %hash;
    csv (in => $_, out => \%hash, key => "id") for sort glob "foo-[0-9]*.csv";

    my @list; # List of arrays
    csv (in => $_, out => \@list)              for sort glob "foo-[0-9]*.csv";

    my @list; # List of hashes
    csv (in => $_, out => \@list, bom => 1)    for sort glob "foo-[0-9]*.csv";

### encoding


If passed,  it should be an encoding accepted by the  `:encoding()` option
to `open`. There is no default value. This attribute does not work in perl
5.6.x.  `encoding` can be abbreviated to `enc` for ease of use in command
line invocations.

If `encoding` is set to the literal value `"auto"`, the method ["header"](#header)
will be invoked on the opened stream to check if there is a BOM and set the
encoding accordingly.   This is equal to passing a true value in the option
[`detect_bom`](#detect_bom).

Encodings can be stacked, as supported by `binmode`:

    # Using PerlIO::via::gzip
    csv (in       => \@csv,
         out      => "test.csv:via.gz",
         encoding => ":via(gzip):encoding(utf-8)",
         );
    $aoa = csv (in => "test.csv:via.gz",  encoding => ":via(gzip)");

    # Using PerlIO::gzip
    csv (in       => \@csv,
         out      => "test.csv:via.gz",
         encoding => ":gzip:encoding(utf-8)",
         );
    $aoa = csv (in => "test.csv:gzip.gz", encoding => ":gzip");

### detect\_bom


If  `detect_bom`  is given, the method  ["header"](#header)  will be invoked on the
opened stream to check if there is a BOM and set the encoding accordingly.

`detect_bom` can be abbreviated to `bom`.

This is the same as setting [`encoding`](#encoding) to `"auto"`.

Note that as the method  ["header"](#header) is invoked,  its default is to also set
the headers.

### headers


If this attribute is not given, the default behavior is to produce an array
of arrays.

If `headers` is supplied,  it should be an anonymous list of column names,
an anonymous hashref, a coderef, or a literal flag:  `auto`, `lc`, `uc`,
or `skip`.

- skip


    When `skip` is used, the header will not be included in the output.

        my $aoa = csv (in => $fh, headers => "skip");

- auto


    If `auto` is used, the first line of the `CSV` source will be read as the
    list of field headers and used to produce an array of hashes.

        my $aoh = csv (in => $fh, headers => "auto");

- lc


    If `lc` is used,  the first line of the  `CSV` source will be read as the
    list of field headers mapped to  lower case and used to produce an array of
    hashes. This is a variation of `auto`.

        my $aoh = csv (in => $fh, headers => "lc");

- uc


    If `uc` is used,  the first line of the  `CSV` source will be read as the
    list of field headers mapped to  upper case and used to produce an array of
    hashes. This is a variation of `auto`.

        my $aoh = csv (in => $fh, headers => "uc");

- CODE


    If a coderef is used,  the first line of the  `CSV` source will be read as
    the list of mangled field headers in which each field is passed as the only
    argument to the coderef. This list is used to produce an array of hashes.

        my $aoh = csv (in      => $fh,
                       headers => sub { lc ($_[0]) =~ s/kode/code/gr });

    this example is a variation of using `lc` where all occurrences of `kode`
    are replaced with `code`.

- ARRAY


    If  `headers`  is an anonymous list,  the entries in the list will be used
    as field names. The first line is considered data instead of headers.

        my $aoh = csv (in => $fh, headers => [qw( Foo Bar )]);
        csv (in => $aoa, out => $fh, headers => [qw( code description price )]);

- HASH


    If `headers` is a hash reference, this implies `auto`, but header fields
    that exist as key in the hashref will be replaced by the value for that
    key. Given a CSV file like

        post-kode,city,name,id number,fubble
        1234AA,Duckstad,Donald,13,"X313DF"

    using

        csv (headers => { "post-kode" => "pc", "id number" => "ID" }, ...

    will return an entry like

        { pc     => "1234AA",
          city   => "Duckstad",
          name   => "Donald",
          ID     => "13",
          fubble => "X313DF",
          }

See also [`munge_column_names`](#munge_column_names) and
[`set_column_names`](#set_column_names).

### munge\_column\_names


If `munge_column_names` is set,  the method  ["header"](#header)  is invoked on the
opened stream with all matching arguments to detect and set the headers.

`munge_column_names` can be abbreviated to `munge`.

### key


If passed,  will default  [`headers`](#headers)  to `"auto"` and return a
hashref instead of an array of hashes. Allowed values are simple scalars or
array-references where the first element is the joiner and the rest are the
fields to join to combine the key.

    my $ref = csv (in => "test.csv", key => "code");
    my $ref = csv (in => "test.csv", key => [ ":" => "code", "color" ]);

with test.csv like

    code,product,price,color
    1,pc,850,gray
    2,keyboard,12,white
    3,mouse,5,black

the first example will return

    { 1   => {
          code    => 1,
          color   => 'gray',
          price   => 850,
          product => 'pc'
          },
      2   => {
          code    => 2,
          color   => 'white',
          price   => 12,
          product => 'keyboard'
          },
      3   => {
          code    => 3,
          color   => 'black',
          price   => 5,
          product => 'mouse'
          }
      }

the second example will return

    { "1:gray"    => {
          code    => 1,
          color   => 'gray',
          price   => 850,
          product => 'pc'
          },
      "2:white"   => {
          code    => 2,
          color   => 'white',
          price   => 12,
          product => 'keyboard'
          },
      "3:black"   => {
          code    => 3,
          color   => 'black',
          price   => 5,
          product => 'mouse'
          }
      }

The `key` attribute can be combined with [`headers`](#headers) for `CSV`
date that has no header line, like

    my $ref = csv (
        in      => "foo.csv",
        headers => [qw( c_foo foo bar description stock )],
        key     =>     "c_foo",
        );

### value


Used to create key-value hashes.

Only allowed when `key` is valid. A `value` can be either a single column
label or an anonymous list of column labels.  In the first case,  the value
will be a simple scalar value, in the latter case, it will be a hashref.

    my $ref = csv (in => "test.csv", key   => "code",
                                     value => "price");
    my $ref = csv (in => "test.csv", key   => "code",
                                     value => [ "product", "price" ]);
    my $ref = csv (in => "test.csv", key   => [ ":" => "code", "color" ],
                                     value => "price");
    my $ref = csv (in => "test.csv", key   => [ ":" => "code", "color" ],
                                     value => [ "product", "price" ]);

with test.csv like

    code,product,price,color
    1,pc,850,gray
    2,keyboard,12,white
    3,mouse,5,black

the first example will return

    { 1 => 850,
      2 =>  12,
      3 =>   5,
      }

the second example will return

    { 1   => {
          price   => 850,
          product => 'pc'
          },
      2   => {
          price   => 12,
          product => 'keyboard'
          },
      3   => {
          price   => 5,
          product => 'mouse'
          }
      }

the third example will return

    { "1:gray"    => 850,
      "2:white"   =>  12,
      "3:black"   =>   5,
      }

the fourth example will return

    { "1:gray"    => {
          price   => 850,
          product => 'pc'
          },
      "2:white"   => {
          price   => 12,
          product => 'keyboard'
          },
      "3:black"   => {
          price   => 5,
          product => 'mouse'
          }
      }

### keep\_headers




When using hashes,  keep the column names into the arrayref passed,  so all
headers are available after the call in the original order.

    my $aoh = csv (in => "file.csv", keep_headers => \my @hdr);

This attribute can be abbreviated to `kh` or passed as `keep_column_names`.

This attribute implies a default of `auto` for the `headers` attribute.

### fragment


Only output the fragment as defined in the ["fragment"](#fragment) method. This option
is ignored when _generating_ `CSV`. See ["out"](#out).

Combining all of them could give something like

    use Text::CSV_XS qw( csv );
    my $aoh = csv (
        in       => "test.txt",
        encoding => "utf-8",
        headers  => "auto",
        sep_char => "|",
        fragment => "row=3;6-9;15-*",
        );
    say $aoh->[15]{Foo};

### sep\_set



If `sep_set` is set, the method ["header"](#header) is invoked on the opened stream
to detect and set [`sep_char`](#sep_char) with the given set.

`sep_set` can be abbreviated to `seps`.

Note that as the  ["header"](#header) method is invoked,  its default is to also set
the headers.

### set\_column\_names


If  `set_column_names` is passed,  the method ["header"](#header) is invoked on the
opened stream with all arguments meant for ["header"](#header).

If `set_column_names` is passed as a false value, the content of the first
row is only preserved if the output is AoA:

With an input-file like

    bAr,foo
    1,2
    3,4,5

This call

    my $aoa = csv (in => $file, set_column_names => 0);

will result in

    [[ "bar", "foo"     ],
     [ "1",   "2"       ],
     [ "3",   "4",  "5" ]]

and

    my $aoa = csv (in => $file, set_column_names => 0, munge => "none");

will result in

    [[ "bAr", "foo"     ],
     [ "1",   "2"       ],
     [ "3",   "4",  "5" ]]

## Callbacks


Callbacks enable actions triggered from the _inside_ of Text::CSV\_XS.

While most of what this enables  can easily be done in an  unrolled loop as
described in the ["SYNOPSIS"](#synopsis) callbacks can be used to meet special demands
or enhance the ["csv"](#csv) function.

- error


        $csv->callbacks (error => sub { $csv->SetDiag (0) });

    the `error`  callback is invoked when an error occurs,  but  _only_  when
    ["auto\_diag"](#auto_diag) is set to a true value. A callback is invoked with the values
    returned by ["error\_diag"](#error_diag):

        my ($c, $s);

        sub ignore3006 {
            my ($err, $msg, $pos, $recno, $fldno) = @_;
            if ($err == 3006) {
                # ignore this error
                ($c, $s) = (undef, undef);
                Text::CSV_XS->SetDiag (0);
                }
            # Any other error
            return;
            } # ignore3006

        $csv->callbacks (error => \&ignore3006);
        $csv->bind_columns (\$c, \$s);
        while ($csv->getline ($fh)) {
            # Error 3006 will not stop the loop
            }

- after\_parse


        $csv->callbacks (after_parse => sub { push @{$_[1]}, "NEW" });
        while (my $row = $csv->getline ($fh)) {
            $row->[-1] eq "NEW";
            }

    This callback is invoked after parsing with  ["getline"](#getline)  only if no  error
    occurred.  The callback is invoked with two arguments:   the current `CSV`
    parser object and an array reference to the fields parsed.

    The return code of the callback is ignored  unless it is a reference to the
    string "skip", in which case the record will be skipped in ["getline\_all"](#getline_all).

        sub add_from_db {
            my ($csv, $row) = @_;
            $sth->execute ($row->[4]);
            push @$row, $sth->fetchrow_array;
            } # add_from_db

        my $aoa = csv (in => "file.csv", callbacks => {
            after_parse => \&add_from_db });

    This hook can be used for validation:


    - FAIL

        Die if any of the records does not validate a rule:

            after_parse => sub {
                $_[1][4] =~ m/^[0-9]{4}\s?[A-Z]{2}$/ or
                    die "5th field does not have a valid Dutch zipcode";
                }

    - DEFAULT

        Replace invalid fields with a default value:

            after_parse => sub { $_[1][2] =~ m/^\d+$/ or $_[1][2] = 0 }

    - SKIP

        Skip records that have invalid fields (only applies to ["getline\_all"](#getline_all)):

            after_parse => sub { $_[1][0] =~ m/^\d+$/ or return \"skip"; }

- before\_print


        my $idx = 1;
        $csv->callbacks (before_print => sub { $_[1][0] = $idx++ });
        $csv->print (*STDOUT, [ 0, $_ ]) for @members;

    This callback is invoked  before printing with  ["print"](#print)  only if no error
    occurred.  The callback is invoked with two arguments:  the current  `CSV`
    parser object and an array reference to the fields passed.

    The return code of the callback is ignored.

        sub max_4_fields {
            my ($csv, $row) = @_;
            @$row > 4 and splice @$row, 4;
            } # max_4_fields

        csv (in => csv (in => "file.csv"), out => *STDOUT,
            callbacks => { before_print => \&max_4_fields });

    This callback is not active for ["combine"](#combine).

### Callbacks for csv ()

The ["csv"](#csv) allows for some callbacks that do not integrate in XS internals
but only feature the ["csv"](#csv) function.

    csv (in        => "file.csv",
         callbacks => {
             filter       => { 6 => sub { $_ > 15 } },    # first
             after_parse  => sub { say "AFTER PARSE";  }, # first
             after_in     => sub { say "AFTER IN";     }, # second
             on_in        => sub { say "ON IN";        }, # third
             },
         );

    csv (in        => $aoh,
         out       => "file.csv",
         callbacks => {
             on_in        => sub { say "ON IN";        }, # first
             before_out   => sub { say "BEFORE OUT";   }, # second
             before_print => sub { say "BEFORE PRINT"; }, # third
             },
         );

- filter


    This callback can be used to filter records.  It is called just after a new
    record has been scanned.  The callback accepts a:

    - hashref

        The keys are the index to the row (the field name or field number, 1-based)
        and the values are subs to return a true or false value.

            csv (in => "file.csv", filter => {
                       3 => sub { m/a/ },       # third field should contain an "a"
                       5 => sub { length > 4 }, # length of the 5th field minimal 5
                       });

            csv (in => "file.csv", filter => { foo => sub { $_ > 4 }});

        If the keys to the filter hash contain any character that is not a digit it
        will also implicitly set ["headers"](#headers) to `"auto"`  unless  ["headers"](#headers)  was
        already passed as argument.  When headers are active, returning an array of
        hashes, the filter is not applicable to the header itself.

        All sub results should match, as in AND.

        The context of the callback sets  `$_` localized to the field indicated by
        the filter. The two arguments are as with all other callbacks, so the other
        fields in the current row can be seen:

            filter => { 3 => sub { $_ > 100 ? $_[1][1] =~ m/A/ : $_[1][6] =~ m/B/ }}

        If the context is set to return a list of hashes  (["headers"](#headers) is defined),
        the current record will also be available in the localized `%_`:

            filter => { 3 => sub { $_ > 100 && $_{foo} =~ m/A/ && $_{bar} < 1000  }}

        If the filter is used to _alter_ the content by changing `$_`,  make sure
        that the sub returns true in order not to have that record skipped:

            filter => { 2 => sub { $_ = uc }}

        will upper-case the second field, and then skip it if the resulting content
        evaluates to false. To always accept, end with truth:

            filter => { 2 => sub { $_ = uc; 1 }}

    - coderef

            csv (in => "file.csv", filter => sub { $n++; 0; });

        If the argument to `filter` is a coderef,  it is an alias or shortcut to a
        filter on column 0:

            csv (filter => sub { $n++; 0 });

        is equal to

            csv (filter => { 0 => sub { $n++; 0 });

    - filter-name

            csv (in => "file.csv", filter => "not_blank");
            csv (in => "file.csv", filter => "not_empty");
            csv (in => "file.csv", filter => "filled");

        These are predefined filters

        Given a file like (line numbers prefixed for doc purpose only):

            1:1,2,3
            2:
            3:,
            4:""
            5:,,
            6:, ,
            7:"",
            8:" "
            9:4,5,6

        - not\_blank

            Filter out the blank lines

            This filter is a shortcut for

                filter => { 0 => sub { @{$_[1]} > 1 or
                            defined $_[1][0] && $_[1][0] ne "" } }

            Due to the implementation,  it is currently impossible to also filter lines
            that consists only of a quoted empty field. These lines are also considered
            blank lines.

            With the given example, lines 2 and 4 will be skipped.

        - not\_empty

            Filter out lines where all the fields are empty.

            This filter is a shortcut for

                filter => { 0 => sub { grep { defined && $_ ne "" } @{$_[1]} } }

            A space is not regarded being empty, so given the example data, lines 2, 3,
            4, 5, and 7 are skipped.

        - filled

            Filter out lines that have no visible data

            This filter is a shortcut for

                filter => { 0 => sub { grep { defined && m/\S/ } @{$_[1]} } }

            This filter rejects all lines that _not_ have at least one field that does
            not evaluate to the empty string.

            With the given example data, this filter would skip lines 2 through 8.

    One could also use modules like [Types::Standard](https://metacpan.org/pod/Types%3A%3AStandard):

        use Types::Standard -types;

        my $type   = Tuple[Str, Str, Int, Bool, Optional[Num]];
        my $check  = $type->compiled_check;

        # filter with compiled check and warnings
        my $aoa = csv (
           in     => \$data,
           filter => {
               0 => sub {
                   my $ok = $check->($_[1]) or
                       warn $type->get_message ($_[1]), "\n";
                   return $ok;
                   },
               },
           );

- after\_in


    This callback is invoked for each record after all records have been parsed
    but before returning the reference to the caller.  The hook is invoked with
    two arguments:  the current  `CSV`  parser object  and a  reference to the
    record.   The reference can be a reference to a  HASH  or a reference to an
    ARRAY as determined by the arguments.

    This callback can also be passed as  an attribute without the  `callbacks`
    wrapper.

- before\_out


    This callback is invoked for each record before the record is printed.  The
    hook is invoked with two arguments:  the current `CSV` parser object and a
    reference to the record.   The reference can be a reference to a  HASH or a
    reference to an ARRAY as determined by the arguments.

    This callback can also be passed as an attribute  without the  `callbacks`
    wrapper.

    This callback makes the row available in `%_` if the row is a hashref.  In
    this case `%_` is writable and will change the original row.

- on\_in


    This callback acts exactly as the ["after\_in"](#after_in) or the ["before\_out"](#before_out) hooks.

    This callback can also be passed as an attribute  without the  `callbacks`
    wrapper.

    This callback makes the row available in `%_` if the row is a hashref.  In
    this case `%_` is writable and will change the original row. So e.g. with

        my $aoh = csv (
            in      => \"foo\n1\n2\n",
            headers => "auto",
            on_in   => sub { $_{bar} = 2; },
            );

    `$aoh` will be:

        [ { foo => 1,
            bar => 2,
            }
          { foo => 2,
            bar => 2,
            }
          ]

- csv

    The _function_  ["csv"](#csv) can also be called as a method or with an existing
    Text::CSV\_XS object. This could help if the function is to be invoked a lot
    of times and the overhead of creating the object internally over  and  over
    again would be prevented by passing an existing instance.

        my $csv = Text::CSV_XS->new ({ binary => 1, auto_diag => 1 });

        my $aoa = $csv->csv (in => $fh);
        my $aoa = csv (in => $fh, csv => $csv);

    both act the same. Running this 20000 times on a 20 lines CSV file,  showed
    a 53% speedup.

# INTERNALS

- Combine (...)
- Parse (...)

The arguments to these internal functions are deliberately not described or
documented in order to enable the  module authors make changes it when they
feel the need for it.  Using them is  highly  discouraged  as  the  API may
change in future releases.

# EXAMPLES

## Reading a CSV file line by line:

    my $csv = Text::CSV_XS->new ({ binary => 1, auto_diag => 1 });
    open my $fh, "<", "file.csv" or die "file.csv: $!";
    while (my $row = $csv->getline ($fh)) {
        # do something with @$row
        }
    close $fh or die "file.csv: $!";

or

    my $aoa = csv (in => "file.csv", on_in => sub {
        # do something with %_
        });

### Reading only a single column

    my $csv = Text::CSV_XS->new ({ binary => 1, auto_diag => 1 });
    open my $fh, "<", "file.csv" or die "file.csv: $!";
    # get only the 4th column
    my @column = map { $_->[3] } @{$csv->getline_all ($fh)};
    close $fh or die "file.csv: $!";

with ["csv"](#csv), you could do

    my @column = map { $_->[0] }
        @{csv (in => "file.csv", fragment => "col=4")};

## Parsing CSV strings:

    my $csv = Text::CSV_XS->new ({ keep_meta_info => 1, binary => 1 });

    my $sample_input_string =
        qq{"I said, ""Hi!""",Yes,"",2.34,,"1.09","\x{20ac}",};
    if ($csv->parse ($sample_input_string)) {
        my @field = $csv->fields;
        foreach my $col (0 .. $#field) {
            my $quo = $csv->is_quoted ($col) ? $csv->{quote_char} : "";
            printf "%2d: %s%s%s\n", $col, $quo, $field[$col], $quo;
            }
        }
    else {
        print STDERR "parse () failed on argument: ",
            $csv->error_input, "\n";
        $csv->error_diag ();
        }

### Parsing CSV from memory

Given a complete CSV data-set in scalar `$data`,  generate a list of lists
to represent the rows and fields

    # The data
    my $data = join "\r\n" => map { join "," => 0 .. 5 } 0 .. 5;

    # in a loop
    my $csv = Text::CSV_XS->new ({ binary => 1, auto_diag => 1 });
    open my $fh, "<", \$data;
    my @foo;
    while (my $row = $csv->getline ($fh)) {
        push @foo, $row;
        }
    close $fh;

    # a single call
    my $foo = csv (in => \$data);

## Printing CSV data

### The fast way: using ["print"](#print)

An example for creating `CSV` files using the ["print"](#print) method:

    my $csv = Text::CSV_XS->new ({ binary => 1, eol => $/ });
    open my $fh, ">", "foo.csv" or die "foo.csv: $!";
    for (1 .. 10) {
        $csv->print ($fh, [ $_, "$_" ]) or $csv->error_diag;
        }
    close $fh or die "$tbl.csv: $!";

### The slow way: using ["combine"](#combine) and ["string"](#string)

or using the slower ["combine"](#combine) and ["string"](#string) methods:

    my $csv = Text::CSV_XS->new;

    open my $csv_fh, ">", "hello.csv" or die "hello.csv: $!";

    my @sample_input_fields = (
        'You said, "Hello!"',   5.67,
        '"Surely"',   '',   '3.14159');
    if ($csv->combine (@sample_input_fields)) {
        print $csv_fh $csv->string, "\n";
        }
    else {
        print "combine () failed on argument: ",
            $csv->error_input, "\n";
        }
    close $csv_fh or die "hello.csv: $!";

### Generating CSV into memory

Format a data-set (`@foo`) into a scalar value in memory (`$data`):

    # The data
    my @foo = map { [ 0 .. 5 ] } 0 .. 3;

    # in a loop
    my $csv = Text::CSV_XS->new ({ binary => 1, auto_diag => 1, eol => "\r\n" });
    open my $fh, ">", \my $data;
    $csv->print ($fh, $_) for @foo;
    close $fh;

    # a single call
    csv (in => \@foo, out => \my $data);

## Rewriting CSV

Rewrite `CSV` files with `;` as separator character to well-formed `CSV`:

    use Text::CSV_XS qw( csv );
    csv (in => csv (in => "bad.csv", sep_char => ";"), out => *STDOUT);

As `STDOUT` is now default in ["csv"](#csv), a one-liner converting a UTF-16 CSV
file with BOM and TAB-separation to valid UTF-8 CSV could be:

    $ perl -C3 -MText::CSV_XS=csv -we\
       'csv(in=>"utf16tab.csv",encoding=>"utf16",sep=>"\t")' >utf8.csv

## Dumping database tables to CSV

Dumping a database table can be simple as this (TIMTOWTDI):

    my $dbh = DBI->connect (...);
    my $sql = "select * from foo";

    # using your own loop
    open my $fh, ">", "foo.csv" or die "foo.csv: $!\n";
    my $csv = Text::CSV_XS->new ({ binary => 1, eol => "\r\n" });
    my $sth = $dbh->prepare ($sql); $sth->execute;
    $csv->print ($fh, $sth->{NAME_lc});
    while (my $row = $sth->fetch) {
        $csv->print ($fh, $row);
        }

    # using the csv function, all in memory
    csv (out => "foo.csv", in => $dbh->selectall_arrayref ($sql));

    # using the csv function, streaming with callbacks
    my $sth = $dbh->prepare ($sql); $sth->execute;
    csv (out => "foo.csv", in => sub { $sth->fetch            });
    csv (out => "foo.csv", in => sub { $sth->fetchrow_hashref });

Note that this does not discriminate between "empty" values and NULL-values
from the database,  as both will be the same empty field in CSV.  To enable
distinction between the two, use [`quote_empty`](#quote_empty).

    csv (out => "foo.csv", in => sub { $sth->fetch }, quote_empty => 1);

If the database import utility supports special sequences to insert `NULL`
values into the database,  like MySQL/MariaDB supports `\N`,  use a filter
or a map

    csv (out => "foo.csv", in => sub { $sth->fetch },
                        on_in => sub { $_ //= "\\N" for @{$_[1]} });

    while (my $row = $sth->fetch) {
        $csv->print ($fh, [ map { $_ // "\\N" } @$row ]);
        }

Note that this will not work as expected when choosing the backslash (`\`)
as `escape_char`, as that will cause the `\` to need to be escaped by yet
another `\`,  which will cause the field to need quotation and thus ending
up as `"\\N"` instead of `\N`. See also [`undef_str`](#undef_str).

    csv (out => "foo.csv", in => sub { $sth->fetch }, undef_str => "\\N");

These special sequences are not recognized by  Text::CSV\_XS  on parsing the
CSV generated like this, but map and filter are your friends again

    while (my $row = $csv->getline ($fh)) {
        $sth->execute (map { $_ eq "\\N" ? undef : $_ } @$row);
        }

    csv (in => "foo.csv", filter => { 1 => sub {
        $sth->execute (map { $_ eq "\\N" ? undef : $_ } @{$_[1]}); 0; }});

## The examples folder

For more extended examples, see the `examples/` `1`. sub-directory in the
original distribution or the git repository `2`.

    1. https://github.com/Tux/Text-CSV_XS/tree/master/examples
    2. https://github.com/Tux/Text-CSV_XS

The following files can be found there:

- parser-xs.pl


    This can be used as a boilerplate to parse invalid `CSV`  and parse beyond
    (expected) errors alternative to using the ["error"](#error) callback.

        $ perl examples/parser-xs.pl bad.csv >good.csv

- csv-check


    This is a command-line tool that uses parser-xs.pl  techniques to check the
    `CSV` file and report on its content.

        $ csv-check files/utf8.csv
        Checked files/utf8.csv  with csv-check 1.9
        using Text::CSV_XS 1.32 with perl 5.26.0 and Unicode 9.0.0
        OK: rows: 1, columns: 2
            sep = <,>, quo = <">, bin = <1>, eol = <"\n">

- csv-split


    This command splits `CSV` files into smaller files,  keeping (part of) the
    header.  Options include maximum number of (data) rows per file and maximum
    number of columns per file or a combination of the two.

- csv2xls


    A script to convert `CSV` to Microsoft Excel (`XLS`). This requires extra
    modules [Date::Calc](https://metacpan.org/pod/Date%3A%3ACalc) and [Spreadsheet::WriteExcel](https://metacpan.org/pod/Spreadsheet%3A%3AWriteExcel). The converter accepts
    various options and can produce UTF-8 compliant Excel files.

- csv2xlsx


    A script to convert `CSV` to Microsoft Excel (`XLSX`).  This requires the
    modules [Date::Calc](https://metacpan.org/pod/Date%3A%3ACalc) and [Spreadsheet::Writer::XLSX](https://metacpan.org/pod/Spreadsheet%3A%3AWriter%3A%3AXLSX).  The converter does
    accept various options including merging several `CSV` files into a single
    Excel file.

- csvdiff


    A script that provides colorized diff on sorted CSV files,  assuming  first
    line is header and first field is the key. Output options include colorized
    ANSI escape codes or HTML.

        $ csvdiff --html --output=diff.html file1.csv file2.csv

- rewrite.pl


    A script to rewrite (in)valid CSV into valid CSV files.  Script has options
    to generate confusing CSV files or CSV files that conform to Dutch MS-Excel
    exports (using `;` as separation).

    Script - by default - honors BOM  and auto-detects separation converting it
    to default standard CSV with `,` as separator.

# CAVEATS

Text::CSV\_XS  is _not_ designed to detect the characters used to quote and
separate fields.  The parsing is done using predefined  (default) settings.
In the examples  sub-directory,  you can find scripts  that demonstrate how
you could try to detect these characters yourself.

## Microsoft Excel

The import/export from Microsoft Excel is a _risky task_, according to the
documentation in `Text::CSV::Separator`.  Microsoft uses the system's list
separator defined in the regional settings, which happens to be a semicolon
for Dutch, German and Spanish (and probably some others as well).   For the
English locale,  the default is a comma.   In Windows however,  the user is
free to choose a  predefined locale,  and then change  _every_  individual
setting in it, so checking the locale is no solution.

As of version 1.17, a lone first line with just

    sep=;

will be recognized and honored when parsing with ["getline"](#getline).

# TODO

- More Errors & Warnings

    New extensions ought to be  clear and concise  in reporting what  error has
    occurred where and why, and maybe also offer a remedy to the problem.

    ["error\_diag"](#error_diag) is a (very) good start, but there is more work to be done in
    this area.

    Basic calls  should croak or warn on  illegal parameters.  Errors should be
    documented.

- setting meta info

    Future extensions might include extending the ["meta\_info"](#meta_info), ["is\_quoted"](#is_quoted),
    and  ["is\_binary"](#is_binary)  to accept setting these  flags for  fields,  so you can
    specify which fields are quoted in the ["combine"](#combine)/["string"](#string) combination.

        $csv->meta_info (0, 1, 1, 3, 0, 0);
        $csv->is_quoted (3, 1);

    [Metadata Vocabulary for Tabular Data](http://w3c.github.io/csvw/metadata/)
    (a W3C editor's draft) could be an example for supporting more metadata.

- Parse the whole file at once

    Implement new methods or functions  that enable parsing of a  complete file
    at once, returning a list of hashes. Possible extension to this could be to
    enable a column selection on the call:

        my @AoH = $csv->parse_file ($filename, { cols => [ 1, 4..8, 12 ]});

    returning something like

        [ { fields => [ 1, 2, "foo", 4.5, undef, "", 8 ],
            flags  => [ ... ],
            },
          { fields => [ ... ],
            .
            },
          ]

    Note that the ["csv"](#csv) function already supports most of this,  but does not
    return flags. ["getline\_all"](#getline_all) returns all rows for an open stream, but this
    will not return flags either.  ["fragment"](#fragment)  can reduce the  required  rows
    _or_ columns, but cannot combine them.

- Cookbook

    Write a document that has recipes for  most known  non-standard  (and maybe
    some standard)  `CSV` formats,  including formats that use  `TAB`,  `;`,
    `|`, or other non-comma separators.

    Examples could be taken from W3C's [CSV on the Web: Use Cases and
    Requirements](http://w3c.github.io/csvw/use-cases-and-requirements/index.html)

- Steal

    Steal good new ideas and features from [PapaParse](http://papaparse.com) or
    [csvkit](http://csvkit.readthedocs.org).

- Perl6 support

    I'm already working on perl6 support [here](https://github.com/Tux/CSV). No
    promises yet on when it is finished (or fast). Trying to keep the API alike
    as much as possible.

## NOT TODO

- combined methods

    Requests for adding means (methods) that combine ["combine"](#combine) and ["string"](#string)
    in a single call will **not** be honored (use ["print"](#print) instead).   Likewise
    for ["parse"](#parse) and ["fields"](#fields)  (use ["getline"](#getline) instead), given the problems
    with embedded newlines.

## Release plan

No guarantees, but this is what I had in mind some time ago:

- DIAGNOSTICS section in pod to \*describe\* the errors (see below)

# EBCDIC

Everything should now work on native EBCDIC systems.   As the test does not
cover all possible codepoints and [Encode](https://metacpan.org/pod/Encode) does not support `utf-ebcdic`,
there is no guarantee that all handling of Unicode is done correct.

Opening `EBCDIC` encoded files on  `ASCII`+  systems is likely to succeed
using Encode's `cp37`, `cp1047`, or `posix-bc`:

    open my $fh, "<:encoding(cp1047)", "ebcdic_file.csv" or die "...";

# DIAGNOSTICS

Still under construction ...

If an error occurs,  `$csv->error_diag` can be used to get information
on the cause of the failure. Note that for speed reasons the internal value
is never cleared on success,  so using the value returned by ["error\_diag"](#error_diag)
in normal cases - when no error occurred - may cause unexpected results.

If the constructor failed, the cause can be found using ["error\_diag"](#error_diag) as a
class method, like `Text::CSV_XS->error_diag`.

The `$csv->error_diag` method is automatically invoked upon error when
the contractor was called with  [`auto_diag`](#auto_diag)  set to  `1` or
`2`, or when [autodie](https://metacpan.org/pod/autodie) is in effect.  When set to `1`, this will cause a
`warn` with the error message,  when set to `2`, it will `die`. `2012 -
EOF` is excluded from [`auto_diag`](#auto_diag) reports.

Errors can be (individually) caught using the ["error"](#error) callback.

The errors as described below are available. I have tried to make the error
itself explanatory enough, but more descriptions will be added. For most of
these errors, the first three capitals describe the error category:

- INI

    Initialization error or option conflict.

- ECR

    Carriage-Return related parse error.

- EOF

    End-Of-File related parse error.

- EIQ

    Parse error inside quotation.

- EIF

    Parse error inside field.

- ECB

    Combine error.

- EHR

    HashRef parse related error.

And below should be the complete list of error codes that can be returned:

- 1001 "INI - sep\_char is equal to quote\_char or escape\_char"


    The  [separation character](#sep_char)  cannot be equal to  [the quotation
    character](#quote_char) or to [the escape character](#escape_char),  as this
    would invalidate all parsing rules.

- 1002 "INI - allow\_whitespace with escape\_char or quote\_char SP or TAB"


    Using the  [`allow_whitespace`](#allow_whitespace)  attribute  when either
    [`quote_char`](#quote_char) or [`escape_char`](#escape_char)  is equal to
    `SPACE` or `TAB` is too ambiguous to allow.

- 1003 "INI - \\r or \\n in main attr not allowed"


    Using default [`eol`](#eol) characters in either [`sep_char`](#sep_char),
    [`quote_char`](#quote_char),   or  [`escape_char`](#escape_char)  is  not
    allowed.

- 1004 "INI - callbacks should be undef or a hashref"


    The [`callbacks`](#callbacks)  attribute only allows one to be `undef` or
    a hash reference.

- 1005 "INI - EOL too long"


    The value passed for EOL is exceeding its maximum length (16).

- 1006 "INI - SEP too long"


    The value passed for SEP is exceeding its maximum length (16).

- 1007 "INI - QUOTE too long"


    The value passed for QUOTE is exceeding its maximum length (16).

- 1008 "INI - SEP undefined"


    The value passed for SEP should be defined and not empty.

- 1010 "INI - the header is empty"


    The header line parsed in the ["header"](#header) is empty.

- 1011 "INI - the header contains more than one valid separator"


    The header line parsed in the  ["header"](#header)  contains more than one  (unique)
    separator character out of the allowed set of separators.

- 1012 "INI - the header contains an empty field"


    The header line parsed in the ["header"](#header) contains an empty field.

- 1013 "INI - the header contains nun-unique fields"


    The header line parsed in the  ["header"](#header)  contains at least  two identical
    fields.

- 1014 "INI - header called on undefined stream"


    The header line cannot be parsed from an undefined source.

- 1500 "PRM - Invalid/unsupported argument(s)"


    Function or method called with invalid argument(s) or parameter(s).

- 1501 "PRM - The key attribute is passed as an unsupported type"


    The `key` attribute is of an unsupported type.

- 1502 "PRM - The value attribute is passed without the key attribute"


    The `value` attribute is only allowed when a valid key is given.

- 1503 "PRM - The value attribute is passed as an unsupported type"


    The `value` attribute is of an unsupported type.

- 2010 "ECR - QUO char inside quotes followed by CR not part of EOL"


    When  [`eol`](#eol)  has  been  set  to  anything  but the  default,  like
    `"\r\t\n"`,  and  the  `"\r"`  is  following  the   **second**   (closing)
    [`quote_char`](#quote_char), where the characters following the `"\r"` do
    not make up the [`eol`](#eol) sequence, this is an error.

- 2011 "ECR - Characters after end of quoted field"


    Sequences like `1,foo,"bar"baz,22,1` are not allowed. `"bar"` is a quoted
    field and after the closing double-quote, there should be either a new-line
    sequence or a separation character.

- 2012 "EOF - End of data in parsing input stream"


    Self-explaining. End-of-file while inside parsing a stream. Can happen only
    when reading from streams with ["getline"](#getline),  as using  ["parse"](#parse) is done on
    strings that are not required to have a trailing [`eol`](#eol).

- 2013 "INI - Specification error for fragments RFC7111"


    Invalid specification for URI ["fragment"](#fragment) specification.

- 2014 "ENF - Inconsistent number of fields"


    Inconsistent number of fields under strict parsing.

- 2021 "EIQ - NL char inside quotes, binary off"


    Sequences like `1,"foo\nbar",22,1` are allowed only when the binary option
    has been selected with the constructor.

- 2022 "EIQ - CR char inside quotes, binary off"


    Sequences like `1,"foo\rbar",22,1` are allowed only when the binary option
    has been selected with the constructor.

- 2023 "EIQ - QUO character not allowed"


    Sequences like `"foo "bar" baz",qu` and `2023,",2008-04-05,"Foo, Bar",\n`
    will cause this error.

- 2024 "EIQ - EOF cannot be escaped, not even inside quotes"


    The escape character is not allowed as last character in an input stream.

- 2025 "EIQ - Loose unescaped escape"


    An escape character should escape only characters that need escaping.

    Allowing  the escape  for other characters  is possible  with the attribute
    ["allow\_loose\_escapes"](#allow_loose_escapes).

- 2026 "EIQ - Binary character inside quoted field, binary off"


    Binary characters are not allowed by default.    Exceptions are fields that
    contain valid UTF-8,  that will automatically be upgraded if the content is
    valid UTF-8. Set [`binary`](#binary) to `1` to accept binary data.

- 2027 "EIQ - Quoted field not terminated"


    When parsing a field that started with a quotation character,  the field is
    expected to be closed with a quotation character.   When the parsed line is
    exhausted before the quote is found, that field is not terminated.

- 2030 "EIF - NL char inside unquoted verbatim, binary off"

- 2031 "EIF - CR char is first char of field, not part of EOL"

- 2032 "EIF - CR char inside unquoted, not part of EOL"

- 2034 "EIF - Loose unescaped quote"

- 2035 "EIF - Escaped EOF in unquoted field"

- 2036 "EIF - ESC error"

- 2037 "EIF - Binary character in unquoted field, binary off"

- 2110 "ECB - Binary character in Combine, binary off"

- 2200 "EIO - print to IO failed. See errno"

- 3001 "EHR - Unsupported syntax for column\_names ()"

- 3002 "EHR - getline\_hr () called before column\_names ()"

- 3003 "EHR - bind\_columns () and column\_names () fields count mismatch"

- 3004 "EHR - bind\_columns () only accepts refs to scalars"

- 3006 "EHR - bind\_columns () did not pass enough refs for parsed fields"

- 3007 "EHR - bind\_columns needs refs to writable scalars"

- 3008 "EHR - unexpected error in bound fields"

- 3009 "EHR - print\_hr () called before column\_names ()"

- 3010 "EHR - print\_hr () called with invalid arguments"

# SEE ALSO

[IO::File](https://metacpan.org/pod/IO%3A%3AFile),  [IO::Handle](https://metacpan.org/pod/IO%3A%3AHandle),  [IO::Wrap](https://metacpan.org/pod/IO%3A%3AWrap),  [Text::CSV](https://metacpan.org/pod/Text%3A%3ACSV),  [Text::CSV\_PP](https://metacpan.org/pod/Text%3A%3ACSV_PP),
[Text::CSV::Encoded](https://metacpan.org/pod/Text%3A%3ACSV%3A%3AEncoded),     [Text::CSV::Separator](https://metacpan.org/pod/Text%3A%3ACSV%3A%3ASeparator),    [Text::CSV::Slurp](https://metacpan.org/pod/Text%3A%3ACSV%3A%3ASlurp),
[Spreadsheet::CSV](https://metacpan.org/pod/Spreadsheet%3A%3ACSV) and [Spreadsheet::Read](https://metacpan.org/pod/Spreadsheet%3A%3ARead), and of course [perl](https://metacpan.org/pod/perl).

If you are using perl6,  you can have a look at  `Text::CSV`  in the perl6
ecosystem, offering the same features.

### non-perl

A CSV parser in JavaScript,  also used by [W3C](http://www.w3.org),  is the
multi-threaded in-browser [PapaParse](http://papaparse.com/).

[csvkit](http://csvkit.readthedocs.org) is a python CSV parsing toolkit.

# AUTHOR

Alan Citterman `<alan@mfgrtl.com>` wrote the original Perl module.
Please don't send mail concerning Text::CSV\_XS to Alan, who is not involved
in the C/XS part that is now the main part of the module.

Jochen Wiedmann `<joe@ispsoft.de>` rewrote the en- and decoding in
C by implementing a simple finite-state machine.   He added variable quote,
escape and separator characters, the binary mode and the print and getline
methods. See `ChangeLog` releases 0.10 through 0.23.

H.Merijn Brand `<h.m.brand@xs4all.nl>` cleaned up the code,  added
the field flags methods,  wrote the major part of the test suite, completed
the documentation,   fixed most RT bugs,  added all the allow flags and the
["csv"](#csv) function. See ChangeLog releases 0.25 and on.

# COPYRIGHT AND LICENSE

    Copyright (C) 2007-2021 H.Merijn Brand.  All rights reserved.
    Copyright (C) 1998-2001 Jochen Wiedmann. All rights reserved.
    Copyright (C) 1997      Alan Citterman.  All rights reserved.

This library is free software;  you can redistribute and/or modify it under
the same terms as Perl itself.
