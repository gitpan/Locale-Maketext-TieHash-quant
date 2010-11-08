package Locale::Maketext::TieHash::quant; ## no critic (Capitalization)

use strict;
use warnings;

our $VERSION = '0.06';

use Carp qw(croak);
use English qw(-no_match_vars $EVAL_ERROR);
use Params::Validate qw(:all);

## no critic (ArgUnpacking)

sub TIEHASH {
    my ($class, %init) = validate_pos(
        @_,
        {type => SCALAR},
        ( ({type => SCALAR}, 1) x ((@_ - 1) / 2) ),
    );

    my $self = bless {}, shift;
    $self->config(nbsp => '&nbsp;', %init);

    return $self;
}

# configure
sub config {
    # Object, Parameter Hash
    my ($self, %init) = validate_pos(
        @_,
        {isa => __PACKAGE__},
        ( ({type => SCALAR}, 1) x ((@_ - 1) / 2) ),
    );

    while (my ($key, $value) = each %init) {
        if ( $key =~ m{\A (?: L10N | nbsp | nbsp_flag | auto_nbsp_flag[12]) \z}xms ) {
            if (
                $key eq 'nbsp'
                && ! defined $value
            ) {
                croak q{key is 'nbsp', value is undef};
            }
            $self->{$key} = $value;
        }
        elsif ($key eq 'numf_comma') {
            $self->{L10N}->{numf_comma} = $value;
        }
        else {
            croak q{key is not 'L10N' or 'nbsp' or 'numf_comma' or 'nbsp_flag' or 'auto_nbsp_flag1' or 'auto_nbsp_flag2'};
        }
    }
    defined wantarray
        or return;

    return (
        %{$self},
        exists $self->{L10N}
        ? (numf_comma => $self->{L10N}->{numf_comma})
        : (),
    );
}

# quantification
sub FETCH {
    # Object, Key
    my ($self, $key) = @_;

    # Into the key is 1 blank to separate the value and the quantification string.
    my ($number, $strings) = split m{[ ]}xms, $key, 2;
    # The quantification string is separated by comma respectively.
    my @string = split m{,}xms, $strings;
    if (defined $self->{nbsp_flag}) {
        # auto_nbsp_flag1
        if (
            defined $self->{auto_nbsp_flag1}
            && length $self->{auto_nbsp_flag1}
        ) {
            $string[0]
                = $self->{nbsp_flag}
                . $string[0];
        }
        # auto_nbsp_flag2
        if (
            @string > 1
            && defined $self->{auto_nbsp_flag2}
            && length $self->{auto_nbsp_flag2}
        ) {
            $string[1]
                = $self->{nbsp_flag}
                . $string[1];
        }
    }
    my $string = eval {
        $self->{L10N}->quant($number, @string);
    };
    $EVAL_ERROR
        and croak $EVAL_ERROR;
    # By the translation the 'nbsp_flag' becomes blank put respectively behind one.
    # These so highlighted blanks are substituted after the translation into the value of 'nbsp'.
    if (
        defined $self->{nbsp_flag}
        && length $self->{nbsp_flag}
    ) {
        $string =~ s{[ ] \Q$self->{nbsp_flag}\E}{$self->{nbsp}}xmsg;
    }

    return $string;
}

# $Id$

1;

__END__

=pod

=head1 NAME

Locale::Maketext::TieHash::quant - Tying method quant to a hash

=head1 VERSION

0.06

=head1 SYNOPSIS

=head2 if you don't use Locale::Maketext::TieHash::L10N

    use strict;
    use warnings;

    use Carp qw(croak);
    use Locale::Maketext::TieHash::quant;
    use MyProgram::L10N;

    my %quant;

    my $lh = MyProgram::L10N->get_handle('de_DE')
        or croak 'What language?';

    # tie and configure
    tie %quant, 'Locale::Maketext::TieHash::quant', (
        L10N       => $lh, # save language handle
        numf_comma => 1,   # set option numf_comma
    );

    # if you use HTML
    # configure 'nbsp_flag', 'auto_nbsp_flag1' and 'auto_nbsp_flag2'
    tied(%quant)->config(
        nbsp_flag       => '~', # set flag to mark whitespaces
        auto_nbsp_flag1 => 1,   # set flag to use 'nbsp_flag' at the singular automatically
        auto_nbsp_flag2 => 1,   # set flag to use 'nbsp_flag' at the plural automatically
        # If you want to test your Script,
        # you set 'nbsp' on a string which you see in the Browser.
        nbsp            => '<span style="color:red">*</span>',
    );

    my $part = 5000.5;
    print <<"EOT";
    @{[ $lh->maketext('Example') ]}
    $quant{
        $part
        . q{ }
        . $lh->maketext('part,parts,no part')
    }
    EOT

