#!perl

use strict;
use warnings;

our $VERSION = 0;

use Carp qw(croak);
use Locale::Maketext::TieHash::L10N;
use Locale::Maketext::TieHash::quant;
use lib qw(./lib);
    use MyProgram::L10N;

my %mt;
{
    my $lh = MyProgram::L10N->get_handle('de_DE')
        or croak 'What language?';
    tie %mt, 'Locale::Maketext::TieHash::L10N', ( ## no critic (Ties)
        L10N       => $lh,
        numf_comma => 1,
    );
}

tie my %quant, 'Locale::Maketext::TieHash::quant'; ## no critic (Ties)
tied(%quant)->config( # get back and set language handle and option ## no critic (Ties)
    # only if you use HTML
    L10N            => { tied(%mt)->config() }->{L10N},
    nbsp_flag       => q{~},
    auto_nbsp_flag1 => 1,
    auto_nbsp_flag2 => 1,
);

my $part = 5000.5; ## no critic (MagicNumbers)
() = print <<"EOT";
$mt{Example}
$quant{"$part $mt{'part,parts,no part'}"}
EOT

__END__

$Id$

__END__