no warnings;

#use DBIx::ModelUpdate;

################################################################################

sub sql_weave_model {

	my ($db_model) = @_;
	
	foreach my $table_name (keys %{$db_model -> {tables}}) {
	
		my $def = $db_model -> {tables} -> {$table_name};

		$def -> {name} = $table_name;
			
		foreach my $column_name (keys %{$def -> {columns}}) {
			$def -> {columns} -> {$column_name} -> {name}       = $column_name;
			$def -> {columns} -> {$column_name} -> {table_name} = $table_name;
		}

		$db_model -> {aliases} -> {$table_name} = $def;
		
		foreach my $alias (@{$def -> {aliases}}) {
			$db_model -> {aliases} -> {$alias} = $def;
		}		
	
	}

	foreach my $table_name (keys %{$db_model -> {tables}}) {
		my $def = $db_model -> {tables} -> {$table_name};

		foreach my $column_name (keys %{$def -> {columns}}) {
			my $column_def = $def -> {columns} -> {$column_name};
				
			$column_name =~ /^ids?_(.*)/ or next;
			
			my $target2 = $1;
			my $target1 = $target2;
		
			if ($target2 =~ /y$/) {
				$target1 =~ s{y$}{ies};
			}
			else {
				$target1 .= 's';
			}
			
			my $referenced_table_def = undef;
			
			if ($column_def -> {ref}) {
				$referenced_table_def = $db_model -> {aliases} -> {$column_def -> {ref}}
			}
			else {
				$referenced_table_def =
					$db_model -> {aliases} -> {$target1} ||
					$db_model -> {aliases} -> {$target2} ||
					$db_model -> {aliases} -> {'voc_' . $target1} ||
					$db_model -> {aliases} -> {'voc_' . $target2} ||
					undef;
			}

			$referenced_table_def or next;
			$referenced_table_def -> {references} ||= [];
			push @{$referenced_table_def -> {references}}, $column_def;
						
		}		
	
	}


}

################################################################################

