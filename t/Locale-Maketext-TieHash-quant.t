use 5.006001;
use strict;
use warnings;
use Test::More tests => 10;
BEGIN { use_ok('Locale::Maketext::TieHash::quant') };

# declare some classes...
{ package L10N;
  use base qw(Locale::Maketext);
}
{ package L10N::en;
  use base qw(L10N);
  our %Lexicon = (
    'Beispiel' => 'Example',
    'Teil,Teile,kein Teil' => 'part,parts,no part',
  );
}

print "# create and store language handle\n";
use Locale::Maketext::TieHash::quant;
my %quant;
{ my $lh = L10N->get_handle('en') || die "What language?";
  ok $lh && ref $lh;
  tie %quant, 'Locale::Maketext::TieHash::quant', L10N => $lh;
}
print "# set option numf_comma to 1 and set nbsp_flag to ~ and set auto_nbsp_flag1 to 1 and set auto_nbsp_flag2 to 1\n";
{ my %cfg = tied(%quant)->Config(
    numf_comma => 1,
    nbsp_flag => '~',
    auto_nbsp_flag1 => 1,
    auto_nbsp_flag2 => 1,
  );
  ok
    $cfg{numf_comma}
    && $cfg{nbsp_flag} eq '~'
  ;
}
print "# initiating dying by storing wrong options\n";
{ eval { tied(%quant)->Config(undef() => undef) };
  my $error1 = $@ || '';
  eval { tied(%quant)->Config(wrong => undef) };
  my $error2 = $@ || '';
  eval { tied(%quant)->Config(nbsp => undef) };
  my $error3 = $@ || '';
  eval { $quant{nbsp} = undef };
  my $error_deprecated = $@ || '';
  ok
    $error1 =~ /\bkey is not true\b/
    && $error2 =~ /\bkey is not '\b/
    && $error3 =~ /\bkey is 'nbsp', value is undef/
    && $error_deprecated =~ /\bkey is 'nbsp', value is undef/
  ;
}
print "# translate\n";
{ my $text = {tied(%quant)->Config}->{L10N}->maketext('Beispiel').":\n".$quant{'5000.5 '.{tied(%quant)->Config}->{L10N}->maketext('Teil,Teile,kein Teil')}."\n";
  ok 1;
  print "# check translation\n";
  ok $text =~ /parts/;
  print "# check option numf_comma\n";
  ok $text =~ /5.000,5/;
  print "# check &nbsp; in HTML\n";
  ok $text =~ /&nbsp;parts/;
}
print "# check method Config()\n";
{ my %cfg = tied(%quant)->Config(nbsp_flag => '~~');
  ok
    $cfg{L10N} && ref($cfg{L10N})
    && $cfg{nbsp} eq '&nbsp;'
    && $cfg{nbsp_flag} eq '~~'
    && $cfg{auto_nbsp_flag1}
    && $cfg{auto_nbsp_flag2}
  ;
  tied(%quant)->Config(nbsp_flag => '~');
}
print "# initiating dying by deprecated method Get()\n";
{ eval { tied(%quant)->Get(undef) };
  my $error1 = $@ || '';
  my $value;
  eval { ($value) = tied(%quant)->Get('wrong') };
  my $error2 = $@ || '';
  ok
    $error1 =~ /\bkey is not true\b/
    && $error2 eq ''
    && !defined($value)
  ;
}
