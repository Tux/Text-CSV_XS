#!/pro/bin/perl

use 5.018002;
use warnings;
use diagnostics;

use Text::CSV_XS qw(csv);
use Data::Peek;

DDumper (csv (
    in               => *DATA,
    sep_char         => "|",
    headers          => "auto",
    allow_whitespace => 1,
    comment_str      => "#"
    ));

# returns:
# [ { id               => "42",
#     name             => "foo",
#     },
#   { id               => "",
#     name             => undef,
#     },
#   ]
#
# expected:
# [ { id               => "42",
#     name             => "foo",
#     },
#   ]

__END__
id | name
#
42 | foo
#
