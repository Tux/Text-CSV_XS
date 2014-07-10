use Text::CSV_XS qw( csv );

BEGIN { *CSV:: = \%Text::CSV_XS::; }
$VERSION = "0.01";

1;

=head1 NAME

CSV - Alias for Text::CSV_XS

=head1 SYNOPSIS

  perl -MCSV -wle'csv (in => [[1,2]], out => *STDOUT)'

=head1 DESCRIPTION

See L<Text::CSV_XS>

=head1 AUTHOR

H.Merijn Brand <h.m.brand@xs4all.nl>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2014 H.Merijn Brand

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