=head2 if you use Locale::Maketext::TieHash::L10N

    use strict;
    use warnings;

    use Carp qw(croak);
    use Locale::Maketext::TieHash::L10N;
    use Locale::Maketext::TieHash::quant;
    use MyProgram::L10N;

    my %mt;
    {
        my $lh = MyProgram::L10N->get_handle('de_DE')
            or croak 'What language?';
        tie %mt, 'Locale::Maketext::TieHash::L10N', (
            L10N       => $lh,
            numf_comma => 1,
        );
    }

    tie my %quant, 'Locale::Maketext::TieHash::quant';
    tied(%quant)->config( # get back and set language handle and option
        # only if you use HTML
        L10N            => { tied(%mt)->config() }->{L10N},
        nbsp_flag       => '~',
        auto_nbsp_flag1 => 1,
        auto_nbsp_flag2 => 1,
    );

    my $part = 5000.5;
    print <<"EOT";
    $mt{Example}
    $quant{"$part $mt{'part,parts,no part'}"}
    EOT

=head2 read configuration

    my %config = tied(%quant)->config();

=head2 write configuration

    my %config = tied(%quant)->config(
        numf_comma => 0,
        nbsp_flag  => q{},
    );

=head1 EXAMPLE

Inside of this Distribution is a directory named example.
Run this *.pl files.

=head1 DESCRIPTION

Object methods like quant don't have interpreted into strings.
The module ties the method quant to a hash.
The object method quant is executed at fetch hash.
At long last this is the same, only the notation is shorter.

You can use the module also without Locale::Maketext::TieHash::L10N.
Whether this is better for you, have decide you.

=head1 SUBROUTINES/METHODS

=head2 method TIEHASH

    use Locale::Maketext::TieHash::quant;
    tie my %quant, 'Locale::Maketext::TieHash::quant', %config;

'TIEHASH' ties your hash and set options defaults.

=head2 method config

'config' configures the language handle and/or options.

    # configure the language handle
    tied(%quant)->config(L10N => $lh);

    # configure option of language handle
    tied(%quant)->config(numf_comma => 1);
    # the same is:
    $lh->{numf_comma} = 1;

    # only for debugging your HTML response
    tied(%quant)->config(
        nbsp => 'see_position_of_nbsp_in_HTML_response',
    ); # default is '&nbsp;'

    # Set a flag to say:
    #  Substitute the whitespace before this flag and this flag to '&nbsp;'
    #  or your debugging string.
    # The "nbsp_flag" is a string (1 or more characters).
    tied(%quant)->config(nbsp_flag => '~');

    # You get the string 'singular,plural,zero' from any data base.
    # - As if the 'nbsp_flag' in front of 'singular' would stand.
    tied(%quant)->config(auto_nbsp_flag1 => 1);
    # - As if the 'nbsp_flag' in front of 'plural' would stand.
    tied(%quant)->config(auto_nbsp_flag2 => 1);

The method calls croak, if the key of your hash is undef or your key isn't correct
and if the value, you set to option 'nbsp', is undef.

'config' accepts all parameters as Hash and gives a Hash back with all attitudes.

=head2 method FETCH

'FETCH' is quantifying the given key of your hash
and give back the translated string as value.

    # quantifying
    print $quant{"$number singular,plural,zero"};
    # the same is:
    print $lh->quant($number, 'singular', 'plural', 'zero');
    ...
    # Use 'nbsp' and 'nbsp_flag', 'auto_nbsp_flag1' and 'auto_nbsp_flag2' are true.
    print $quant{"$number singular,plural,zero"};
    # the same is:
    my $result = $lh->quant($number, '~' . 'singular', '~' . 'plural', 'zero');
    $result =~ s{[ ] ~}{&nbsp;}xmsg; # But not a global debugging function is available.

The method calls croak, if the method 'quant' of your stored language handle dies.

=head1 DIAGNOSTICS

All methods can croak at false parameters.

=head1 CONFIGURATION AND ENVIRONMENT

nothing

=head1 DEPENDENCIES

Carp

English

L<Params::Validate|Params::Validate>

=head1 INCOMPATIBILITIES

not known

=head1 BUGS AND LIMITATIONS

not known

=head1 SEE ALSO

L<Tie::Hash|Tie::Hash>

L<Locale::Maketext|Locale::Maketext>

L<Locale::Maketext::TieHash::L10N|Locale::Maketext::TieHash::L10N>

=head1 AUTHOR

Steffen Winkler

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2004 - 2010,
Steffen Winkler
C<< <steffenw at cpan.org> >>.
All rights reserved.

This module is free software;
you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut