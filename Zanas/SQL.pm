no warnings;

#use DBIx::ModelUpdate;

################################################################################

sub sql_assert_core_tables {

my $time = time;

#print STDERR "sql_assert_core_tables [$$] started...\n";

	my %defs = (
	
		sessions => {
		
			columns => {

				id      => {TYPE_NAME  => 'bigint', _PK    => 1},
				id_user => {TYPE_NAME  => 'int'},
				id_role => {TYPE_NAME  => 'int'},
				ts      => {TYPE_NAME  => 'timestamp'},
			}

		},

		roles => {

			columns => {
				id   => {TYPE_NAME  => 'int', _EXTRA => 'auto_increment', _PK => 1},
				fake => {TYPE_NAME  => 'bigint', COLUMN_DEF => 0, NULLABLE => 0},
				name  => {TYPE_NAME    => 'varchar', COLUMN_SIZE  => 255},
				label => {TYPE_NAME    => 'varchar', COLUMN_SIZE  => 255},
			},

		},

		users => {

			columns => {
				id   => {TYPE_NAME  => 'int', _EXTRA => 'auto_increment', _PK => 1},
				fake => {TYPE_NAME  => 'bigint', COLUMN_DEF => 0, NULLABLE => 0},
				name =>     {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
				login =>    {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
				label =>    {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
				password => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
				id_role =>  {TYPE_NAME => 'int'},
			}

		},

		log => {

			columns => {
				id   => {TYPE_NAME  => 'int', _EXTRA => 'auto_increment', _PK => 1},
				fake => {TYPE_NAME  => 'bigint', COLUMN_DEF => 0, NULLABLE => 0},
				id_user =>   {TYPE_NAME => 'int'},
				id_object => {TYPE_NAME => 'int'},
				ip =>     {TYPE_NAME => 'varchar', COLUMN_SIZE => 15},
				ip_fw =>  {TYPE_NAME => 'varchar', COLUMN_SIZE => 15},
				type =>   {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
				action => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
				error  => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
				params => {TYPE_NAME => 'text'},
				dt     => {TYPE_NAME => 'timestamp'},
				mac    => {TYPE_NAME  => 'varchar', COLUMN_SIZE => 17},
			}

		},	
	
	);
	
	$conf -> {core_cache_html} and $defs {cache_html} = {
		columns => {
			uri     => {TYPE_NAME  => 'varchar', COLUMN_SIZE  => 255, _PK    => 1},
			ts      => {TYPE_NAME  => 'timestamp'},
		}
	};

	$model_update -> assert (tables => \%defs);
	
#print STDERR "sql_assert_core_tables [$$] finished:" . (time - $time) . " ms";	
	
}

################################################################################

sub sql_temporality_callback {
		
	my ($self, %params) = @_;
	
	my $needed_tables = $params {tables};
	
	while (my ($name, $definition) = each %$needed_tables) {

		sql_is_temporal_table ($name) or next;
		
		my $log_def = Storable::dclone ($definition);
		
		foreach my $key (keys %{$log_def -> {columns}}) {
			delete $log_def -> {columns} -> {$key} -> {_EXTRA};
			delete $log_def -> {columns} -> {$key} -> {_PK};
		}

		$log_def -> {columns} -> {id} -> {TYPE_NAME} ||= 'int';

		delete $log_def -> {data};

		$log_def -> {keys} ||= {};
		$log_def -> {keys} -> {__id} = 'id';

		$log_def -> {columns} -> {__dt} = {
			TYPE_NAME => 'datetime',
		};

		$log_def -> {columns} -> {__id} = {
			TYPE_NAME  => 'int', 
			_EXTRA => 'auto_increment', 
			_PK    => 1,
		};

		$log_def -> {columns} -> {__op} = {
			TYPE_NAME  => 'int', 
		};

		$log_def -> {columns} -> {__id_log} = {
			TYPE_NAME  => 'int', 
		};

		$log_def -> {columns} -> {__is_actual} = {
			TYPE_NAME  => 'tinyint', 
			NULLABLE => 0,
			COLUMN_DEF => 0,
		};

		$params {tables} -> {'__log_' . $name} = $log_def;			

	}
	
}

################################################################################

sub sql_is_temporal_table {

	if (ref $conf -> {db_temporality} eq ARRAY) {
		$conf -> {db_temporality} = {(map {$_ => 1} @{$conf -> {db_temporality}})};
	}

	my ($name) = @_;
	
	return 0 if $name =~ /^__log_/;

	if (ref $conf -> {db_temporality} eq HASH) {
		return $conf -> {db_temporality} -> {$name};
	}
	else {
		return $conf -> {db_temporality};
	}

}

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

	print STDERR $@ if $@;
	
	our $SQL_VERSION = sql_version ();
	$SQL_VERSION -> {driver} = $driver_name;

	delete $INC {"Zanas/SQL/${driver_name}.pm"};

	our $model_update = DBIx::ModelUpdate -> new (
		$db, 
		dump_to_stderr => 1, 
		before_assert  => $conf -> {'db_temporality'} ? \&sql_temporality_callback : undef,
	);
		
	our %sts = ();

# print STDERR "sql_reconnect: calling sql_assert_core_tables\n";

	sql_assert_core_tables (); # unless $driver_name eq 'Oracle';

}   	

################################################################################

sub sql_disconnect {

	$db -> disconnect;	
	undef $db;
	undef %sts;
	
}

################################################################################

sub sql_select_vocabulary {
	my ($table_name, $options) = @_;	
	$options -> {order} ||= 'label';
	return sql_select_all ("SELECT id, label FROM $table_name WHERE fake = 0 ORDER BY $$options{order}");
}

1;