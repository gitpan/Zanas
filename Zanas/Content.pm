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

	if ($_REQUEST {role}) {
	
		my @tables = map { $_ =~ s/.*\.//; $_ } $db -> tables();
		@tables = map { $_ =~ s/\`//g; $_ } @tables;
		my $multiple_roles = grep {$_ eq 'map_roles_to_users'} @tables;
		
		if ($multiple_roles) {
		
			my $id_role = sql_select_array (<<EOS, $user -> {id}, $_REQUEST {role});
				SELECT 
					roles.id 
				FROM 
					roles, 
					map_roles_to_users 
				WHERE 
					map_roles_to_users.id_user=? 
				AND 
					roles.id=map_roles_to_users.id_role 
				AND 
					roles.name = ?
EOS
			if ($id_role) {
				sql_do ("UPDATE users SET id_role = ? WHERE id = ? ", $id_role, $user->{id});
				$user -> {role} = $_REQUEST{role};
			}
			
		}
		
	}

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

################################################################################

sub delete_file {

	unlink $r -> document_root . $_[0];

}

################################################################################

sub select__static_files {

	$r -> filename =~ /\w+\.\w+/;
	
	my $filename = $&;

	my $content_type = 
		$r -> filename =~ /\.js/ ? 'application/x-javascript' :
		$r -> filename =~ /\.css/ ? 'text/css' :
		'application/octet-stream';

	my $path = $STATIC_ROOT . $filename . '.gz.pm';
	-f $path or $path = $STATIC_ROOT . $filename . '.pm';
	
	$r -> header_out ('Content-Type' => $content_type);	
	$r -> header_out ('Content-Encoding' => 'gzip') if $path =~ /\.gz/;
	$r -> header_out ('Content-Length' => -s $path);
	$r -> header_out ('Cache-Control' => 'max-age=' . 24 * 60 * 60);
	
	$r -> send_http_header ();

	open (F, $path) or die ("Can't open $path: $!\n");
	$r -> send_fd (F);
	close (F);
	
	$_REQUEST {__response_sent} = 1;
	
}

################################################################################

sub download_file {

	my ($options) = @_;
	
	$options -> {type} ||= 'application/octet-stream';
	
	$r -> status (200);

	$options -> {file_name} =~ s{.*\\}{};
	
	$options -> {type} .= '; charset=' . $options -> {charset} if $options -> {charset};

	my $path = $r -> document_root . $options -> {path};
	
	my $start = 0;
	my $content_length = -s $path;
	my $range_header = $r -> header_in ("Range");
	if ($range_header =~ /bytes=(\d+)/) {
		$start = $1;
		my $finish = $content_length - 1;
		$r -> header_out ('Content-Range', "bytes $start-$finish/$content_length");
		$content_length -= $start;
	}

	$r -> content_type ($options -> {type});
	$options -> {no_force_download} or $r -> header_out ('Content-Disposition' => "attachment;filename=" . $options -> {file_name}); 
	$r -> header_out ('Content-Length' => $content_length);
	$r -> header_out ('Accept-Ranges' => 'bytes');
	
	$r -> send_http_header ();

	open (F, $path) or die ("Can't open file $path: $!");
	seek (F, $start, 0);
	$r -> send_fd (F);
	close F;

	$_REQUEST {__response_sent} = 1;
	
}

################################################################################

sub upload_file {
	
	my ($options) = @_;
	
	my $upload = $apr -> upload ('_' . $options -> {name});
	
	return undef unless ($upload and $upload -> size);
	
	my $fh = $upload -> fh;
	
	my $path = "/i/$$options{dir}/" . time . '-' . $$;
	
	my $real_path = $r -> document_root . $path;
	
	open (OUT, ">$real_path") or die "Can't write to $real_path: $!";
	binmode OUT;
	
	my $time = time;
	my $fn = "/$$conf{site_root}/i/dbf/_$time.dbf";
	
	my $buffer = '';
	my $file_length = 0;
	while (my $bytesread = read ($fh, $buffer, 1024)) {
		$file_length += $bytesread;
		print OUT $buffer;
	}
	close (OUT);
	
	my $filename = $upload -> filename;
	$filename =~ s{.*\\}{};
	
	return {
		file_name => $filename,
		size      => $upload -> size,
		type      => $upload -> type,
		path      => $path
	}
	
}

################################################################################

sub add_vocabularies {

	my ($item, @names) = @_;
	
	map {$item -> {$_} = sql_select_vocabulary ($_)} @names;

}

1;