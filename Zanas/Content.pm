use URI::Escape;

use Apache::Constants qw(:common);
use Apache::Request;

use Zanas::SQL;

################################################################################

sub keep_alive {
	my $sid = shift;
	sql_do ("UPDATE sessions SET ts = NULL WHERE id = ? ", $sid);
}

################################################################################

sub call_for_role {
	my $sub_name = shift;
	my $role = $_USER ? $_USER -> {role} : '';	
	my $full_sub_name = $sub_name . '_for_' . $role;
	my $name_to_call = 
		exists $$_PACKAGE {$full_sub_name} ? $full_sub_name : 
		exists $$_PACKAGE {$sub_name} ? $sub_name : 
		undef;
	
	if ($name_to_call) {
		return &$name_to_call (@_);
	}
	else {
		print STDERR "call_for_role: callback procedure not found: \$sub_name = $sub_name, \$role = $role \n";
	}

	return $name_to_call ? &$name_to_call (@_) : undef;
		
}

################################################################################

sub get_user {

	sql_do ("DELETE FROM sessions WHERE ts < now() - INTERVAL ? MINUTE", $conf -> {session_timeout});
	sql_do ("UPDATE sessions SET ts = NULL WHERE id = ? ", $_REQUEST {sid});

	my $user = sql_select_hash (<<EOS, $_REQUEST {sid});
		SELECT
			users.*
			, roles.name AS role
		FROM
			sessions
			INNER JOIN users ON sessions.id_user = users.id
			INNER JOIN roles ON users.id_role = roles.id
		WHERE
			sessions.id = ?
EOS

	$user -> {label} ||= $user -> {name} if $user;
	
	return $user;

}

################################################################################

sub delete_fakes {
	my ($table_name) = @_;
	$table_name ||= $_REQUEST {type};
	my @sids = (0, sql_select_col ("SELECT id FROM sessions WHERE id <> ?", $_REQUEST {sid}));	
	sql_do ("DELETE FROM $table_name WHERE fake NOT IN (" . (join ', ', @sids) . ')');
}

################################################################################

sub interpolate {
	my $template = $_[0];
	my $result = '';
	my $code = "\$result = <<EOINTERPOLATION\n$template\nEOINTERPOLATION";
	eval $code;
	$result .= $@;
	return $result;
}

################################################################################

sub get_filehandle {
#	return $q -> upload ($_[0]);	
	return $apr -> upload ($_[0]) -> fh;	
}

################################################################################

sub redirect {
#	print $q -> redirect ($_[0]);
	$r -> internal_redirect ($_[0]);
}

################################################################################

sub log_action {
	my ($id_user, $type, $action, $error) = @_;
	sql_do ("INSERT INTO log (id_user, type, action, error, params) VALUES (?, ?, ?, ?, ?)", $id_user, $type, $action, $error, Data::Dumper -> Dump ([\%_REQUEST], ['_REQUEST']));
}

1;