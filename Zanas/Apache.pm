no warnings;

use Number::Format;
use HTTP::Date;
use URI::Escape;

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

#################################################################################

sub handler {

	our $_PACKAGE = __PACKAGE__ . '::';
	
	my  $use_cgi = $ENV {SCRIPT_NAME} =~ m{index\.pl} || $ENV {GATEWAY_INTERFACE} =~ m{^CGI/} || $conf -> {use_cgi} || $preconf -> {use_cgi} || !$INC{'Apache/Request.pm'};
	
	our $r   = $use_cgi ? new Zanas::Request () : $_[0];
	our $apr = $use_cgi ? $r : Apache::Request -> new ($r);
		
	my $parms = $apr -> parms;
	our %_REQUEST = %{$parms};
	
	$_REQUEST {type} =~ s/_for_.*//;
	$_REQUEST {__uri} = $r -> uri;
	$_REQUEST {__uri} =~ s{/cgi-bin/.*}{/};
	$_REQUEST {__uri} =~ s{\/\w+\.\w+$}{};
	
	$number_format or our $number_format = Number::Format -> new (%{$conf -> {number_format}});
	
   	sql_reconnect ();

	require_fresh ($_PACKAGE . '::Config');

   	$conf -> {dbf_dsn} and our $dbf = DBI -> connect ($conf -> {dbf_dsn}, {RaiseError => 1});
   	
   	$conf -> {lang} ||= 'RUS';
   	
   	$conf -> {i18n} ||= {};
   	
   	fill_in_i18n ('RUS', {
   		_charset                 => 'windows-1251',
		Exit                     => 'Выход',
		toolbar_pager_empty_list => 'список пуст',		
		toolbar_pager_of         => ' из ',
		confirm_ok               => 'Сохранить данные?',
		confirm_esc              => 'Уйти без сохранения данных?',
		ok                       => 'применить', 
		cancel                   => 'вернуться', 
		'close'                  => 'закрыть',
		back                     => '&lt;&lt; назад',
		'next'                   => 'продолжить &gt;&gt;',		
		User                     => 'Пользователь',
		not_logged_in		 => 'не определён',
		Print                    => 'Печать',
		F1                       => 'F1: Справка',
		Select                   => 'Выбрать',
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
		'close'                  => 'close',
		back                     => '&lt;&lt; back',
		'next'                   => 'next &gt;&gt;',
		User                     => 'User',
		not_logged_in		 => 'not logged in',
		Print                    => 'Print',
		F1                       => 'F1: Help',
		Select                   => 'Select',
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
		'close'                  => 'fermer',
		back                     => '&lt;&lt; pas prйcйdent',
		'next'                   => 'suite &gt;&gt;',
		User                     => 'Utilisateur',
		not_logged_in		 => 'indйfini',
		Print                    => 'Imprimer',
		F1                       => 'F1: Aide',
		Select                   => 'Sйlection',
   	});

#print STDERR Dumper (\%ENV);
#	$_REQUEST {type} = '_static_files' if $r -> filename =~ /\w\.\w/;
#	$_REQUEST {type} = '_static_files' if ($ENV{PATH_INFO} =~ /\w\.\w/ || $r -> filename =~ /\w\.\w/);
	$_REQUEST {type} = '_static_files' if (($ENV{PATH_INFO} =~ /\w\.\w/ && $ENV{PATH_INFO} ne '/index.html') || $r -> filename =~ /\w\.\w/);

	$conf -> {include_js}  ||= ['js'];
   	
   	$_REQUEST {__include_js} = [];
   	push @{$_REQUEST {__include_js}}, @{$conf -> {include_js}};

   	$_REQUEST {__include_css} = [];
   	push @{$_REQUEST {__include_css}}, @{$conf -> {include_css}};
   	
	if ($_REQUEST {keepalive}) {
		my $timeout = 60 * $conf -> {session_timeout} - 1;
		keep_alive ($_REQUEST {keepalive});
		$r -> content_type ('text/html');
		$r -> send_http_header;
		print <<EOH;
			<html><head>
				<META HTTP-EQUIV=Refresh CONTENT="$timeout; URL=$_REQUEST {__uri}?keepalive=$_REQUEST{keepalive}">
			</head></html>			
EOH
		return;
	}	
   	
	my $action = $_REQUEST {action};
		
	our $_USER = get_user ();
	
	$_REQUEST {lang} ||= $_USER -> {lang} if $_USER;
	
	$_REQUEST {lang} ||= $preconf -> {lang} || $conf -> {lang}; # According to NISO Z39.53
	
	our $i18n = $conf -> {i18n} -> {$_REQUEST {lang}};
	
	require_fresh ($_PACKAGE . '::Calendar');
	
	eval "our \$_CALENDAR = new ${_PACKAGE}Calendar (\\\%_REQUEST)";
	
	if ((!$_USER and $_REQUEST {type} ne 'logon' and $_REQUEST {type} ne '_static_files')) {

		delete $_REQUEST {sid};
		delete $_REQUEST {salt};
		delete $_REQUEST {_salt};
		delete $_REQUEST {__include_js};
		delete $_REQUEST {__include_css};

		redirect ('/?type=logon&redirect_params=' . uri_escape (Dumper (\%_REQUEST)));
		
	}
	
	elsif (exists ($_USER -> {redirect})) {
		
		redirect (create_url ());
		
	}

	elsif ($_REQUEST {keepalive}) {
	
		redirect ("/\?type=logon&_frame=$_REQUEST{_frame}");
		
	}
	else {
			
		require_fresh ("${_PACKAGE}Content::menu");
		require_fresh ("${_PACKAGE}Content::page");

		$page = get_page ();
	
		unless ($page -> {type} =~ /^_/) {
			require_fresh ("${_PACKAGE}Content::$$page{type}");
			require_fresh ("${_PACKAGE}Presentation::$$page{type}");
		};
		
		if ($action) {
		
			my $sub_name = "validate_${action}_$$page{type}";		
			
			my $error_code = call_for_role ($sub_name);
			
			if ($error_code) {		
				my $error_message_template = $error_messages -> {"${action}_$$page{type}_${error_code}"} || $error_code;
				$_REQUEST {error} = interpolate ($error_message_template);
			}
			
			if ($_REQUEST {error}) {
				out_html ({}, draw_page ($page));
			}
			else {
			
				delete $_REQUEST {__response_sent};

				eval {	
					delete_fakes () if $action eq 'create';
					call_for_role ("do_${action}_$$page{type}");
					
					if (($action eq 'execute') and ($$page{type} eq 'logon') and $_REQUEST {redirect_params}) {
					
						my $VAR1;

						eval $_REQUEST {redirect_params};
						
						while (my ($key, $value) = each %$VAR1) {
							$_REQUEST {$key} = $value;
						}					
						
					} elsif ($conf -> {core_cache_html}) {
						sql_do ("DELETE FROM cache_html");
						my $cache_path = $r -> document_root . '/cache/*';
						eval {`rm -rf $cache_path`};
					}
					
				};	
				
				if ($@) {
					$_REQUEST {error} = $@;
					out_html ({}, draw_page ($page));
				}
				else {
				
					$_REQUEST {__response_sent} or redirect ({action => '', redirect_params => ''}, {kind => 'js'});
				
#					unless ($_REQUEST {__response_sent}) {
				
#						my $url = create_url (action => '', redirect_params => '');
#						out_html ({}, qq {<body onLoad="window.open ('$url&salt=' + Math.random (), '_parent', 'location=0,menubar=0,status=0,toolbar=0')"></body>});
				
#					}
				
				}
				
			}
			
			log_action ($_USER -> {id}, $$page{type}, $action, $_REQUEST {error}, $_REQUEST {id});

		}
		else {

			out_html ({}, draw_page ($page));

		}   

	}
   
   	$db -> disconnect;
	
	return OK;

}

