no warnings;

use URI::Escape;

use Apache::Constants qw(:common);
#use Apache::Request;

use Zanas::SQL;

################################################################################

sub add_totals {

	my ($ar, $options) = @_;	
	my $totals = {};
	
	foreach my $r (@$ar) {
		
		while (my ($key, $value) = each %$r) {
			
			next if $key =~ /^id|label$/;
			
			$totals -> {$key} += $r -> {$key};
			
		}
		
	}
	
	$totals -> {label} = 'Итого';
	
	$options -> {position} = 0 + @$ar unless defined $options -> {position};
	
	splice (@$ar, $options -> {position}, 0, $totals);
	
}

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

	if ($ENV{HTTP_COOKIE} =~ /sid=(\d+)/ && !defined $_REQUEST {sid}) {
#		$_REQUEST {sid} ||= $1;
	}

	sql_do ("DELETE FROM sessions WHERE ts < now() - INTERVAL ? MINUTE", $conf -> {session_timeout});
	sql_do ("UPDATE sessions SET ts = NULL WHERE id = ? ", $_REQUEST {sid});

	my $user = sql_select_hash (<<EOS, $_REQUEST {sid});
		SELECT
			users.*
			, roles.name AS role
			, sessions.id_role AS session_role
			, session_roles.name AS session_role_name
		FROM
			sessions
			INNER JOIN users ON sessions.id_user = users.id
			INNER JOIN roles ON users.id_role = roles.id
			LEFT JOIN roles as session_roles ON sessions.id_role = session_roles.id
		WHERE
			sessions.id = ?
EOS

	if ($user && $user -> {session_role}) {
		$user -> {id_role} = $user -> {session_role};
		$user -> {role} = $user -> {session_role_name};
	}

	if ($user && $_REQUEST {role} && ($conf -> {core_multiple_roles} || $preconf -> {core_multiple_roles})) {

		my $id_role = sql_select_scalar (<<EOS, $user -> {id}, $_REQUEST {role});
			SELECT
				roles.id
			FROM
				roles,
				map_roles_to_users
			WHERE
				map_roles_to_users.id_user = ?
				AND roles.id=map_roles_to_users.id_role
				AND roles.name = ?
EOS
		
		$user -> {role} = $_REQUEST {role} if ($id_role);
		
		if ($id_role) {

			my $id_session = sql_select_scalar ("SELECT id FROM sessions WHERE id_user = ? AND id_role = ?", $user -> {id}, $id_role);

			if ($id_session) {
				$_REQUEST {sid} = $id_session;
			} else {
				$_REQUEST {sid} = sql_select_array ("select floor(rand() * 9223372036854775807)");
				sql_do ("INSERT INTO sessions (id, id_user, id_role) VALUES (?, ?, ?)", $_REQUEST {sid}, $user -> {id}, $id_role);
			}

			delete $_REQUEST {role};

			$user -> {redirect} = 1;
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

	my ($url, $options) = @_;
	
	if (ref $url eq HASH) {
		$url = create_url (%$url);
	}
	
	if ($_REQUEST {__uri} ne '/' && $url =~ m{^\/\?}) {
		$url =~ s{^\/\?}{$_REQUEST{__uri}\?};
	}
	
	$options ||= {};
	$options -> {kind} ||= 'internal';
	
	if ($options -> {kind} eq 'internal') {
		$r -> internal_redirect ($url);
		$_REQUEST {__response_sent} = 1;
		return;
	}

	if ($options -> {kind} eq 'http') {		
		$r -> status ($options -> {status} || 302);
		$r -> header_out ('Location' => 'http://' . $ENV{HTTP_HOST} . $url);
		$r -> send_http_header;
		$_REQUEST {__response_sent} = 1;
		return;
	}

	if ($options -> {kind} eq 'js') {
	
		if ($options -> {label}) {
			$options -> {before} = 'alert(' . js_escape ($options -> {label}) . '); ';
		}
	
		$options -> {target} ||= '_parent';
		out_html ({}, qq {<body onLoad="$$options{before} window.open ('$url&_salt=' + Math.random (), '$$options{target}')"></body>});
		$_REQUEST {__response_sent} = 1;
		return;
		
	}
	
}

################################################################################

sub log_action {

	my ($id_user, $type, $action, $error, $id) = @_;
	
	my $ip = $ENV {REMOTE_ADDR};
	my $ip_fw = $ENV {HTTP_X_FORWARDED_FOR};
	
	sql_do ("INSERT INTO log (id_user, type, action, error, params, ip, id_object, ip_fw) VALUES (?, ?, ?, ?, ?, ?, ?, ?)", $id_user, $type, $action, $error, Data::Dumper -> Dump ([\%_REQUEST], ['_REQUEST']), $ip, $id, $ip_fw);
	
}

################################################################################

sub delete_file {

	unlink $r -> document_root . $_[0];

}

################################################################################

sub select__static_files {

#	$r -> filename =~ /\w+\.\w+/;
	
	$ENV{PATH_INFO} =~ /\w+\.\w+/ or $r -> filename =~ /\w+\.\w+/;
	
	my $filename = $&;

	my $content_type = 
		$filename =~ /\.js/ ? 'application/x-javascript' :
		$filename =~ /\.css/ ? 'text/css' :
		$filename =~ /\.htm/ ? 'text/html' :
		'application/octet-stream';

	my $path = $STATIC_ROOT . $filename . '.gz.pm';
	(-f $path and $r -> header_in ('Accept-Encoding') =~ /gzip/) or $path = $STATIC_ROOT . $filename . '.pm';
	
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
	
	$upload -> filename =~ /[A-Za-z0-9]+$/;
	
	my $path = "/i/$$options{dir}/" . time . "-$$.$&";
	
	my $real_path = $r -> document_root . $path;
	
	open (OUT, ">$real_path") or die "Can't write to $real_path: $!";
	binmode OUT;
		
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
		path      => $path,
		real_path => $real_path,
	}
	
}

################################################################################

sub add_vocabularies {

	my ($item, @names) = @_;
	
	map {$item -> {$_} = sql_select_vocabulary ($_)} @names;

}

1;