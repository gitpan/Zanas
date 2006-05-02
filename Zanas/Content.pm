no warnings;

################################################################################

sub peer_name {

	$preconf -> {peer_name} or die "Peer name not defined\n";

	return $preconf -> {peer_name};

}

################################################################################

sub peer_reconnect {

	unless ($UA) {
	
		our $UA = LWP::UserAgent -> new (
			agent                 => "Zanas/$Zanas_VERSION (" . peer_name () . ")",
			requests_redirectable => ['GET', 'HEAD', 'POST'],
		);
		
		$HTTP::Request::Common::DYNAMIC_FILE_UPLOAD = 1;
		
	}
		
}

################################################################################

sub peer_proxy {

	my ($peer_server, $params) = @_;
	
	my $url = $preconf -> {peer_servers} -> {$peer_server} or die "Peer server '$peer_server' not defined\n";
	
	$_REQUEST {__peer_server} = $peer_server;
	
	peer_reconnect ();
		
	$url .= '?sid=';
	$url .= $_REQUEST {sid};
	
	my @keys = keys %$params;

	foreach my $k (@keys) {
		$url .= '&';
		$url .= $k;
		$url .= '=';
		$url .= uri_escape ($params -> {$k});
	}		
		
	$request = HTTP::Request -> new ('GET', $url);
	
	my $virgin = 1;
		
	my $response = $UA -> request ($request,
				
		sub { 
			
			if ($virgin) {
				$r -> print ($r -> protocol);
				$r -> print (" 200OK\015\012");
				$r -> print ($_[1] -> headers_as_string);
				$r -> print ("\015\012");
				$virgin = 0;
			}
		
			$r -> print ($_[0]);
		},
		
	);
		
	$_REQUEST {__response_sent} = 1;

}

################################################################################

sub peer_query {

	my ($peer_server, $params, $options) = @_;
	
	my $url = $preconf -> {peer_servers} -> {$peer_server} or die "Peer server '$peer_server' not defined\n";
	
	peer_reconnect ();
	
	foreach my $k (keys %_REQUEST) {
		next if $k =~ /^__/;
		next if exists $params -> {$k};
		$params -> {$k} = $_REQUEST {$k};
	}
	
	$params -> {__d} = 1;
	
	my @headers = (Accept_Encoding => 'gzip');

	$options -> {files} = [$options -> {file}] if $options -> {file};
	if (ref $options -> {files} eq ARRAY) {
		
		foreach my $name (@{$options -> {files}}) {
			my $file = upload_file ({ name => $name, dir => 'upload/images'});
			$params -> {'_' . $name} = [$file -> {real_path}, $params -> {'_' . $name}];
		}
		
		push @headers, (Content_Type => 'form-data');
		
	}
		
	my $response = $UA -> request (POST $url,
		@headers,
		Content         => [ %$params ],
	);
	
	foreach my $k (keys %$params) {
		my $v = $params -> {$k};
		ref $v eq ARRAY or next;
		unlink $v -> [0];
	}		
	
	while (1) {
		
		$response -> is_success or die ($response -> status_line);
		
		my $dump = $response -> content;
	
		if ($response -> headers -> header ('Content-Encoding') eq 'gzip') {
			$dump = Compress::Zlib::memGunzip ($dump);
		}
		
		eval $dump;
		
		my ($root, $data) = (%$VAR1);
		
		undef $VAR1;
			
		$_REQUEST {__peer_server} = $peer_server;
					
		if ($root eq 'data') {			
			return $data;
		}
		
		if ($root eq 'redirect') {
		
			$response = $UA -> request (GET $url . $data -> {url} . '&__d=1',
				Accept_Encoding => 'gzip',
			);
		
		}
		elsif ($root eq 'error') {
		
			$data -> {message} = '#' . $data -> {field} . '#:' . $data -> {message} if ($data -> {field});
			
			$_REQUEST {error} = $data -> {message};
			$_REQUEST {error} = '#' . $data -> {field} . '#:' . $_REQUEST {error} if $data -> {field};
			
			return $_REQUEST {error};
			
		}
		else {
			die ("Invalid root tag: $root\n");
		}
			
	}

}


#############################################################################

sub get_skin_name {

	return
		$_REQUEST {xls} ? 'XL' :
		$_REQUEST {__dump} || $_REQUEST {__d} ? 'Dumper' :
		$_REQUEST {__proto} ? 'XMLProto' :
		$_REQUEST {__x} ? 'XMLDumper' :
		'Classic';

}

#############################################################################

sub is_off {
	
	my ($options, $value) = @_;
	
	return 0 unless $options -> {off};
	
	if ($options -> {off} eq 'if zero') {
		return ($value == 0);
	}
	elsif ($options -> {off} eq 'if not') {
		return !$value;
	}
	else {
		return $options -> {off};
	}

}

################################################################################

sub async ($@) {

	my ($sub, @args) = @_;

	eval { &$sub (@args); };
	
	print STDERR $@ if $@;
	
	
#	sql_disconnect ();

#	defined (my $child_pid = fork) or die "Cannot fork: $!\n";
	
#	sql_reconnect ();

#	return $child_pid if $child_pid;
	
#	chdir '/' or die "Can't chdir to /: $!";
#	close STDIN;
#	close STDOUT;
#	close STDERR;	
	
#	eval { &$sub (@args); };
	
#	sql_disconnect ();

#	CORE::exit ();

}

################################################################################

