no warnings;

#################################################################################

sub get_request {

	my $http_host = $ENV {HTTP_X_FORWARDED_HOST} || $self -> {preconf} -> {http_host};
	if ($http_host) {
		$ENV {HTTP_HOST} = $ENV {HTTP_X_FORWARDED_HOST};
	}

	if ($connection) {
		our $r   = new Zanas::InternalRequest ($connection, $request);
		our $apr = $r;
		return;
	}
	else {
	
		our $use_cgi = $ENV {SCRIPT_NAME} =~ m{index\.pl} || $ENV {GATEWAY_INTERFACE} =~ m{^CGI/} || $conf -> {use_cgi} || $preconf -> {use_cgi} || !$INC{'Apache/Request.pm'};

		our $r   = $use_cgi ? new Zanas::Request ($preconf, $conf) : $_[0];
		our $apr = $use_cgi ? $r : Apache::Request -> new ($r);
		
	}

	if (ref $apr eq 'Apache::Request') {
		require Apache::Cookie;
		our %_COOKIES = Apache::Cookie -> fetch;
	}
	else {
		require CGI;
		require CGI::Cookie;
		our %_COOKIES = CGI::Cookie -> fetch;
	}

}


#################################################################################

sub handler {

	$_PACKAGE ||= __PACKAGE__ . '::';
		
	get_request (@_);

	my $parms = $apr -> parms;
	undef %_REQUEST;
	our %_REQUEST = %{$parms};
	
	delete $_REQUEST {__x} if $preconf -> {core_no_xml};
	
	$_REQUEST {__no_navigation} ||= $_REQUEST {select};
		
	$_REQUEST {type} =~ s/_for_.*//;
	$_REQUEST {__uri} = $r -> uri;
	$_REQUEST {__uri} =~ s{/cgi-bin/.*}{/};
	$_REQUEST {__uri} =~ s{\/\w+\.\w+$}{};
	$_REQUEST {__uri} =~ s{\?.*}{};
	$_REQUEST {__uri} =~ s{^/+}{/};
	$_REQUEST {__uri} =~ s{\&salt\=[\d\.]+}{}gsm;
	
	our $_SKIN = 'Zanas::Presentation::Skins::' . get_skin_name ();	
	eval "require $_SKIN";
	$_SKIN -> {options} ||= $_SKIN -> options;
	*{$_SKIN . '::_REQUEST'} = *{$_PACKAGE . '_REQUEST'};
	*{$_SKIN . '::_USER'}    = *{$_PACKAGE . '_USER'};
	*{$_SKIN . '::Zanas_VERSION_NAME'}    = *{$_PACKAGE . 'Zanas_VERSION_NAME'};
	*{$_SKIN . '::SQL_VERSION'}    = *{$_PACKAGE . 'SQL_VERSION'};
	*{$_SKIN . '::conf'    } = *{$_PACKAGE . 'conf'};
	*{$_SKIN . '::preconf' } = *{$_PACKAGE . 'preconf'};
	*{$_SKIN . '::r'       } = *{$_PACKAGE . 'r'};
	*{$_SKIN . '::i18n'    } = *{$_PACKAGE . 'i18n'};
	*{$_SKIN . '::create_url'    } = *{$_PACKAGE . 'create_url'};

	if ($r -> uri =~ m{/\w+\.(css|gif|ico|js|html)$}) {
		select__static_files ();
		return OK;
	}

	if ($preconf -> {core_auth_cookie}) {
		my $c = $_COOKIES {sid};
		$_REQUEST {sid} ||= $c -> value if $c;
	}
		
   	sql_reconnect ();

	require_fresh ($_PACKAGE . 'Config');
	   	   	   	   	   	   	
	if ($_REQUEST {keepalive}) {
		my $timeout = 60 * $conf -> {session_timeout} - 1;
		$_REQUEST {virgin} or keep_alive ($_REQUEST {keepalive});
		$r -> content_type ('text/html');
		$r -> send_http_header;
		print <<EOH;
			<html><head>
				<META HTTP-EQUIV=Refresh CONTENT="$timeout; URL=$_REQUEST{__uri}?keepalive=$_REQUEST{keepalive}">
			</head></html>			
EOH
		return OK;
	}		
	
	if ($_REQUEST {__whois}) {
		my $user = sql_select_hash ('SELECT users.id, users.label, users.mail, roles.name AS role FROM sessions INNER JOIN users ON sessions.id_user = users.id INNER JOIN roles ON users.id_role = roles.id WHERE sessions.id = ?', $_REQUEST {__whois});
		out_html ({}, Dumper ({data => $user}));
		return OK;
	}
   	
	our $_USER = get_user ();

	$number_format or our $number_format = Number::Format -> new (%{$conf -> {number_format}});

	$conf -> {__filled_in} or fill_in ();

   	$_REQUEST {__include_js} ||= [];
   	push @{$_REQUEST {__include_js}}, @{$conf -> {include_js}} if $conf -> {include_js};

   	$_REQUEST {__include_css} ||= [];
   	push @{$_REQUEST {__include_css}}, @{$conf -> {include_css}} if $conf -> {include_css};
						
	if ((!$_USER -> {id} and $_REQUEST {type} ne 'logon' and $_REQUEST {type} ne '_boot')) {

		delete $_REQUEST {sid};
		delete $_REQUEST {salt};
		delete $_REQUEST {_salt};
		delete $_REQUEST {__include_js};
		delete $_REQUEST {__include_css};
		
		my $type = ($preconf -> {core_skip_boot} || $conf -> {core_skip_boot}) ? 'logon' : '_boot';
		
		redirect ("/?type=$type&redirect_params=" . b64u_freeze (\%_REQUEST));
		
	}
			
	elsif (exists ($_USER -> {redirect})) {
		
		redirect (create_url ());
		
	}

	elsif ($_REQUEST {keepalive}) {
	
		redirect ("/\?type=logon&_frame=$_REQUEST{_frame}");
		
	}
	else {
			
		require_fresh ("${_PACKAGE}Content::menu");

		$_REQUEST {lang} ||= $_USER -> {lang} if $_USER;
		$_REQUEST {lang} ||= $preconf -> {lang} || $conf -> {lang}; # According to NISO Z39.53	
		our $i18n = $conf -> {i18n} -> {$_REQUEST {lang}};
		
		unless ($_CALENDAR) {
			require_fresh ($_PACKAGE . 'Calendar');
			eval "our \$_CALENDAR = new ${_PACKAGE}Calendar (\\\%_REQUEST)";
		}
		
		my $page = {
			menu => call_for_role ('select_menu') || call_for_role ('get_menu'),
			type => $_REQUEST {type},
		};
		
		if ($conf -> {core_extensible_menu} && $_USER -> {systems}) {
			
			foreach my $sys (sort grep {/\w/} split /\,/, $_USER -> {systems}) {
				my @items = ();
				eval {@items = &{"_${sys}_menu"}()};
				push @{$page -> {menu}}, @items;
			}

		}

		call_for_role ('get_page');

		if (!$page -> {type} && @{$page -> {menu}} > 0) {
			$page -> {type} = $page -> {menu} -> [0] -> {name};
			$_REQUEST {type}= $page -> {type}; 
		};
	
		unless ($page -> {type} =~ /^_/) {
			require_fresh ("${_PACKAGE}Content::$$page{type}");
			require_fresh ("${_PACKAGE}Presentation::$$page{type}");
		};
		
		$_REQUEST {__last_last_query_string} ||= $_REQUEST {__last_query_string};

		my $action = $_REQUEST {action};

		if ($action) {
			
			undef $__last_insert_id;

			eval { $db -> {AutoCommit} = 0; };
	
			our %_OLD_REQUEST = %_REQUEST;
			
			log_action_start ();
		
			my $sub_name = "validate_${action}_$$page{type}";		
			
			my $error_code = undef;			
			eval {	$error_code = call_for_role ($sub_name); };
			$error_code = $@ if $@;
						
			if ($_USER -> {demo_level} > 0) {
				($action =~ /^execute/ and $$page{type} eq 'logon') or $error_code ||= '»звините, вы работаете в демонстрационном режиме';
			}
			
			if ($error_code) {		
				my $error_message_template = $error_messages -> {"${action}_$$page{type}_${error_code}"} || $error_code;
				$_REQUEST {error} = interpolate ($error_message_template);
			}
			
			if ($_REQUEST {error}) {
				out_html ({}, draw_page ($page));
			}
			else {						
				
				unless ($_REQUEST {__peer_server}) {
				
					delete $_REQUEST {__response_sent};

					eval {					

						delete_fakes () if $action eq 'create';

						call_for_role ("do_${action}_$$page{type}");

						if (($action =~ /^execute/) and ($$page{type} eq 'logon') and $_REQUEST {redirect_params}) {

							my $VAR1 = b64u_thaw ($_REQUEST {redirect_params});

							foreach my $key (keys %$VAR1) {
								$_REQUEST {$key} = $VAR1 -> {$key};
							}					

						} elsif ($conf -> {core_cache_html}) {
							sql_do ("DELETE FROM cache_html");
							my $cache_path = $r -> document_root . '/cache/*';
							$^O eq 'MSWin32' or eval {`rm -rf $cache_path`};
						}

					};
					
					$_REQUEST {error} = $@ if $@;
								
				}
				
				if ($_REQUEST {error}) {
					out_html ({}, draw_page ($page));
				}
				elsif (!$_REQUEST {__response_sent}) {
								
					if ($action eq 'delete' && $conf -> {core_auto_esc} == 2) {						
						esc ({label => $_REQUEST {__redirect_alert}});
					}
					else {
						redirect (
							{
								action => '', 
								redirect_params => '',
							}, 
							{
								kind => 'js', 
								label => $_REQUEST {__redirect_alert},
							}
						);
					}				
				
				}
				
			}
			
			eval {
				$db -> commit unless $_REQUEST {error} || $db -> {AutoCommit};
				$db -> {AutoCommit} = 1;
			};

			log_action_finish ();

		}
		else {
					
#		   	sql_reconnect ();

			if (
				$conf -> {core_auto_esc} == 2 && 
				$_REQUEST {sid} && 
				(
					$r -> header_in ('Referer') =~ /action=\w/ ||
					$r -> header_in ('Referer') !~ /__last_query_string=$_REQUEST{__last_query_string}/ ||
					$r -> header_in ('Referer') !~ /type=$_REQUEST{type}/
				)
			) {
			
				my ($method, $url) = split /\s+/, $r -> the_request;
				
				$url =~ s{\&?_?salt=[\d\.]+}{}gsm;
				$url =~ s{\&?sid=\d+}{}gsm;

				my $no = sql_select_scalar ('SELECT no FROM __access_log WHERE id_session = ? AND href = ?', $_REQUEST {sid}, $url);
				
				unless ($no) {
					$no = 1 + sql_select_scalar ('SELECT MAX(no) FROM __access_log WHERE id_session = ?', $_REQUEST {sid});
					sql_do ('INSERT INTO __access_log (id_session, no, href) VALUES (?, ?, ?)', $_REQUEST {sid}, $no, $url);
				}

				$_REQUEST {__last_query_string} = $no;
				
				$_REQUEST {__last_last_query_string} ||= $_REQUEST {__last_query_string};
			
			}
				
			$r -> header_out ('Expires' => '-1');
				
			out_html ({}, draw_page ($page));
			
		}   

	}
   
#   	$db -> disconnect;
	
	return OK;

}

