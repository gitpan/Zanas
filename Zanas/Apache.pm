no warnings;

use Number::Format;

################################################################################

sub handler {

	our $_PACKAGE = __PACKAGE__ . '::';
	
	my  $use_cgi = $ENV {SCRIPT_NAME} =~ m{index\.pl} || $ENV {GATEWAY_INTERFACE} =~ m{^CGI/} || $conf -> {use_cgi} || $preconf -> {use_cgi} || !$INC{'Apache/Request.pm'};
	
#print STDERR "\%ENV = ", Dumper (\%ENV);

#print STDERR "\$use_cgi = $use_cgi\n";
	
	our $r   = $use_cgi ? new Zanas::Request () : $_[0];

#print STDERR "\$r = ", Dumper ($r);

	our $apr = $use_cgi ? $r : Apache::Request -> new ($r);

#print STDERR "\$apr = ", Dumper ($apr);
		
	my $parms = $apr -> parms;
	our %_REQUEST = %{$parms};
	
	$_REQUEST {type} =~ s/_for_.*//;
	
	$number_format or our $number_format = Number::Format -> new (%{$conf -> {number_format}});
	
	require_fresh ($_PACKAGE . '::Config');

   	sql_reconnect ();

   	$conf -> {dbf_dsn} and our $dbf = DBI -> connect ($conf -> {dbf_dsn}, {RaiseError => 1});
	
	$_REQUEST {type} = '_static_files' if $r -> filename =~ /\w\.\w/;
	
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
				<META HTTP-EQUIV=Refresh CONTENT="$timeout; URL=/?keepalive=$_REQUEST{keepalive}">
			</head></html>			
EOH
		return;
	}	
   	
	my $action = $_REQUEST {action};
		
	our $_USER = get_user ();
	
	require_fresh ($_PACKAGE . '::Calendar');
	
	eval "our \$_CALENDAR = new ${_PACKAGE}Calendar (\\\%_REQUEST)";

#	if (!$_USER and $_REQUEST {type} ne 'logon' and $_REQUEST {type} ne '_static_files') {
		
#		redirect ("/\?type=logon&_frame=$_REQUEST{_frame}");
		
#	}

	if (!$_USER and $_REQUEST {type} ne 'logon' and $_REQUEST {type} ne '_static_files') {
#		$_REQUEST {return_type}   = $_REQUEST {type} unless ($_REQUEST {return_type});
#		$_REQUEST {return_id}     = $_REQUEST {id} unless ($_REQUEST {return_id});
#		$_REQUEST {return_action} = $_REQUEST {action} unless ($_REQUEST {return_action});
#		delete $_REQUEST {id};
#		delete $_REQUEST {action};

		delete $_REQUEST {sid};
		delete $_REQUEST {salt};
		delete $_REQUEST {_salt};
		delete $_REQUEST {__include_js};
		delete $_REQUEST {__include_css};

		redirect ('/?type=logon&redirect_params=' . uri_escape (Dumper (\%_REQUEST)));

#		redirect (create_url ( type => 'logon', _frame => $_REQUEST{_frame}));
		
	}

	elsif ($_REQUEST {keepalive}) {
	
		redirect ("/\?type=logon&_frame=$_REQUEST{_frame}");
		
	}
	else {
	
		my $user_agent = $r->header_in ('User-Agent');

		$_USER -> {drawer_name} = 
			$user_agent =~ /MSIE [56]/  ? 'MSIE_5':
			$user_agent =~ /Mozilla\/3/ ? 'Mozilla_3':
			$user_agent =~ /Mozilla\/5/ ? 'MSIE_5':
			'Unsupported';
		
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
			
				eval {	
					delete_fakes () if $action eq 'create';
					call_for_role ("do_${action}_$$page{type}");
					
					if (($action eq 'execute') and ($$page{type} eq 'logon') and $_REQUEST {redirect_params}) {
					
						my $VAR1;

						eval $_REQUEST {redirect_params};
						
						while (my ($key, $value) = each %$VAR1) {
							$_REQUEST {$key} = $value;
						}					
						
					}
					
				};	
				
				if ($@) {
					$_REQUEST {error} = $@;
					out_html ({}, draw_page ($page));
				}
				else {					
					my $url = create_url (action => '', redirect_params => '');
					out_html ({}, qq {<body onLoad="window.open ('$url&salt=' + Math.random (), '_top', 'location=0,menubar=0,status=0,toolbar=0')"></body>});
				}
				
			}

			log_action ($_USER -> {id}, $$page{type}, $action, $_REQUEST {error}, $r -> connection -> remote_ip, $_REQUEST {id});

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
	
#print STDERR "out_html: \$html = $html\n";
	
	$html or return;
	
	if ($_REQUEST {dbf}) {
		redirect ("/$html");
	}
	
	if ($_REQUEST {xls}) {
		my $fn = 'i/xls/' . time . '.xls';
		open (O, ">$$conf{site_root}/$fn") or die "Can't write to $$conf{site_root}/$fn: $!";
		print O $html;
		close (O);
		redirect ("/$fn");
	}	
	else {
	
		if ($conf -> {core_sweep_spaces}) {
			$html =~ s{^\s+}{}gsm; 
			$html =~ s{[ \t]+}{ }g;
		}

		$_REQUEST {__content_type} ||= 'text/html; charset=windows-1251';
		$r -> content_type ($_REQUEST {__content_type});
		
		if (($conf -> {core_gzip} or $preconf -> {core_gzip}) and $r -> header_in ('Accept-Encoding') =~ /gzip/) {
			$r -> header_out ('Content-Encoding' => 'gzip');
			$html = Compress::Zlib::memGzip ($html);
		}		

		$r -> header_out ('Content-Length' => length $html);
		
		$r -> send_http_header;
		print $html;
	}	

}

1;