sub send_mail {

	my ($options) = @_;
	
	warn "send_mail: " . Dumper ($options);
	
	my $to = $options -> {to};
	
		##### Multiple recipients
	
	if (ref $to eq ARRAY) {
	
		foreach (@$to) {
			$options -> {to} = $_;
			send_mail ($options);
		}
		
		return;
	
	}
	
		##### To address
		
	if (!ref $to && $to > 0) {
		$to = sql_select_hash ('SELECT label, mail FROM users WHERE id = ?', $to);
	}

	if ($preconf -> {mail} -> {to}) {
		$options -> {text} .= Dumper ($to);
		$to = $preconf -> {mail} -> {to};
	}

	my $real_to = $to;	
	if (ref $to eq HASH) {
		$real_to = $to -> {mail};
		$to = encode_mail_header ($to -> {label}, $options -> {header_charset}) . "<$real_to>";
	}
	
	unless ($real_to =~ /\@/) {
		warn "send_mail: INVALID MAIL ADDRESS '$real_to'\n";
		return;
	}
	
		##### From address

	$options -> {from} ||= $preconf -> {mail} -> {from};
	my $from = $options -> {from};
	if (ref $from eq HASH) {
		$from -> {mail} ||= $from -> {address};
		$from = encode_mail_header ($from -> {label}, $options -> {header_charset}) . "<" . $from -> {mail} . ">";
	}

		##### Message subject

	my $subject = encode_mail_header ($options -> {subject}, $options -> {header_charset});

		##### Message body
	
	$options -> {body_charset} ||= 'windows-1251';
	$options -> {content_type} ||= 'text/plain';
	
	if ($options -> {href}) {	
		$options -> {href} =~ /^http/ or $options -> {href} = "http://$ENV{HTTP_HOST}" . $options -> {href};
		$options -> {href} = "<br><br><a href='$$options{href}'>$$options{href}</a>" if $options -> {content_type} eq 'text/html';
		$options -> {text} .= "\n\n" . $options -> {href};
	}
#	my $text = encode_qp ($options -> {text});
	my $text = encode_base64 ($options -> {text});
	
	unless ($^O eq 'MSWin32') {
		defined (my $child_pid = fork) or die "Cannot fork: $!\n";
		return $child_pid if $child_pid;
	}
		
		##### connecting...

	my $smtp = Net::SMTP -> new ($preconf -> {mail} -> {host});
	$smtp -> mail ($ENV{USER});
	$smtp -> to ($real_to);
	$smtp -> data ();

		##### sending main message

	$smtp -> datasend (<<EOT);
From: $from
To: $to
Subject: $subject
Content-type: multipart/mixed;
	Boundary="0__=4CBBE500DFA7329E8f9e8a93df938690918c4CBBE500DFA7329E"
Content-Disposition: inline

--0__=4CBBE500DFA7329E8f9e8a93df938690918c4CBBE500DFA7329E
Content-Type: $$options{content_type}; charset="$$options{body_charset}"
Content-Transfer-Encoding: base64

$text
EOT

		##### sending attach
		
	if ($options -> {attach} && -f $options -> {attach} -> {real_path}) {
	
		my $type = $options -> {attach} -> {type};
		$type ||= 'application/octet-stream';
		
		my $fn   = $options -> {attach} -> {file_name};
		$fn ||= $options -> {attach} -> {real_path};
		$fn =~ s{.*[\\\/]}{};
		
	$smtp -> datasend (<<EOT);
--0__=4CBBE500DFA7329E8f9e8a93df938690918c4CBBE500DFA7329E
Content-type: $type;
	name="$fn"
Content-Disposition: attachment; filename="$fn"
Content-transfer-encoding: base64

EOT

	my $buf = '';
	open (FILE, $options -> {attach} -> {real_path}) or die "Can't open ${$$options{attach}}{real_path}: $!";
	while (read (FILE, $buf, 60*57)) {
	       $smtp -> datasend (encode_base64 ($buf));
	}
	close (FILE);

	$smtp -> datasend (<<EOT);

--0__=4CBBE500DFA7329E8f9e8a93df938690918c4CBBE500DFA7329E--
EOT
	
	}

	$smtp -> dataend ();
	$smtp -> quit;
		
	unless ($^O eq 'MSWin32') {
		CORE::exit (0);
	}

}

################################################################################

sub encode_mail_header {

	my ($s, $charset) = @_;

	$charset ||= 'windows-1251';
	
	if ($charset eq 'windows-1251') {
		$s =~ y{ÀÁÂÃÄÅ¨ÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäå¸æçèéêëìíîïðñòóôõö÷øùúûüýþÿ}{áâ÷çäå³öúéêëìíîïðòóôõæèãþûýÿùøüàñÁÂ×ÇÄÅ£ÖÚÉÊËÌÍÎÏÐÒÓÔÕÆÈÃÞÛÝßÙØÜÀÑ};
		$charset = 'koi8-r';
	}

	$s = '=?' . $charset . '?B?' . encode_base64 ($s) . '?=';
	$s =~ s{[\n\r]}{}g;
	return $s;	
	
}

################################################################################

sub b64u_freeze {

	b64u_encode (
		$Storable::VERSION ? 
			Storable::freeze ($_[0]) : 
			Dumper ($_[0])
	);
	
}

################################################################################

sub b64u_thaw {

	my $serialized = b64u_decode ($_[0]);
	
	if ($Storable::VERSION) {
		return Storable::thaw ($serialized);
	}
	else {
		my $VAR1;
		eval $serialized;
		return $VAR1;
	}
	
}

################################################################################

sub b64u_encode {
	my $s = MIME::Base64::encode ($_[0]);
	$s =~ y{+/=}{-_.};
	$s =~ s{[\n\r]}{}gsm;
	return $s;
}

