no strict;
no warnings;

use DBD::Oracle qw(:ora_types);

################################################################################

sub sql_version {

	my $version = {	strings => [ sql_select_col ('SELECT * FROM V$VERSION') ] };
	
	$version -> {string} = $version -> {strings} -> [0];
	
	($version -> {number}) = $version -> {string} =~ /([\d\.]+)/;
	
	$version -> {number_tokens} = [split /\./, $version -> {number}];
	
	return $version;
	
}

################################################################################

sub sql_prepare {

	my ($sql) = @_;
	
#print STDERR "sql_prepare (pid=$$): $sql\n";
	
	my $qoute = '"';

	if ($sql =~ /^(\s*SELECT.*FROM\s+)(.*)$/is) {
	
		my ($head, $tables_reference, $tail) = ($1, $2);
		
		if ($tables_reference =~ /^(.*)((WHERE|GROUP|ORDER).*)$/is) {
			($tables_reference, $tail) = ($1, $2);
		}
#		print "head: $head\ntables_reference: $tables_reference\ntail: $tail\n\n";
		my @table_names;
		if ($tables_reference =~ s/^(_\w+)/$qoute$1$qoute/) {
			push (@table_names, $1);
		}
		push (@table_names, $1) while ($tables_reference =~ s/,\s*(_\w+)/, $qoute$1$qoute/ig);
		push (@table_names, $1) while ($tables_reference =~ s/JOIN\s*(_\w+)/JOIN $qoute$1$qoute/ig);
		$sql = $head . $tables_reference . $tail;
		foreach my $table_name (@table_names) {
#			print "table_name: $table_name\n";
			$sql =~ s/(\W)($table_name)\./$1$qoute$2$qoute\./g;
		}
	} 
	
	$sql =~ s/^(\s*UPDATE\s+)(_\w+)/$1$qoute$2$qoute/is;
	$sql =~ s/^(\s*INSERT\s+INTO\s+)(_\w+)/$1$qoute$2$qoute/is;
	$sql =~ s/^(\s*DELETE\s+FROM\s+)(_\w+)/$1$qoute$2$qoute/is;

	my $st;

	eval {$st = $db  -> prepare ($sql, {
		ora_auto_lob => ($sql !~ /for\s+update\s*/ism),
	})};
	
	if ($@) {
		my $msg = "sql_prepare: $@ (SQL = $sql)\n";
		print STDERR $msg;
		die $msg;
	}
	
	
	return $st;

}

################################################################################

sub sql_do_refresh_sessions {

	my $timeout = $conf -> {session_timeout};
	if ($preconf -> {core_auth_cookie} =~ /^\+(\d+)([mhd])/) {
		$timeout = $1;
		$timeout *= 
			$2 eq 'h' ? 60 :
			$2 eq 'd' ? 1440 :
			1;
	}

	$db -> {AutoCommit} = 0;
	sql_do ("DELETE FROM sessions WHERE ts < sysdate - ? / 1440", $timeout);
	sql_do ("UPDATE sessions SET ts = sysdate WHERE id = ?", $_REQUEST {sid});
	$db -> commit;
	$db -> {AutoCommit} = 1;
	
}

################################################################################

sub sql_do {

	my ($sql, @params) = @_;
	my $st = sql_prepare ($sql);
	
#	eval {
		$st -> execute (@params);
		$st -> finish;	
#	};

#	if ($@ && $@ =~ /ORA\-02292/) {	
#		$_REQUEST {error} = '�������� ����������� �����������. �������� �����������.';	
#	} 
#	elsif ($@) {
#		die $@;
#	}
	
}

################################################################################

