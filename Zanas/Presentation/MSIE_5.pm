################################################################################

sub MSIE_5_register_hotkey {

	my ($hashref, $type, $data) = @_;

	$hashref -> {label} =~ s{\&(.)}{<u>$1</u>} or return;
	
	my $c = $1;
	
	my $code = 0;
	
	if ($c eq '<') {
		$code = 37;
	}
	elsif ($c eq '>') {
		$code = 39;
	}
	elsif (lc $c eq 'ж') {
		$code = 186;
	}
	elsif (lc $c eq 'э') {
		$code = 222;
	}
	else {
		$c =~ y{…÷” ≈Ќ√Ўў«’Џ‘џ¬јѕ–ќЋƒ∆Ёя„—ћ»“№Ѕёйцукенгшщзхъфывапролджэ€чсмитьбю}{qwertyuiop[]asdfghjkl;'zxcvbnm,.qwertyuiop[]asdfghjkl;'zxcvbnm,.};
		$code = (ord ($c) - 32);
	}


	push @scan2names, {
		code => $code,
		type => $type,
		data => $data,
	};

}

################################################################################

sub MSIE_5_handle_hotkey_focus {

	my ($r) = @_;
	
	<<EOJS
		if (window.event.keyCode == $$r{code} && window.event.altKey && window.event.ctrlKey) {
			document.form.$$r{data}.focus ();
			event.returnValue = false;
		}
EOJS

}

################################################################################

sub MSIE_5_handle_hotkey_href {

	my ($r) = @_;
	
	<<EOJS
		if (window.event.keyCode == $$r{code} && window.event.altKey && window.event.ctrlKey) {
			window.location.href = document.getElementById ('$$r{data}').href + '&_salt=@{[rand]}';
		}
EOJS

}

################################################################################