################################################################################

sub b64u_decode {
	my $s = $_ [0];
	$s =~ y{-_.}{+/=};
	return MIME::Base64::decode ($s);
}

################################################################################

sub require_fresh {

	my ($module_name, $fatal) = @_;	

#warn ("require_fresh ('$module_name') called...\n");
	
	my $file_name = $module_name;
	$file_name =~ s{(::)+}{\/}g;

	my $inc_key = $file_name . '.pm';

	$file_name =~ s{^(.+?)\/}{\/};
	
	my $found = 0;
	my $the_path = '';
	
	foreach my $path (reverse (@$PACKAGE_ROOT)) {
		my $local_file_name = $path . $file_name . '.pm';
		-f $local_file_name or next;
		$file_name = $local_file_name;
		$found = 1;
		$the_path = $path;
		last;
	}

	$found or return "File not found: $file_name\n";
	
	my $need_refresh = $preconf -> {core_spy_modules} || !$INC {$inc_key};
	
	my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $last_modified, $ctime, $blksize, $blocks);
	if ($need_refresh) {
		($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $last_modified, $ctime, $blksize, $blocks) = stat ($file_name);
		my $last_load = $INC_FRESH {$module_name} + 0;
		$need_refresh &&= $last_load < $last_modified;
	}
		
	if ($need_refresh) {
	
		if ($_OLD_PACKAGE) {
			open (S, $file_name);
			my $src = join '', (<S>);
			close (S);
			$src =~ s{package\s+$_OLD_PACKAGE}{package $_NEW_PACKAGE}g;
			$src =~ s{$_OLD_PACKAGE\:\:}{$_NEW_PACKAGE\:\:}g;
			eval $src;
		}
		else {
			do $file_name;
		}

		die $@ if $@;

		if (
			$file_name =~ /Config\.pm$/
			&& $DB_MODEL
		) {
			sql_weave_model ($DB_MODEL);
		}

		if (
			$file_name =~ /Config\.pm$/
			&& $db
			&& $last_modified > 0 + sql_select_scalar ('SELECT unix_ts FROM __required_files WHERE file_name = ?', $module_name)
		) {
		
			my $unix_ts = 0 + sql_select_scalar ('SELECT unix_ts FROM __required_files WHERE file_name = ?', $module_name);
		
			if ($DB_MODEL) {

				open  (CONFIG, $file_name) || die "can't open $file_name: $!";
				flock (CONFIG, LOCK_EX);
				$model_update -> assert (%$DB_MODEL);
				flock (CONFIG, LOCK_UN);
				close (CONFIG);

			}

			if (-d "$the_path/Updates") {

				open  (CONFIG, $file_name) || die "can't open $file_name: $!";
				flock (CONFIG, LOCK_EX);

				eval {

					opendir (DIR, "$the_path/Updates") || die "can't opendir $the_path/Updates: $!";
					my @scripts = readdir (DIR);
					closedir DIR;

					foreach my $script (@scripts) {

						$script =~ /\.p[lm]$/ or next;

						my $script_path = "$the_path/Updates/$script";

print STDERR "\nfound update script: '$script_path'... ";

						my $md5 = Digest::MD5 -> new;
						open (SCRIPT, $script_path) || die "can't open $script_path: $!";
						$md5 -> addfile (*SCRIPT);
						close   (SCRIPT);

						my $digest = $md5 -> b64digest;
						my $old_digest = sql_select_scalar ('SELECT checksum FROM _script_checksums WHERE name = ?', $script);

						unless ($digest eq $old_digest) {

print STDERR "it's new...";

							my $result = do $script_path;

							unless (defined $result) {
								die $! || $@ || "$script_path didn't return any true value\n";
							}

							if ($old_digest) {
								sql_do ('UPDATE _script_checksums SET checksum = ? WHERE name = ?', $digest, $script);
							}
							else {
								sql_do ('INSERT INTO _script_checksums (name, checksum) VALUES (?, ?)', $script, $digest);
							}

print STDERR "ok\n";


						}
						else {

print STDERR "already executed.\n";

						}


					}

				};

				flock (CONFIG, LOCK_UN);
				close (CONFIG);

				die $@ if $@;

			}
		
		};
		
		if ($db && $db -> ping) {
			sql_do ('DELETE FROM __required_files WHERE file_name = ?', $module_name);
			sql_do ('INSERT INTO __required_files (file_name, unix_ts) VALUES (?, ?)', $module_name, time);
		}
	
		$INC_FRESH {$module_name} = $last_modified;
		
	}

        if ($@) {
		$_REQUEST {error} = $@;
		print STDERR "require_fresh: error load module $module_name: $@\n";
        }	
        
        return $@;
	
}

################################################################################

sub add_totals {

	my ($ar, $options) = @_;	
	my $totals = {};
	
	foreach my $r (@$ar) {
		
		foreach my $key (keys %$r) {
			
			next if $key =~ /^id|label$/;
			
			$totals -> {$key} += $r -> {$key};
			
		}
		
	}
	
	$totals -> {label} = 'Èòîãî';
	
	$options -> {position} = 0 + @$ar unless defined $options -> {position};
	
	splice (@$ar, $options -> {position}, 0, $totals);
	
}


################################################################################

sub do_add_DEFAULT {
	
	sql_do_relink ($_REQUEST {type}, [get_ids ('clone')] => $_REQUEST {id});

}

################################################################################

