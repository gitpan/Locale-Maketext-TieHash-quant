package MyProgram::L10N::de; ## no critic (Capitalization)

use strict;
use warnings;

our $VERSION = 0;

use parent qw(MyProgram::L10N);

no warnings qw(once); ## no critic (NoWarnings)
our %Lexicon = ( ## no critic (PackageVars Capitalization)
    'Example'            => 'Beispiel',
    'part,parts,no part' => 'Teil,Teile,kein Teil',
);

1;

__END__

$Id$