sub sql_select_all_cnt {

	my ($sql, @params) = @_;
		

	unless ($sql =~ s{LIMIT\s+(\d+)\s*\,\s*(\d+).*}{}ism) {
		return sql_select_all ($sql, @params);
	}

	my ($start, $portion) = ($1, $2);

	my $options = {};
	if (@params > 0 and ref ($params [-1]) eq HASH) {
		$options = pop @params;
	}
	
	if ($options -> {fake}) {
	
		my $where = 'WHERE ';
		my $fake  = $_REQUEST {fake} || 0;
	
		foreach my $table (split /\,/, $options -> {fake}) {
			$where .= "$table.fake IN ($fake) AND ";
		}	
		
		$sql =~ s{where}{$where}i;
			
	}


	
	my $st = sql_prepare ($sql);
	$st -> execute (@params);
	my $cnt = 0;	
	my @result = ();
	
	while (my $i = $st -> fetchrow_hashref ()) {
	
		$cnt++;
		
		$cnt > $start or next;
		$cnt <= $start + $portion or last;
			
		push @result, lc_hashref ($i);
	
	}
	
	$st -> finish;
	
	$sql =~ s{SELECT.*?FROM}{SELECT COUNT(*) FROM}ism;
		
	my $cnt = sql_select_scalar ($sql, @params);
			
	return (\@result, $cnt);

}

################################################################################

sub sql_select_all {

	my ($sql, @params) = @_;

	my $options = {};
	if (@params > 0 and ref ($params [-1]) eq HASH) {
		$options = pop @params;
	}
	
	if ($options -> {fake}) {
	
		my $where = 'WHERE ';
		my $fake  = $_REQUEST {fake} || 0;
	
		foreach my $table (split /\,/, $options -> {fake}) {
			$where .= "$table.fake IN ($fake) AND ";
		}	
		
		$sql =~ s{where}{$where}i;
			
	}

	my $st = sql_prepare ($sql);
	$st -> execute (@params);
	my $result = $st -> fetchall_arrayref ({});	
	$st -> finish;
	
	foreach my $i (@$result) {
		lc_hashref ($i);
	}
	
	return $result;

}

################################################################################

sub sql_select_col {

	my ($sql, @params) = @_;

	my @result = ();
	
	if ($sql =~ s{LIMIT\s+(\d+)\s*\,\s*(\d+).*}{}ism) {
		my ($start, $portion) = ($1, $2);
		($start, $portion) = (0, $start) unless ($portion);
	
		my $st = sql_prepare ($sql);
		$st -> execute (@params);
		my $cnt = 0;	
 	
		while (my @r = $st -> fetchrow_array ()) {
	
			$cnt++;
		
			$cnt > $start or next;
			$cnt <= $start + $portion or last;
			
			push @result, @r;
	
		}
	
		$st -> finish;

	} else {

		my $st = sql_prepare ($sql);
		$st -> execute (@params);
		while (my @r = $st -> fetchrow_array ()) {
			push @result, @r;
		}
		$st -> finish;
	}
	
	return @result;

}

################################################################################

sub lc_hashref {

	my ($hr) = @_;
	
	foreach my $key (keys %$hr) {
		$hr -> {lc $key} = $hr -> {$key};
	}
	
	return $hr;

}

################################################################################

sub sql_select_hash {

	my ($sql_or_table_name, @params) = @_;
	
	if ($sql_or_table_name !~ /^\s*SELECT/i) {
	
		my $id = $_REQUEST {id};
		
		if (@params) {
			$id = ref $params [0] eq HASH ? $params [0] -> {id} : $params [0];
		}
	
		@params = ({}) if (@params == 0);
		
		return sql_select_hash ("SELECT * FROM $sql_or_table_name WHERE id = ?", $id);
		
	}	

	my $st = sql_prepare ($sql_or_table_name);
	$st -> execute (@params);
	my $result = $st -> fetchrow_hashref ();
	$st -> finish;		
	
	return lc_hashref ($result);

}

################################################################################

sub sql_select_array {

	my ($sql, @params) = @_;
	my $st = sql_prepare ($sql);
	$st -> execute (@params);
	my @result = $st -> fetchrow_array ();
	$st -> finish;
	
	return wantarray ? @result : $result [0];

}

################################################################################

