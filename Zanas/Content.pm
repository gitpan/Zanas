no warnings;

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
	
#print STDERR "\nrequire_fresh: \$module_name = $module_name\n";

	my $file_name = $module_name;
	$file_name =~ s{(::)+}{\/}g;

	my $inc_key = $file_name . '.pm';

#print STDERR "require_fresh: \$inc_key = $inc_key\n";

	$file_name =~ s{^(.+?)\/}{\/};
	
	my $found = 0;
	foreach my $path (@$PACKAGE_ROOT) {
		my $local_file_name = $path . $file_name . '.pm';
		-f $local_file_name or next;
		$file_name = $local_file_name;
		$found = 1;
		last;
	}

	$found or return "File not found: $file_name\n";
	
#	$file_name = $PACKAGE_ROOT . $file_name . '.pm';

#print STDERR "require_fresh: \$file_name = $file_name\n";
	
#	-f $file_name or return "File not found: $file_name\n";
		
	my $need_refresh = $conf -> {core_spy_modules} || $preconf -> {core_spy_modules} || !$INC {$inc_key};

#print STDERR "require_fresh: \$need_refresh = $need_refresh (1)\n";
	
	if ($need_refresh) {
		my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $last_modified, $ctime, $blksize, $blocks) = stat ($file_name);
		my $last_load = $INC_FRESH {$module_name} + 0;
		$need_refresh &&= $last_load < $last_modified;
	}

