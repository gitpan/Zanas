no warnings;

use DBI;

use Data::Dumper;
use DBIx::ModelUpdate;

################################################################################

sub sql_reconnect {

	return if $db and $db -> ping;
	
	$conf = {%$conf, %$preconf};

	our $db  = DBI -> connect ($conf -> {'db_dsn'}, $conf -> {'db_user'}, $conf -> {'db_password'}, {
		RaiseError  => 1, 
		AutoCommit  => 1,
		LongReadLen => 100000000,
		LongTruncOk => 1,
	});

	my $driver_name = $db -> {Driver} -> {Name};

	eval "require Zanas::SQL::$driver_name";

	delete $INC {"Zanas/SQL/${driver_name}.pm"};

	our $model_update = DBIx::ModelUpdate -> new ($db, dump_to_stderr => 1);
	
	our %sts = ();

}   	

################################################################################

sub sql_disconnect {

	$db -> disconnect;	
	undef $db;
	undef %sts;
	
}

1;