################################################################################

sub out_html {

	my ($options, $html) = @_;
		
	$html or return;
	
	if ($_REQUEST {dbf}) {
		redirect ("/$html");
	}
	
	if ($_REQUEST {xls}) {
	
		my $fn_local = '/i/xls/' . time . "$$.xls";
		my $fn = $r -> document_root . $fn_local;
		open (O, ">$fn") or die "Can't write to $fn: $!";
		print O $html;
		close (O);
		
		download_file ({
			path => $fn_local,
			file_name => "file.xls",
		});
		
		unlink $fn;
		
	}	
	else {
	
		if ($conf -> {core_sweep_spaces}) {
			$html =~ s{^\s+}{}gsm; 
			$html =~ s{[ \t]+}{ }g;
		}

		$_REQUEST {__content_type} ||= 'text/html; charset=' . $i18n -> {_charset};

		$r -> content_type ($_REQUEST {__content_type});
		$r -> header_out ('X-Powered-By' => 'Zanas/' . $Zanas::VERSION);

		if (($conf -> {core_gzip} or $preconf -> {core_gzip}) && ($r -> header_in ('Accept-Encoding') =~ /gzip/)) {
			$r -> content_encoding ('gzip');
			unless ($_REQUEST {__is_gzipped}) {
				$html = Compress::Zlib::memGzip ($html);
			}
		}		

		$r -> header_out ('Content-Length' => length $html);
#		$r -> header_out ('Set-Cookie' => "sid=$_REQUEST{sid};path=/;") if $_REQUEST{sid};
		
		$r -> send_http_header;		
		$r -> header_only or print $html;
		
	}	

}

