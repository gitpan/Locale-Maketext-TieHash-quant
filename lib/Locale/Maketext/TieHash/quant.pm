package Locale::Maketext::TieHash::quant;

use 5.006001;
use strict;
use warnings;
use Carp qw(croak);

our $VERSION = '0.01';

require Tie::Hash;
our @ISA = qw(Tie::Hash);

sub TIEHASH {
  bless {nbsp => '&nbsp;'}, shift;
}

# store language handle or options
sub STORE {
  # Object, Key, Value
  my ($self, $key, $value) = @_;
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

# quantification
sub FETCH {
  # Object, Key
  my ($self, $key) = @_;
  local $_;
  # Into key stands by 1 blank separate the value and the quantification string.
  my ($number, $strings) = split / /, $key, 2;
  # Quantification string is separated by comma respectively.
  my @string = split ',', $strings;
  # auto_nbsp_flag1
  if (defined $self->{auto_nbsp_flag1} and length $self->{auto_nbsp_flag1}) {
    $string[0] = $self->{nbsp_flag}.$string[0];
  }
  # auto_nbsp_flag2
  if (@string > 1 and defined $self->{auto_nbsp_flag2} and length $self->{auto_nbsp_flag2}) {
    $string[1] = $self->{nbsp_flag}.$string[1];
  }
  eval {
    $_ = $self->{L10N}->quant($number, @string);
  };
  $@ and croak $@;
  # By the translation the "nbsp_flag" becomes blank put respectively behind one.
  # These so highlighted blanks are changed after the translation into the value of "nbsp".
  if (defined $self->{nbsp_flag} and length $self->{nbsp_flag}) {
    s/ \Q$self->{nbsp_flag}\E/$self->{nbsp}/g;
  }
  $_;
}

# get values
sub Get {
  my $self = shift;
  my @rv;
  for (@_) {
    $_ or croak "Get(undef) detected";
    /^(?:L10N|nbsp|nbsp_flag|auto_nbsp_flag[12])$/ or croak "unknown '$_'";
    push @rv, $self->{$_};
  }
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
 tie my %quant, 'Locale::Maketext::TieHash::quant';
 { use MyProgram::L10N;
   my $lh = MyProgram::L10N->get_handle() || die "What language?";
   # store language handle
   $quant{L10N} = $lh;
 }
 # store option numf_comma
 $quant{numf_comma} = 1;
 ...
 # if you use HTML
 # store "nbsp_flag", "auto_nbsp_flag1" and "auto_nbsp_flag2"
 @quant{qw/nbsp_flag auto_nbsp_flag1 auto_nbsp_flag2/} = qw(~ 1 1);
 ...
 my $part = 5000.5;
 print qq~$mt{Example}:\n$quant{"$part ".$lh->maketext('part,parts,no part')}\n~;

=head2 if you use Locale::Maketext::TieHash::L10N

 use strict;
 use Locale::Maketext::TieHash::L10N;
 tie my %mt, 'Locale::Maketext::TieHash::L10N';
 use Locale::Maketext::TieHash::quant;
 tie my %quant, 'Locale::Maketext::TieHash::quant';
 { use MyProgram::L10N;
   my $lh = MyProgram::L10N->get_handle() || die "What language?";
   # store language handle
   $mt{L10N} = $lh;
 }
 # store option numf_comma
 $mt{numf_comma} = 1;
 # only if you use HTML: store option nbsp_flag
 $mt{nbsp_flag} = '~';
 # copy settings
 @quant{tied(%mt)->Keys} = tied(%mt)->Values;
 ...
 # if you use HTML
 # store option auto_nbsp_flag1 and auto_nbsp_flag2
 @quant{qw/auto_nbsp_flag1 auto_nbsp_flag2/} = (1, 1);
 ...
 my $part = 5000.5;
 print qq~$mt{Example}:\n$quant{"$part $mt{'part,parts,no part'}"}\n~;

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

=head1 SEE ALSO

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