sub do_create_DEFAULT {

	my $default_values = {};
	
	while (my ($k, $v) = each %_REQUEST) {
	
		next if $k =~ /^_/;
		next if $k eq 'sid';
		next if $k eq 'salt';
		next if $k eq 'select';
		next if $k eq 'type';
		next if $k eq 'action';
		next if $k eq 'lang';
		next if $k eq 'error';
				
		$default_values -> {$k} = $v;
	
	}
	
	$_REQUEST {id} = sql_do_insert ($_REQUEST {type}, $default_values);

}

################################################################################

sub do_update_DEFAULT {
	
	sql_do_update ($_REQUEST {type}, [map { substr $_, 1 } grep { /^_[^_]/ && $_ ne '_id_log' } keys %_REQUEST]);

}

################################################################################

sub do_delete_DEFAULT {

	sql_do ("UPDATE $_REQUEST{type} SET fake = -1 WHERE id = ?", $_REQUEST{id});

}

################################################################################

sub do_undelete_DEFAULT {

	sql_do ("UPDATE $_REQUEST{type} SET fake =  0 WHERE id = ?", $_REQUEST{id});
	sql_undo_relink ($_REQUEST{type}, $_REQUEST{id});

}

################################################################################

sub call_for_role {

	my $sub_name = shift;

	my $time = $preconf -> {core_debug_profiling} == 1 ? time : undef;

	my $role = $_USER ? $_USER -> {role} : '';	

	my $full_sub_name = $sub_name . '_for_' . $role;

	my $default_sub_name = $sub_name;
	$default_sub_name =~ s{_$_REQUEST{type}$}{_DEFAULT};
	
	my $name_to_call = 
		exists $$_PACKAGE {$full_sub_name}    ? $full_sub_name : 
		exists $$_PACKAGE {$sub_name}         ? $sub_name : 
		exists $$_PACKAGE {$default_sub_name} ? $default_sub_name : 
		undef;
	
	if ($name_to_call) {
		my $result = &$name_to_call (@_);
		print STDERR "Profiling [$$] " . 1000 * (time - $time) . " ms $name_to_call\n" if $preconf -> {core_debug_profiling} == 1;
		return $result;
	}
	else {
		$sub_name    =~ /^validate_/ 
		or $sub_name eq 'get_menu'
		or $sub_name eq 'select_menu'
		or print STDERR "call_for_role: callback procedure not found: \$sub_name = $sub_name, \$role = $role \n";
	}

	return $name_to_call ? &$name_to_call (@_) : undef;
		
}

################################################################################

sub get_user {

	return if $_REQUEST {type} eq '_static_files';
		
	sql_do_refresh_sessions ();

	my $user = undef;
	
	if ($_REQUEST {__login}) {
		$user = sql_select_hash ('SELECT * FROM users WHERE login = ? AND password = PASSWORD(?)', $_REQUEST {__login}, $_REQUEST {__password});
		$user -> {id} or undef $user;
	}
	
	my $peer_server = undef;
	
	if ($r -> header_in ('User-Agent') =~ m{^Zanas/.*? \((.*?)\)}) {
	
		$peer_server = $1;
					
		my $local_sid = sql_select_scalar ('SELECT id FROM sessions WHERE peer_id = ? AND peer_server = ?', $_REQUEST {sid}, $peer_server);
		
		unless ($local_sid) {
		
			my $user = peer_query ($peer_server, {__whois => $_REQUEST {sid}});
			
			my $role = $conf -> {peer_roles} -> {$peer_server} -> {$user -> {role}} || $conf -> {peer_roles} -> {$peer_server} -> {''};
			
			$role or die ("Peer role $$user{role} is undefined for the server $peer_server\n");
			
			my $id_role = sql_select_scalar ('SELECT id FROM roles WHERE name = ?', $role);

			$id_role or die ("Role not found: $role\n");

			my $id_user = 
			
				sql_select_scalar ('SELECT id FROM users WHERE peer_id = ? AND peer_server = ?', $user -> {id}, $peer_server) ||
				
				sql_do_insert ('users', {
					fake        => -128,
					peer_id     => $user -> {id},
					peer_server => $peer_server,
				});
				
			sql_do ('UPDATE users SET label = ?, id_role = ?, mail = ?  WHERE id = ?', $user -> {label}, $id_role, $user -> {mail}, $id_user);
			
			while (1) {
				$local_sid = int (time * rand);
				last if 0 == sql_select_scalar ('SELECT COUNT(*) FROM sessions WHERE id = ?', $local_sid);
			}

			sql_do ("DELETE FROM sessions WHERE id_user = ?", $id_user);
			
			sql_do ("INSERT INTO sessions (id, id_user, peer_id, peer_server) VALUES (?, ?, ?, ?)", $local_sid, $id_user, $_REQUEST {sid}, $peer_server);
					
		}
		
		$_REQUEST {sid} = $local_sid;
		
	}
	
	my $session = sql_select_hash ('sessions', $_REQUEST {sid});
	
	if ($session -> {ip}) {	
		$session -> {ip}    eq $ENV {REMOTE_ADDR}          or return undef;
		$session -> {ip_fw} eq $ENV {HTTP_X_FORWARDED_FOR} or return undef;	
		ip => $ENV {REMOTE_ADDR}, 
		ip_fw => $ENV {HTTP_X_FORWARDED_FOR},	
	}
	else {
		sql_do (
			'UPDATE sessions SET ip = ?, ip_fw = ? WHERE id = ?',
			$ENV {REMOTE_ADDR},
			$ENV {HTTP_X_FORWARDED_FOR}, $_REQUEST {sid},
		);
	}

	$user ||= sql_select_hash (<<EOS, $_REQUEST {sid});
		SELECT
			users.*
			, roles.name AS role
			, sessions.id_role AS session_role
		FROM
			sessions
			, users
			, roles
		WHERE
			sessions.id_user = users.id
			AND users.id_role = roles.id
			AND sessions.id = ?
EOS

	if ($user && $user -> {id}) {
		$user -> {session_role_name} = sql_select_scalar ("SELECT name FROM sessions, roles WHERE sessions.id_role = roles.id AND sessions.id = ?", $_REQUEST {sid});
	}

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
				while (1) {
					$_REQUEST {sid} = int (time () * rand ());
					last if 0 == sql_select_scalar ('SELECT COUNT(*) FROM sessions WHERE id = ?', $_REQUEST {sid});
				}
				sql_do ("INSERT INTO sessions (id, id_user, id_role) VALUES (?, ?, ?)", $_REQUEST {sid}, $user -> {id}, $id_role);
				sql_do_refresh_sessions ();
			}

			delete $_REQUEST {role};

			$user -> {redirect} = 1;
		}
	}

	$user -> {label} ||= $user -> {name} if $user;
	
	$user -> {peer_server} = $peer_server;
		
	return $user -> {id} ? $user : undef;

}