################################################################################

sub out_html {

	my ($options, $html) = @_;
		
	$html or return;
	
	return if $_REQUEST {__response_sent};
	
	if ($conf -> {core_sweep_spaces}) {
		$html =~ s{^\s+}{}gsm; 
		$html =~ s{[ \t]+}{ }g;
	}

	unless ($preconf -> {core_no_morons}) {
		$html =~ s{window\.open}{nope}gsm; 
	}


	$_REQUEST {__content_type} ||= 'text/html; charset=' . $i18n -> {_charset};

	$r -> content_type ($_REQUEST {__content_type});
	$r -> header_out ('X-Powered-By' => 'Zanas/' . $Zanas::VERSION);

	if ($] > 5.007) {
		require Encode;
		$html = Encode::encode ('windows-1252', $html);
	}

	$preconf -> {core_mtu} ||= 1500;
	
	if (
		($conf -> {core_gzip} or $preconf -> {core_gzip}) && 
		400 + length $html > $preconf -> {core_mtu} &&
		($r -> header_in ('Accept-Encoding') =~ /gzip/)
	) {
		$r -> content_encoding ('gzip');
		unless ($_REQUEST {__is_gzipped}) {
			$html = Compress::Zlib::memGzip ($html);
		}
	}

	$r -> header_out ('Content-Length' => length $html);

	if ($preconf -> {core_auth_cookie}) {
	
		set_cookie (
			-name    =>  'sid',
			-value   =>  $_REQUEST {sid} || 0,
			-expires =>  $preconf -> {core_auth_cookie},
			-path    =>  '/',
		)      
		
	}


	$r -> send_http_header;
	
	$r -> header_only or print $html;		

}