sub sql_assert_core_tables {

my $time = time;

#print STDERR "sql_assert_core_tables [$$] started...\n";

	my %defs = (
	
		_script_checksums => {
		
			columns => {
				name     => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255, _PK => 1},
				ts       => {TYPE_NAME => 'timestamp'},
				checksum => {TYPE_NAME => 'char', COLUMN_SIZE => 22},
			}

		},

		__access_log => {
		
			columns => {
				id         => {TYPE_NAME => 'bigint', _EXTRA => 'auto_increment', _PK => 1},
				id_session => {TYPE_NAME => 'bigint'},
				ts         => {TYPE_NAME => 'timestamp'},
				no         => {TYPE_NAME => 'int'},
				href       => {TYPE_NAME => 'text'},
			},
			
			keys => {
				ix => 'id_session,no',
				ix2 => 'id_session,href(255)',
			},

		},
		
		__moved_links => {
		
			columns => {
				id          => {TYPE_NAME => 'bigint', _EXTRA => 'auto_increment', _PK => 1},
				table_name  => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
				column_name => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
				id_from     => {TYPE_NAME => 'int'},
				id_to       => {TYPE_NAME => 'int'},
			},
			
			keys => {
				id_to => 'id_to',
			},

		},
		
		__required_files => {
		
			columns => {
				unix_ts   => {TYPE_NAME => 'bigint'},
				file_name => {TYPE_NAME => 'varchar', COLUMN_SIZE  => 255},
			},
			
			keys => {
				ix => 'file_name',
			},

		},

		sessions => {
		
			columns => {

				id      => {TYPE_NAME  => 'bigint', _PK    => 1},
				id_user => {TYPE_NAME  => 'int'},
				id_role => {TYPE_NAME  => 'int'},
				ts      => {TYPE_NAME  => 'timestamp'},

				ip =>     {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
				ip_fw =>  {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
	
				peer_server => {TYPE_NAME    => 'varchar', COLUMN_SIZE  => 255},
				peer_id => {TYPE_NAME    => 'bigint'},
				
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
				mail     => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
				id_role  =>  {TYPE_NAME => 'int'},

				peer_server => {TYPE_NAME    => 'varchar', COLUMN_SIZE  => 255},
				peer_id => {TYPE_NAME    => 'int'},
				
			}

		},

		log => {

			columns => {
				id   => {TYPE_NAME  => 'int', _EXTRA => 'auto_increment', _PK => 1},
				fake => {TYPE_NAME  => 'bigint', COLUMN_DEF => 0, NULLABLE => 0},
				id_user =>   {TYPE_NAME => 'int'},
				id_object => {TYPE_NAME => 'int'},
				ip =>     {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
				ip_fw =>  {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
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
	
	foreach my $name (keys (%$needed_tables)) {

		sql_is_temporal_table ($name) or next;
		
		my $log_def = Storable::dclone ($needed_tables -> {$name});
		
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


	if ($db) {
		my $ping = $db -> ping;
		return if $ping;
	}
	
	$conf = {%$conf, %$preconf};

   	$conf -> {dbf_dsn} and our $dbf = DBI -> connect ($conf -> {dbf_dsn}, {RaiseError => 1});

	our $db  = DBI -> connect ($conf -> {'db_dsn'}, $conf -> {'db_user'}, $conf -> {'db_password'}, {
		RaiseError  => 1, 
		AutoCommit  => 1,
		LongReadLen => 100000000,
		LongTruncOk => 1,
		InactiveDestroy => 0,
	});

	my $driver_name = $db -> {Driver} -> {Name};

	eval "require Zanas::SQL::$driver_name";

	print STDERR $@ if $@;
	
	our $SQL_VERSION = sql_version ();
	$SQL_VERSION -> {driver} = $driver_name;

	delete $INC {"Zanas/SQL/${driver_name}.pm"};

	unless ($preconf -> {no_model_update}) {
	
		our $model_update = DBIx::ModelUpdate -> new (		
			$db, 
			dump_to_stderr => 1,
			before_assert  => $conf -> {'db_temporality'} ? \&sql_temporality_callback : undef,
		);
		
		sql_assert_core_tables (); # unless $driver_name eq 'Oracle';
		
		$preconf -> {no_model_update} = 1;
		
	}
		
	our %sts = ();

}   	

################################################################################

sub sql_disconnect {
	if ($db) { $db -> disconnect; }
	undef $db;
	undef %sts;	
}

################################################################################

sub sql_select_vocabulary {
	my ($table_name, $options) = @_;	
	$options -> {order} ||= 'label';
	my ($filter, $limit);
	$filter = "AND $options->{filter}" if $options -> {filter};
	$limit = "LIMIT $options->{limit}" if $options -> {limit};
	return sql_select_all ("SELECT id, label FROM $table_name WHERE fake = 0 $filter ORDER BY $$options{order} $limit");
}

################################################################################

sub sql_select_ids {
	my ($sql, @params) = @_;
	my @ids = sql_select_col ($sql, @params);
	push @ids, -1;
	return join ',', @ids;
}

################################################################################

sub sql_select_id {

	my ($table, $values, @lookup_field_sets) = @_;
	
	exists $values -> {fake} or $values -> {fake} = 0;
	
	@lookup_field_sets = (['label']) if @lookup_field_sets == 0;
	
	my $record = {};
	
	foreach my $lookup_fields (@lookup_field_sets) {

		my $sql = "SELECT * FROM $table WHERE fake <= 0";
		my @params = ();

		foreach my $lookup_field (@$lookup_fields) {
			$sql .= " AND $lookup_field = ?";
			push @params, $values -> {$lookup_field};
		}

		$sql .= " ORDER BY fake DESC, id DESC";
		
		$record = sql_select_hash ($sql, @params);
		
		last if $record -> {id};

	}
		
	while (my $id = ($record -> {is_merged_to} || $record -> {id_merged_to})) {
		$record = sql_select_hash ($table, $id);
	}
	
	return $record -> {id} || sql_do_insert ($table, $values);

}


1;