################################################################################

sub delete_fakes {
	my ($table_name) = @_;
	$table_name ||= $_REQUEST {type};
	my @sids = (0, sql_select_col ("SELECT id FROM sessions WHERE id <> ?", $_REQUEST {sid}));	
	my $sids = join ', ', @sids;

	if ($conf -> {core_recycle_ids}) {
		$__last_insert_id = sql_select_scalar ("SELECT MIN(id) FROM $table_name WHERE fake NOT IN ($sids) AND fake > 0 ORDER BY id");
		sql_do ("DELETE FROM $table_name WHERE id = ?", $__last_insert_id);
		sql_do ("UPDATE $table_name SET fake = ? WHERE id = ?", $_REQUEST {sid}, $__last_insert_id);
	}
	else {
		sql_do ("DELETE FROM $table_name WHERE fake NOT IN ($sids) AND fake > 0");
	}
	
	
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

sub esc {

	my ($options) = @_;
	
	$options -> {kind} = 'js';

	redirect (esc_href (), $options);

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

#	if ($options -> {kind} eq 'internal') {
#		$r -> internal_redirect ($url);
#		$_REQUEST {__response_sent} = 1;
#		return;
#	}

	if ($options -> {kind} eq 'http' || $options -> {kind} eq 'internal') {
	
		$r -> status ($options -> {status} || 302);
			
		$r -> header_out ('Location' => $url);
		$r -> send_http_header;
		$_REQUEST {__response_sent} = 1;
		return;
		
	}

	if ($options -> {kind} eq 'js') {
	
		if ($options -> {label}) {
			$options -> {before} = 'alert(' . js_escape ($options -> {label}) . '); ';
		}
	
		my $target = $options -> {target} ? "'$$options{target}'" : "(window.name == 'invisible' ? '_parent' : '_self')";


		my $static_salt = $Zanas_VERSION_NAME;
		$static_salt .= '_00000';
		if ($_REQUEST {sid}) {
			$static_salt .= $_REQUEST {sid};
		}
		else {
			$static_salt .= $$ . time ();
			$static_salt =~ s{\.}{}g;
		}

		my $root = $_REQUEST{__uri};
				
		if ($_REQUEST {__x}) {
								
			out_html ({}, XML::Simple::XMLout ({
				url   => $url,
			}, 
				RootName => 'redirect',
				XMLDecl  => '<?xml version="1.0" encoding="windows-1251"?>',
			));
					
		}
		elsif ($_REQUEST {__d}) {
			out_html ({}, Dumper ({redirect => {url   => $url}}));
		}
		else {

			out_html ({}, <<EOH);
<html>
	<head>
		<script src="${root}navigation_${static_salt}.js">
		</script>
	</head>
	<body onLoad="$$options{before}; nope ('$url&salt=' + Math.random (), $target)">
	</body>
</html>
EOH

		}
		

		$_REQUEST {__response_sent} = 1;
		return;
		
	}
	
}

################################################################################

sub log_action_start {

	our $__log_id = $_REQUEST {id};
	our $__log_user = $_USER -> {id};
	
	$_REQUEST {error} = substr ($_REQUEST {error}, 0, 255);
	
	$_REQUEST {_id_log} = sql_do_insert ('log', {
		id_user => $_USER -> {id}, 
		type => $_REQUEST {type}, 
		action => $_REQUEST {action}, 
		ip => $ENV {REMOTE_ADDR}, 
		error => $_REQUEST {error}, 
		ip_fw => $ENV {HTTP_X_FORWARDED_FOR},
		fake => 0,
		mac => (!$preconf -> {core_no_log_mac}) ? get_mac () : '',
	});
		
}

################################################################################

sub log_action_finish {
	
	$_REQUEST {_params} = $_REQUEST {params} = Data::Dumper -> Dump ([\%_OLD_REQUEST], ['_REQUEST']);	
	$_REQUEST {error} = substr ($_REQUEST {error}, 0, 255);
	$_REQUEST {_error}  = $_REQUEST {error};
	$_REQUEST {_id_object} = $__log_id || $_REQUEST {id} || $_OLD_REQUEST {id};
	$_REQUEST {_id_user} = $__log_user || $_USER -> {id};
	
	sql_do_update ('log', ['params', 'error', 'id_object', 'id_user'], {id => $_REQUEST {_id_log}, lobs => ['params']});
	delete $_REQUEST {params};
	delete $_REQUEST {_params};
	
}

################################################################################

sub delete_file {

	unlink $r -> document_root . $_[0];

}

################################################################################

sub select__boot {

	return {};

}

################################################################################

sub select__static_files {

	$ENV{PATH_INFO} =~ /\w+\.\w+/ or $r -> filename =~ /\w+\.\w+/ or $ENV {REQUEST_URI} =~ /\w+\.\w+/;
	
	my $filename = $&;
	
	my $v = '_' . $Zanas_VERSION_NAME;
	$filename =~ s{$v}{}i;

	$filename =~ s{_00000\d+(\.[a-z]{2,3})$}{$1};

	my $content_type = 
		$filename =~ /\.js/ ? 'application/x-javascript' :
		$filename =~ /\.css/ ? 'text/css' :
		$filename =~ /\.htm/ ? 'text/html' :
		'application/octet-stream';

	my $path = $_SKIN -> static_path ($filename);
	my $gzip = 0;

#warn ("select__static_files (1): \$path = '$path'\n");

	if (-f "$path.gz.pm" && $r -> header_in ('Accept-Encoding') =~ /gzip/) {
		$path .= '.gz';
		$path .= '.pm';
		$gzip = 1;
	}
	else {
		$path .= '.pm';
	}
	
#warn ("select__static_files (2): \$path = '$path'\n");
	
	$r -> content_type ($content_type);
	$r -> content_encoding ('gzip') if $gzip;
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
		
	$r -> status (200);

	$options -> {file_name} =~ s{.*\\}{};
		
	my $type = 
		$options -> {charset} ? $options -> {'ty' . "pe"} . '; charset=' . $options -> {charset} :
		$options -> {'ty' . "pe"};

	$type ||= 'application/octet-stream';

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

	$r -> content_type ($type);
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
	
	return undef unless ($upload and $upload -> size > 0);
	
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

	my ($item, @items) = @_;
	
#	map {$item -> {$_} = sql_select_vocabulary ($_)} @names;

	while (@items) {
	
		my $name = shift @items;
		
		my $options = {};
		
		if (@items > 0 && ref $items [0] eq HASH) {
		
			$options = shift @items;
		
		}
		
		$item -> {$name} = sql_select_vocabulary ($name, $options);
		
	}

}

################################################################################

sub set_cookie {

	if (ref $r eq 'Apache') {
		require Apache::Cookie;
		my $cookie = Apache::Cookie -> new ($r, @_);
		$cookie -> bake;
	}
	else {
		require CGI::Cookie;
		my $cookie = CGI::Cookie -> new (@_);
		$r -> header_out ('cookie', $cookie -> as_string);
	}

}

################################################################################

sub select__logout {
	sql_do ('DELETE FROM __access_log WHERE id_session = ?', $_REQUEST {sid}) if ($conf -> {core_auto_esc} == 2);
	sql_do ('DELETE FROM sessions WHERE id = ?', $_REQUEST {sid});
	redirect ('/?type=logon', {kind => 'js', label => $i18n -> {session_terminated}});
}

################################################################################

sub select__info {
	
	my $os_name = $^O;
	if ($^O eq 'MSWin32') {		
		eval {
			require Win32;
			my ($string, $major, $minor, $build, $id) = Win32::GetOSVersion ();
			my $imm = $id . $major . $minor;
			$os_name = 'MS Windows ' . (
				$imm == 140 ? '95 ' :
				$imm == 1410 ? '98 ' :
				$imm == 1490 ? 'Me ' :
				$imm == 2351 ? 'NT 3.51 ' :
				$imm == 240 ? 'NT 4.0 ' :
				$imm == 250 ? '2000 ' :
				$imm == 251 ? 'XP ' :
				"Unknown ($id . $major . $minor)"
			) . $string . " Build $build"
		};	
	} else {
		eval {
			require POSIX;
			my ($sysname, $nodename, $release, $version, $machine) = POSIX::uname();
			my $imm = $id . $major . $minor;
			$os_name = "$sysname $release [$machine]";
		};	
	}
		
	my @z = grep {/\d/} split /(\d)/, $Zanas::VERSION;
		
	require Config;

	return [
	
		{
			id    => 'OS',
			label => $os_name,
		},

		{
			
			id    => 'WEB server',
			label => $ENV {SERVER_SOFTWARE},
		
		},	

		{
			id    => 'Perl',
			label => (sprintf "%vd", $^V),
		},
	
		{
			id    => 'DBMS',
			label => $SQL_VERSION -> {string},
		},

		{
			id    => 'DB driver',
			label => 'DBD::' . $SQL_VERSION -> {driver} . ' ' . ${'DBD::' . $SQL_VERSION -> {driver}.'::VERSION'},
			path  => $INC {'DBD/' . $SQL_VERSION -> {driver} . '.pm'},
		},

		{
			id    => 'DB maintainer',
			label => 'DBIx::ModelUpdate ' . $DBIx::ModelUpdate::VERSION,
			path  => $INC {'DBIx/ModelUpdate.pm'},
		},
		
		{			
			id    => 'Parameters module',
			label => ref $apr,
		},
		
		{			
			id    => 'Engine',
			label => "Zanas $Zanas_VERSION ($Zanas_VERSION_NAME)",
			path  => $preconf -> {core_path},
		},

		{			
			id    => 'Application package',
			label => ($_PACKAGE =~ /(\w+)/),
			path  => join ',', @$PACKAGE_ROOT,
		},
				
		
#		{			
#			id    => '$preconf',
#			label => '<pre>' . Dumper ($preconf),
#		},

#		{			
#			id    => '$conf',
#			label => '<pre>' . Dumper ($conf),
#		},
		

#		map {{id => $_, label => $ENV {$_}}} sort keys %ENV

	]	

}

################################################################################

sub get_item_of__object_info {

	$_REQUEST {__read_only} = 1;

	my $item = sql_select_hash ($_REQUEST {object_type});

	$item -> {last_create} = sql_select_hash ("SELECT * FROM log WHERE type = ? AND action = 'create' AND id_object = ? ORDER BY id DESC LIMIT 1", $_REQUEST {object_type}, $_REQUEST {id});
	$item -> {last_create} -> {dt} =~ s{(\d+)\-(\d+)\-(\d+)}{$3.$2.$1};
	$item -> {last_create} -> {user} = sql_select_hash ('users', $item -> {last_create} -> {id_user}); 
	
	$item -> {last_update} = sql_select_hash ("SELECT * FROM log WHERE type = ? AND action = 'update' AND id_object = ? ORDER BY id DESC LIMIT 1", $_REQUEST {object_type}, $_REQUEST {id});
	$item -> {last_update} -> {dt} =~ s{(\d+)\-(\d+)\-(\d+)}{$3.$2.$1};
	$item -> {last_update} -> {user} = sql_select_hash ('users', $item -> {last_update} -> {id_user}); 
	
	my @references = ();
	
	foreach my $reference ( sort {$a -> {table_name} . ' ' . $a -> {name} cmp $b -> {table_name} . ' ' . $b -> {name}} @{$DB_MODEL -> {tables} -> {$_REQUEST {object_type}} -> {references}}) {

		my $where = ' WHERE fake = 0 AND ' . $reference -> {name};

		if ($reference -> {TYPE_NAME} =~ /int/) {
			$where .= " = $_REQUEST{id}";
		}
		else {
			$where .= " LIKE '\%,$_REQUEST{id},\%'";
		}
		
		my $cnt = sql_select_scalar ("SELECT COUNT(*) FROM " . $reference -> {table_name} . $where) or next;

		push @references, {
			table_name => $reference -> {table_name},
			name => $reference -> {name},
			cnt => $cnt,
		};
		
		if ($_REQUEST {table_name} eq $reference -> {table_name} && $_REQUEST {name} eq $reference -> {name}) {

			my $start = $_REQUEST {start} + 0;

			($item -> {records}, $item -> {cnt}) = sql_select_all_cnt ('SELECT * FROM ' . $reference -> {table_name} . $where . " ORDER BY id DESC LIMIT $start, 15");

		}
		
	}
	
	$item -> {references} = \@references;
		
	return $item;
	
}

################################################################################

sub get_mac {

	my ($ip) = @_;	
	$ip ||= $ENV {REMOTE_ADDR};

	my $cmd = $^O eq 'MSWin32' ? 'arp -a' : 'arp -an';
	my $arp = '';
	
	eval {$arp = lc `$cmd`};
	$arp or return '';
	
	foreach my $line (split /\n/, $arp) {

		$line =~ /\($ip\)/ or next;

		if ($line =~ /[0-9a-f]{2}\:[0-9a-f]{2}\:[0-9a-f]{2}\:[0-9a-f]{2}\:[0-9a-f]{2}\:[0-9a-f]{2}/) {
			return $&;
		}
		
	}
	
	return '';

}

################################################################################

sub fill_in {

   	$conf -> {lang} ||= 'RUS';   	

   	$conf -> {i18n} ||= {};

   	fill_in_button_presets (

   		ok => {
   			icon    => 'ok',
   			label   => 'ok',
   			hotkey  => {code => ENTER, ctrl => 1},
   			confirm => 'confirm_ok',
   		},
   		
   		cancel => {
   			icon   => 'cancel',
   			label  => 'cancel',
   			hotkey => {code => ESC},
   			confirm => confirm_esc,
   			preconfirm => 'is_dirty',
   		},

   		edit => {
   			icon   => 'edit',
   			label  => 'edit',
   			hotkey => {code => F4},
   		},

   		choose => {
   			icon   => 'choose',
   			label  => 'choose',
   			hotkey => {code => ENTER, ctrl => 1},
   		},

   		'close' => {
   			icon   => 'ok',
   			label  => 'close',
   			hotkey => {code => ESC},
   		},
   		
   		back => {
			icon => 'back', 
			label => 'back', 
			hotkey => {code => F11 },
		},

   		next => {
			icon => 'next',
			label => 'next',
   			hotkey => {code => F12},
		},

   		delete => {
   			icon    => 'delete',
   			label   => 'delete',
   			hotkey  => {code => DEL, ctrl => 1},
   		},

   	);
   	
   	fill_in_i18n ('RUS', {
   		_charset                 => 'windows-1251',
   		_calendar_lang           => 'ru',
   		_format_d		 => '%d.%m.%Y',
   		_format_dt		 => '%d.%m.%Y  %k:%M',
		Exit                     => 'Âûõîä',
		toolbar_pager_empty_list => 'ñïèñîê ïóñò',		
		toolbar_pager_of         => ' èç ',
		confirm_ok               => 'Ñîõðàíèòü äàííûå?',
		confirm_esc              => 'Óéòè áåç ñîõðàíåíèÿ äàííûõ?',
		ok                       => 'ïðèìåíèòü', 
		cancel                   => 'âåðíóòüñÿ', 
		choose                   => 'âûáðàòü', 
		delete                   => 'óäàëèòü', 
		edit                     => 'ðåäàêòèðîâàòü', 
		'close'                  => 'çàêðûòü',
		back                     => '&lt;&lt; íàçàä',
		'next'                   => 'ïðîäîëæèòü &gt;&gt;',		
		User                     => 'Ïîëüçîâàòåëü',
		not_logged_in		 => 'íå îïðåäåë¸í',
		Print                    => 'Ïå÷àòü',
		F1                       => 'F1: Ñïðàâêà',
		Select                   => 'Âûáðàòü',
		yes                      => 'Äà', 
		no                       => 'Íåò', 
		confirm_open_vocabulary  => 'Îòêðûòü îêíî ðåäàêòèðîâàíèÿ ñïðàâî÷íèêà?',
		confirm_close_vocabulary => 'Âû âûáðàëè',
		session_terminated       => 'Ñåññèÿ çàâåðøåíà',
		save_or_cancel           => 'Ïîæàëóéñòà, ñíà÷àëà ñîõðàíèòå äàííûå (Ctrl-Enter) èëè îòìåíèòå ââîä (Esc)',
		infty                    => '&infin;', 
		voc                      => ' ñïðàâî÷íèê...',
   	});
   	
   	fill_in_i18n ('ENG', {
   		_charset                 => 'windows-1252',
   		_calendar_lang           => 'en',
   		_format_d		 => '%d.%m.%Y',
   		_format_dt		 => '%d.%m.%Y  %k:%M',
		Exit                     => 'Exit',
		toolbar_pager_empty_list => 'empty list',		
		toolbar_pager_of         => ' of ',
		confirm_ok               => 'Commit changes?',
		confirm_esc              => 'Cancel changes?',
		ok                       => 'ok', 
		cancel                   => 'cancel', 
		choose                   => 'choose', 
		delete                   => 'delete', 
		edit                     => 'edit', 
		'close'                  => 'close',
		back                     => '&lt;&lt; back',
		'next'                   => 'next &gt;&gt;',
		User                     => 'User',
		not_logged_in		 => 'not logged in',
		Print                    => 'Print',
		F1                       => 'F1: Help',
		Select                   => 'Select',
		yes                      => 'Yes', 
		no                       => 'No', 
		confirm_open_vocabulary  => 'Open the vocabulary window?',
		confirm_close_vocabulary => 'Your choice is',
		session_terminated       => 'Logged off',
		save_or_cancel           => 'Please save your data (Ctrl-Enter) or cancel pending input (Esc)',
		infty                    => '&infin;', 
		voc                      => ' vocabulary...',
   	});
	
   	fill_in_i18n ('FRE', {
   		_charset                 => 'windows-1252',
   		_calendar_lang           => 'fr',
   		_format_d		 => '%d/%m/%Y',
   		_format_dt		 => '%d/%m/%Y  %k:%M',
		Exit                     => 'Déconnexion',
		toolbar_pager_empty_list => 'liste vide',
		toolbar_pager_of         => ' de ',
		confirm_ok               => 'Sauver des changements?',
		confirm_esc              => 'Quitter sans sauvegarde?',
		ok                       => 'appliquer', 
		cancel                   => 'annuler', 
		choose                   => 'choisir', 
		delete                   => 'supprimer', 
		edit                     => 'rediger', 
		'close'                  => 'fermer',
		back                     => '&lt;&lt; pas précédent',
		'next'                   => 'suite &gt;&gt;',
		User                     => 'Utilisateur',
		not_logged_in		 => 'indéfini',
		Print                    => 'Imprimer',
		F1                       => 'F1: Aide',
		Select                   => 'Sélection',
		yes                      => 'Oui', 
		no                       => 'Non', 
		confirm_open_vocabulary  => 'Ouvrir le vocabulaire?',
		confirm_close_vocabulary => 'Vous avez choisi',
		session_terminated       => 'Déconnecté',
		save_or_cancel           => "Veuillez sauvegarder vos données (Ctrl-Enter) ou bien annuler l\\'opération (Esc)",
		infty                    => '&infin;', 
		voc                      => ' vocabulaire...',
   	}); 
   	
   	$conf -> {__filled_in} = 1;

}

################################################################################

sub fill_in_i18n {

	my ($lang, $entries) = @_;
   	$conf -> {i18n} ||= {};
   	$conf -> {i18n} -> {$lang} ||= {};
	return if $conf -> {i18n} -> {$lang} -> {_is_filled};
	
	while (my ($key, $value) = each %$entries) {
		$conf -> {i18n} -> {$lang} -> {$key} ||= $value;
	}
	
	$conf -> {i18n} -> {$lang} -> {_page_title} ||= $conf -> {page_title};

	$conf -> {i18n} -> {$lang} -> {_is_filled} = 1;

};

################################################################################

sub fill_in_button_presets {

	my %entries = @_;
   	$conf -> {button_presets} ||= {};
	return if $conf -> {button_presets} -> {_is_filled};
	
	while (my ($key, $value) = each %entries) {
		$conf -> {button_presets} -> {$key} ||= $value;
	}
	
	$conf -> {button_presets} -> {_is_filled} = 1;

};

################################################################################

sub get_ids {

	my ($name) = @_;
	
	$name .= '_';
	
	my @ids = ();
	
	while (my ($key, $value) = each %_REQUEST) {
		$key =~ /$name(\d+)/ or next;
		push @ids, $1;
	}
	
	return @ids;	

}

################################################################################

sub is_recording {

	return $preconf -> {core_recording} || $_REQUEST {sid} =~ /^0[1-9]/;
	
}

################################################################################

sub get_page {}

1;