sub sql_select_scalar {

	my ($sql, @params) = @_;

	my @result;

	if ($sql =~ s{LIMIT\s+(\d+)\s*\,?\s*(\d+)?.*}{}ism) {
		my ($start, $portion) = ($1, $2);
		($start, $portion) = (0, $start) unless ($portion);
	
		my $st = sql_prepare ($sql);
		$st -> execute (@params);
		my $cnt = 0;	
	
		while (my @r = $st -> fetchrow_array ()) {
	
			$cnt++;
		
			$cnt > $start or next;
			$cnt <= $start + $portion or last;
			
			push @result, @r;
			last;
	
		}
	
		$st -> finish;

	} else {

		my $st = sql_prepare ($sql);
		$st -> execute (@params);
		@result = $st -> fetchrow_array ();
		$st -> finish;
	}
	
	return $result [0];

}

################################################################################

sub sql_select_path {
	
	my ($table_name, $id, $options) = @_;
	
	$options -> {name} ||= 'name';
	$options -> {type} ||= $table_name;
	$options -> {id_param} ||= 'id';

	my ($parent) = $id;

	my @path = ();

	while ($parent) {	
		my $r = sql_select_hash ("SELECT id, parent, $$options{name} as name, '$$options{type}' as type, '$$options{id_param}' as id_param FROM $table_name WHERE id = ?", $parent);
		$r -> {cgi_tail} = $options -> {cgi_tail},
		unshift @path, $r;		
		$parent = $r -> {parent};	
	}
	
	if ($options -> {root}) {
		unshift @path, {
			id => 0, 
			parent => 0, 
			name => $options -> {root}, 
			type => $options -> {type}, 
			id_param => $options -> {id_param},
			cgi_tail => $options -> {cgi_tail},
		};
	}

	return \@path;

}

################################################################################

sub sql_select_subtree {

	my ($table_name, $id, $options) = @_;
	
	my @ids = ($id);
	
	while (TRUE) {
	
		my $ids = join ',', @ids;
	
		my @new_ids = sql_select_col ("SELECT id FROM $table_name WHERE parent IN ($ids) AND id NOT IN ($ids)");
		
		last unless @new_ids;
	
		push @ids, @new_ids;
	
	}
	
	return @ids;

}

################################################################################

sub sql_do_update {

	my ($table_name, $field_list, $options) = @_;
	
	ref $options eq HASH or $options = {
		stay_fake => $options,
		id        => $_REQUEST {id},
	};
	
	$options -> {id} ||= $_REQUEST {id};
		
	my %lobs = map {$_ => 1} @{$options -> {lobs}};
	
	my @field_list = grep {!$lobs {$_}} @$field_list;
	
	if (@field_list > 0) {
		my $sql = join ', ', map {"$_ = ?"} @field_list;
		$options -> {stay_fake} or $sql .= ', fake = 0';
		$sql = "UPDATE $table_name SET $sql WHERE id = ?";	

		my @params = @_REQUEST {(map {"_$_"} @field_list)};	
		push @params, $options -> {id};
		sql_do ($sql, @params);

	}
	
	foreach my $lob_field (@{$options -> {lobs}}) {
	
print STDERR "Going to write a LOB in ${table_name}.${lob_field}, id = $$options{id}...\n";
	
#		$db -> {AutoCommit} = 0;
	
		my $st = sql_prepare ("SELECT $lob_field FROM $table_name WHERE id = ? FOR UPDATE");
		my $lob_locator;
		$st -> execute ($options -> {id});
		($lob_locator) = $st -> fetchrow_array;

		unless ($lob_locator) {
			sql_do ("UPDATE $table_name SET $lob_field = empty_clob() WHERE id = ? ", $options -> {id});
			$st -> execute ($options -> {id});
			($lob_locator) = $st -> fetchrow_array;
		}

		$db -> ora_lob_trim   ($lob_locator, 0);
		
		my $value = $_REQUEST {$lob_field} || $_REQUEST {"_$lob_field"};
		
		if ($value) {
		
			my @args = ($lob_locator, $value);

#print STDERR Dumper (\@args);
		
			$db -> ora_lob_append (@args);
		}
		
#		$db -> commit;

#		$db -> {AutoCommit} = 1;
		
	}
	
}

