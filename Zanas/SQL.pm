no warnings;

use DBI;

use Data::Dumper;
use DBIx::ModelUpdate;

################################################################################

sub sql_do {
	my ($sql, @params) = @_;
	my $st = $db -> prepare ($sql);
	$st -> execute (@params);
	$st -> finish;	
}

################################################################################

sub sql_select_all_cnt {

	my ($sql, @params) = @_;
	
#	$sql =~ s{SELECT}{SELECT SQL_CALC_FOUND_ROWS}i;
	
#print STDERR $sql;
	
	my $st = $db -> prepare ($sql);
	$st -> execute (@params);
	my $result = $st -> fetchall_arrayref ({});	
	$st -> finish;
	
#	my $cnt = $db -> selectrow_array ("select found_rows()");

	$sql =~ s{SELECT.*?FROM}{SELECT COUNT(*) FROM}ism;
	if ($sql =~ s{LIMIT.*}{}ism) {
#		pop @params;
	}
	$st = $db -> prepare ($sql);
	$st -> execute (@params);
	
	my $cnt = 0;	
	if ($sql =~ /GROUP\s+BY/i) {
		$cnt++ while $st -> fetch ();
	}
	else {
		$cnt = $st -> fetchrow_array ();
	}
	
	return ($result, $cnt);

}

################################################################################

sub sql_select_all {

	my ($sql, @params) = @_;
	my $st = $db -> prepare ($sql);
	$st -> execute (@params);
	my $result = $st -> fetchall_arrayref ({});	
	$st -> finish;
	
	return $result;

}

################################################################################

sub sql_select_col {

	my ($sql, @params) = @_;
	
	my @result = ();
	my $st = $db -> prepare ($sql);
	$st -> execute (@params);
	while (my @r = $st -> fetchrow_array ()) {
		push @result, @r;
	}
	$st -> finish;
	
	return @result;

}

################################################################################

sub sql_select_vocabulary {

	my ($table_name) = @_;	
	return sql_select_all ("SELECT id, label FROM $table_name WHERE fake = 0 ORDER BY label");
	
}

################################################################################

sub sql_select_hash {

	my ($sql_or_table_name, @params) = @_;
	
	if (@params == 0 and $sql_or_table_name !~ /^\s*SELECT/i) {
	
		return sql_select_hash ("SELECT * FROM $sql_or_table_name WHERE id = ?", $_REQUEST {id});
		
	}
	
	my $st = $db -> prepare ($sql_or_table_name);
	$st -> execute (@params);
	my $result = $st -> fetchrow_hashref ();
	$st -> finish;
	
	return $result;

}

################################################################################

sub sql_select_array {

	my ($sql, @params) = @_;
	my $st = $db -> prepare ($sql);
	$st -> execute (@params);
	my @result = $st -> fetchrow_array ();
	$st -> finish;
	
	return wantarray ? @result : $result [0];

}

################################################################################

sub sql_select_scalar {

	my ($sql, @params) = @_;
	my $st = $db -> prepare ($sql);
	$st -> execute (@params);
	my @result = $st -> fetchrow_array ();
	$st -> finish;
	
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

sub sql_last_insert_id {
	return 0 + sql_select_array ("SELECT LAST_INSERT_ID()");
}

################################################################################

sub sql_do_update {

	my ($table_name, $field_list, $stay_fake) = @_;
	my $sql = join ', ', map {"$_ = ?"} @$field_list;
	$stay_fake or $sql .= ', fake = 0';
	$sql = "UPDATE $table_name SET $sql WHERE id = ?";	
	my @params = @_REQUEST {(map {"_$_"} @$field_list), 'id'};	
	sql_do ($sql, @params);
	
}

################################################################################

sub sql_do_insert {

	my ($table_name, $pairs) = @_;
		
	my $fields = '';
	my $args   = '';
	my @params = ();

	$pairs -> {fake} = $_REQUEST {sid} unless exists $pairs -> {fake};

	while (my ($field, $value) = each %$pairs) {	
		my $comma = @params ? ', ' : '';	
		$fields .= "$comma $field";
		$args   .= "$comma ?";
		push @params, $value;	
	}
	
	sql_do ("INSERT INTO $table_name ($fields) VALUES ($args)", @params);	
	
	return sql_last_insert_id ();
	
}

################################################################################

sub sql_do_delete {

	my ($table_name, $options) = @_;
	
	if (ref $options -> {file_path_columns} eq ARRAY) {
		
		map {sql_delete_file ({table => $table_name, path_column => $_})} @{$options -> {file_path_columns}}
		
	}
		
	sql_do ("DELETE FROM $table_name WHERE id = ?", $_REQUEST{id});
	
}

################################################################################

sub sql_delete_file {

	my ($options) = @_;	
	
	my $path = sql_select_array ("SELECT $$options{path_column} FROM $$options{table} WHERE id = ?", $_REQUEST {id});
	
#print STDERR "sql_delete_file: unlinking '$path'\n";

	unlink $path;

#print STDERR "sql_delete_file: '$path' unlinked\n";

}

################################################################################

sub sql_download_file {

	my ($options) = @_;
	
	my $r = sql_select_hash ("SELECT * FROM $$options{table} WHERE id = ?", $_REQUEST {id});
	$options -> {path} = $r -> {$options -> {path_column}};
	$options -> {type} = $r -> {$options -> {type_column}};
	$options -> {file_name} = $r -> {$options -> {file_name_column}};
	
	download_file ($options);
	
}

################################################################################

sub sql_upload_file {
	
	my ($options) = @_;

print STDERR "sql_upload_file: purge started\n";
	
	sql_delete_file ($options);

print STDERR "sql_upload_file: purge finished\n";
	
	my $uploaded = upload_file ($options) or return;
	
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

sub sql_reconnect {

	return if $db and $db -> ping;
	
	$conf = {%$conf, %$preconf};

	our $db  = DBI -> connect ($conf -> {'db_dsn'}, $conf -> {'db_user'}, $conf -> {'db_password'}, {RaiseError => 1});
	
	our $model_update = DBIx::ModelUpdate -> new ($db, dump_to_stderr => 1);

}   	

1;