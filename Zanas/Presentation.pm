no warnings;

###############################################################################

sub format_picture {

	my ($txt, $picture) = @_;
	
	my $result = $number_format -> format_picture ($txt, $picture);
	
	if ($_USER -> {demo_level} > 1) {
		$result =~ s{\d}{\*}g;
	}
	
	return $result;

}

################################################################################

sub js_ok_escape {
	return '';
}

################################################################################

sub js_escape {
	my ($s) = @_;	
	$s =~ s/\"/\'/gsm; #"
	$s =~ s{[\n\r]+}{ }gsm;
	$s =~ s{\\}{\\\\}g;
	$s =~ s{\'}{\\\'}g; #'
	return "'$s'";
}

################################################################################

sub register_hotkey {

	my ($hashref, $type, $data, $options) = @_;
	
	my $code = $_SKIN -> register_hotkey ($hashref) or return;
	
	push @scan2names, {
		code => $code,
		type => $type,
		data => $data,
		ctrl => $options -> {ctrl},
		alt  => $options -> {alt},
	};

}

################################################################################

sub hotkeys {
	foreach (@_) { hotkey ($_) };
}

################################################################################

sub hotkey {

	my ($def) = $_[0];
		
	$def -> {type} ||= 'href';

	if ($def -> {code} =~ /^F(\d+)/) {
		$def -> {code} = 111 + $1;
	}
	elsif ($def -> {code} =~ /^ESC$/i) {
		$def -> {code} = 27;
	}
	elsif ($def -> {code} =~ /^DEL$/i) {
		$def -> {code} = 46;
	}
	elsif ($def -> {code} =~ /^ENTER$/i) {
		$def -> {code} = 13;
	}
	
	push @scan2names, $def;
	
}

################################################################################

sub trunc_string {
	my ($s, $len) = @_;
	return $s if $_REQUEST {xls};
	return length $s <= $len - 3 ? $s : substr ($s, 0, $len - 3) . '...';
}

################################################################################

sub esc_href {

	if ($conf -> {core_auto_esc} == 2) {
	
		my $href = sql_select_scalar ('SELECT href FROM __access_log WHERE id_session = ? AND no = ?', $_REQUEST {sid}, $_REQUEST {__last_last_query_string});
		$href ||= "/?type=$_REQUEST{type}";
	
		$href .= '&sid=' . $_REQUEST {sid};
		$href .= '&salt=' . rand * time;
				
		if ($_REQUEST {__last_scrollable_table_row}) {
			$href =~ s{\&?__scrollable_table_row\=\d*}{}g;
			$href .= '&__scrollable_table_row=' . $_REQUEST {__last_scrollable_table_row};
		}

		return $href;
		
	}

	my $esc_query_string = $_REQUEST {__last_query_string};
	$esc_query_string =~ y{-_.}{+/=};
	my $query_string = MIME::Base64::decode ($esc_query_string);
	my $salt = time (); #rand ();
	$query_string =~ s{salt\=[\d\.]+}{salt=$salt}g;
	$query_string =~ s{sid\=[\d\.]+}{sid=$_REQUEST{sid}}g;
	return $_REQUEST {__uri} . '?' . $query_string;
	
	
}


################################################################################

sub create_url {

	my %over = @_;
	
	defined $over {salt} or $over {salt} = rand * time;
	
	my %param = %_REQUEST;
	
	delete $param {__last_last_query_string};

	foreach my $k (keys %over) {
		$param {$k} = $over {$k};
	}
	
	my $url = $_REQUEST {__uri} . '?';
	
	foreach my $k (keys %param) {
		my $v = $param {$k};

		defined $v or next;

		next if $k =~ /^_/ && $k !~ /^(__last_last_query_string|__last_query_string|__last_scrollable_table_row|__no_navigation|__infty|__no_infty)$/;
		next if $k eq 'password';
		next if $k eq 'select' && !$v;
		next if $k eq 'action' && !$v;
		next if $k eq '__last_query_string' && !$v;
		
		$url .= '&' unless $url =~ /\?$/;
		$url .= $k;
		$url .= '=';
		$url .= uri_escape ($v);
		
	}
	
	return $url;
		
}

################################################################################

sub hrefs {

	my ($order) = @_;
	
	return $order ? (
		href      => create_url (order => $order, desc => 0, __last_last_query_string => $_REQUEST {__last_last_query_string}),
		href_asc  => create_url (order => $order, desc => 0, __last_last_query_string => $_REQUEST {__last_last_query_string}),
		href_desc => create_url (order => $order, desc => 1, __last_last_query_string => $_REQUEST {__last_last_query_string}),
	) : ();
	
}

################################################################################

sub headers {

	my @result = ();
	
	while (@_) {
	
		my $label = shift;
		$label =~ s/_/ /g;

		my $order;
		$order = shift if $label ne ' ';
		
		push @result, {label => $label, hrefs ($order)};
	
	}
	
	return \@result;

}

################################################################################

sub order {

	my $default = shift;
	my $result;
	
	while (@_) {
		my $name  = shift;
		my $sql   = shift;
		$name eq $_REQUEST {order} or next;
		$result   = $sql;
		last;
	}
	
	$result ||= $default;
	
	if ($_REQUEST {desc}) {
	
		$result .= ',';
		$result =~ s/\s+/ /g;	
		$result =~ s/ \,/\,/g;	
		$result =~ s/([^(ASC|DESC)])\,/$1 ASC\,/g;
		$result =~ s/ DESC\,/ BCSC\,/g;
		$result =~ s/ ASC\,/ DESC\,/g;
		$result =~ s/ BCSC\,/ ASC\,/g;

		chop $result;	
		
	}
			
	return $result;

}

################################################################################

sub check_title {

	my ($options) = @_;

	$options -> {title} ||= $options -> {label};
	$options -> {title} =~ s{\<.*?\>}{}g;	
	$options -> {title} =~ s{^(\&nbsp\;)+}{};	
	$options -> {title} =~ s{\"}{\&quot\;}g;	
	$options -> {attributes} -> {title} = $options -> {title};
	$options -> {title} = qq{title="$$options{title}"} if length $options -> {title}; #"

}

################################################################################

sub check_href {

	my ($options) = @_;	
	
	if (ref $options -> {href} eq HASH) {
		$options -> {href} = create_url (%{$options -> {href}});
	}	
	
	if ($options -> {href} !~ /^(\#|java|mailto|\/i\/)/) {
	
		$options -> {href} =~ s{\&?_?salt=[\d\.]+}{}gsm;
		$options -> {href} .= '&salt=' . (rand * time);

		if ($options -> {href} !~ /[\&\?]sid=/) {
			$options -> {href} .= "\&sid=$_REQUEST{sid}";
		}	

		if ($_REQUEST {select} and $options -> {href} !~ /[\&\?]select=/) {
			$options -> {href} .= "\&select=$_REQUEST{select}";
		}	

		if ($_REQUEST {period} and $options -> {href} !~ /\&period=/) {
			$options -> {href} .= "\&period=$_REQUEST{period}";
		}

		if ($_REQUEST {__uri} ne '/' && $options -> {href} =~ m{^\/\?}) {
			$options -> {href} =~ s{^\/\?}{$_REQUEST{__uri}\?};
		}
		
		if ($conf -> {core_auto_esc} == 2 && $options -> {href} !~ m{\&?__last_query_string=\d+}) {
			$options -> {href} .= '&__last_query_string=' . $_REQUEST{__last_query_string};
		}
		
		if ($conf -> {core_auto_esc} == 2 && !$_FLAG_ADD_LAST_QUERY_STRING && $_REQUEST{__last_scrollable_table_row} > 0 && $options -> {href} !~ /__last_scrollable_table_row/ ) {
			$options -> {href} .= '&__last_scrollable_table_row=' . $_REQUEST{__last_scrollable_table_row};
		}

		if ($_FLAG_ADD_LAST_QUERY_STRING) {
		
			if ($conf -> {core_auto_esc} == 1) {

				my $query_string = $ENV {QUERY_STRING};
				$query_string =~ s{\&?__last_query_string\=[^\&]+}{}gsm;

				$query_string =~ s{\&?__scrollable_table_row\=\d*}{}g;
				$query_string .= "&__scrollable_table_row=$scrollable_row_id";

				my $esc_query_string = MIME::Base64::encode ($query_string);
				$esc_query_string =~ y{+/=}{-_.};
				$esc_query_string =~ s{[\r\n]}{}gsm;

				$options -> {href} =~ s{\&?__last_query_string\=[^\&]+}{}gsm;
				$options -> {href} .= "&__last_query_string=$esc_query_string";

			}
			elsif ($conf -> {core_auto_esc} == 2) {
				$options -> {href} =~ s{\&?__last_scrollable_table_row=\d*}{}gsm;
				$options -> {href} .= "&__last_scrollable_table_row=$scrollable_row_id";
			}

		}		
	
	}
	
	$options -> {href} =~ s/\&+/\&/g;
	

}

################################################################################

sub draw__info {

	my ($data) = @_;
	
	draw_table (
	
		sub {
			draw_cells ({}, [
				$i -> {id},
				{label => $i -> {label}, max_len => 10000000},
				{label => $i -> {path}, max_len => 10000000},
			])
		},
		
		$data,
		
		{		
			
			title => {label => '���������� � �������'},
			
			lpt => 1,
			
		},
	
	);
	
}

################################################################################

sub draw__boot {

	$_REQUEST {__no_navigation} = 1;
	
	my $propose_gzip = 0;
	if (($conf -> {core_gzip} or $preconf -> {core_gzip}) && ($r -> header_in ('Accept-Encoding') !~ /gzip/)) {
		$propose_gzip = 1;
	}

	$_REQUEST {__on_load} = <<EOJS;
	
		
		if (navigator.appVersion.indexOf ("MSIE") != -1 && navigator.appVersion.indexOf ("Opera") == -1) {

			var version=0;
			var temp = navigator.appVersion.split ("MSIE");
			version  = parseFloat (temp [1]);

			if (version < 5.5) {
				alert ('��������! ������ WEB-���������� ��������������� � ������������� ������ ��������� � ���������� ��������� MS Internet Explorer ������ �� ���� 5.5. �� ����� ������� ����� ����������� ������ ' + version + '. ����������, ��������� ������ ���������� �������������� ��������� ���������� MS Internet Explorer �� ������� ������ (��������� ���������� � ���������� ���������) ��� �������� ��� ��������������.');
				document.location.href = 'http://www.microsoft.com/ie';
				return;				
			}
			
			if ($propose_gzip) {
				alert ('��������! ��������� ������ �������� ����� �� ��������� ������������ ���������������� �������� (HTTP 1.1) ��� ����� � ��������. ���������, ����������, ������ �������������� ��������� ������������� ��������� HTTP 1.1 ��� ����� � �������� $ENV{HTTP_HOST} -- ��� ���������� ���������� ��������� ������� �������� ������ � 3-5 ���.');
			}


		}
		else {
		
			var brand = navigator.appName;
		
			if (navigator.appVersion.indexOf ("Opera") > -1) {
				brand = 'Opera';
			}

			alert ('��������! ������ WEB-���������� ��������������� � ������������� ������ ��������� � ���������� ��������� MS Internet Explorer. �� ��������� ������������ ��������� ' + brand + '. � ���� �������� ����������� ��������� ������������ �� ������������ � ������������ ����� ������������. ����������, ����������� ����������� ��, ������������� �� ����� ������� �����.');
			
		}					
						
		nope ('$_REQUEST{__uri}?type=logon&redirect_params=$_REQUEST{redirect_params}', '_self');

		setTimeout ("document.getElementById ('abuse_1').style.display = 'block'", 10000);
		
EOJS

	return <<EOH
	
			<img src="/0.gif" width=100% height=20%>
		
			<center>

		<noscript>
		
			
			<table border=0 width=50% height=30% cellspacing=1 cellpadding=0 bgcolor=red><tr><td>
				<table border=0 width=100% height=100% cellspacing=0 cellpadding=10><tr><td bgcolor=white>		
		
					<b>��������!</b> ������������ ������� �� ����� ������� ����� ��������� ����� �������, ��� ���������� ������ ���������� ����������.

					<p>����������, ��������� ������ ���������� �������������� ��������� ������������� �������� ��������� (javaScript) ��� ������� $ENV{HTTP_HOST}.
			
				</table>
			</table>
			
		
		</noscript>
		
			<table id="abuse_1" border=0 width=50% height=30% cellspacing=1 cellpadding=0 bgcolor=red style="display:none"><tr><td>
				<table border=0 width=100% height=100% cellspacing=0 cellpadding=10><tr><td bgcolor=white>		
		
					<b>��������!</b> ������������ ������� �� ����� ������� ����� ��������� ����� �������, ��� ���������� ������ ���������� ����������. ��������, ��� ������� � ������������� ������������, ���������� � �������� � ������������� �������� Internet: ���������, ��������������� � �. �.

					<p>����������, ��������� ������ ���������� �������������� ��������� ������������� ������� window . open() ��� ������� $ENV{HTTP_HOST}.
			
				</table>
			</table>
						
EOH

}

################################################################################

sub draw_item_of__object_info {

	my ($data) = @_;

	draw_form (
	
		{
			no_edit => 1,
		},
		
		$data,
		
		[
			[
				{
					label => 'id',
					value => $_REQUEST {id},
				},
				{
					label => 'type',
					value => $_REQUEST {object_type},
				},
			],
			[
				{
					label => 'label',
					value => $data -> {label},
				},
				{
					label => 'fake',
					value => $data -> {fake},
				},
			],
			
			{type => 'banner', label => 'LOG'},
			
			[
				{
					label  => 'when created',
					value  => $data -> {last_create} -> {dt},
					href   => "/?type=log&__popup=1&id=" . $data -> {last_create} -> {id},
					target => '_blank',
				},
				{
					label => 'when updated',
					value => $data -> {last_update} -> {dt},
					href  => "/?type=log&__popup=1&id=" . $data -> {last_update} -> {id},
					target => '_blank',
				},
			],
			[
				{
					label  => 'who created',
					value  => $data -> {last_create} -> {user} -> {label},
					href   => "/?type=users&id=" . $data -> {last_create} -> {id_user},
				},
				{
					label  => 'who updated',
					value  => $data -> {last_update} -> {user} -> {label},
					href   => "/?type=users&id=" . $data -> {last_update} -> {id_user},
				},
			],
			
		],
	
	)
	
	.
	
	draw_table (
	
		[
			'table',
			'column',
			'count',
		],
		
		sub {
		
			draw_cells ({
				href => {table_name => $i -> {table_name}, name => $i -> {name}},
			}, [
				$i -> {table_name},
				$i -> {name},
				{
					label   => $i -> {cnt},
					picture => '### ### ### ### ###',
					off     => 'if zero',
				},
			])
		
		},
		
		$data -> {references},
		
		{
			title => {label => 'References'},
			lpt => 1,
		},
	
	)
	
	.
	
	draw_table (
	
		[
			'id',
			'label',
			'dt',
		],
	
		sub {
			
			$i -> {dt} =~ s{(\d+)\-(\d+)\-(\d+)}{$3.$2.$1};
		
			draw_cells ({
				href => "/?type=$_REQUEST{table_name}&id=$$i{id}",
			}, [
				$i -> {id},
				$i -> {label} || $i -> {no},
				$i -> {dt},
			])
		
		},
		
		$data -> {records},
		
		{
			title => {label => "Referring $_REQUEST{table_name} by $_REQUEST{name}"},
			off => !$_REQUEST {table_name},
			top_toolbar => [{}, {
				type => 'pager',
				cnt  => 0 + @{$data -> {records}},
				total => $data -> {cnt},
			}],
			
		},
	
	)
	
}

################################################################################
#                     R   E   F   A   C   T   O   R   E   D                    #
################################################################################

sub draw_auth_toolbar {

	return '' if $_REQUEST {__no_navigation} or $conf -> {core_no_auth_toolbar};
	
	return $_SKIN -> draw_auth_toolbar ({
		top_toolbar => ($conf -> {top_banner} ? interpolate ($conf -> {top_banner}) : ''),
		calendar    => ($_CALENDAR            ? $_CALENDAR -> draw () : ''),
		user_label  => ($i18n -> {User} . ': ' . ($_USER -> {label} || $i18n -> {not_logged_in})),
	});
			
}

################################################################################

sub draw_hr {

	my (%options) = @_;
		
	$options {height} ||= 1;
	$options {class}  ||= bgr8;
	
	return $_SKIN -> draw_hr (\%options);
		
}

################################################################################

sub draw_window_title {

	my ($options) = @_;
	
	return '' if $options -> {off};
	
	our $__last_window_title = $options -> {label};
		
	return $_SKIN -> draw_window_title (@_);

}

################################################################################

sub draw_form {

	my ($options, $data, $fields) = @_;
	
	return '' if $options -> {off};
	
	$options -> {hr} = draw_hr (height => 10);
	
	if (ref $data eq HASH && $data -> {fake} == -1 && !exists $options -> {no_edit}) {
		$options -> {no_edit} = 1;
	}
	
	$options -> {data} = $data;
	
	$options -> {name}    ||= 'form';
	
	!$_REQUEST {__only_form} or $_REQUEST {__only_form} eq $options -> {name} or return '';
	
	$options -> {target}  ||= 'invisible';	
	$options -> {method}  ||= 'post';
	$options -> {enctype} ||= 'multipart/form-data';
	$options -> {target}  ||= 'invisible';	
	$options -> {action}    = 'update' unless exists $options -> {action};

	my   @keep_params = map {{name => $_, value => $_REQUEST {$_}}} @{$options -> {keep_params}};
	push @keep_params, {name  => 'sid',                         value => $_REQUEST {sid}                         };
	push @keep_params, {name  => 'select',                      value => $_REQUEST {select}                      };
	push @keep_params, {name  => 'type',                        value => $_REQUEST {type}   || $options -> {type}};
	push @keep_params, {name  => 'id',                          value => $_REQUEST {id}     || $options -> {id}  };
	push @keep_params, {name  => 'action',                      value => $options -> {action}                    };
	push @keep_params, {name  => '__last_query_string',         value => $_REQUEST {__last_last_query_string}    };
	push @keep_params, {name  => '__last_scrollable_table_row', value => $_REQUEST {__last_scrollable_table_row} };
	$options -> {keep_params} = \@keep_params;	

		
	if (
		$_REQUEST {__edit} 
		&& !$_REQUEST{__from_table} 
		&& !(ref $data eq HASH && $data -> {fake} > 0)
	) {
		$options -> {esc} = create_url (__last_query_string => $_REQUEST {__last_last_query_string}, __edit => '');
	}	
	elsif ($conf -> {core_auto_esc} > 0 && $_REQUEST {__last_query_string}) {
		$options -> {esc} = esc_href ();
	}	
						
	our $tabindex = 1;
	
	my @rows = ();
			
	foreach my $field (@$fields) {
		
		my $row;
		
		if (ref $field eq ARRAY) {
			my @row = ();
			foreach (@$field) {
				next if $_ -> {off};
				next if $_REQUEST {__read_only} && $_ -> {type} eq 'password';
				push @row, $_;
			}
			next if @row == 0;
			$row = \@row;
		}
		else {
			next if $field -> {off};
			next if $_REQUEST {__read_only} && $field -> {type} eq 'password';
			$row = [$field];
		}
		
		push @rows, $row;

	}
	
	my $max_colspan = 1;
	
	foreach my $row (@rows) {
		my $sum_colspan = 0;
		for (my $i = 0; $i < @$row; $i++) {
			$row -> [$i] -> {colspan} ||= 1;
			$sum_colspan += $row -> [$i] -> {colspan};
			$sum_colspan ++;
			next if $i < @$row - 1;
			$row -> [$i] -> {sum_colspan} = $sum_colspan;
		}
		$max_colspan > $sum_colspan or $max_colspan = $sum_colspan;
	}

	$_SKIN -> start_form () if $_SKIN -> {options} -> {no_buffering};

	foreach my $row (@rows) {
		$row -> [-1] -> {colspan} += ($max_colspan - $row -> [-1] -> {sum_colspan});
		$_SKIN -> start_form_row () if $_SKIN -> {options} -> {no_buffering};
		foreach (@$row) { $_ -> {html} = draw_form_field ($_, $data) };
		$_SKIN -> draw_form_row ($row) if $_SKIN -> {options} -> {no_buffering};
	}
	
	$options -> {rows} = \@rows;
				
	$options -> {path} = ($data -> {path} && !$_REQUEST{__no_navigation}) ? draw_path ($options, $data -> {path}) : '';
	
	delete $options -> {menu} if $_REQUEST {__edit};
	if ($options -> {menu}) {	
		$options -> {menu} = [ grep {!$_ -> {off}} @{$options -> {menu}} ];
	}
	delete $options -> {menu} if @{$options -> {menu}} == 0;
		
	if ($options -> {menu}) {
		
		foreach my $item (@{$options -> {menu}}) {
				
			if ($item -> {type}) {
				$item -> {href} = {type => $item -> {type}, start => ''};
				$item -> {is_active} = $item -> {type} eq $_REQUEST {type} ? 1 : 0;
			}
			else {
				$item -> {is_active} += 0;
			}
		
			check_href ($item);
			
			if ($conf -> {core_auto_esc} == 2) {
			
				$item -> {href} =~ s{\&?__last_query_string=\d*}{}gsm;
				$item -> {href} .= "&__last_query_string=$_REQUEST{__last_last_query_string}";

				$item -> {href} =~ s{\&?__last_scrollable_table_row=\d*}{}gsm;
				$item -> {href} .= "&__last_scrollable_table_row=$_REQUEST{__last_scrollable_table_row}";
			
			}
			
			if ($item -> {hotkey}) {
				hotkey ({
					%{$item -> {hotkey}},
					data => $item,
					type => 'href',
				});
			}			
			
		}
	
	
	} 
	
	unless (exists $options -> {bottom_toolbar}) {
	
		$options -> {bottom_toolbar} =
			($_REQUEST {__no_navigation} && !$_REQUEST {select}) ? draw_close_toolbar ($options) :
			$options -> {back} ? draw_back_next_toolbar ($options) :
			$options -> {no_ok} ? draw_esc_toolbar ($options) :
			draw_ok_esc_toolbar ($options, $data);

	}
	
#	$__last_centered_toolbar_id = '';
	
	return $_SKIN -> draw_form ($options);

}

################################################################################

sub draw_form_field {

	my ($field, $data) = @_;
								
	if (
		($_REQUEST {__read_only} or $field -> {read_only})
	 	 &&  $field -> {type} ne 'hgroup'
	 	 &&  $field -> {type} ne 'banner'
	 	 &&  $field -> {type} ne 'iframe'
	 	 &&  $field -> {type} ne 'color'
		 && ($field -> {type} ne 'text' || !$conf -> {core_keep_textarea})
	)
	{
		
		if ($field -> {type} eq 'file') {
			$field -> {file_name} ||= $field -> {name} . '_name';
			$field -> {name}        = $field -> {file_name};
			$field -> {href}      ||= {action => 'download'};
			$field -> {target}    ||= 'invisible';
		}
		elsif ($field -> {type} eq 'checkbox') {
			$field -> {value} = $data -> {$field -> {name}} || $field -> {checked} ? $i18n -> {yes} : $i18n -> {no};
		}
		else {
			$field -> {value} ||= $data -> {$field -> {name}};
		}	
		
		$field -> {type} = 'static';
		
	}	
	
	$field -> {type} ||= 'string';
	
	!$_REQUEST {__only_field} or $_REQUEST {__only_field} eq $field -> {name} or return '';

	$field -> {tr_id}  = 'tr_' . $field -> {name};

	$field -> {html} = &{"draw_form_field_$$field{type}"} ($field, $data);
	
	$conf -> {kb_options_focus} ||= $conf -> {kb_options_buttons};
	$conf -> {kb_options_focus} ||= {ctrl => 1, alt => 1};
	
	register_hotkey ($field, 'focus', '_' . $field -> {name}, $conf -> {kb_options_focus});
	
	$field -> {label} .= ':' if $field -> {label};
	
	$field -> {colspan} ||= $_REQUEST {__max_cols} - 1;
	
	$field -> {state}     = $data -> {fake} == -1 ? 'deleted' : $_REQUEST {__read_only} ? 'passive' : 'active';
	
	$field -> {label_width} = '20%' unless $field -> {is_slave};	
	
	return $_SKIN -> draw_form_field ($field);

}

################################################################################

sub draw_path {

	my ($options, $list) = @_;

	return '' if $_REQUEST {lpt};
	return '' unless $list;
	return '' unless ref $list eq ARRAY;
	return '' unless @$list > 0;

	$options -> {id_param} ||= 'id';
	$options -> {max_len}  ||= $conf -> {max_len};
	$options -> {max_len}  ||= 30;
	$options -> {nowrap}     = $options -> {multiline} ? '' : 'nowrap';
	
	$_REQUEST {__path} = [];
	
	for (my $i = 0; $i < @$list; $i ++) {		
	
		my $item = $list -> [$i];
	
		$item -> {label}      = trunc_string ($item -> {label} || $item -> {name}, $options -> {max_len});
		$item -> {id_param} ||= $options -> {id_param};		
		$item -> {cgi_tail} ||= $options -> {cgi_tail};
		
		unless ($_REQUEST {__edit} || $i == @$list - 1) {
			$item -> {href} = "/?type=$$item{type}&$$item{id_param}=$$item{id}&$$item{cgi_tail}";
			check_href ($item);
			push @{$_REQUEST {__path}}, $item -> {href};
		}
	
	}
	
	return $_SKIN -> draw_path ($options, $list);
	
}

################################################################################

sub draw_form_field_banner {

	my ($field, $data) = @_;
	return $_SKIN -> draw_form_field_banner (@_);

}

################################################################################

sub draw_form_field_button {

	my ($options, $data) = @_;
	$options -> {value} ||= $data -> {$options -> {name}};
	$options -> {value} =~ s/\"/\&quot\;/gsm; #"

	return $_SKIN -> draw_form_field_button (@_);

}

################################################################################

sub draw_form_field_string {

	my ($options, $data) = @_;

	$options -> {max_len} ||= $options -> {size};
	$options -> {max_len} ||= 255;
	$options -> {attributes} -> {maxlength} = $options -> {max_len};

	$options -> {size}    ||= 120;
	$options -> {attributes} -> {size}      = $options -> {size};
	
	$options -> {value}   ||= $data -> {$options -> {name}};
		
	if ($options -> {picture}) {
		$options -> {value} = format_picture ($options -> {value}, $options -> {picture});
		$options -> {value} =~ s/^\s+//g;
	}
	
	$options -> {value} =~ s/\"/\&quot\;/gsm; #";
	$options -> {attributes} -> {value} = $options -> {value};
	
	$options -> {attributes} -> {name}  = '_' . $options -> {name};
			
	$options -> {attributes} -> {tabindex} = ++ $_REQUEST {__tabindex};

	return $_SKIN -> draw_form_field_string (@_);
	
}

################################################################################

sub draw_form_field_date {

	my ($_options, $data) = @_;	
	$_options -> {no_time} = 1;	
	return draw_form_field_datetime ($_options, $data);

}

################################################################################

sub draw_form_field_datetime {

	my ($options, $data) = @_;
		
	if ($r -> header_in ('User-Agent') =~ /MSIE 5\.0/) {
		$options -> {size} ||= $options -> {no_time} ? 11 : 16;
		return draw_form_field_string ($options, $data);
	}	
		
	unless ($options -> {format}) {
	
		if ($options -> {no_time}) {
			$options -> {format}  ||= $i18n -> {_format_d} || '%d.%m.%Y';
			$options -> {size}    ||= 11;
		}
		else {
			$options -> {format}  ||= $i18n -> {_format_dt} || '%d.%m.%Y %k:%M';
			$options -> {size}    ||= 16;
		}
	
	}
		
	$options -> {attributes} -> {size}      = $options -> {size};
	$options -> {attributes} -> {maxlength} = $options -> {size};

	$options -> {value}   ||= $data -> {$options -> {name}};
	$options -> {attributes} -> {value} = $options -> {value};
	
	$options -> {attributes} -> {id} = 'input_' . $options -> {name};

	$options -> {attributes} -> {tabindex} = ++ $_REQUEST {__tabindex};

	return $_SKIN -> draw_form_field_datetime (@_);

}

################################################################################

sub draw_form_field_file {
	my ($options, $data) = @_;
	$options -> {size} ||= 60;
	return $_SKIN -> draw_form_field_file (@_);
}

################################################################################

sub draw_form_field_hidden {
	my ($options, $data) = @_;	
	$options -> {value}   ||= $data -> {$options -> {name}};
	$options -> {value} =~ s/\"/\&quot\;/gsm; #";
	return $_SKIN -> draw_form_field_hidden (@_);	
}

################################################################################

sub draw_form_field_hgroup {

	my ($options, $data) = @_;
			
	foreach my $item (@{$options -> {items}}) {
		next if $item -> {off};
		$item -> {label} .= ': ' if $item -> {label} && !$item -> {no_colon};
		$item -> {type}   = 'static' if $_REQUEST {__read_only} || $options -> {read_only} || $item -> {read_only};
		$item -> {type} ||= 'string';
		$item -> {html}   = &{'draw_form_field_' . $item -> {type}} ($item, $data);
	}
	
	return $_SKIN -> draw_form_field_hgroup (@_);
		
}

################################################################################

sub draw_form_field_text {

	my ($options, $data) = @_;
	
	$options -> {value}   ||= $data -> {$options -> {name}};
	$options -> {value} =~ s/\"/\&quot\;/gsm; #";
	$options -> {cols} ||= 60;
	$options -> {rows} ||= 25;

	$options -> {attributes} -> {class} ||= 'form-active-inputs';	
	$options -> {attributes} -> {readonly} = 1 if $_REQUEST {__read_only} or $options -> {read_only};	
	$options -> {attributes} -> {tabindex} = ++ $_REQUEST {__tabindex};
	
	return $_SKIN -> draw_form_field_text (@_);

}

################################################################################

sub draw_form_field_password {

	my ($options, $data) = @_;

	$options -> {size} ||= $conf -> {size} || 120;	
	$options -> {attributes} -> {tabindex} = ++ $_REQUEST {__tabindex};
	
	return $_SKIN -> draw_form_field_password (@_);
	
}

################################################################################

sub draw_form_field_static {

	my ($options, $data) = @_;
		
	if ($options -> {add_hidden}) {
		$options -> {hidden_name}  ||= '_' . $options -> {name};
		$options -> {hidden_value} ||= $data    -> {$options -> {name}};
		$options -> {hidden_value} ||= $options -> {value};
		$options -> {hidden_value} =~ s/\"/\&quot\;/gsm; #";
	}	

	if ($options -> {href} && !$_REQUEST {__edit}) {	
		check_href ($options);
	}
	else {
		delete $options -> {href};
	}
	
		
	my $value = $data -> {$options -> {name}};	

	my $static_value = '';
	
	if (ref $value eq ARRAY) {
	
		my %v = (map {$_ => 1} @$value);
		
		$static_value = [];
		
		foreach my $pv (@{$options -> {values}}) {
		
			push @$static_value, $pv if $v {$pv -> {id}};
			
			foreach my $ppv (@{$pv -> {items}}) {
				push @$static_value, $ppv if $v {$ppv -> {id}};
			}
			
		}						
		
	}
	else {
	
		if (ref $options -> {values} eq ARRAY) {
		
			my ($item) = grep {$_ -> {id} == $value} @{$options -> {values}};
						
			$static_value = $item -> {label} . ' ';
			
			if ($item -> {type} eq 'hgroup') {
				$item -> {read_only} = 1;
				$static_value .= draw_form_field_hgroup ($item, $data);
			}
			elsif ($item -> {type} || $item -> {name}) {
				$static_value .= draw_form_field_static ($item, $data);
			}

		}
		elsif (ref $options -> {values} eq HASH) {
			$static_value = $options -> {values} -> {$value};
		}
		else {
			$static_value = $options -> {value} || $value;
		}
		
	}
		
	$options -> {value} = $static_value;		
	$options -> {value} = format_picture ($options -> {value}, $options -> {picture}) if $options -> {picture};
	
	return $_SKIN -> draw_form_field_static (@_);
			
}

################################################################################

sub draw_form_field_checkbox {

	my ($options, $data) = @_;
	
	$options -> {attributes} -> {checked}  = 1 if $options -> {checked} || $data -> {$options -> {name}};
	$options -> {attributes} -> {tabindex} = ++ $_REQUEST {__tabindex};
	
	return $_SKIN -> draw_form_field_checkbox (@_);
	
}

################################################################################

sub draw_form_field_radio {

	my ($options, $data) = @_;
			
	$options -> {values} = [ grep { !$_ -> {off} } @{$options -> {values}} ];

	foreach my $value (@{$options -> {values}}) {
	
		$value -> {attributes} -> {tabindex} = ++ $_REQUEST {__tabindex};
		$value -> {attributes} -> {checked} = 1 if $data -> {$options -> {name}} == $value -> {id};
					
		$value -> {type} ||= 'select' if $value -> {values};		
		$value -> {type} or next;
			
		my $renderrer = "draw_form_field_$$value{type}";
		
		$value -> {html} = &$renderrer ($value, $data);
		delete $value -> {attributes} -> {class};
						
	}
			
	return $_SKIN -> draw_form_field_radio (@_);
	
}

################################################################################

sub draw_form_field_select {

	my ($options, $data) = @_;
	
	$options -> {max_len} ||= $conf -> {max_len};
	$options -> {attributes} -> {class} ||= 'form-active-inputs';	
	$options -> {attributes} -> {tabindex} = ++ $_REQUEST {__tabindex};

	if ($options -> {rows}) {
		$options -> {attributes} -> {multiple} = 1;	
		$options -> {attributes} -> {size} = $options -> {rows};	
	}

	foreach my $value (@{$options -> {values}}) {
		
		$value -> {selected} = (($value -> {id} eq $data -> {$options -> {name}}) or ($value -> {id} eq $options -> {value})) ? 'selected' : '';
		$value -> {label} = trunc_string ($value -> {label}, $options -> {max_len});
		$value -> {id} =~ s{\"}{\&quot;}g; #";
		
	}

	if (defined $options -> {other}) {
	
		ref $options -> {other} or $options -> {other} = {href => $options -> {other}, label => $i18n -> {voc}};
		
		check_href ($options -> {other});
		
		$options -> {other} -> {href} =~ s{([\&\?])select\=\w+}{$1};
		$options -> {other} -> {width}  ||= 600;
		$options -> {other} -> {height} ||= 400;
		
		$options -> {onChange} = <<EOJS;
		
			if (this.options[this.selectedIndex].value == -1 && window.confirm ('$$i18n{confirm_open_vocabulary}')) {

				var fname = '_$$options{name}_iframe';
				var f = document.getElementById (fname);

				var dname = '_$$options{name}_div';
				var d = document.getElementById (dname);

				f.src = '${$$options{other}}{href}&select=$$options{name}';
				
				d.style.top   = this.offsetTop + this.offsetParent.offsetTop + this.offsetParent.offsetParent.offsetTop;
				d.style.left  = this.offsetLeft + this.offsetParent.offsetLeft + this.offsetParent.offsetParent.offsetLeft;
				d.style.display = 'block';
				this.style.display = 'none';
				
				d.focus ();
				
			}
EOJS

	}		

	if (defined $options -> {detail}) {
		my $h = {href => {}};
		check_href ($h);
		$options -> {onChange} = qq{activate_link ('$$h{href}&__only_field=$$options{detail}&__only_form=' + this.form.name + '&_$$options{name}=' + this.options[this.selectedIndex].value, 'invisible');}
	}

	return $_SKIN -> draw_form_field_select (@_);
	
}

################################################################################

sub draw_form_field_checkboxes {

	return $_SKIN -> draw_form_field_checkboxes (@_);
	
}

################################################################################

sub draw_form_field_image {

	return $_SKIN -> draw_form_field_image (@_);

}

################################################################################

sub draw_form_field_color {

	my ($options, $data) = @_;

	$options -> {value} ||= $data -> {$options -> {name}};

	return $_SKIN -> draw_form_field_color (@_);

}

################################################################################

sub draw_form_field_iframe {
	
	my ($options, $data) = @_;

	return $_SKIN -> draw_form_field_iframe (@_);

}

################################################################################

sub draw_form_field_htmleditor {
	
	my ($options, $data) = @_;
		
	push @{$_REQUEST{__include_js}}, 'rte/fckeditor';
	
	$options -> {value} ||= $data -> {$options -> {name}};
		
	$options -> {value} =~ s{\\}{\\\\}gsm;
	$options -> {value} =~ s{\"}{\\\"}gsm; #"
	$options -> {value} =~ s{\'}{\\\'}gsm;
	$options -> {value} =~ s{[\n\r]+}{\\n}gsm;

	return $_SKIN -> draw_form_field_htmleditor (@_);

}

################################################################################

sub draw_toolbar {

	my ($options, @buttons) = @_;
	
	return '' if $options -> {off};	
	
	$_REQUEST {__toolbars_number} ||= 0;
		
	my $form_name = $_REQUEST {__toolbars_number} ? 'toolbar_form_' . $_REQUEST {__toolbars_number} : 'toolbar_form';
	$_REQUEST {__toolbars_number} ++;

	if ($_REQUEST {select}) {

		hotkeys (
			{
				code => 27,
				data => 'cancel',
			},
		);

		unshift @buttons, {
			icon    => 'cancel',
			id      => 'cancel',
			label   => $i18n -> {close},
			href    => "javaScript:window.parent.restoreSelectVisibility('_$_REQUEST{select}', true);window.parent.focus();",
		};
		
	}
	
	foreach my $button (@buttons) {
	
		if (ref $button eq HASH) {
			next if $button -> {off};
			$button -> {type} ||= 'button';
			$button -> {html} = &{'draw_toolbar_' . $button -> {type}} ($button);
		}
		else {
			$button = {html => $button, type => 'input_raw'};
		}
		
		push @{$options -> {buttons}}, $button;

	};
	
	return $_SKIN -> draw_toolbar ($options);
	
}

################################################################################

sub draw_toolbar_break {
	my ($options) = @_;
	return $_SKIN -> draw_toolbar_break ($options);
}

################################################################################

sub draw_toolbar_button {

	my ($options) = @_;
			
	$conf -> {kb_options_buttons} ||= {ctrl => 1, alt => 1};	
	
	register_hotkey ($options, 'href', $options, $conf -> {kb_options_buttons});
	
	check_href ($options);
			
	if (
		$conf -> {core_auto_esc} == 2 && 
		(	
			$options -> {keep_esc} ||
			(!exists $options -> {keep_esc} && $options -> {icon} eq 'create' && $options -> {href} !~ /action=create/)
		)
	) {
		
		$options -> {href} =~ s{\&?__last_query_string=\d*}{}gsm;
		$options -> {href} .= "&__last_query_string=$_REQUEST{__last_last_query_string}";

		$options -> {href} =~ s{\&?__last_scrollable_table_row=\d*}{}gsm;
		$options -> {href} .= "&__last_scrollable_table_row=$_REQUEST{__last_scrollable_table_row}";
	
	}		

	if ($options -> {confirm}) {
		$options -> {target} ||= '_self';
		my $salt = rand;
		my $msg = js_escape ($options -> {confirm});
		$options -> {href} =~ s{\%}{\%25}gsm; 		# wrong, but MSIE uri_unescapes the 1st arg of window.open :-(
		$options -> {href} = qq [javascript:if (confirm ($msg)) {nope('$$options{href}', '$$options{target}')}];
	} 
	
	if ($options -> {href} =~ /^java/) {
		$options -> {target} = '_self';
	}

	if ($options -> {hotkey}) {
		$options -> {id} ||= $options;
		$options -> {hotkey} -> {data}    = $options -> {id};
		$options -> {hotkey} -> {off}     = $options -> {off};
		hotkey ($options -> {hotkey});
	}	
		
	$options -> {id} ||= '' . $options;
	
	return $_SKIN -> draw_toolbar_button ($options);

}

################################################################################

sub draw_toolbar_input_select {

	my ($options) = @_;
		
	$options -> {max_len} ||= $conf -> {max_len};
	
	foreach my $value (@{$options -> {values}}) {		
		$value -> {label}    = trunc_string ($value -> {label}, $options -> {max_len});						
		$value -> {selected} = (($value -> {id} eq $_REQUEST {$options -> {name}}) or ($value -> {id} eq $options -> {value})) ? 'selected' : '';
	}

	return $_SKIN -> draw_toolbar_input_select ($options);
	
}

################################################################################

sub draw_toolbar_input_checkbox {

	my ($options) = @_;
	
	$options -> {checked} = $_REQUEST {$options -> {name}} ? 'checked' : '';

	return $_SKIN -> draw_toolbar_input_checkbox ($options);
	
}

################################################################################

sub draw_toolbar_input_submit {

	return $_SKIN -> draw_toolbar_input_submit (@_);

}

################################################################################

sub draw_toolbar_input_text {

	my ($options) = @_;
	
	$options -> {value} ||= $_REQUEST {$options -> {name}};	
	$options -> {size} ||= 15;		
	$options -> {keep_params} ||= [keys %_REQUEST];
	
	return $_SKIN -> draw_toolbar_input_text (@_);

}

################################################################################

sub draw_toolbar_input_datetime {

	my ($options) = @_;
			
	if ($r -> header_in ('User-Agent') =~ /MSIE 5\.0/) {
		$options -> {size} ||= $options -> {no_time} ? 11 : 16;
		return draw_toolbar_input_text ($options, $data);
	}
		
	unless ($options -> {format}) {
	
		if ($options -> {no_time}) {
			$options -> {format}  ||= $i18n -> {_format_d} || '%d.%m.%Y';
			$options -> {size}    ||= 11;
		}
		else {
			$options -> {format}  ||= $i18n -> {_format_dt} || '%d.%m.%Y %k:%M';
			$options -> {size}    ||= 16;
		}
	
	}
			
	$options -> {attributes} -> {size}      = $options -> {size};
	$options -> {attributes} -> {maxlength} = $options -> {size};

	$options -> {value}      ||= $_REQUEST {$$options{name}};
	$options -> {attributes} -> {value} = $options -> {value};
	
	$options -> {attributes} -> {id} = 'input' . $options -> {name};

	$options -> {attributes} -> {tabindex} = ++ $_REQUEST {__tabindex};
	
	return $_SKIN -> draw_toolbar_input_datetime (@_);
	
}

################################################################################

sub draw_toolbar_input_date {

	my ($_options) = @_;

	$_options -> {no_time} = 1;

	return draw_toolbar_input_datetime ($_options);
	
}

################################################################################

sub draw_toolbar_pager {

	my ($options) = @_;
	
	$options -> {portion} ||= $conf -> {portion};

	$options -> {start} = $_REQUEST {start} + 0;

	$conf -> {kb_options_pager} ||= $conf -> {kb_options_buttons};
	$conf -> {kb_options_pager} ||= {ctrl => 1};
	
	if ($options -> {start} > $options -> {portion}) {
		$options -> {rewind_url} = create_url (start => 0);
	}
	
	if ($options -> {start} > 0) {

		hotkey ({
			code => 33, 
			data  => '_pager_prev', 
			%{$conf -> {kb_options_pager}},
		});
		
		$options -> {back_url} = create_url (start => ($options -> {start} - $options -> {portion} < 0 ? 0 : $options -> {start} - $options -> {portion}));

	}
	
	if ($options -> {start} + $$options{cnt} < $$options{total} || $$options{total} == -1) {
	
		hotkey ({
			code => 34, 
			data  => '_pager_next', 
			%{$conf -> {kb_options_pager}},
		});
		
		$options -> {next_url} = create_url (start => $options -> {start} + $options -> {portion});

	}
	
	$options -> {infty_url}   = create_url (__infty => 1 - $_REQUEST {__infty}, __no_infty => 1 - $_REQUEST {__no_infty});
	
	$options -> {infty_label} = $options -> {total} > 0 ? $options -> {total} : $i18n -> {infty};

	return $_SKIN -> draw_toolbar_pager (@_);

}

################################################################################

sub draw_centered_toolbar_button {

	my ($options) = @_;
	
	if ($options -> {preset}) {
		my $preset = $conf -> {button_presets} -> {$options -> {preset}};
		$options -> {hotkey}     ||= $preset -> {hotkey};
		$options -> {icon}       ||= $preset -> {icon};
		$options -> {label}      ||= $i18n -> {$preset -> {label}};
		$options -> {label}      ||= $preset -> {label};
		$options -> {confirm}    ||= $i18n -> {$preset -> {confirm}};
		$options -> {confirm}    ||= $preset -> {confirm};
		$options -> {preconfirm} ||= $preset -> {preconfirm};
	}	

	if ($options -> {hotkey}) {
		$options -> {id} ||= $options;
		$options -> {hotkey} -> {data}    = $options -> {id};
		$options -> {hotkey} -> {off}     = $options -> {off};
		hotkey ($options -> {hotkey});
	}

	$options -> {href} = 'javaScript:' . $options -> {onclick} if $options -> {onclick};

	check_href ($options);
	
	if (
		$conf -> {core_auto_esc} == 2 && 
		!(	
			$options -> {keep_esc} ||
			(!exists $options -> {keep_esc} && $options -> {icon} eq 'cancel')
		)
	) {
		$options -> {href} =~ s{__last_query_string\=\d+}{__last_query_string\=$_REQUEST{__last_last_query_string}}gsm;
	}

	my $target = $options -> {target};
	$target ||= '_self';

	if ($options -> {confirm}) {
		my $salt = rand;
		my $msg = js_escape ($options -> {confirm});
		$options -> {preconfirm} ||= 1;
		$options -> {href} =~ s{\%}{\%25}gsm; 		# wrong, but MSIE uri_unescapes the 1st arg of window.open :-(
		$options -> {href} = qq [javascript:if (!($$options{preconfirm}) || ($$options{preconfirm} && confirm ($msg))) {nope('$$options{href}', '$target')} else {window.parent.document.body.style.cursor = 'normal'; nop ();} ];
	} 	

	if ($options -> {href} =~ /^java/) {
		$options -> {target} = '_self';
	}
	
	return $_SKIN -> draw_centered_toolbar_button (@_);

}

################################################################################

sub draw_centered_toolbar {

	$_REQUEST{lpt} and return '';

	my ($options, $list) = @_;

#	our $__last_centered_toolbar_id = 'toolbar_' . int $list;

	$options -> {cnt} = 0;
	
	foreach (@$list) {	
		next if $_ -> {off};
		$_ -> {html} = draw_centered_toolbar_button ($_);
		$options -> {cnt} ++;
	}

	return $_SKIN -> draw_centered_toolbar (@_);

}

################################################################################

sub draw_esc_toolbar {

	my ($options) = @_;
		
	$options -> {href} = $options -> {esc};
	$options -> {href} ||= "/?type=$_REQUEST{type}";
	check_href ($options);

	draw_centered_toolbar ($options, [
		@{$options -> {left_buttons}},
		@{$options -> {additional_buttons}},
		{
			preset => 'cancel',
			href => $options -> {href}, 
			off  => $options -> {no_esc}, 
		},
		@{$options -> {right_buttons}},
	])
	
}

################################################################################

sub draw_ok_esc_toolbar {

	my ($options, $data) = @_;		
	
	$options -> {href} = $options -> {esc};
	$options -> {href} ||= "/?type=$_REQUEST{type}";
	check_href ($options);

	my $name = $options -> {name};
	$name ||= 'form';
	
	$options -> {label_ok}     ||= $i18n -> {ok};
	$options -> {label_cancel} ||= $i18n -> {cancel};
	$options -> {label_choose} ||= $i18n -> {choose};
	$options -> {label_edit}   ||= $i18n -> {edit};

	draw_centered_toolbar ($options, [
		@{$options -> {left_buttons}},
		{
			preset => 'ok',
			label => $options -> {label_ok}, 
			href => "javaScript:document.$name.fireEvent(\\'onsubmit\\'); document.$name.submit()", 
			off  => $_REQUEST {__read_only},
		},
		{
			preset => 'edit',
			href  => create_url (__last_query_string => $_REQUEST {__last_last_query_string}) . '&__edit=1',
			off   => ((!$conf -> {core_auto_edit} && !$_REQUEST{__auto_edit}) || !$_REQUEST{__read_only} || $options -> {no_edit}),
		},
		{
			preset => 'choose',
			label => $options -> {label_choose},
			href  => js_set_select_option ('', $data),
			off   => (!$_REQUEST {__read_only} || !$_REQUEST {select}),
		},
		@{$options -> {additional_buttons}},
		{
			preset => 'cancel',
			label => $options -> {label_cancel}, 			
			href => $options -> {href}, 
			off  => $options -> {no_esc},
		},
		@{$options -> {right_buttons}},
	 ])
	
}

################################################################################

sub draw_close_toolbar {
	
	my ($options) = @_;		

	draw_centered_toolbar ({}, [
		@{$options -> {left_buttons}},
		@{$options -> {additional_buttons}},
		{
			preset => 'close',     
			href => 'javascript:window.close()',
		},
		@{$options -> {right_buttons}},
	 ])
	
}

################################################################################

sub draw_back_next_toolbar {

	my ($options) = @_;
	
	my $type = $options -> {type};
	$type ||= $_REQUEST {type};
	
	my $back = $options -> {back};
	$back ||= "/?type=$type";
	
	my $name = $options -> {name};
	$name ||= 'form';

	draw_centered_toolbar ($options, [
		@{$options -> {left_buttons}},
		{
			preset => 'back', 
			href => $back, 
		},
		@{$options -> {additional_buttons}},
		{
			preset => 'next', 
			href => '#', 
			onclick => "document.$name.submit()",
		},
		@{$options -> {right_buttons}},
	])
	
}

################################################################################

sub draw_menu {

	my ($types, $cursor, $_options) = @_;
	
	@$types or return '';
	
	$_REQUEST {__no_navigation} and return '';	

	if ($preconf -> {core_show_dump}) {
	
		push @$types, {
			label  => 'Dump',
			name   => '_dump',
			href   => create_url () . '&__dump=1',
			side   => 'right_items',
			target => '_blank',
			no_off => 1,
		};

		push @$types, {
			label  => 'Info',
			href   => "/?type=_object_info&object_type=$_REQUEST{type}&id=$_REQUEST{id}",
			side   => 'right_items',
			no_off => 1,
		} if $_REQUEST {id} && $DB_MODEL -> {tables} -> {$_REQUEST {type}};

		push @$types, {
			label  => 'Proto',
			name   => '_proto',
			href   => create_url () . '&__proto=1&__edit=' . $_REQUEST {__edit},			
			side   => 'right_items',
			target => '_blank',
			no_off => 1,
		};
	
	}

	if ($_options -> {lpt}) {
	
		push @$types, {
			label  => 'MS Excel',
			name   => '_xls',
			href   => create_url (xls => 1, salt => rand * time) . '&__infty=1',
			side   => 'right_items',
			target => 'invisible',
		};
	
	}

	push @$types, {
		label => $i18n -> {Exit},
		name  => '_logout',
		href  => $conf -> {exit_url} || create_url (type => '_logout', id => ''),
		side  => 'right_items',
	};

	foreach my $type (@$types)	{
	
		next if $type -> {off};
	
		$conf -> {kb_options_menu} ||= {ctrl => 1, alt => 1};
	
		register_hotkey ($type, 'href', 'main_menu_' . $type -> {name}, $conf -> {kb_options_menu});
		
		if ($_REQUEST {__edit} && !$type -> {no_off}) {
			$type -> {href} = "javaScript:alert('$$i18n{save_or_cancel}'); document.body.style.cursor = 'normal'; nop ();";
		}
		elsif ($type -> {no_page}) {
			$type -> {href} = "javaScript:document.body.style.cursor = 'normal'; nop ()";
		} 
		else {
			$type -> {href} ||= "/?type=$$type{name}";
			$type -> {href} .= "&role=$$type{role}" if $type -> {role};
			check_href ($type);
		}

		if (ref $type -> {items} eq ARRAY && !$_REQUEST {__edit}) {
			$type -> {vert_menu} = draw_vert_menu ($type -> {name}, $type -> {items});
			$type -> {onhover} = "open_popup_menu ('$$type{name}')";
		}
		else {
			$type -> {onhover} = <<EOJS
	if (last_vert_menu [0]) {
	
		for (var i = 0; i < last_vert_menu.length; i++) {
			if (last_vert_menu [i]) last_vert_menu [i].style.display = 'none';
			last_vert_menu [i] = null;
		}
		
	};
EOJS
		}
		
		$type -> {side  } ||= 'left_items';
		$type -> {target} ||= '_self';

		push @{$_options -> {$type -> {side}}}, $type;
	
	}
	
	return $_SKIN -> draw_menu ($_options);

}

################################################################################

sub draw_vert_menu {

	my ($name, $types, $level) = @_;
	
	$level ||= 0;
	
	$types = [grep {!$_ -> {off}} @$types];
	
	foreach my $type (@$types) {
	
		if (ref $type -> {items} eq ARRAY && !$_REQUEST {__edit}) {

			my $sublevel = $level + 1;
			$type -> {name}     ||= '' . $type if $type -> {items};
			$type -> {vert_menu}  = draw_vert_menu ($type -> {name}, $type -> {items}, $sublevel);
			$type -> {onclick}    = "open_popup_menu ('$$type{name}', $sublevel)";
			
		}
		else {
			
			$type -> {onhover}    = '';
			$type -> {href}     ||= "/?type=$$type{name}";
			$type -> {href}      .= "&role=$$type{role}" if $type -> {role};

			check_href ($type);

			$type -> {onclick} = $type -> {href} =~ /^javascript\:/i ? $' : "activate_link('$$type{href}')";  #'
			$type -> {onclick} =~ s{[\n\r]}{}gsm;
		}
	
	}

	return $_SKIN -> draw_vert_menu ($name, $types, $level);

}

################################################################################

sub js_set_select_option {
	return $_SKIN -> js_set_select_option (@_);
}

################################################################################

sub draw_cells {

	my $options = (ref $_[0] eq HASH) ? shift () : {};
	
	my $result = '';
	
	foreach my $cell (@{$_[0]}) {
	
		$result .= 
			!ref ($cell) || $cell -> {off} || $cell -> {read_only} ? draw_text_cell ($cell, $options) :
			($cell -> {type} eq 'checkbox' || exists $cell -> {checked}) ? draw_checkbox_cell ($cell, $options) :
			($cell -> {type} eq 'button'   || $cell -> {icon}) ? draw_row_button ($cell, $options) :		
			$cell  -> {type} eq 'input'    ? draw_input_cell  ($cell, $options) :
			$cell  -> {type} eq 'radio'    ? draw_radio_cell  ($cell, $options) :
			$cell  -> {type} eq 'select'   ? draw_select_cell ($cell, $options) :
			draw_text_cell ($cell, $options);
	
	}
	
	return $result;
	
}

################################################################################

sub draw_text_cells {
	return draw_cells (@_);	
}

################################################################################

sub draw_row_buttons {
	return draw_cells (@_);	
}

################################################################################

sub _adjust_row_cell_style {

	my ($data, $options) = @_;

	$data -> {attributes} ||= {};
	$data -> {attributes} -> {colspan} = $data -> {colspan} if $data -> {colspan};
	$data -> {attributes} -> {rowspan} = $data -> {rowspan} if $data -> {rowspan};
	
	$data -> {attributes} -> {bgcolor} ||= $data    -> {bgcolor};
	$data -> {attributes} -> {bgcolor} ||= $options -> {bgcolor};

	$data -> {attributes} -> {style} ||= $data    -> {style};
	$data -> {attributes} -> {style} ||= $options -> {style};
	
	unless ($data -> {attributes} -> {style}) {
		delete $data -> {attributes} -> {style};
		$data -> {attributes} -> {class} ||= $data    -> {class};
		$data -> {attributes} -> {class} ||= $options -> {class};
		$data -> {attributes} -> {class} ||= 
			$options -> {is_total} ? 'row-cell-total' : 
			$data -> {attributes} -> {bgcolor} ? 'row-cell-transparent' : 
			'row-cell';
	}	

}

################################################################################

sub draw_text_cell {

	my ($data, $options) = @_;
	
	return '' if ref $data eq HASH && $data -> {hidden};

	ref $data eq HASH or $data = {label => $data};
			
	_adjust_row_cell_style ($data, $options);
				
	$data -> {off} = is_off ($data, $data -> {label});
	
	unless ($data -> {off}) {

		$data -> {max_len} ||= $data -> {size} || $conf -> {size}  || $conf -> {max_len} || 30;

		if (ref $data -> {values} eq ARRAY) {

			foreach (@{$data -> {values}}) {
				$_ -> {id} == $data -> {value} or next;
				$data -> {label} = $_ -> {label};
				last;
			}

		}
		
		$data -> {attributes} -> {align} ||= 'right' if $options -> {is_total};

		check_title ($data);	
		
		if ($_REQUEST {select} && !$options -> {no_select_href} && !$data -> {no_select_href}) {
			$data -> {href}   = js_set_select_option ('', {id => $i -> {id}, label => $data -> {label}});
		}
		else {
			$data -> {href}   ||= $options -> {href} unless $options -> {is_total};
			$data -> {target} ||= $options -> {target};
		}

		if ($data -> {href} && !$_REQUEST {lpt}) {
			check_href ($data);
			$options -> {a_class} ||= 'row-cell';
			$data -> {a_class} ||= $options -> {a_class};
		}
		else {
			delete $data -> {href};
		}

		if ($data -> {picture}) {	
			$data -> {label} = format_picture ($data -> {label}, $data -> {picture});
			$data -> {attributes} -> {align} ||= 'right';
		}
		else {
			$data -> {label} = trunc_string ($data -> {label}, $data -> {max_len});
		}

		exists $options -> {strike} or $data -> {strike} ||= $i -> {fake} < 0;

	}
	
	return $_SKIN -> draw_text_cell ($data, $options);

}

################################################################################

sub draw_radio_cell {

	my ($data, $options) = @_;
	
	return draw_text_cell (@_) if $data -> {read_only} || $data -> {off};
	
	$data -> {value} ||= 1;	
	$data -> {checked} = $data -> {checked} ? 'checked' : '';

	_adjust_row_cell_style ($data, $options);

	check_title ($data);
	
	return $_SKIN -> draw_radio_cell ($data, $options);

}

################################################################################

sub draw_checkbox_cell {

	my ($data, $options) = @_;
	
	return draw_text_cell (@_) if $data -> {read_only} || $data -> {off};

	$data -> {value} ||= 1;	
	$data -> {checked} = $data -> {checked} ? 'checked' : '';

	_adjust_row_cell_style ($data, $options);

	check_title ($data);

	return $_SKIN -> draw_checkbox_cell ($data, $options);
	
}

################################################################################

sub draw_select_cell {

	my ($data, $options) = @_;

	return draw_text_cell ($data, $options) if ($_REQUEST {__read_only} && !$data -> {edit}) || $data -> {read_only} || $data -> {off};
	
	$data -> {max_len} ||= $conf -> {max_len};

	_adjust_row_cell_style ($data, $options);

	foreach my $value (@{$data -> {values}}) {
		$value -> {selected} = ($value -> {id} eq $data -> {value}) ? 'selected' : '';
		$value -> {label} = trunc_string ($value -> {label}, $data -> {max_len});
		$value -> {id} =~ s{\"}{\&quot;}g; #"
	}

	return $_SKIN -> draw_select_cell ($data, $options);
	
}

################################################################################

sub draw_input_cell {

	my ($data, $options) = @_;
	
	return draw_text_cell ($data, $options) if ($_REQUEST {__read_only} && !$data -> {edit}) || $data -> {read_only} || $data -> {off};

	$data -> {size} ||= 30;

	$data -> {attributes} ||= {};
	$data -> {attributes} -> {class} ||= 'row-cell';
	
	_adjust_row_cell_style ($data, $options);
						
	$data -> {label} ||= '';
	
	if ($data -> {picture}) {
		$data -> {label} = format_picture ($data -> {label}, $data -> {picture});
		$data -> {label} =~ s/^\s+//g;
		$data -> {attributes} -> {align} ||= 'right';
	}
			
	check_title ($data);
		
	return $_SKIN -> draw_input_cell ($data, $options);

}

################################################################################

sub draw_row_button {

	my ($options) = @_;	
	
	check_href  ($options);

	if ($options -> {confirm}) {
		my $salt = rand;
		my $msg = js_escape ($options -> {confirm});
		$options -> {href} =~ s{\%}{\%25}gsm; 		# wrong, but MSIE uri_unescapes the 1st arg of window.open :-(
		$options -> {href} = qq [javascript:if (confirm ($msg)) {nope('$$options{href}', '_self')} else {document.body.style.cursor = 'normal'; nop ();}];
	}

	if (
		$conf -> {core_auto_esc} == 2 && 
		! (	
			$options -> {keep_esc} ||
			(!exists $options -> {keep_esc} && $options -> {icon} eq 'delete' && !$_REQUEST {id})
		)

	) {
		$options -> {href} =~ s{__last_query_string\=\d+}{__last_query_string\=$_REQUEST{__last_last_query_string}}gsm;
	}

	if ($options -> {href} =~ /^java/) {
		$options -> {target} = '_self';
	}

	check_title ($options);

	return $_SKIN -> draw_row_button ($options);

}

################################################################################

sub draw_table_header {

	my ($rows) = @_;
	
	ref $rows -> [0] eq ARRAY or $rows = [$rows];
	
	return $_SKIN -> draw_table_header ($rows, [map {draw_table_header_row ($_)} @$rows]);
	
}

################################################################################

sub draw_table_header_row {

	my ($cells) = @_;
		
	return $_SKIN -> draw_table_header_row ($rows, [map {
		ref $_ eq ARRAY ? (join map {draw_table_header_cell ($_)} @$_) : draw_table_header_cell ($_)
	} @$cells]);
	
}

################################################################################

sub draw_table_header_cell {

	my ($cell) = @_;
	
	ref $cell eq HASH or $cell = {label => $cell};

	check_title ($cell);
	
	foreach my $field (qw(href href_asc href_desc)) {
	
		$cell -> {$field} or next;
		
		my $h = {href => $cell -> {$field}};
		check_href ($h);
		$cell -> {$field} => $h -> {href};
	
	}
	
	$cell -> {colspan} ||= 1;
	$cell -> {rowspan} ||= 1;
	
	$cell -> {attributes} ||= {};
	$cell -> {attributes} -> {class}   ||= 'row-cell-header';
	$cell -> {attributes} -> {colspan} ||= $cell -> {colspan};
	$cell -> {attributes} -> {rowspan} ||= $cell -> {rowspan};
	
	return $_SKIN -> draw_table_header_cell ($cell);

}

################################################################################

sub draw_table_row {

	my ($n, $tr_callback) = @_;

	$i -> {__n} = $n;		
	$i -> {__types} = [];
	$i -> {__trs}   = [];
	
	$_SKIN -> {__current_row} = $i;

	my $tr_id = {href => 'id=' . $i -> {id}};
	check_href ($tr_id);
	$tr_id -> {href} =~ s{\&salt=[\d\.]+}{};
	$i -> {__tr_id} = $tr_id -> {href};

	foreach my $callback (@$tr_callback) {

		our $_FLAG_ADD_LAST_QUERY_STRING = 1;

		$_SKIN -> start_table_row if $_SKIN -> {options} -> {no_buffering};
		my $tr = &$callback ();
		$_SKIN -> draw_table_row ($tr) if $_SKIN -> {options} -> {no_buffering};
					
		undef $_FLAG_ADD_LAST_QUERY_STRING;
		
		$tr or next;
		
		$scrollable_row_id ++;
		
		push @{$i -> {__trs}}, $tr unless $_SKIN -> {options} -> {no_buffering};
					
	}
	
	if (@{$i -> {__types}} > 0) {			
		$i -> {__menu} = draw_vert_menu ($i, $i -> {__types});			
	}

}

################################################################################

sub draw_table {

	return '' if $_REQUEST {__only_form};

	my $headers = [];

	unless (ref $_[0] eq CODE or (ref $_[0] eq ARRAY and ref $_[0] -> [0] eq CODE)) {
		$headers = shift;
	}

	my ($tr_callback, $list, $options) = @_;
	
	$options -> {type}   ||= $_REQUEST{type};
	
	$options -> {action} ||= 'add';
	$options -> {name}   ||= 'form';
	$options -> {header}   = draw_table_header ($headers) if @$headers > 0;

	return '' if $options -> {off};		

	ref $tr_callback eq ARRAY or $tr_callback = [$tr_callback];
		
	if (ref $options -> {title} eq HASH) {
				
		unless ($_REQUEST {select}) {
			$options -> {title} -> {height} ||= 10;
			$options -> {title} = 
				draw_hr (%{$options -> {title}}) .
				draw_window_title ($options -> {title}) if $options -> {title} -> {label};
		}
		
	}
	
	if (ref $options -> {top_toolbar} eq ARRAY) {			
		$options -> {top_toolbar} = draw_toolbar (@{ $options -> {top_toolbar} });
	}
	
	if (ref $options -> {path} eq ARRAY) {
		$options -> {path} = draw_path ({}, $options -> {path});
	}
	
	if ($options -> {'..'} && !$_REQUEST{lpt}) {
	
		my $url = $_REQUEST {__path} -> [-1];
		if ($conf -> {core_auto_esc} > 0 && $_REQUEST {__last_query_string}) {
			$url = esc_href ();
		}

		our $_FLAG_ADD_LAST_QUERY_STRING = 1;

		$options -> {dotdot} = draw_text_cell ({
			a_id  => 'dotdot',
			label => '..',
			href  => $url,
			no_select_href => 1,
			colspan => 0 + @$headers,
		});
		
		$scrollable_row_id ++;
		
		undef $_FLAG_ADD_LAST_QUERY_STRING;

		hotkey ({code => Esc, data => 'dotdot'});

	}

	$_SKIN -> start_table ($options) if $_SKIN -> {options} -> {no_buffering};

	my $n = 1;
	
	if (ref $list eq 'DBI::st') {
	
		while (our $i = $list -> fetchrow_hashref) {
			draw_table_row ($n++, $tr_callback);
		}
		
		$list -> finish;
		
	}
	else {

		foreach our $i (@$list) {
			draw_table_row ($n++, $tr_callback);
		}
		
	}
	
	my $html = $_SKIN -> draw_table ($tr_callback, $list, $options);
	
	$lpt = 1 if $options -> {lpt};
	
	return $html;

}

################################################################################

sub draw_tr {

	### O B S O L E T E !!!
	
	my ($options, @tds) = @_;	
	return qq {<tr>@tds</tr>};

}

################################################################################

sub draw_one_cell_table {

	### A B A N D O N E D !!!

	my ($options, $body) = @_;
	return $_SKIN -> draw_one_cell_table ($options, $body);

}

################################################################################

sub draw_page {

	my ($page) = @_;
	
	$_REQUEST {lpt} ||= $_REQUEST {xls};
	$_REQUEST {__read_only} = 1 if ($_REQUEST {lpt});
		
	delete $_REQUEST {__response_sent};
	
	$page -> {body} = '';

	my ($selector, $renderrer);
	
	unless ($_REQUEST {error}) {
	
		if ($_REQUEST {id}) {
			$selector  = 'get_item_of_' . $page -> {type};
			$renderrer = 'draw_item_of_' . $page -> {type};
		} 
		elsif ($_REQUEST {dbf}) {
			$selector  = 'select_' . $page -> {type};
			$renderrer = 'dbf_write_' . $page -> {type};
		} 
		else {
			$selector  = 'select_' . $page -> {type};
			$renderrer = 'draw_' . $page -> {type};
		}
		
		undef $page -> {content};		
		
		eval { $page -> {content} = call_for_role ($selector)};

		if ($@) {
			warn $@;
			$_REQUEST {error} = $@;
		}
		
		return '' if $_REQUEST {__response_sent};
		
		return $_SKIN -> draw_page ($page) if !$_REQUEST {error} && $_SKIN -> {options} -> {no_presentation};

		if ($conf -> {core_auto_edit} && $_REQUEST {id} && ref $page -> {content} eq HASH && $page -> {content} -> {fake} > 0) {
			$_REQUEST {__edit} = 1;
		}
						
		if ($_REQUEST {__popup}) {
			$_REQUEST {__read_only} = 1;
			$_REQUEST {__pack} = 1;
			$_REQUEST {__no_navigation} = 1;
		}
		
		our @scan2names = ();	
		our $scrollable_row_id = 0;
		our $lpt = 0;

		eval { 
			$_SKIN -> start_page ($page) if $_SKIN -> {options} -> {no_buffering};
			$page  -> {auth_toolbar} = draw_auth_toolbar ();
			$page  -> {body} 	= call_for_role ($renderrer, $page -> {content}); 
			$page  -> {menu}         = draw_menu ($page -> {menu}, $page -> {highlighted_type}, {lpt => $lpt});
		};
		
		$page -> {scan2names} = \@scan2names;
		
		if ($@) {
			warn $@;
			$_REQUEST {error} = $@;
		}
						
	}

	if ($_REQUEST {error}) {
		
		if ($_REQUEST {error} =~ s{^\#(\w+)\#\:}{}) {
			$page -> {error_field} = $1;
		}

		return $_SKIN -> draw_error_page ($page);		
		
	}
		
	return $_SKIN -> draw_page ($page);		
		
}

1;