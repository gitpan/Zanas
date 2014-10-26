BEGIN {

	use File::Spec;
#	use DBIx::ModelUpdate;

	$| = 1;

	no warnings;

	my $fn = File::Spec -> rel2abs ($0);

	$fn = readlink $fn while -l $fn;
	$fn =~ s{/lib/.*}{};
	$fn =~ s{\\lib\\.*}{};
	
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
	
	sql_reconnect ();
	
	do $config_path;
	
	our $number_format = Number::Format -> new (%{$conf -> {number_format}});

	our $_SKIN = 'Zanas::Presentation::Skins::' . get_skin_name ();	
	*{$_SKIN . '::_REQUEST'} = *{$_PACKAGE . '_REQUEST'};
	*{$_SKIN . '::conf'}     = *{$_PACKAGE . 'conf'};
	*{$_SKIN . '::preconf'}  = *{$_PACKAGE . 'preconf'};
	*{$_SKIN . '::r'}        = *{$_PACKAGE . 'r'};
	*{$_SKIN . '::i18n'}     = *{$_PACKAGE . 'i18n'};

}

END {

	sql_disconnect ();

}

1;