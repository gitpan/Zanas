BEGIN {

	use File::Spec;
	use DBIx::ModelUpdate;

	$| = 1;

	no warnings;

	my $fn = File::Spec -> rel2abs ($0);

	$fn = readlink $fn while -l $fn;
	$fn =~ s{/lib/.*}{};
	
	$PACKAGE_ROOT = [$fn . '/lib/' . __PACKAGE__ . '/'];
	
	my $config_path = $fn . '/lib/' . __PACKAGE__ . '/Config.pm';
	
	push @INC, $PACKAGE_ROOT;
	
	$fn .= '/conf/httpd.conf';

	open (CONF, $fn) or die ("Can't open $fn:$!\n");
	my $conf = join '', (<CONF>);
	close (CONF);

	$conf =~ s{.*<perl>}{}gsm;
	$conf =~ s{</perl>.*}{}gsm;
	eval "\$^W = 0; $conf";
	
	require Zanas;

#	require Zanas::Presentation::MSIE_5;
#	require Zanas::Content;
#	require Zanas::Presentation;
#	require Zanas::SQL;
	
	sql_reconnect ();
	
	do $config_path;
	
	our $number_format = Number::Format -> new (%{$conf -> {number_format}});

}

END {

	sql_disconnect ();

}

1;