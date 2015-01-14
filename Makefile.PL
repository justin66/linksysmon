require 5.002;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME	 => 'linksysmon',
    VERSION_FROM => 'linksysmon.pm',
    dist         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
