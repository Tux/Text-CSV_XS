#!/pro/bin/perl

use 5.018002;
use warnings;

use Data::Peek;
use Text::CSV_XS qw(csv);

my $file = "pm-1192516.csv";

sub make_list {
    my %opt  = @_;

    my %plus;
    my @head = map { s/\+$// && $plus{$_}++; $_ } @{$opt{headings}};

    my %foo;
    my $list = csv (
        in               => $opt{file},
        headers          => \@head,
        sep_char         => "|",
        quote_char       => undef,
        empty_is_undef   => 1,
        allow_whitespace => 1,
        auto_diag        => 1,
        on_in            => sub {
            foreach my $f (@head) {
                $f eq "item" and next;
                push @{$foo{$_{item}}{$f}}, $plus{$f} ? split m/;\s*/ => $_{$f} : $_{$f};
                }
            },
        );

    return \%foo;
    }

DDumper make_list (file => $file, headings => [ "item", "seen in+" ]);