#################################################################################

sub pub_handler {

	$_PACKAGE ||= __PACKAGE__ . '::';
	
	get_request (@_);
	
	my $parms = $apr -> parms;
	if ($parms -> {debug1} or $r -> uri =~ m{/(navigation\.js|0\.html|0\.gif|zanas\.css)}) {
		handler (@_);
		return OK;		
	};
	our %_REQUEST = %{$parms};		
	$_REQUEST {__uri} = $r -> uri;
	
	$_REQUEST {__uri} =~ s{^http://[^/]+}{};
	$_REQUEST {__uri} =~ s{\/\w+\.\w+$}{};

	$_REQUEST {__uri_chomped} = $_REQUEST {__uri};
	$_REQUEST {__uri_chomped} =~ s{/+$}{};
	
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
	
	our $_PAGE = select_pub_page ();
	return 0 if $_REQUEST {__response_sent};
	
	my $type   = $_PAGE -> {type};
	my $id     = $_PAGE -> {id};
	my $action = $_REQUEST {action};
	
	if ($action) {

		require_fresh ("${_PACKAGE}Content::${type}");
		
		$_REQUEST {error} = call_for_role ("validate_${action}_${type}");
		
		if ($_REQUEST {error}) {
		
#			redirect ("?error=$error_code", {kind => 'http'});

			redirect (
				($_REQUEST {__uri_chomped} . '/?' . join '&', map {"$_=" . uri_escape ($_REQUEST {$_})} grep {/^_[^_]/} keys %_REQUEST) . "&error=$_REQUEST{error}",
				{kind => 'http'},
			);

		}
		else {

			eval { $db -> {AutoCommit} = 0; };
			call_for_role ("do_${action}_${type}");
			eval { 
				$db -> commit unless $_REQUEST {error};
				$db -> {AutoCommit} = 1;
			};

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
			return OK if $_REQUEST {__response_sent}; 
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

#   	$db -> disconnect;
	
	return OK;

}


1;