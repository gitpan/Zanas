use DBI;

use Data::Dumper;

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
	my $cnt = $st -> fetchrow_array ();
	
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

	my ($sql, @params) = @_;
	my $st = $db -> prepare ($sql);
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
	my ($table_name) = @_;
	sql_do ("DELETE FROM $table_name WHERE id = ?", $_REQUEST{id});
}

1;