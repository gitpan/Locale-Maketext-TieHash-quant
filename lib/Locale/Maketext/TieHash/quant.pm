package Locale::Maketext::TieHash::quant;

use 5.006001;
use strict;
use warnings;
use Carp qw(croak);

our $VERSION = '0.04';

require Tie::Hash;
our @ISA = qw(Tie::Hash);

sub TIEHASH {
  my $self = bless {}, shift;
  $self->Config(nbsp => '&nbsp;', @_);
  $self;
}

# configure
sub Config {
  # Object, Parameter Hash
  my $self = shift;
  while (@_) {
    my ($key, $value) = (shift(), shift);
    unless ($key) {
      croak 'key is not true';
    }
    elsif ($key =~ /^(?:L10N|nbsp|nbsp_flag|auto_nbsp_flag[12])$/) {
      $key eq 'nbsp' and (defined $value or croak "key is 'nbsp', value is undef");
      $self->{$key} = $value;
    }
    elsif ($key eq 'numf_comma') {
      $self->{L10N}->{numf_comma} = $value;
    }
    else {
      croak "key is not 'L10N' or 'nbsp' or 'numf_comma' or 'nbsp_flag' or 'auto_nbsp_flag1' or 'auto_nbsp_flag2'";
    }
  }
  defined wantarray or return;
  ( %{$self},
    exists $self->{L10N}
    ? (numf_comma => $self->{L10N}->{numf_comma})
    : (),
  );
}

# quantification
sub FETCH {
  # Object, Key
  my ($self, $key) = @_;
  local $_;
  # Into key stands by 1 blank separate the value and the quantification string.
  my ($number, $strings) = split / /, $key, 2;
  # Quantification string is separated by comma respectively.
  my @string = split /,/, $strings;
  if (defined $self->{nbsp_flag}) {
    # auto_nbsp_flag1
    if (defined $self->{auto_nbsp_flag1} and length $self->{auto_nbsp_flag1}) {
      $string[0] = $self->{nbsp_flag}.$string[0];
    }
    # auto_nbsp_flag2
    if (@string > 1 and defined $self->{auto_nbsp_flag2} and length $self->{auto_nbsp_flag2}) {
      $string[1] = $self->{nbsp_flag}.$string[1];
    }
  }
  eval {
    $_ = $self->{L10N}->quant($number, @string);
  };
  $@ and croak $@;
  # By the translation the "nbsp_flag" becomes blank put respectively behind one.
  # These so highlighted blanks are substituted after the translation into the value of "nbsp".
  if (defined $self->{nbsp_flag} and length $self->{nbsp_flag}) {
    s/ \Q$self->{nbsp_flag}\E/$self->{nbsp}/g;
  }
  $_;
}

# store language handle or options (deprecated)
sub STORE {
  # Object, Key, Value
  my ($self, $key, $value) = @_;
  $self->Config($key => $value);
}

# get values (deprecated)
sub Get {
  my $self = shift;
  for (@_) {
    $_ or croak 'key is not true';
  }
  my @rv = @{{$self->Config}}{@_};
  return wantarray ? @rv : $rv[0];
}

1;
__END__

=head1 NAME

Locale::Maketext::TieHash::quant - Tying method quant to a hash

=head1 SYNOPSIS

