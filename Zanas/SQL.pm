use DBI;

use Data::Dumper;
use DBIx::ModelUpdate;

=head1 NAME

SQL.pm - essential DBI wrapper for Zanas. All subs use a unique global database connection.

=cut

################################################################################

=head1 sql_do

Executes a given SQL (DML) statement with supplied parameters. Returns nothing.

=head2 Synopsis

	sql_do ('INSERT INTO my_table (id, name) VALUES (?, ?)', $id, $name);

=cut

################################################################################

sub sql_do {
	my ($sql, @params) = @_;
	my $st = $db -> prepare ($sql);
	$st -> execute (@params);
	$st -> finish;	
}


################################################################################

=head1 sql_select_all_cnt

Executes a given SQL (SELECT) statement with supplied parameters and returns the resultset (listref of hashrefs) and the number of rows in the corresponding selection without the C<LIMIT> clause.

=head2 Synopsis

	my ($rows, $cnt)= sql_select_all_cnt (<<EOS, ...);
		SELECT 
			...
		FROM 
			...
		WHERE 
			...
		ORDER BY 
			...
		LIMIT
			$start, 15
EOS

=cut

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

=head1 sql_select_all

Executes a given SQL (SELECT) statement with supplied parameters and returns the resultset (listref of hashrefs).

=head2 Synopsis

	my $rows = sql_select_all_cnt ('SELECT id, name FROM my_table WHERE name LIKE ?', '%');

=cut

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

=head1 sql_select_col

Executes a given SQL (one column SELECT) statement with supplied parameters and returns the resultset (listref of hashrefs).

=head2 Synopsis

	my $rows = sql_select_col ('SELECT name FROM my_table WHERE name LIKE ?', '%');

=cut

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
		
	my $fields = 'fake';
	my $args   = '?';
	my @params = $_REQUEST {sid};
	
	while (my ($field, $value) = each %$pairs) {
	
		$fields .= ', ' . $field;
		$args   .= ', ?';
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
	
	unlink $path;

}

################################################################################

=head1 sql_download_file

Fetches file info from a given table for the current id and sends file downloading response to the client

=head2 options

=over

=item table

SQL table name

=item path_column

name of the column containing the full path to the file

=item file_name_column

name of the column containing the [original, truncated] file name

=item type_column

name of the column containing the file MIME type

=back

=cut

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

=head1 sql_upload_file

Uploads the file with given CGI name in a given directory under DocumentRoot and stores the related info into the given table for the current id

=head2 options

=over

=item table

SQL table name

=item dir

directory name (relative to DocumentRoot, must be writeable by httpd, file will be named time.pid)

=item path_column

name of the column containing the full path to the file

=item file_name_column

name of the column containing the [original, truncated] file name

=item type_column

name of the column containing the file MIME type

=item size_column

name of the column containing the file size (in bytes)

=back

=cut

################################################################################

sub sql_upload_file {
	
	my ($options) = @_;
	my $uploaded = upload_file ($options) or return;
	
	my (@fields, @params) = ();
	
	foreach my $field (qw(file_name size type path)) {	
		my $column_name = $options -> {$field . '_column'} or next;
		push @fields, "$column_name = ?";
		push @params, $uploaded -> {$field};
	}
	
	@fields or return;
	
	my $tail = join ', ', @fields;
		
	sql_do ("UPDATE $$options{table} SET $tail WHERE id = ?", @params, $_REQUEST {id});
	
	return $uploaded;
	
}

################################################################################

sub sql_adjust_schema ($) {

	my ($tables) = @_;
	
	ref $tables eq HASH and $tables = [$tables];
	
	foreach my $table (@$tables) {
		      	
		my @test = sql_select_col ("SHOW TABLES LIKE '$$table{name}'");
		
		@test or sql_do (<<EOH);
			CREATE TABLE $$table{name} (
				id int unsigned primary key
				, fake bigint unsigned not null
			)
EOH
		
		my $existing_columns = {};
		my $st = $db -> prepare ("SHOW COLUMNS FROM $$table{name}");
		$st -> execute ();
	
		while (my $col = $st -> fetchrow_hashref) {
			next if $col -> {Field} =~ /^id|fake$/;
			$existing_columns -> {$col -> {Field}} = $col;
		}
		
		foreach my $column (@{$table -> {columns}}) {		
			next if $column -> {name} =~ /^id|fake$/;
			next if exists $existing_columns -> {$column -> {name}};
			sql_do ("ALTER TABLE $$table{name} ADD $$column{name} $$column{type}");
		}
	
	}	

}

################################################################################

sub sql_reconnect {

	return if $db and $db -> ping;

	our $db  = DBI -> connect ($conf -> {'db_dsn'}, $conf -> {'db_user'}, $conf -> {'db_password'}, {RaiseError => 1});
	
	our $model_update = DBIx::ModelUpdate -> new ($db, dump_to_stderr => 1);

}   	

1;