#print STDERR "require_fresh: \$need_refresh = $need_refresh (2)\n";
		
	if ($need_refresh) {
	
#print STDERR "require_fresh: \$_OLD_PACKAGE = $_OLD_PACKAGE\n";

		if ($_OLD_PACKAGE) {
			open (S, $file_name);
			my $src = join '', (<S>);
			close (S);
			$src =~ s{$_OLD_PACKAGE}{$_NEW_PACKAGE}g;

#print STDERR "require_fresh: \$src = $src\n";

			eval $src;
		}
		else {
			do $file_name;
		}
	
		$INC_FRESH {$module_name} = time;
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

sub call_for_role {

	my $sub_name = shift;
	my $time = $preconf -> {core_debug_profiling} == 1 ? time : undef;
	my $role = $_USER ? $_USER -> {role} : '';	
	my $full_sub_name = $sub_name . '_for_' . $role;
	my $name_to_call = 
		exists $$_PACKAGE {$full_sub_name} ? $full_sub_name : 
		exists $$_PACKAGE {$sub_name} ? $sub_name : 
		undef;
	
	if ($name_to_call) {
		my $result = &$name_to_call (@_);
		print STDERR "Profiling [$$] " . 1000 * (time - $time) . " ms $name_to_call\n" if $preconf -> {core_debug_profiling} == 1;
		return $result;
	}
	else {
		$sub_name =~ '^validate_' or print STDERR "call_for_role: callback procedure not found: \$sub_name = $sub_name, \$role = $role \n";
	}

	return $name_to_call ? &$name_to_call (@_) : undef;
		
}

################################################################################

sub get_user {

	return if $_REQUEST {type} eq '_static_files';
		
	sql_do_refresh_sessions ();

#	sql_do ("DELETE FROM sessions WHERE ts < now() - INTERVAL ? MINUTE", $conf -> {session_timeout});
#	sql_do ("UPDATE sessions SET ts = NULL WHERE id = ? ", $_REQUEST {sid});

#	my $user = sql_select_hash (<<EOS, $_REQUEST {sid});
#		SELECT
#			users.*
#			, roles.name AS role
#			, sessions.id_role AS session_role
#			, session_roles.name AS session_role_name
#		FROM
#			sessions
#			INNER JOIN users ON sessions.id_user = users.id
#			INNER JOIN roles ON users.id_role = roles.id
#			LEFT JOIN roles as session_roles ON sessions.id_role = session_roles.id
#		WHERE
#			sessions.id = ?
#EOS

	my $user = undef;
	
	if ($_REQUEST {__login}) {
		$user = sql_select_hash ('SELECT * FROM users WHERE login = ? AND password = PASSWORD(?)', $_REQUEST {__login}, $_REQUEST {__password});
		$user -> {id} or undef $user;
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
		
	return $user -> {id} ? $user : undef;

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
	
#	$url =~ m{^http://} or $url = 'http://' . $ENV{HTTP_HOST} . $url;
#	my $http_host = $ENV {HTTP_X_FORWARDED_HOST} || $preconf -> {http_host};
#	if ($http_host) {
#		substr ($url, index ($url, $ENV{HTTP_HOST}), length ($ENV{HTTP_HOST})) = $http_host;
#	}
	
	if ($options -> {kind} eq 'internal') {
		$r -> internal_redirect ($url);
		$_REQUEST {__response_sent} = 1;
		return;
	}

	if ($options -> {kind} eq 'http') {		
	
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
	
#		$options -> {target} ||= '_parent';
#		out_html ({}, qq {<body onLoad="$$options{before}; window.open ('$url&_salt=' + Math.random (), (window.name == 'application_frame' ? '_self' : '$$options{target}'))"></body>});

		my $target = $options -> {target} ? "'$$options{target}'" : "(window.name == 'invisible' ? '_parent' : '_self')";

		out_html ({}, qq {<body onLoad="$$options{before}; window.open ('$url&_salt=' + Math.random (), $target)"></body>});
		$_REQUEST {__response_sent} = 1;
		return;
		
	}
	
}

################################################################################

sub log_action_start {

	our $__log_id = $_REQUEST {id};
	our $__log_user = $_USER -> {id};
	
	$_REQUEST {_id_log} = sql_do_insert ('log', {
		id_user => $_USER -> {id}, 
		type => $_REQUEST {type}, 
		action => $_REQUEST {action}, 
		ip => $ENV {REMOTE_ADDR}, 
		error => $_REQUEST {error}, 
		ip_fw => $ENV {HTTP_X_FORWARDED_FOR},
		fake => 0,
	});
		
}

################################################################################

sub log_action_finish {
	
	$_REQUEST {_params} = $_REQUEST {params} = Data::Dumper -> Dump ([\%_OLD_REQUEST], ['_REQUEST']);	
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

sub select__static_files {

	$ENV{PATH_INFO} =~ /\w+\.\w+/ or $r -> filename =~ /\w+\.\w+/ or $ENV {REQUEST_URI} =~ /\w+\.\w+/;
	
	my $filename = $&;
	
	my $content_type = 
		$filename =~ /\.js/ ? 'application/x-javascript' :
		$filename =~ /\.css/ ? 'text/css' :
		$filename =~ /\.htm/ ? 'text/html' :
		'application/octet-stream';

	my $path = $STATIC_ROOT . $filename . '.gz.pm';
	(-f $path and $r -> header_in ('Accept-Encoding') =~ /gzip/) or $path = $STATIC_ROOT . $filename . '.pm';
	
	$r -> content_type ($content_type);
	$r -> content_encoding ('gzip') if $path =~ /\.gz/;
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
	sql_do ('DELETE FROM sessions WHERE id = ?', $_REQUEST {sid});	
	redirect ('/?type=logon', {kind => 'http'});
}

################################################################################

sub get_version_name {

	unless ($Zanas::VERSION_NAME) {

		my @z = grep {/\d/} split /(\d)/, $Zanas::VERSION;

		my $word = '';
		my @c = qw(b d f g k l m n p q r s t v x z);
		my @v = qw(a e i o u);
		my $n = $Zanas::VERSION * 10000;
		$n = ($n * 1973 + 112) % 11111;
		$word .= uc $c [$n % @c];
		$n = ($n * 1973 + 112) % 11111;
		$word .= $v [$n % @v];
		$n = ($n * 1973 + 112) % 11111;
		$word .= $c [$n % @c];
		$n = ($n * 1973 + 112) % 11111;
		$word .= $v [$n % @v];
		$n = ($n * 1973 + 112) % 11111;
		$word .= $c [$n % @c];
		
		$Zanas::VERSION_NAME = $word;

	}
		
	return $Zanas::VERSION_NAME;

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
	
	my $word = get_version_name ();
	
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
			label => "Zanas $Zanas::VERSION ($word)",
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
			hotkey => { code => ESC },
		},

   		next => {
			icon => 'next',
			label => 'next',
   			hotkey => {code => ENTER, ctrl => 1},
		},

   	);
   	
   	fill_in_i18n ('RUS', {
   		_charset                 => 'windows-1251',
		Exit                     => 'Выход',
		toolbar_pager_empty_list => 'список пуст',		
		toolbar_pager_of         => ' из ',
		confirm_ok               => 'Сохранить данные?',
		confirm_esc              => 'Уйти без сохранения данных?',
		ok                       => 'применить', 
		cancel                   => 'вернуться', 
		choose                   => 'выбрать', 
		edit                     => 'редактировать', 
		'close'                  => 'закрыть',
		back                     => '&lt;&lt; назад',
		'next'                   => 'продолжить &gt;&gt;',		
		User                     => 'Пользователь',
		not_logged_in		 => 'не определён',
		Print                    => 'Печать',
		F1                       => 'F1: Справка',
		Select                   => 'Выбрать',
		yes                      => 'Да', 
		no                       => 'Нет', 
		confirm_open_vocabulary  => 'Открыть окно редактирования справочника?',
		confirm_close_vocabulary => 'Вы выбрали',
   	});
   	
   	fill_in_i18n ('ENG', {
   		_charset                 => 'windows-1252',
		Exit                     => 'Exit',
		toolbar_pager_empty_list => 'empty list',		
		toolbar_pager_of         => ' of ',
		confirm_ok               => 'Commit changes?',
		confirm_esc              => 'Cancel changes?',
		ok                       => 'ok', 
		cancel                   => 'cancel', 
		choose                   => 'choose', 
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
   	});
	
   	fill_in_i18n ('FRE', {
   		_charset                 => 'windows-1252',
		Exit                     => 'Quitter',
		toolbar_pager_empty_list => 'liste vide',
		toolbar_pager_of         => ' de ',
		confirm_ok               => 'Sauver des changements?',
		confirm_esc              => 'Quitter sans sauvegarde?',
		ok                       => 'appliquer', 
		cancel                   => 'annuler', 
		choose                   => 'choisir', 
		edit                     => 'rediger', 
		'close'                  => 'fermer',
		back                     => '&lt;&lt; pas prйcйdent',
		'next'                   => 'suite &gt;&gt;',
		User                     => 'Utilisateur',
		not_logged_in		 => 'indйfini',
		Print                    => 'Imprimer',
		F1                       => 'F1: Aide',
		Select                   => 'Sйlection',
		yes                      => 'Oui', 
		no                       => 'Non', 
		confirm_open_vocabulary  => 'Ouvrir le vocabulaire?',
		confirm_close_vocabulary => 'Vous avez choisi',
   	});   	

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

1;