#################################################################################

sub pub_handler {

	our $_PACKAGE = __PACKAGE__ . '::';

	our $r   = $use_cgi ? new Zanas::Request () : $_[0];
	our $apr = $use_cgi ? $r : Apache::Request -> new ($r);

	my $parms = $apr -> parms;
	our %_REQUEST = %{$parms};		
	$_REQUEST {__uri} = $r -> uri;
	$_REQUEST {__uri} =~ s{\/\w+\.\w+$}{};

	$_REQUEST {__uri_chomped} = $_REQUEST {__uri};
	$_REQUEST {__uri_chomped} =~ s{/$}{};

	our %_COOKIES = Apache::Cookie -> fetch;
	my $c = $_COOKIES {psid};
	$_REQUEST {sid} = $c -> value if $c;
	
	$_REQUEST {__content_type} ||= 'text/html; charset=' . ($conf -> {_charset} || 'windows-1251');

	sql_reconnect ();

	eval {
		require_fresh ("${_PACKAGE}Content::pub_users");
		our $_USER = get_public_user ();
	};
	
	my $cache_key = $_REQUEST {__uri_chomped} . '/' . $r -> args;
	my $cache_fn  = $r -> document_root . '/cache/' . uri_escape ($cache_key, "/.") . '.html';
	
	if ($conf -> {core_cache_html} && !$_USER -> {id}) {
		
		my $time = sql_select_scalar ("SELECT UNIX_TIMESTAMP(ts) FROM cache_html WHERE uri = ?", $cache_key);
		
		my $ims = $r -> header_in ("If-Modified-Since");
		$ims =~ s{\;.*}{};
		
		if ($ims && $time && (str2time ($ims) >= $time)) {
			$r -> status (304);
			$r -> send_http_header;
			$_REQUEST {__response_sent} = 1;
			return OK;
		}		
		
		$r -> content_type ($_REQUEST {__content_type});
		$r -> header_out ('Last-Modified' => time2str ($time));
		$r -> header_out ('Cache-Control' => 'max-age=0');
		$r -> header_out ('X-Powered-By' => 'Zanas/' . $Zanas::VERSION);

		if ($r -> header_only && $time) {
			$r -> send_http_header ();
			$_REQUEST {__response_sent} = 1;
			return OK;
		}

		my $use_gzip = ($conf -> {core_gzip} or $preconf -> {core_gzip}) && ($r -> header_in ('Accept-Encoding') =~ /gzip/);

#		my $field = $use_gzip ? 'gzipped' : 'html';		
#		my $html = sql_select_scalar ("SELECT $field FROM cache_html WHERE uri = ?", $cache_key);

		my $cache_fn_to_read = $cache_fn;
		if ($use_gzip) {
			$cache_fn_to_read .= '.gz';
			$r -> content_encoding ('gzip');
		}
		
		if (-f $cache_fn_to_read) {
			$r -> content_type ($_REQUEST {__content_type});
			$r -> header_out ('Content-Length' => -s $cache_fn_to_read);
			$r -> header_out ('Last-Modified'  => time2str ($time));
			$r -> header_out ('Cache-Control'  => 'max-age=0');
			$r -> header_out ('X-Powered-By'   => 'Zanas/' . $Zanas::VERSION);
			$r -> send_http_header ();

			open (F, $cache_fn_to_read) or die ("Can't open $cache_fn_to_read: $!\n");
			$r -> send_fd (F);
			close (F);
			
			$_REQUEST {__response_sent} = 1;			
			return OK;
		}
		
#		if ($html) {
#			$_REQUEST {__is_gzipped} = $use_gzip;
#			out_html ({}, $html);
#			return OK;
#		}
	
	}
   	
	require_fresh ("${_PACKAGE}Config");
	require_fresh ("${_PACKAGE}Content::pub_page");
	
	our $_PAGE = select_pub_page;
	return 0 if $_REQUEST {__response_sent};
	
	my $type   = $_PAGE -> {type};
	my $id     = $_PAGE -> {id};
	my $action = $_REQUEST {action};
	
	if ($action) {

		require_fresh ("${_PACKAGE}Content::${type}");
		
		my $error_code = uri_escape (call_for_role ("validate_${action}_${type}"));
		
		if ($error_code) {
			redirect ("?error=$error_code", {kind => 'http'});
		}
		else {
			call_for_role ("do_${action}_${type}");
			$_REQUEST {__response_sent} or redirect ({action => ''}, {kind => 'http'});
		}
		
	}
	else {	

		require_fresh ("${_PACKAGE}Presentation::pub_page");

		require_fresh ("${_PACKAGE}Content::$type");
		require_fresh ("${_PACKAGE}Presentation::$type");
		
		my ($selector, $renderrer) =  $id ? 
			("get_item_of_$type", "draw_item_of_$type") :
			("select_$type", "draw_$type"); 
		
		
		eval {
			my $content = &$selector ();
			$_PAGE -> {body} = &$renderrer ($content);
		};
		print STDERR $@ if $@;

		my $html = draw_pub_page ();

		if ($conf -> {core_cache_html}) {
			
			my $gzipped = (($conf -> {core_gzip} or $preconf -> {core_gzip})) ? Compress::Zlib::memGzip ($html) : '';		
#			sql_do ('REPLACE INTO cache_html (uri, html, gzipped) VALUES (?, ?, ?)', $cache_key, $html, $gzipped);
			sql_do ('REPLACE INTO cache_html (uri) VALUES (?)', $cache_key);
			
			open (F, ">$cache_fn") or die ("Can't write to $cache_fn: $!\n");
			print F $html;
			close (F);
			
			if ($gzipped) {
				open (F, ">$cache_fn.gz") or die ("Can't write to $cache_fn.gz: $!\n");
				binmode (F);
				print F $gzipped;
				close (F);
			}
						
		}
		
		$r -> header_out ('Last-Modified' => time2str (time));
		$r -> header_out ('Cache-Control' => 'max-age=0');

		out_html ({}, $html);
		
	}

   	$db -> disconnect;
	
	return OK;

}


1;