use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'MooseX::Storage::IO::MongoDB',
    AUTHOR           => q{Marco Masetti <grubert65@gmail.com>},
    VERSION_FROM     => 'lib/MooseX/Storage/IO/MongoDB.pm',
    ABSTRACT_FROM    => 'lib/MooseX/Storage/IO/MongoDB.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'MongoDB'                       => 0,
        'MooseX::Storage'               => 0,
        'MooseX::Role::Parameterized'   => 0,
        'namespace::autoclean'          => 0,
        'Try::Tiny'                     => 0,
        'Carp'                          => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'MooseX-Storage-IO-MongoDB-*' },
);
