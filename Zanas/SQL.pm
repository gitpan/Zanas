use DBI;

use Data::Dumper;

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

1;