################################################################################

sub sql_do_insert {

	my ($table_name, $pairs) = @_;
		
	my $fields = '';
	my $args   = '';
	my @params = ();

	$pairs -> {fake} = $_REQUEST {sid} unless exists $pairs -> {fake};

	foreach my $field (keys %$pairs) { 
		my $comma = @params ? ', ' : '';	
		$fields .= "$comma $field";
		$args   .= "$comma ?";
		push @params, $pairs -> {$field};	
	}
	
	sql_do ("INSERT INTO $table_name ($fields) VALUES ($args)", @params);	
	
	my $id = sql_select_scalar ("SELECT ${table_name}_seq.currval FROM DUAL");
		
	return $id;
		
}

################################################################################

sub sql_do_delete {

	my ($table_name, $options) = @_;
	
	if (ref $options -> {file_path_columns} eq ARRAY) {
		
		map {sql_delete_file ({table => $table_name, path_column => $_})} @{$options -> {file_path_columns}}
		
	}
	
	our %_OLD_REQUEST = %_REQUEST;	
	eval {
		my $item = sql_select_hash ($table_name);
		foreach my $key (keys %$item) {
			$_OLD_REQUEST {'_' . $key} = $item -> {$key};
		}
	};
	
	sql_do ("DELETE FROM $table_name WHERE id = ?", $_REQUEST{id});
	
	delete $_REQUEST{id};
	
}

################################################################################

sub sql_delete_file {

	my ($options) = @_;	
	
	if ($options -> {path_column}) {
		$options -> {file_path_columns} = [$options -> {path_column}];
	}
	
	foreach my $column (@{$options -> {file_path_columns}}) {
		my $path = sql_select_array ("SELECT $$options{path_column} FROM $$options{table} WHERE id = ?", $_REQUEST {id});
		delete_file ($path);
	}
	

}

################################################################################

sub sql_download_file {

	my ($options) = @_;
	
	$_REQUEST {id} ||= $_PAGE -> {id};
	
	my $r = sql_select_hash ("SELECT * FROM $$options{table} WHERE id = ?", $_REQUEST {id});
	$options -> {path} = $r -> {$options -> {path_column}};
	$options -> {type} = $r -> {$options -> {type_column}};
	$options -> {file_name} = $r -> {$options -> {file_name_column}};
	
	download_file ($options);
	
}

################################################################################

sub sql_upload_file {
	
	my ($options) = @_;

	my $uploaded = upload_file ($options) or return;
	
	sql_delete_file ($options);
	
	my (@fields, @params) = ();
	
	foreach my $field (qw(file_name size type path)) {	
		my $column_name = $options -> {$field . '_column'} or next;
		push @fields, "$column_name = ?";
		push @params, $uploaded -> {$field};
	}
	
	foreach my $field (keys (%{$options -> {add_columns}})) {
		push @fields, "$field = ?";
		push @params, $options -> {add_columns} -> {$field};
	}
	
	@fields or return;
	
	my $tail = join ', ', @fields;
		
	sql_do ("UPDATE $$options{table} SET $tail WHERE id = ?", @params, $_REQUEST {id});
	
	return $uploaded;
	
}

################################################################################
	
sub sql_select_loop {

	my ($sql, $coderef, @params) = @_;
	
	my $st = sql_prepare ($sql);
	$st -> execute (@params);
	
	our $i;
	while ($i = $st -> fetchrow_hashref) {
		lc_hashref ($i);
		&$coderef ();
	}
	
	$st -> finish ();

}

################################################################################

sub keep_alive {
	my $sid = shift;
	sql_do ("UPDATE sessions SET ts = sysdate WHERE id = ? ", $sid);
}

1;