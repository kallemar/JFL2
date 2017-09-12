use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'JFL2',
    AUTHOR              => q{Kalle Marjamäki kalle@marjamaki.net},
    VERSION_FROM        => 'lib/JFL.pm',
    ABSTRACT            => 'Junior Football Leaque registration and management system',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'YAML'       => 0,
        'Dancer'     => 1.311,
        'Dancer::Plugin::ValidateTiny'     => 0,
        'Dancer::Plugin::ORMesque'         => 0,
        'Dancer::Plugin::Email'            => 0,
        'Dancer::Plugin::Auth::Extensible' => 0,
        'Crypt::SaltedHash'                => 0,
        'Dancer::Plugin::REST'             => 0,
        'Dancer::Plugin::Auth::Basic'      => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'JFL-*' },
);
