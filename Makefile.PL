use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		=> 'Zanas',
    'VERSION_FROM'	=> 'Zanas.pm',
    'PREREQ_PM'		=> {
	'DBI'			=> '1.21',
	'DBD::mysql'		=> '2.9002',
	'Apache::Request'	=> '0.33',
    },
    ($] >= 5.005 ?    
	(ABSTRACT_FROM => 'Zanas.pm', 
	AUTHOR     => 'D. Ovsyanko <do@zanas.ru>') : ())
);
