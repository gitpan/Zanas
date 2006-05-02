use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		=> 'Zanas',
    'VERSION_FROM'	=> 'Zanas.pm',
    'PREREQ_PM'		=> {
	'DBI'			=> '1.21',
#	'DBD::mysql'		=> '2.9002',
#	'Apache::Request'	=> '0.33',
	'Number::Format'	=> '1.45',
	'DBIx::ModelUpdate'	=> '0.65',
	'Storable'		=> '',
	'MIME::Base64'		=> '',
	'Time::HiRes'		=> '',
#	'Config::ApacheFormat'  => '',
	'File::Temp'		=> '',
	'Digest::MD5'		=> '',
	'Fcntl'			=> '',
	'XML::Simple'		=> '2.14',
    },
    ($] >= 5.005 ?    
	(
	ABSTRACT   => 'A RAD platform for WEB GUIs with rich DHTML widget set.', 
	AUTHOR     => 'D. Ovsyanko <do@zanas.ru>') : ())
);
