use 5.006001;
use strict;
use warnings;
use Test::More tests => 9;
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

use Locale::Maketext::TieHash::quant;
tie my %quant, 'Locale::Maketext::TieHash::quant';
print "# create and store language handle\n";
my $lh = L10N->get_handle('en') || die "What language?";
ok $lh && ref $lh;
$quant{L10N} = $lh;
print "# set option numf_comma to 1 and set nbsp_flag to ~ and set auto_nbsp_flag1 to 1 and set auto_nbsp_flag2 to 1\n";
@quant{qw/numf_comma nbsp_flag auto_nbsp_flag1 auto_nbsp_flag2/} = qw/1 ~ 1 1/;
ok 1;
print "# initiating dying by storing wrong options\n";
{ eval { no warnings; $quant{undef()} = undef };
  my $error1 = $@ || '';
  eval { $quant{wrong} = undef };
  my $error2 = $@ || '';
  eval { $quant{nbsp} = undef };
  my $error3 = $@ || '';
  ok $error1 =~ /\bkey is not true\b/ && $error2 =~ /\bkey is not '/ && $error3 =~ /\bkey is 'nbsp', value is undef/;
}
print "# translate\n";
my $text = $lh->maketext('Beispiel').":\n".$quant{'5000.5 '.$lh->maketext('Teil,Teile,kein Teil')}."\n";
ok 1;
print "# check translation\n";
ok $text =~ /parts/;
print "# check option numf_comma\n";
ok $text =~ /5.000,5/;
print "# check &nbsp; in HTML\n";
ok $text =~ /&nbsp;parts/;
print "# initiating dying by Get()\n";
{ eval { tied(%quant)->Get(undef) };
  my $error1 = $@ || '';
  eval { tied(%quant)->Get('wrong')};
  my $error2 = $@ || '';
  ok $error1 =~ /\b\QGet(undef) detected\E\b/ && $error2 =~ /\bunknown 'wrong'/;
}