=head2 if you don't use Locale::Maketext::TieHash::L10N

 use strict;
 use Locale::Maketext::TieHash::quant;
 my %quant;
 { use MyProgram::L10N;
   my $lh = MyProgram::L10N->get_handle() || die "What language?";
   # tie and configure
   tie %quant, 'Locale::Maketext::TieHash::quant',
     L10N       => $lh,   # save language handle
     numf_comma => 1,     # set option numf_comma
   ;
 }
 ...
 # if you use HTML
 # configure "nbsp_flag", "auto_nbsp_flag1" and "auto_nbsp_flag2"
 tied(%quant)->Config(
   nbsp_flag       => '~',   # set flag to mark whitespaces
   auto_nbsp_flag1 => 1,     # set flag to use "nbsp_flag" at the singular automatically
   auto_nbsp_flag2 => 1,     # set flag to use "nbsp_flag" at the plural automatically
   # If you want to test your Script,
   # you set "nbsp" on a string which you see in the Browser.
   nbsp            => '<span style="color:red">§</span>',
 ;
 ...
 my $part = 5000.5;
 print qq~$mt{Example}:\n$quant{$part.' '.$lh->maketext('part,parts,no part')}\n~;

=head2 if you use Locale::Maketext::TieHash::L10N

 use strict;
 use Locale::Maketext::TieHash::L10N;
 my %mt;
 { use MyProgram::L10N;
   my $lh = MyProgram::L10N->get_handle() || die "What language?";
   tie %mt, 'Locale::Maketext::TieHash::L10N', L10N => $lh, numf_comma => 1;
 }
 use Locale::Maketext::TieHash::quant;
 tie my %quant, 'Locale::Maketext::TieHash::quant',
   tied(%mt)->Config(),   # get back and set language handle and option
   # only if you use HTML
   nbsp_flag => '~',
   auto_nbsp_flag1 => 1,
   auto_nbsp_flag2 => 1,
 ;
 ...
 my $part = 5000.5;
 print qq~$mt{Example}:\n$quant{"$part $mt{'part,parts,no part'}"}\n~;

=head2 read Configuration

 my %config = tied(%quant)->Config();

=head2 write Configuration

 my %config = tied(%quant)->Config(numf_comma => 0, nbsp_flag => '');

=head2 get the language handle C<">L10NC<">, C<">nbspC<">, C<">nbsp_flagC<">, C<">auto_nbsp_flag1C<"> and/or C<">auto_nbsp_flag2C<"> back

 # You can get the language handle "L10N", "nbsp", "nbsp_flag", "auto_nbsp_flag1" and/or "auto_nbsp_flag2" back on this way.
 my ($lh, $nbsp, $nbsp_flag, $auto_nbsp_flag1, $auto_nbsp_flag2) = tied(%quant)->Get(qw/L10N nbsp nbsp_flag auto_nbsp_flag1 auto_nbsp_flag2/);

=head1 DESCRIPTION

Object methods like quant don't have interpreted into strings.
The module ties the method quant to a hash.
The object method quant is executed at fetch hash.
At long last this is the same, only the notation is shorter.

You can use the module also without Locale::Maketext::TieHash::L10N.
Whether this is better for you, have decide you.

=head1 METHODS

=head2 TIEHASH

 use Locale::Maketext::TieHash::quant;
 tie my %quant, 'Locale::Maketext::TieHash::quant', %config;

C<">TIEHASHC<"> ties your hash and set options defaults.

=head2 Config

C<">ConfigC<"> configures the language handle and/or options.

 # configure the language handle
 tied(%quant)->Config(L10N => $lh);

 # configure option of language handle
 tied(%quant)->Config(numf_comma => 1);
 # the same is:
 $lh->{numf_comma} = 1;

 # only for debugging your HTML response
 tied(%quant)->Config(nbsp => 'see_position_of_nbsp_in_HTML_response');   # default is '&nbsp;'

 # Set a flag to say:
 #  Substitute the whitespace before this flag and this flag to '&nbsp;' or your debugging string.
 # The "nbsp_flag" is a string (1 or more characters).
 tied(%quant)->Config(nbsp_flag => '~');

 # You get the string "singular,plural,negative" from any data base.
 # - As if the "nbsp_flag" in front of "singular" would stand.
 tied(%quant)->Config(auto_nbsp_flag1 => 1);
 # - As if the "nbsp_flag" in front of "plural" would stand.
 tied(%quant)->Config(auto_nbsp_flag2 => 1);

The method calls croak, if the key of your hash is undef or your key isn't correct
and if the value, you set to option C<">nbspC<">, is undef.

C<">ConfigC<"> accepts all parameters as Hash and gives a Hash back with all attitudes.

=head2 FETCH

C<">FETCHC<"> quantifying the given key of your hash and give back the translated string as value.

 # quantifying
 print $quant{"$number singular,plural,negative"};
 # the same is:
 print $lh->quant($number, 'singular', 'plural', 'negative');
 ...
 # Use "nbsp" and "nbsp_flag", "auto_nbsp_flag1" and "auto_nbsp_flag2" are true.
 print $quant{"$number singular,plural,negative"};
 # the same is:
 my $result = $lh->quant($number, '~'.'singular', '~'.'plural', 'negative');
 $result =~ s/ ~/&nbsp;/g;   # But not a global debugging function is available.

The method calls croak, if the method C<">quantC<"> of your stored language handle dies.

=head2 STORE (deprecated)

C<">STOREC<"> stores the language handle or options.

 # store the language handle
 $quant{L10N} = $lh;

 # store option of language handle
 $quant{numf_comma} = 1;
 # the same is:
 $lh->{numf_comma} = 1;

 # only for debugging your HTML response
 $quant{nbsp} = 'see_position_of_nbsp_in_HTML_response';   # default is '&nbsp;'

 # Set a flag to say:
 #  Substitute the whitespace before this flag and this flag to '&nbsp;' or your debugging string.
 # The "nbsp_flag" is a string (1 or more characters).
 $quant{nbsp_flag} = '~';

 # You get the string "singular,plural,negative" from any data base.
 $quant{auto_nbsp_flag1} = 1;   # As if the "nbsp_flag" in front of "singular" would stand.
 $quant{auto_nbsp_flag2} = 1;   # As if the "nbsp_flag" in front of "plural" would stand.

The method calls croak, if the key of your hash is undef or your key isn't correct
and if the value, you set to option C<">nbspC<">, is undef.

=head2 Get (deprecated)

Submit 1 key or more. The method C<">GetC<"> give you the values back.

The method calls croak if a key is undef or unknown.

=head1 SEE ALSO

Tie::Hash

Locale::Maketext

Locale::Maketext::TieHash::L10N

=head1 AUTHOR

Steffen Winkler, E<lt>cpan@steffen-winkler.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004, 2005 by Steffen Winkler

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6.1 or,
at your option, any later version of Perl 5 you may have available.

=cut