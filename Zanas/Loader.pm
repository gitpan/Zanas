package Zanas::Loader;

################################################################################

sub import {

	my ($dummy, $root, $package, $preconf) = @_;
	
	$root =~ /[A-Z0-9_]+$/;
	my $old_package = $&;
	
	if ($old_package ne $package) {
		${$package . '::_OLD_PACKAGE'} = $old_package;
	}
	
	${$package . '::_NEW_PACKAGE'} = $package;
	${$package . '::_PACKAGE'}     = $package . '::';
	${$package . '::PACKAGE_ROOT'} = $root;
	${$package . '::preconf'}      = $preconf;
	
	my $dos = $preconf -> {core_path} ? <<EOL : 'require Zanas::Util; require Zanas;';
		do "$$preconf{core_path}/Zanas/Apache.pm";
		do "$$preconf{core_path}/Zanas/Content.pm";
		do "$$preconf{core_path}/Zanas/InternalRequest.pm";
		do "$$preconf{core_path}/Zanas/Presentation.pm";
		do "$$preconf{core_path}/Zanas/Presentation/MSIE_5.pm";
		do "$$preconf{core_path}/Zanas/Request.pm";
		do "$$preconf{core_path}/Zanas/Request/Upload.pm";
		do "$$preconf{core_path}/Zanas/SQL.pm";
		do "$$preconf{core_path}/Zanas.pm";
EOL

	my $cmd = <<EOC;
		package $package;
		do "$root/Config.pm";
		do "$root/Calendar.pm";
		$dos
EOC
	
#	print STDERR $cmd;

	eval $cmd;

	print STDERR $@ if $@;

}

1;