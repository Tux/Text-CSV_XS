use Text::CSV_XS qw( csv );
use Data::Peek;
use JSON;

BEGIN { *CSV:: = \%Text::CSV_XS::; }
$VERSION = "0.04";

sub dcsv { DDumper     (csv (@_, diag_verbose => 9)); }
sub jcsv { decode_json (csv (@_, diag_verbose => 9)); }

1;

=head1 NAME

CSV - Alias for Text::CSV_XS

=head1 SYNOPSIS

  perl -MCSV -wle'csv (in => [[1,2]])'

  perl -MCSV -wle'DDumper (csv (in => \q{foo,"bar, foo",quux}))'
  perl -MCSV -wle'dcsv (in => \q{foo,"bar, foo",quux})'

  perl -MCSV -wle'print jcsv (in => "file.csv")'

=head1 DESCRIPTION

Wrapper for Text::CSV_XS with csv importing also Data::Peek and JSON
See L<Text::CSV_XS>, L<Data::Peek>, L<JSON>

=head2 dcsv

Uses L<Data::Peek>'s DDumper to output the result of C<csv>

=head2 jcsv

Uses L<JSON>'s decode_json to convert the result of C<csv> to JSON.

=head1 AUTHOR

H.Merijn Brand <h.m.brand@xs4all.nl>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2023 H.Merijn Brand

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
