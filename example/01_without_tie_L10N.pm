#!perl

use strict;
use warnings;

our $VERSION = 0;

use Carp qw(croak);
use Locale::Maketext::TieHash::quant;
use lib qw(./lib);
use MyProgram::L10N;

my %quant;

my $lh = MyProgram::L10N->get_handle('de_DE')
    or croak 'What language?';

# tie and configure
tie %quant, 'Locale::Maketext::TieHash::quant', ( ## no critic (Ties)
    L10N       => $lh, # save language handle
    numf_comma => 1,   # set option numf_comma
);

# if you use HTML
# configure 'nbsp_flag', 'auto_nbsp_flag1' and 'auto_nbsp_flag2'
tied(%quant)->config(
    nbsp_flag       => q{~}, # set flag to mark whitespaces
    auto_nbsp_flag1 => 1,    # set flag to use 'nbsp_flag' at the singular automatically
    auto_nbsp_flag2 => 1,    # set flag to use 'nbsp_flag' at the plural automatically
    # If you want to test your Script,
    # you set 'nbsp' on a string which you see in the Browser.
    nbsp            => '<span style="color:red">*</span>',
);

my $part = 5000.5; ## no critic (MagicNumbers)
() = print <<"EOT";
@{[ $lh->maketext('Example') ]}
$quant{
    $part
    . q{ }
    . $lh->maketext('part,parts,no part')
}
EOT

# $Id$

__END__