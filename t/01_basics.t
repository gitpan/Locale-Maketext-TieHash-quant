use strict;
use warnings;

use Test::More tests => 20 + 1;
use Test::NoWarnings;
use Test::Exception;

BEGIN {
    use_ok('Locale::Maketext::TieHash::quant');
    use_ok('lib', './example/lib');
    use_ok('MyProgram::L10N');
}

my %quant;
{
    my $lh;
    lives_ok(
        sub {
            $lh = MyProgram::L10N->get_handle('de_DE');
        },
        'create a language handle',
    );
    isa_ok(
        $lh,
        'MyProgram::L10N',
        'check languege handle',
    );
    lives_ok(
        sub {
        	   tie %quant, 'Locale::Maketext::TieHash::quant', L10N => $lh;
        },
        'store languege handle',
    );
}

{
    my %cfg = tied(%quant)->config(
        numf_comma      => 1,
        nbsp_flag       => '~',
        auto_nbsp_flag1 => 1,
        auto_nbsp_flag2 => 1,
    );
    ok(
        $cfg{numf_comma}
        && $cfg{nbsp_flag} eq '~',
        'set option numf_comma to 1 and set nbsp_flag to ~ and set auto_nbsp_flag1 to 1 and set auto_nbsp_flag2 to 1'
    );
}
throws_ok(
    sub {
        tied(%quant)->config(undef() => undef);
    },
    qr{\Q'undef'\E}xms,
);
throws_ok(
    sub {
        tied(%quant)->config(wrong => undef);
    },
    qr{\b\Qkey is not '\E\b}xms,
);
throws_ok(
    sub {
        tied(%quant)->config(nbsp => undef);
    },
    qr{\b\Qkey is 'nbsp', value is undef}xms,
);
throws_ok(
    sub {
        $quant{nbsp} = 1;
    },
    qr{\Q"STORE"}xms,
);

is(
    { tied(%quant)->config() }->{L10N}->maketext('Example'),
    'Beispiel',
    'translate',
);
like(
    $quant{
        '5000.5 '
        . { tied(%quant)->config() }->{L10N}->maketext('part,parts,no part')
    },
    qr{Teile}xms,
    'check translation',
);
like(
    $quant{
        '5000.5 '
        . { tied(%quant)->config() }->{L10N}->maketext('part,parts,no part')
    },
    qr{\Q5.000,5}xms,
    'check option numf_comma',
);
like(
    $quant{
        '5000.5 '
        . { tied(%quant)->config() }->{L10N}->maketext('part,parts,no part')
    },
    qr{\Q&nbsp;Teile}xms,
    'check &nbsp; in HTML',
);

{
    my %cfg = tied(%quant)->config(nbsp_flag => '~~');
    isa_ok(
        $cfg{L10N},
        'MyProgram::L10N',
        'config returns L10N',
    );
    is(
        $cfg{nbsp},
        '&nbsp;',
        'config returns nbsp',
    );
    is(
        $cfg{nbsp_flag},
        '~~',
        'config get back nbsp_flag',
    );
    ok(
        $cfg{auto_nbsp_flag1},
        'config get back auto_nbsp_flag1',
    );
    ok(
        $cfg{auto_nbsp_flag2},
        'config get back auto_nbsp_flag2',
    );
    # roll back
    tied(%quant)->config(nbsp_flag => '~');
}