sub MSIE_5_js_escape {
	my ($s) = @_;	
	$s =~ s/\"/\'/gsm;
	$s =~ s{[\n\r]+}{ }gsm;
	$s =~ s{\'}{\\\'}g; #'
	return "'$s'";	
}

################################################################################

sub MSIE_5_draw_page {

	my ($page) = @_;
	
	$_REQUEST {lpt} ||= $_REQUEST {xls};
		
	delete $_REQUEST {__response_sent};
	
	my $body = '';

	my ($selector, $renderrer);
	
	our @scan2names = ();
	
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
		
		my $content;
		
		eval {
			$content = call_for_role ($selector);
		};
		
		print STDERR $@ if $@;
				
		return '' if $_REQUEST {__response_sent};

		if ($_REQUEST {__popup}) {
			$_REQUEST {__read_only} = 1;
			$_REQUEST {__pack} = 1;
			$_REQUEST {__no_navigation} = 1;
		}

		eval {
			$body = call_for_role ($renderrer, $content);
		};
		
		$_REQUEST {error} = $@ if $@;
		
	}

	if ($_REQUEST {error}) {
	
		my $message = js_escape ($_REQUEST {error});
				
		my $html = <<EOH;
			<html>
				<head></head>
				<body onLoad="history.go (-1); alert($message);">
				</body>
			</html>				
EOH

		return $html;
		
	}
	
	if ($_REQUEST{dbf}) {	
		return $body;
	}
	elsif ($_REQUEST{lpt}) {
	
		$body =~ s{^.*?\<table[^\>]*lpt\=\"?1\"?[^\>]*\>}{<table border cellspacing=0 cellpadding=5>}sm; #"
	
		return <<EOH;
			<html>
				<head>
					<title>Ќѕ‘</title>
				</head>
				<body bgcolor=white leftMargin=0 topMargin=0 marginwidth="0" marginheight="0">
					$body
				</body>
			</html>
EOH

	}
	
	$_USER -> {role} eq 'admin' and $_REQUEST{id} or my $lpt = $body =~ s{<table[^\>]*lpt\=\"?1\"?[^\>]*\>}{\<table cellspacing\=1 cellpadding\=5 width\=100\%\>}gsm; #"
	
	my $menu = draw_menu ($page -> {menu}, $page -> {highlighted_type});
	
	$_REQUEST {__scrollable_table_row} ||= 0;
	
	my $meta_refresh = $_REQUEST {__meta_refresh} ? qq{<META HTTP-EQUIV=Refresh CONTENT="$_REQUEST{__meta_refresh}; URL=@{[create_url()]}">} : '';	
	
	my $auth_toolbar = draw_auth_toolbar ({lpt => $lpt});

	my $keepalive = $_REQUEST{sid} ? <<EOH : '';
		<iframe name=keepalive src="/?keepalive=$_REQUEST{sid}" width=0 height=0>
		</iframe>
EOH
	
	
	return <<EOH;
		<html>
			<head>
				<title>$$conf{page_title}</title>
				<meta name="Generator" content="Zanas/MSIE5 $Zanas::VERSION">
				$meta_refresh
				
				<LINK href="/zanas.css" type=text/css rel=STYLESHEET>
				@{[ map {<<EOJS} @{$_REQUEST{__include_css}} ]}
					<LINK href="/i/$_.css" type=text/css rel=STYLESHEET>
EOJS

					<script src="/navigation.js">
					</script>
				@{[ map {<<EOCSS} @{$_REQUEST{__include_js}} ]}
					<script type="text/javascript" src="/i/${_}.js">
					</script>
EOCSS
				<script>
					var scrollable_table = null;
					var scrollable_table_row = 0;
					var scrollable_table_row_cell = 0;						
					var scrollable_table_row_cell_old_style = '';
					var is_dirty = false;					
					var scrollable_table_is_blocked = false;
					var q_is_focused = false;					
					var scrollable_rows = new Array();									
										
				</script>
			</head>
			<body bgcolor=white leftMargin=0 topMargin=0 marginwidth="0" marginheight="0" name="body" id="body">

				<script for="body" event="onload">

					@{[ $_REQUEST {__pack} ? <<EOF : '']}
						var newWidth  = document.all ['bodyArea'].offsetWidth + 10;
						var newHeight = document.all ['bodyArea'].offsetHeight + 30;
						window.resizeTo (newWidth, newHeight);						
						window.moveTo ((screen.width - newWidth) / 2, (screen.height - newHeight) / 2);
EOF
							
					var tables = document.body.getElementsByTagName ('table');

					if (tables != null) {										
						for (var i = 0; i < tables.length; i++) {
						
							if (tables [i].id != 'scrollable_table') continue;
							
							var rows = tables [i].tBodies (0).rows;
							
							for (var j = 0; j < rows.length; j++) {
								scrollable_rows = scrollable_rows.concat (rows [j]);
							}
						}					
					}
									
					scrollable_table = getElementById ('scrollable_table');
							
					if (scrollable_table) {				
				
						scrollable_table = scrollable_table.tBodies (0);
					
						scrollable_table_row = $_REQUEST{__scrollable_table_row};
						scrollable_table_row_cell = 0;

						if (scrollable_rows.length > 0) {
							scrollable_table_row_cell_old_style = scrollable_rows [scrollable_table_row].cells [scrollable_table_row_cell].className;
							scrollable_rows [scrollable_table_row].cells [scrollable_table_row_cell].className = 'txt6';
						}
						else {
							scrollable_table = null;
						}
						
					}
					
					var focused_inputs = getElementsByName ('$_REQUEST{__focused_input}');
					
					if (focused_inputs != null && focused_inputs.length > 0) {
						focused_inputs [0].focus ();
					}
					else {					
						var inputs = document.body.getElementsByTagName ('input');
						if (inputs != null) {
							for (var i = 0; i < inputs.length; i++) {
								if (inputs [i].type != 'text') continue;
								if (inputs [i].name == 'q') break;
								inputs [i].focus ();
								break;
							}
						}
					}

					@{[ $_REQUEST {__blur_all} ? <<EOF : '']}
					
					if (inputs != null) {										
						for (var i = 0; i < inputs.length; i++) {
							inputs [i].blur ();
						}					
					}

EOF
				</script>

				<script for="body" event="onkeydown">												
					if (window.event.keyCode == 88 && window.event.altKey) document.location.href = '/?_salt=@{[rand]}';					
					handle_basic_navigation_keys ();
					@{[ map {&{"MSIE_5_handle_hotkey_$$_{type}"} ($_)} @scan2names ]}							
				</script>						
				<div id="bodyArea">
					$auth_toolbar			
					$menu
					$body
				</div>
				<iframe name=invisible src="/0.html" width=0 height=0>
				</iframe>
				$keepalive
			</body>
		</html>
EOH
	
}

################################################################################

sub MSIE_5_draw_form_field_button {
	my ($options, $data) = @_;
	my $s = $$data{$$options{name}};
	$s ||= $$options{value};
	$s =~ s/\"/\&quot\;/gsm; #"
	my $onclick = $$options{onclick} || '';
	return qq {<input type="button" name="_$$options{name}" value="$s" onClick="$onclick">};
}

################################################################################

sub MSIE_5_draw_menu {

	my ($types, $cursor) = @_;	
	
	@$types or return '';
	
	$_REQUEST {__no_navigation} and return '';
	
	my ($tr1, $tr2, $tr3) = ('', '', '');

	foreach my $type (@$types)	{
	
		MSIE_5_register_hotkey ($type, 'href', 'main_menu_' . $type -> {name});
	
		$tr1 .= <<EOH;
			<td class=bgr8 rowspan=2><img src="/i/toolbars/n_left.gif" border=0></td>
			<td bgcolor=#ffffff><img height=1 src="/0.gif" width=1 border=0></td>				
			<td class=bgr8 rowspan=2><img src="/i/toolbars/n_right.gif" border=0></td>
EOH
	
#		my $aclass = $$type{name} eq $cursor ? 'lnk1' : 'lnk0';
#		my $tclass = $$type{name} eq $cursor ? 'bgr4' : 'bgr8';

		my ($aclass, $tclass);
		if ($type -> {role}) {
			$aclass = "$$type{name}_for_$$type{role}" eq $cursor ? 'lnk1' : 'lnk0';
			$tclass = "$$type{name}_for_$$type{role}" eq $cursor ? 'bgr4' : 'bgr8';
		} else {
			$aclass = $$type{name} eq $cursor ? 'lnk1' : 'lnk0';
			$tclass = $$type{name} eq $cursor ? 'bgr4' : 'bgr8';
		}

#			<td class=$tclass nowrap>&nbsp;&nbsp;<a class=$aclass id="main_menu_$$type{name}" href="/?type=$$type{name}&sid=$_REQUEST{sid}@{[$_REQUEST{period} ? '&period=' . $_REQUEST {period} : '']}">$$type{label}</a>&nbsp;&nbsp;</td>

		$tr2 .= <<EOH;
			<td class=bgr1><img height=20 src="/0.gif" width=1 border=0></td>
			<td class=$tclass nowrap>&nbsp;&nbsp;<a class=$aclass id="main_menu_$$type{name}" href="/?type=$$type{name}&sid=$_REQUEST{sid}@{[$_REQUEST{period} ? '&period=' . $_REQUEST {period} : '']}@{[$type->{role} ? '&role=' . $type->{role} : '']}">$$type{label}</a>&nbsp;&nbsp;</td>
EOH

		$tr3 .= <<EOH;
			<td class=bgr1><img height=1 src="/0.gif" width=1 border=0></td>
			<td class=bgr1 nowrap><img height=1 src="/0.gif" width=1 border=0></td>
EOH

	}

	return <<EOH;
		<table width="100%" class=bgr8 cellspacing=0 cellpadding=0 border=0>
			<tr>
				<td class=bgr8 width=7><img height=1 src="/0.gif" width=7 border=0></td>
				$tr2
				<td class=bgr1><img height=20 src="/0.gif" width=1 border=0></td>
				<td class=bgr8 width=100%><img height=1 src="/0.gif" width=1 border=0></td>
			<tr>
				<td class=bgr8><img height=1 src="/0.gif" width=1 border=0></td>
				$tr3
				<td class=bgr1><img height=1 src="/0.gif" width=1 border=0></td>
				<td class=bgr8 width=100%><img height=1 src="/0.gif" width=1 border=0></td>
				
		</table>	
EOH
}

################################################################################

sub MSIE_5_draw_hr {

	my (%options) = @_;
	
	$options {height} ||= 1;
	$options {class}  ||= bgr8;	
	
	return <<EOH;
		<table border=0 cellspacing=0 cellpadding=0 width="100%">
			<tr><td class=$options{class}><img src="/0.gif" width=1 height=$options{height}></td></tr>
		</table>
EOH
	
}

################################################################################

sub MSIE_5_draw_input_cell {

	my ($data) = @_;
	
	return '' if $data -> {off};
	
	$data -> {max_len} ||= $conf -> {max_len};
	$data -> {max_len} ||= 30;

	$data -> {size} ||= 30;
	
	$data -> {attributes} ||= {};
	$data -> {attributes} -> {class} ||= 'txt4';
			
	$data -> {a_class} ||= 'lnk4';

	my $txt = trunc_string ($data -> {label}, $data -> {max_len});
	
	$txt ||= '';
	
	my $attributes = dump_attributes ($data -> {attributes});
		
	return qq {<td $attributes><nobr><input onFocus="q_is_focused = true" onBlur="q_is_focused = false" type="text" name="$$data{name}" value="$txt" maxlength="$$data{max_len}" size="$$data{size}"></nobr></td>};

}

################################################################################

sub MSIE_5_draw_checkbox_cell {

	my ($data) = @_;
	my $value = $data -> {value} || 1;
	
	my $checked = $data -> {checked} ? 'checked' : '';

	$data -> {attributes} ||= {};
	$data -> {attributes} -> {class} ||= 'txt4';

	my $attributes = dump_attributes ($data -> {attributes});

	return qq {<td $attributes>&nbsp;} if $data -> {off};	

	return qq {<td $attributes><input type=checkbox name=$$data{name} $checked value='$value'></td>};
	
}

################################################################################

sub MSIE_5_draw_text_cells {

	my $options = (ref $_[0] eq HASH) ? shift () : {};
	
	return join '', map { MSIE_5_draw_text_cell ($_) } @{$_[0]};
	
}


################################################################################

sub MSIE_5_draw_text_cell {

	my ($data) = @_;
		
	return '' if $data -> {off};
	
	$data -> {max_len} ||= $conf -> {max_len};
	$data -> {max_len} ||= 30;
	
	$data -> {attributes} ||= {};
	$data -> {attributes} -> {class} ||= 'txt4';
			
	$data -> {a_class} ||= 'lnk4';
	
	my $txt;
	
	if ($data -> {picture}) {	
		$txt = $number_format -> format_picture ($data -> {label}, $data -> {picture});
		$data -> {attributes} -> {align} ||= 'right';
	}
	else {
		$txt = trunc_string ($data -> {label}, $data -> {max_len});
	}
	
	$txt ||= '&nbsp;';
	
	if ($data -> {href}) {
		check_href ($data);
		my $target = $data -> {target} ? "target='$$data{target}'" : '';
		$txt = qq { <a title="$$data{label}" class=$$data{a_class} $target href="$$data{href}" onFocus="blur()">$txt</a> };
	}
	
	my $attributes = dump_attributes ($data -> {attributes});
	
	return qq {<td $attributes><nobr>$txt</nobr></td>};

}

################################################################################

sub MSIE_5_draw_tr {

	my ($options, @tds) = @_;
	
	return qq {<tr>@tds</tr>};

}

################################################################################

sub MSIE_5_draw_one_cell_table {

	my ($options, $body) = @_;
	
	return <<EOH
	
		@{[ $options -> {js_ok_escape} ? MSIE_5_js_ok_escape () : '' ]}
		
		<table cellspacing=0 cellpadding=0 width="100%">
				<form name=form action=/ method=post enctype=multipart/form-data target=invisible>
					<tr><td class=bgr8>$body
				</form>
		</table>
EOH

}

################################################################################

sub MSIE_5_draw_table_header {

	my ($cell) = @_;
	
	if (ref $cell eq ARRAY) {
	
		my $line = join '', (map {MSIE_5_draw_table_header ($_)} @$cell);
		
		return (ref $cell -> [0] eq ARRAY ? '' : '<tr>') . $line;
							
	}
	elsif (!ref $cell) {
	
		return "<th class=bgr4>$cell\&nbsp;";
		
	}
	
	return '' if $cell -> {off};
	
	$cell -> {label} = "<a class=lnk4 href=\"$$cell{href}\"><b>" . $cell -> {label} . "</b></a>" if $cell -> {href};
	$cell -> {label} .= "\&nbsp;\&nbsp;<a class=lnk4 href=\"$$cell{href_asc}\"><b>\&uarr;</b></a>" if $cell -> {href_asc};
	$cell -> {label} .= "\&nbsp;\&nbsp;<a class=lnk4 href=\"$$cell{href_desc}\"><b>\&darr;</b></a>" if $cell -> {href_desc};
	$cell -> {colspan} ||= 1;
	
	return "<th class=bgr4 colspan=$$cell{colspan}>$$cell{label}\&nbsp;";

}

################################################################################

sub MSIE_5_draw_table {

	my $headers = [];

	unless (ref $_[0] eq CODE or (ref $_[0] eq ARRAY and ref $_[0] -> [0] eq CODE)) {
		$headers = shift;
	}
	
	my ($tr_callback, $list, $options) = @_;
	
	return '' if $options -> {off};
		
	my $ths = @$headers ? '<thead>' . MSIE_5_draw_table_header ($headers) . '</thead>' : '';
	
	my $trs = '';
	
	my @tr_callbacks = ref $tr_callback eq ARRAY ? @$tr_callback : ($tr_callback);
	
	my $n = 0;
	foreach our $i (@$list) {
		$i -> {__n} = $n++;
		foreach my $callback (@tr_callbacks) {
			$trs .= '<tr>';
			$trs .= &$callback ();
			$trs .= '</tr>';
		}
	}
	
	$options -> {type}   ||= $_REQUEST{type};
	$options -> {action} ||= 'add';
	$options -> {name}   ||= 'form';
	
	my $hiddens = '';
	
	foreach my $key (keys %_REQUEST) {
		next if $key =~ /^_/ or $key =~/^(type|action|sid)$/;
		$hiddens .= qq {<input type=hidden name=$key value="$_REQUEST{$key}">};
	}

	return <<EOH
		
		@{[ $options -> {js_ok_escape} ? MSIE_5_js_ok_escape ({name => $options -> {name}, no_ok => $options -> {no_ok}}) : '' ]}
		
		<table cellspacing=0 cellpadding=0 width="100%"><tr><td class=bgr8>
		
			<form name=$$options{name} action=/ method=post enctype=multipart/form-data target=invisible>
			
				<input type=hidden name=type value=$$options{type}> 
				<input type=hidden name=action value=$$options{action}> 
				<input type=hidden name=sid value=$_REQUEST{sid}>
				$hiddens
		
				<table cellspacing=1 cellpadding=5 width="100%" id="scrollable_table">
					$ths
					<tbody>
						$trs
					</tbody>
				</table>
				$$options{toolbar}
			
			</form>
			
		</table>
EOH

}

################################################################################

sub MSIE_5_draw_path {

	$_REQUEST{lpt} and return '';

	my ($options, $list) = @_;
	
	($list and ref $list eq ARRAY and @$list) or return '';

	$options -> {id_param} ||= 'id';
	$options -> {max_len} ||= $conf -> {max_len};
	$options -> {max_len} ||= 30;
	
	$path = '';
	
	my $nowrap = $options -> {multiline} ? '' : 'nowrap';
	
	my $n = 2;
	foreach my $item (@$list) {		
	
		my $name = trunc_string ($item -> {name}, $options -> {max_len});
	
		$path and $path .= '&nbsp;/&nbsp;';
		
		$path and $options -> {multiline} and $path .= '<br>' . ('&nbsp;&nbsp;' x ($n++));
		
		$id_param = $item -> {id_param};
		$id_param ||= $options -> {id_param};
		
		$item -> {cgi_tail} ||= $options -> {cgi_tail};

		$path .= <<EOH;
			<a class=lnk1 href="/?type=$$item{type}&$id_param=$$item{id}&sid=$_REQUEST{sid}&$$item{cgi_tail}">$name</a>
EOH
	
	}

	return draw_hr (height => 10) . <<EOH
		
		<table cellspacing=0 cellpadding=0 width="100%" border=0>
			<tr>
				<td class=bgr5>
					<table cellspacing=0 cellpadding=0 width="100%" border=0>
						<tr>
							<td class=bgr6 colspan=4><img height=1 src="/0.gif" width=1 border=0></td>
						</tr>
						<tr>
<!--						
							<td><img height=14 hspace=4 src="/i/toolbars/4pt.gif" width=2 border=0></td>
-->							
							<td class='header6' $nowrap>&nbsp;$path&nbsp;</td>
							<td>
								<table cellspacing=0 cellpadding=0 width="100%" border=0>
									<tr>
										<td _background="/i/toolbars/4pt.gif" height=15><img height=15  hspace=0 src="/0.gif" width=1 border=0></td>
									</tr>
								</table>
							</td>
							<td align=right><img height=15  src="/0.gif" width=4 border=0></td>
						</tr>
						<tr>
							<td class=bgr8 colspan=4><img height=1 src="/0.gif" width=1 border=0></td>
						</tr>
						<tr>
							<td class=bgr6 colspan=4><img height=1 src="/0.gif" width=1 border=0></td>
						</tr>
					</table>
				</td>
			</tr>
		</table>
EOH

}

################################################################################

sub MSIE_5_draw_window_title {

	my ($options) = @_;
	
	return '' if $options -> {off};
	
	return <<EOH
		<table cellspacing=0 cellpadding=0 width="100%"><tr><td class='header15'><img src="/0.gif" width=1 height=20 align=absmiddle>&nbsp;&nbsp;&nbsp;$$options{label}</table>
EOH

}

################################################################################

sub MSIE_5_draw_toolbar {

	my ($options, @buttons) = @_;
	
	return '' if $options -> {off};	
	
	$_REQUEST {__toolbars_number} ||= 0;
	
	my $form_name = $_REQUEST {__toolbars_number} ? 'toolbar_form_' . $_REQUEST {__toolbars_number} : 'toolbar_form';
	$_REQUEST {__toolbars_number} ++;
	
	return <<EOH
		<table class=bgr5 cellspacing=0 cellpadding=0 width="100%" border=0>
			<form action=/ name=$form_name>
			
				@{[ map {<<EO} @{$options -> {keep_params}} ]}
					<input type=hidden name=$_ value=$_REQUEST{$_}>
EO
					<input type=hidden name=sid value=$_REQUEST{sid}>
				<tr>
					<td class=bgr0 colspan=15><img height=1 src="/0.gif" width=1 border=0></td>
				</tr>
				<tr>
					<td class=bgr6 colspan=15><img height=1 src="/0.gif" width=1 border=0></td>
				</tr>
				<tr>
					<td width=20>
						<table cellspacing=0 cellpadding=0 width=20 border=0>
							<tr>
								<td _background="/i/toolbars/6ptbg.gif"><img height=17 hspace=0 src="/0.gif" width=1 border=0></td>
							</tr>
						</table>
					</td>
					@buttons
					<td width="100%">
						<table cellspacing=0 cellpadding=0 width="100%" border=0>
							<tr>
								<td _background="/i/toolbars/6ptbg.gif"><img height=17 hspace=0 src="/0.gif" width=1 border=0></td>
							</tr>
						</table>
					</td>
					<td align=right><img height=23 src="/0.gif" width=4 border=0></td>
				</tr>
				<tr>
					<td class=bgr8 colspan=15><img height=1 src="/0.gif" width=1 border=0></td>
				</tr>
				<tr>
					<td class=bgr6 colspan=15><img height=1 src="/0.gif" width=1 border=0></td>
				</tr>
			</form>
		</table>
EOH

}

################################################################################

sub MSIE_5_draw_toolbar_button {

	my ($options) = @_;
	
	return '' if $options -> {off};
	
	$options -> {target} ||= '_self';
	
	MSIE_5_register_hotkey ($options, 'href', $options);
	
	check_href ($options);

	if ($options -> {confirm}) {
		my $salt = rand;
		my $msg = js_escape ($options -> {confirm});
		$options -> {href} = qq [javascript:if (confirm ($msg)) {window.open('$$options{href}', '$$options{target}')}];
	} 
	
	return <<EOH
		<td nowrap>&nbsp;<a class=lnk0 href="$$options{href}" id="$options"><b>[$$options{label}]</b></a></td>
		<td><img height=15 hspace=4 src="/i/toolbars/razd1.gif" width=2 border=0></td>
EOH

}

################################################################################

sub MSIE_5_draw_toolbar_input_text {

	my ($options) = @_;
	
	return '' if $options -> {off};

	my $value = $options -> {value};
	$value ||= $_REQUEST{$$options{name}};
	
	my $hiddens = '';
	
	foreach my $key (keys %_REQUEST) {
		next if $key eq $options -> {name} or $key =~ /^_/ or $key eq 'start' or $key eq 'sid';
		$hiddens .= qq {<input type=hidden name=$key value="$_REQUEST{$key}">};
	}
		
	return <<EOH
		<td nowrap>$$options{label}: <input type=text name=$$options{name} value="$value" onFocus="scrollable_table_is_blocked = true; q_is_focused = true" onBlur="scrollable_table_is_blocked = false; q_is_focused = false">$hiddens</td>
		<td><img height=15  hspace=4 src="/i/toolbars/razd1.gif" width=2 border=0></td>
EOH

}

################################################################################

sub MSIE_5_draw_toolbar_pager {

	my ($options) = @_;
	
	$options -> {portion} ||= $conf -> {portion};

	my $start = $_REQUEST {start} + 0;

	my $label = '';	

	if ($start > $options -> {portion}) {
		$url = create_url (start => 0);
		$label .= qq {&nbsp;<a href="$url" class=lnk0 onFocus="blur()"><b>&lt;&lt;</b></a>&nbsp;};
	}

	if ($start > 0) {
		MSIE_5_register_hotkey ({label => '&<'}, 'href', '_pager_prev');
		$url = create_url (start => $start - $options -> {portion});
		$label .= qq {&nbsp;<a href="$url" class=lnk0 id="_pager_prev" onFocus="blur()"><b><u>&lt;</u></b></a>&nbsp;};
	}
	
	$options -> {total} or return '<td nowrap>список пуст<td><img height=15  hspace=4 src="/i/toolbars/razd1.gif" width=2 border=0></td>';
	
	$label .= ($start + 1) . ' - ' . ($start + $$options{cnt}) . ' из ' . $$options{total};
	
	if ($start + $$options{cnt} < $$options{total}) {
	
		MSIE_5_register_hotkey ({label => '&>'}, 'href', '_pager_next');
		$url = create_url (start => $start + $options -> {portion});
		$label .= qq {&nbsp;<a href="$url" class=lnk0 id="_pager_next" onFocus="blur()"><b><u>&gt;</u></b></a>&nbsp;};
	}
	
	return <<EOH
		<td nowrap>$label</td>
		<td><img height=15  hspace=4 src="/i/toolbars/razd1.gif" width=2 border=0></td>
EOH

}

################################################################################

sub MSIE_5_draw_row_button {

	my ($options) = @_;	
	
	return '<td class=bgr0 valign=top nowrap width="1%">&nbsp;' if $options -> {off};
	
#	$options -> {href} = create_url (%{$options -> {href}}) if ref $options -> {href} eq HASH;
	
	check_href ($options);
	
	if ($options -> {confirm}) {
		my $salt = rand;
		my $msg = js_escape ($options -> {confirm});
		$options -> {href} = qq [javascript:if (confirm ($msg)) {window.open('$$options{href}', '_self')}];
	} 
	
	my $title = $options -> {label};
	
	if ($conf -> {core_show_icons}) {	
		$options -> {label} = qq|<img src="/i/buttons/$$options{icon}.gif" alt="$$options{label}" border=0 hspace=0 vspace=0>|
	}
	else {
		$options -> {label} = "\&nbsp;[$$options{label}]\&nbsp;";
	}

	return qq {<td class=bgr4 valign=top nowrap width="1%"><a class=lnk0 title="$title" href="$$options{href}" onFocus="blur()" target="$$options{target}">$$options{label}</a>};

}

################################################################################

sub MSIE_5_draw_row_buttons {

	my ($options, $buttons) = @_;

	return $options -> {off} ? 
		'<td class=bgr4 valign=top nowrap width="1%">&nbsp;':
		(join '', map {draw_row_button ($_)} @$buttons) . '</td>';

}

################################################################################

sub MSIE_5_draw_form_field {

	my ($field, $data) = @_;
		
	if (ref $field eq ARRAY) {
	
		my $html = '';
	
		for (my $i = 0; $i < @$field; $i++) {		
			my $subfield = $field -> [$i];					
			$subfield -> {is_slave} = 1;
			$subfield -> {colspan} = $i == @$field - 1 ? $_REQUEST {__max_cols} - 2 * $i - 1 : 1;
			$html .= MSIE_5_draw_form_field ($subfield, $data);		
		}
		
		return $html;
	
	}

	return '' if $field -> {off};
	
	my $type = $field -> {type};
	$type = 'static' if ($_REQUEST {__read_only} or $field -> {read_only}) and $type ne 'hgroup';	
	$type ||= 'string';
	
	my $html = &{"draw_form_field_$type"} ($field, $data);
	
	MSIE_5_register_hotkey ($field, 'focus', '_' . $field -> {name});	

	$field -> {label} .= '&nbsp;*' if $field -> {mandatory};
	
	$field -> {label} .= ':' if $field -> {label};
	
	$field -> {colspan} ||= $_REQUEST {__max_cols} - 1;
	
	$field -> {label_width} = '20%' unless $field -> {is_slave};
	my $label_width = $field -> {label_width} ? 'width=' . $field -> {label_width} : '';
	my $cell_width  = $field -> {cell_width}  ? 'width=' . $field -> {cell_width}  : '';
		
	return $type eq 'hidden' ? $html : <<EOH;
		<td class='header5' nowrap align=right $label_width>$$field{label}</td>
		<td class=bgr4 colspan=$$field{colspan} $cell_width>$html</td>
EOH

}

################################################################################

sub MSIE_5_draw_form {

	my ($options, $data, $fields) = @_;
	
	my $action = exists $options -> {action} ? $options -> {action} : 'update';
	
	my $type = $options -> {type};
	$type ||= $_REQUEST{type};

	my $id = $options -> {id};
	$id ||= $_REQUEST{id};

	my $name = $options -> {name};
	$name ||= 'form';

	my $target = $options -> {target};
	$target ||= 'invisible';

	my $trs = '';
	my $n = 0;	
	
	my $max_cols = 1;
	
	foreach my $field (@$fields) {
		next unless ref $field eq ARRAY;
		$max_cols = @$field if $max_cols < @$field;
	}
	
	$_REQUEST {__max_cols} = $max_cols * 2;

	foreach my $field (@$fields) {
					
		next if ref $field eq HASH and $field -> {off};
		next if ref $field eq ARRAY and @$field == 0;
					
		$trs .= '<tr>' . MSIE_5_draw_form_field ($field, $data) . '</tr>';
	
	}
	
	my $path = ($data -> {path} && !$_REQUEST{__no_navigation}) ? draw_path ($options, $data -> {path}) : '';
	
	my $bottom_toolbar = 
		exists $options -> {bottom_toolbar} ? $options -> {bottom_toolbar} :		
		$_REQUEST {__no_navigation} ? draw_close_toolbar ($options) :
		$options -> {back} ? draw_back_next_toolbar ($options) :
		$options -> {no_ok} ? draw_esc_toolbar ($options) :
		draw_ok_esc_toolbar ($options);

	return <<EOH
$path<table cellspacing=1 cellpadding=5 width="100%">

			@{[ MSIE_5_js_ok_escape ($options) ]}
			
			<form name=$name action=/ method=post enctype=multipart/form-data target=$target>
				<input type=hidden name=type value=$type> 
				<input type=hidden name=id value=$id> 
				<input type=hidden name=action value=$action> 
				<input type=hidden name=sid value=$_REQUEST{sid}>
				$trs
			</form>
		</table>$bottom_toolbar
EOH

}

################################################################################

sub MSIE_5_js_ok_escape {
	
	my ($options) = @_;
	
	$options -> {name} ||= 'form';
	$options -> {confirm_ok} ||= '—охранить данные?';
	
	$options -> {confirm_ok} = js_escape ($options -> {confirm_ok});

	return <<EOH
	
		<script for="body" event="onkeypress">
		
			if (window.event.keyCode == 27 && (!is_dirty || window.confirm ('”йти без сохранени€ данных?'))) {
				activate_link (document.getElementById ('esc').href);
			}
			
			@{[ $options -> {no_ok} ? '' : <<EOOK ]}
		
			if (window.event.keyCode == 10 && window.confirm ($$options{confirm_ok})) {
				document.$$options{name}.submit ();
			}
EOOK
													
		</script>
		
EOH

}

################################################################################

sub MSIE_5_draw_form_field_string {

	my ($options, $data) = @_;
	
	$options -> {max_len} ||= $conf -> {max_len};	
	$options -> {max_len} ||= $options -> {size};
	$options -> {max_len} ||= 30;		
	
	my $s = $options -> {value};
	$s ||= $$data{$$options{name}};
	if ($options -> {picture}) {
		$s = $number_format -> format_picture ($s , $options -> {picture});
		$s =~ s/^\s+//g; 
	}
	
	$s =~ s/\"/\&quot\;/gsm; #";
	
	my $attributes = dump_attributes ($options -> {attributes});
	
	my $size = $options -> {size} ? "size=$$options{size} maxlength=$$options{size}" : "size=120";	
	return qq {<input $attributes onFocus="scrollable_table_is_blocked = true; q_is_focused = true" onBlur="scrollable_table_is_blocked = false; q_is_focused = false" autocomplete="off" type="text" maxlength="$$options{max_len}" name="_$$options{name}" value="$s" $size onKeyPress="if (window.event.keyCode != 27) is_dirty=true">};
	
}

################################################################################

sub MSIE_5_draw_form_field_datetime {

	my ($options, $data) = @_;
	
	$options -> {max_len} ||= $conf -> {max_len};	
	$options -> {max_len} ||= $options -> {size};
	
	unless ($options -> {format}) {
	
		if ($options -> {no_time}) {
			$conf -> {format_d}   ||= '%d.%m.%Y';
			$options -> {format}  ||= $conf -> {format_d};
			$options -> {max_len} ||= 20;		
			$options -> {size}    ||= 11;
		}
		else {
			$conf -> {format_dt}  ||= '%d.%m.%Y %k:%M';
			$options -> {format}  ||= $conf -> {format_dt};
			$options -> {size}    ||= 16;
		}
	
	}
	
	$options -> {format}  ||= $options -> {no_time} ? $conf -> {format_d} : $conf -> {format_dt};

	my $s = $options -> {value};
	$s ||= $$data{$$options{name}};
	$s =~ s/\"/\&quot\;/gsm; #";
	
	$options -> {attributes} -> {id} = 'input_' . $options -> {name};
	
	$options -> {attributes} -> {readonly} = 1;
	
	my $attributes = dump_attributes ($options -> {attributes});
	
	my $size = $options -> {size} ? "size=$$options{size} maxlength=$$options{size}" : "size=30";	
	
	push @{$_REQUEST {__include_js}},  'jscalendar/calendar', 'jscalendar/lang/calendar-ru', 'jscalendar/calendar-setup';
	push @{$_REQUEST {__include_css}}, 'jscalendar/calendar-win2k-1';
	
	my $shows_time = $options -> {no_time} ? 'false' : 'true';
	
	return <<EOH
		<input $attributes onFocus="scrollable_table_is_blocked = true; q_is_focused = true" onBlur="scrollable_table_is_blocked = false; q_is_focused = false" autocomplete="off" type="text" maxlength="$$options{max_len}" name="_$$options{name}" value="$s" $size onKeyPress="if (window.event.keyCode != 27) is_dirty=true">
		<button id="calendar_trigger_$$options{name}" class="txt7">...</button>
		
		<script type="text/javascript">
			Calendar.setup(
				{
					inputField : "input_$$options{name}",
					ifFormat : "%d.%m.%Y %k:%M",
					showsTime : $shows_time,
					button : "calendar_trigger_$$options{name}"
				}
			);
		</script>

EOH
	
}

################################################################################

sub MSIE_5_draw_form_field_file {
	my ($options, $data) = @_;	
	$options -> {size} ||= 60;
	return qq {<input onFocus="scrollable_table_is_blocked = true; q_is_focused = true" onBlur="scrollable_table_is_blocked = false; q_is_focused = false" type="file" name="_$$options{name}" size=$$options{size} onKeyPress="if (window.event.keyCode != 27) is_dirty=true">};
}

################################################################################

sub MSIE_5_draw_form_field_hidden {
	my ($options, $data) = @_;
	my $s = $$data{$$options{name}};
	$s ||= $$options{value};
	$s =~ s/\"/\&quot\;/gsm; #"
	return qq {<input type="hidden" name="_$$options{name}" value="$s">};
}

################################################################################

sub MSIE_5_draw_form_field_hgroup {
	my ($options, $data) = @_;
	map {$_ -> {label} .= '&nbsp;*' if $_ -> {mandatory}} @{$options -> {items}};
	return join '&nbsp;&nbsp;', map {$_ -> {label} . ($_ -> {label} ? ': ' : '') . ($_ -> {off} ? '' : &{'draw_form_field_' . (($_REQUEST {__read_only} || $options -> {read_only} || $_ -> {read_only}) ? 'static' : $_ -> {type} ? $_ -> {type} : 'string')}($_, $data))} @{$options -> {items}};
}

################################################################################

sub MSIE_5_draw_form_field_text {
	my ($options, $data) = @_;
	my $s = $$data{$$options{name}};
	$s =~ s/\"/\&quot\;/gsm; #"
	
	my $cols = $options -> {cols};
	$cols ||= 60;
	
	my $rows = $options -> {rows};
	$rows ||= 25;

	my $value = $options -> {value};
	$value ||= '';

	return qq {<textarea onFocus="scrollable_table_is_blocked = true; q_is_focused = true" onBlur="scrollable_table_is_blocked = false; q_is_focused = false" rows=$rows cols=$cols name="_$$options{name}" value="$value" onKeyPress="if (window.event.keyCode != 27) is_dirty=true">$s</textarea>};
}

################################################################################

sub MSIE_5_draw_form_field_password {
	my ($options, $data) = @_;
	return qq {<input type="password" name="_$$options{name}" size=120 onKeyPress="if (window.event.keyCode != 27) is_dirty=true">};
}

################################################################################

sub MSIE_5_draw_form_field_static {

	my ($options, $data) = @_;
	
	my $hidden_name = $$options{hidden_name};
	$hidden_name ||= $$options{name};

	my $hidden_value = $$options{hidden_value};
	$hidden_value ||= $$data{$$options{name}};
	$hidden_value ||= $$options{value};
	$hidden_value =~ s/\"/\&quot\;/gsm; #"
	
	my $static_value = 
		ref $options -> {values} eq ARRAY ? (map {$_ -> {label}} grep {$_ -> {id} == $data -> {$options -> {name}}} @{$options -> {values}})[0] : 
		ref $options -> {values} eq HASH ?  $options -> {values} -> {$data -> {$options -> {name}}} : 
		($options -> {value} || $data -> {$options -> {name}});
		
	$static_value = $number_format -> format_picture ($static_value, $options -> {picture}) if $options -> {picture};	
		
	if ($options -> {href}) {
	
		check_href ($options);
		$options -> {a_class} ||= 'lnk4';
		$static_value = qq{<a href="$$options{href}" target="$$options{target}" class="$$options{a_class}">$static_value</a>}
	
	}

	return $$options{add_hidden} ? qq {$static_value <input type=hidden name="$hidden_name" value="$hidden_value">} : $static_value;
	
}

################################################################################

sub MSIE_5_draw_form_field_radio {

	my ($options, $data) = @_;
	
	my $html = '';
	
	foreach my $value (@{$options -> {values}}) {
		my $checked = $data -> {$options -> {name}} == $value -> {id} ? 'checked' : '';
		$html .= qq {<input onFocus="scrollable_table_is_blocked = true; q_is_focused = true" onBlur="scrollable_table_is_blocked = false; q_is_focused = false" type="radio" name="_$$options{name}" value="$$value{id}" $checked onClick="is_dirty=true">&nbsp;$$value{label} <br>};
	}
		
	return $html;
	
}

################################################################################

sub MSIE_5_draw_form_field_checkbox {

	my ($options, $data) = @_;
	
	my $s = $options -> {checked} || $data -> {$options -> {name}};
	
	$s =~ s/\"/\&quot\;/gsm; #"
	
	my $checked = $s ? 'checked' : '';
	
	return qq {<input type="checkbox" name="_$$options{name}" value="1" $checked onChange="is_dirty=true">};
	
}

################################################################################

sub MSIE_5_draw_form_field_checkboxes {

	my ($options, $data) = @_;
	
	my $html = '';
	
	foreach my $value (@{$options -> {values}}) {
		my $checked = $data -> {$options -> {name}} == $value -> {id} ? 'checked' : '';
		$html .= qq {<input type="checkbox" name="_$$options{name}" value="$$value{id}" $checked onChange="is_dirty=true">&nbsp;$$value{label} <br>};
	}
		
	return $html;
	
}

################################################################################

sub MSIE_5_draw_form_field_select {

	my ($options, $data) = @_;
	
	my $html = '';
	
	$options -> {max_len} ||= $conf -> {max_len};
	
	unshift @{$options -> {values}}, {id => 0, label => $options -> {empty}} if exists $options -> {empty};

	foreach my $value (@{$options -> {values}}) {
		
		my $selected = (($value -> {id} eq $data -> {$options -> {name}}) or ($value -> {id} eq $options -> {value})) ? 'selected' : '';
		my $label = trunc_string ($value -> {label}, $options -> {max_len});						
		$html .= qq {<option value="$$value{id}" $selected>$label</option>};
	}
		
	return <<EOH;
		<select name="_$$options{name}" onChange="is_dirty=true" onkeypress="typeAhead()">
			$html
		</select>
EOH
	
}

################################################################################

sub MSIE_5_draw_esc_toolbar {

	my ($options) = @_;
		
	$options -> {href} = $options -> {esc};
	$options -> {href} ||= "/?type=$_REQUEST{type}";
	check_href ($options);

	draw_centered_toolbar ($options, [
		@{$options -> {additional_buttons}},
		{icon => 'cancel', label => 'вернутьс€', href => "$options->{href}", id => 'esc'},
	])
	
}

################################################################################

sub MSIE_5_draw_ok_esc_toolbar {

	my ($options) = @_;		
	
	$options -> {href} = $options -> {esc};
	$options -> {href} ||= "/?type=$_REQUEST{type}";
	check_href ($options);

	my $name = $options -> {name};
	$name ||= 'form';
	
	$options -> {label_ok} ||= 'применить';
	$options -> {label_cancel} ||= 'вернутьс€';

	draw_centered_toolbar ($options, [
		{
			icon => 'ok',     
			label => $options -> {label_ok}, 
			href => '#', 
			onclick => "document.$name.submit()"
		},
		@{$options -> {additional_buttons}},
		{
			icon => 'cancel', 
			label => $options -> {label_cancel}, 
			href => $options -> {href}, 
			id => 'esc'
		},
	 ])
	
}

################################################################################

sub MSIE_5_draw_close_toolbar {
	
	my ($options) = @_;		

	draw_centered_toolbar ({}, [
		@{$options -> {additional_buttons}},
		{
			icon => 'ok',     
			label => 'закрыть', 
			href => 'javascript:window.close()',
			id => 'esc',
		},
	 ])
	
}

################################################################################

sub MSIE_5_draw_back_next_toolbar {

	my ($options) = @_;
	
	my $type = $options -> {type};
	$type ||= $_REQUEST {type};
	
	my $back = $options -> {back};
	$back ||= "/?type=$type";
	
	draw_centered_toolbar ($options, [
		{icon => 'back', label => '&lt;&lt; назад', href => $back, id => 'esc'},
		@{$options -> {additional_buttons}},
		{icon => 'next', label => 'продолжить &gt;&gt;', href => '#', onclick => 'document.form.submit()'},
	])
	
}

################################################################################

sub MSIE_5_draw_centered_toolbar_button {

	my ($options) = @_;
	
	return '' if $options -> {off};
	
	check_href ($options);
	
	my $target = $options -> {target};
	$target ||= '_self';

	if ($options -> {confirm}) {
		my $salt = rand;
		my $msg = js_escape ($options -> {confirm});
		$options -> {href} = qq [javascript:if (confirm ($msg)) {window.open('$$options{href}', '$target')}];
	} 	
	
	return <<EOH
		<!--<td><a onclick="$$options{onclick}" href="$$options{href}" target="$$options{target}"><img hspace=3 src="/i/buttons/$$options{icon}.gif" border=0></a></td>-->
		<td nowrap>&nbsp;<a class=lnk0 onclick="$$options{onclick}" id="$$options{id}" href="$$options{href}" target="$$options{target}"><b>[$$options{label}]</b></a>&nbsp;</td>
		<td><img height=15 hspace=4 src="/i/toolbars/razd1.gif" width=2 border=0></td>
EOH

}

################################################################################

sub MSIE_5_draw_centered_toolbar {

	$_REQUEST{lpt} and return '';

	my ($options, $list) = @_;

	my $colspan = 3 * (1 + @$list) + 1;

	return <<EOH;
	
		<table cellspacing=0 cellpadding=0 width="100%" border=0>
			<tr>
				<td class=bgr5>
					<table cellspacing=0 cellpadding=0 width="100%" border=0>
						<tr>
							<td class=bgr0 colspan=$colspan><img height=1 src="/0.gif" width=1 border=0></td>
						</tr>
						<tr>
							<td class=bgr6 colspan=$colspan><img height=1 src="/0.gif" width=1 border=0></td></tr>
								<tr>
									<td width="45%">
										<table cellspacing=0 cellpadding=0 width="100%" border=0>
											<tr>
												<td _background="/i/toolbars/6ptbg.gif"><img height=17 hspace=0 src="/0.gif" width=1 border=0></td>
											</tr>
										</table>
									</td>
									<td><img height=15 hspace=4 src="/i/toolbars/razd1.gif" width=2 border=0></td>
									@{[ map {draw_centered_toolbar_button ($_)} @$list]}
									<td width="45%">
										<table cellspacing=0 cellpadding=0 width="100%" border=0>
											<tr>
												<td _background="/i/toolbars/6ptbg.gif"><img height=17 hspace=0 src="/0.gif" width=1 border=0></td>
											</tr>
										</table>
									</td>
									<td align=right><img height=23 src="/0.gif" width=4 border=0></td>
								</tr>
								<tr>
									<td class=bgr8 colspan=$colspan><img height=1 src="/0.gif" width=1 border=0></td>
								</tr>
								<tr>
									<td class=bgr6 colspan=$colspan><img height=1 src="/0.gif" width=1 border=0></td>
								</tr>
							</table>
						</tr>
					</table>
				</tr>
			</table>
		</tr>
	</table>
	
EOH

}

################################################################################

sub MSIE_5_draw_auth_toolbar {

	$_REQUEST {__no_navigation} and return '';

	my ($options) = @_;		
	
	my $calendar = <<EOH;
		<td class=bgr1><img height=22 src="/0.gif" width=4 border=0></td>
		<td class=bgr1><A class=lnk2>@{[ $_CALENDAR -> draw () ]}</A></td>
		<td class=bgr1><img height=22 src="/0.gif" width=4 border=0></td>				
EOH

	$top_banner = interpolate ($conf -> {top_banner});
	
	return <<EOH;

		<table cellSpacing=0 cellPadding=0 border=0 width=100%>
			<tr><td class=bgr1><img height=1 src="/0.gif" width=1 height=1 border=0></td></tr>
			<tr><td class=bgr6><img height=1 src="/0.gif" width=1 height=1 border=0></td></tr>
		</table>
		<table cellSpacing=0 cellPadding=0 border=0 width=100%>
			<tr>
				<td class=bgr1><nobr>&nbsp;&nbsp;</nobr></td>

				<td class=bgr1><img height=22 src="/0.gif" width=4 border=0></td>
<!--				
				<td class=bgr1><img src="/i/top_tb_icons/user.gif" border=0 hspace=3 align=absmiddle></td>
-->				
				<td class=bgr1><nobr><A class=lnk2>ѕользователь: @{[ $_USER && $_USER -> {label} ? $_USER -> {label} : 'не определЄн']}</a>&nbsp;&nbsp;</nobr></td>

				$calendar

				<td class=bgr1 nowrap width="100%"></td>							
				
				@{[ $options -> {lpt} ? <<EOLPT : '']}
				<td class=bgr1><img height=22 src="/0.gif" width=4 border=0></td>
<!--				
				<td class=bgr1><img src="/i/top_tb_icons/gear.gif" border=0 hspace=3 align=absmiddle></td>
-->				
				<td class=bgr1><nobr><A class=lnk2 href="@{[ create_url (lpt => 1) ]}" target="_blank">[ѕечать]</a>&nbsp;&nbsp;</nobr></td>

				<td class=bgr1><img height=22 src="/0.gif" width=4 border=0></td>
<!--				
				<td class=bgr1><img src="/i/top_tb_icons/stat.gif" border=0 hspace=3 align=absmiddle></td>
-->				
				<td class=bgr1><nobr><A class=lnk2 href="@{[ create_url (xls => 1) ]}" target="_blank">[MS Excel]</a>&nbsp;&nbsp;</nobr></td>
EOLPT

				@{[ $_USER ? <<EOEXIT : '' ]}
				<td class=bgr1><img height=22 src="/0.gif" width=4 border=0></td>
<!--				
				<td class=bgr1><img src="/i/top_tb_icons/exit.gif" border=0 hspace=3 align=absmiddle></td>
-->				
				<td class=bgr1><nobr><A class=lnk2 href="/">[¬ыход]</A>&nbsp;&nbsp;</nobr></td>
EOEXIT

				<td class=bgr1><img height=22 src="/0.gif" width=4 border=0></td>
				<td class=bgr1><img height=1 src="/0.gif" width=7 border=0></td>
			</tr>
		</table>
		$top_banner
		<table cellSpacing=0 cellPadding=0 border=0 width=100%>
			<tr><td class=bgr7><img height=1 src="/0.gif" width=1 height=1 border=0></td></tr>
			<tr><td class=bgr1><img height=1 src="/0.gif" width=1 height=1 border=0></td></tr>
		</table>

EOH

}

################################################################################

sub MSIE_5_draw_form_field_image {
	my ($options, $data) = @_;
	my $s = $$data{$$options{name}};
	$s =~ s/\"/\&quot\;/gsm; #"
	return <<EOS;
<input type="hidden" name="_$$options{name}" value="$$options{id_image}">
<img src="$$options{src}" id="$$options{name}_preview" width = "$$options{width}" height = "$$options{height}">
&nbsp;
<input type="button" value="¬ыбрать" onClick="window.open('$$options{new_image_url}', 'selectImage' , '');">
EOS

}

################################################################################

sub MSIE_5_draw_form_field_htmleditor {
	
	my ($options, $data) = @_;
	
	return '' if $options -> {off};
	
	push @{$_REQUEST{__include_js}}, 'rte/fckeditor';
	
	my $s = $$data{$$options{name}};
		
	$s =~ s{\"}{\\\"}gsm;
	$s =~ s{\'}{\\\'}gsm;
	$s =~ s{[\n\r]+}{\\n}gsm;

	return <<EOS;
		<SCRIPT language="javascript">
<!--
var oFCKeditor_$$options{name} ;
oFCKeditor_$$options{name} = new FCKeditor('_$$options{name}', '$$options{width}', '$$options{height}') ;
oFCKeditor_$$options{name}.Value = '$s';
oFCKeditor_$$options{name}.Create() ;
//-->
		</SCRIPT>
EOS
}



1;