no warnings;

################################################################################

sub register_hotkey {

	my ($hashref, $type, $data, $options) = @_;

	$hashref -> {label} =~ s{\&(.)}{<u>$1</u>} or return;
	
	my $c = $1;
	
	my $code = 0;
	
	if ($c eq '<') {
		$code = 37;
	}
	elsif ($c eq '>') {
		$code = 39;
	}
	elsif (lc $c eq 'æ') {
		$code = 186;
	}
	elsif (lc $c eq 'ý') {
		$code = 222;
	}
	else {
		$c =~ y{ÉÖÓÊÅÍÃØÙÇÕÚÔÛÂÀÏÐÎËÄÆÝß×ÑÌÈÒÜÁÞéöóêåíãøùçõúôûâàïðîëäæýÿ÷ñìèòüáþ}{qwertyuiop[]asdfghjkl;'zxcvbnm,.qwertyuiop[]asdfghjkl;'zxcvbnm,.};
		$code = (ord ($c) - 32);
	}

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

	map { hotkey ($_) } @_;

}

################################################################################

sub hotkey {

	my ($def) = $_[0];
	
	return if $def -> {off};
	
	$def -> {type} ||= 'href';
	if ($def -> {code} =~ /^F(\d+)/) {
		$def -> {code} = 111 + $1;
	}
	
	push @scan2names, $def;
	
}

################################################################################

sub handle_hotkey_focus {

	my ($r) = @_;
	
	<<EOJS
		if (window.event.keyCode == $$r{code} && window.event.altKey && window.event.ctrlKey) {
			document.form.$$r{data}.focus ();
			event.keyCode      = 0;
			event.returnValue  = false;
			event.cancelBubble = true;
		}
EOJS

}

################################################################################

sub handle_hotkey_href {

	my ($r) = @_;
	
	my $ctrl = $r -> {ctrl} ? '' : '!';
	my $alt  = $r -> {alt}  ? '' : '!';

	<<EOJS
		if (window.event.keyCode == $$r{code} && $alt window.event.altKey && $ctrl window.event.ctrlKey) {
//			window.location.href = document.getElementById ('$$r{data}').href + '&_salt=@{[rand]}';
			var a = document.getElementById ('$$r{data}');
			activate_link (a.href, a.target);
			event.keyCode      = 0;
			event.returnValue  = false;
			event.cancelBubble = true;
		}
EOJS

}

################################################################################

sub js_escape {
	my ($s) = @_;	
	$s =~ s/\"/\'/gsm;
	$s =~ s{[\n\r]+}{ }gsm;
	$s =~ s{\'}{\\\'}g; #'
	return "'$s'";	
}

################################################################################

sub draw_page {

	my ($page) = @_;
	
	$_REQUEST {lpt} ||= $_REQUEST {xls};
	$_REQUEST {__read_only} = 1 if ($_REQUEST {lpt});
		
	delete $_REQUEST {__response_sent};
	
	my $body = '';

	my ($selector, $renderrer);
	
	our @scan2names = ();
	
	our $scrollable_row_id = 0;

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
		
		$_REQUEST{_xls_checksum} and $body =~ s{</table>}{<tr style="display:none"><td>$_REQUEST{_xls_checksum}</table>};
	
		$_REQUEST{xls} and $body =~ s{<td}{<td style="padding:5px"};

		$_REQUEST{_xml}	= "<xml>$_REQUEST{_xml}</xml>" if $_REQUEST{_xml};

		return <<EOH;
			<html xmlns:x="urn:schemas-microsoft-com:office/excel" xmlns:o="urn:schemas-microsoft-com:office:office">
				<head>
					<title>$$i18n{_page_title}</title>
					<meta http-equiv=Content-Type content="text/html; charset=$$i18n{_charset}">
					$_REQUEST{_xml}
					<style>
						TD {
							padding: 5px;
						}
					</style>
				</head>
				<body bgcolor=white leftMargin=0 topMargin=0 marginwidth="0" marginheight="0">
					$body
				</body>
			</html>
EOH

	}
	
#	$_USER -> {role} eq 'admin' and $_REQUEST{id} or my $lpt = $body =~ s{<table[^\>]*lpt\=\"?1\"?[^\>]*\>}{\<table cellspacing\=1 cellpadding\=5 id='scrollable_table' width\=100\%\>}gsm; #"
	my $lpt = $body =~ s{<table[^\>]*lpt\=\"?1\"?[^\>]*\>}{\<table cellspacing\=1 cellpadding\=5 id='scrollable_table' width\=100\%\>}gsm; #"
	
	my $menu = draw_menu ($page -> {menu}, $page -> {highlighted_type});
	
	$_REQUEST {__scrollable_table_row} ||= 0;
	
	my $meta_refresh = $_REQUEST {__meta_refresh} ? qq{<META HTTP-EQUIV=Refresh CONTENT="$_REQUEST{__meta_refresh}; URL=@{[create_url()]}">} : '';	
	
	my $auth_toolbar = draw_auth_toolbar ({lpt => $lpt});

#	my $root = $^O eq 'MSWin32' ? '/i/' : $_REQUEST{__uri};
	my $root = $_REQUEST{__uri};
	
	my $request_package = ref $apr;
	my $mod_perl = $ENV {MOD_PERL};
	$mod_perl ||= 'NO mod_perl AT ALL';
	
	my $timeout = 1000 * (60 * $conf -> {session_timeout} - 1);
				
	return <<EOH;
		<html>		
			<head>
				<title>$$i18n{_page_title}</title>
				<meta name="Generator" content="Zanas ${Zanas::VERSION} / $$SQL_VERSION{string}; parameters are fetched with $request_package; gateway_interface is $ENV{GATEWAY_INTERFACE}; $mod_perl is in use">
				$meta_refresh
				
				<LINK href="${root}zanas.css" type=text/css rel=STYLESHEET>
				@{[ map {<<EOJS} @{$_REQUEST{__include_css}} ]}
					<LINK href="/i/$_.css" type=text/css rel=STYLESHEET>
EOJS

					<script src="${root}navigation.js">
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
					var td2sr = new Array ();
					var td2sc = new Array ();
					
					function td_on_click () {
						var uid = window.event.srcElement.uniqueID;
						var new_scrollable_table_row = td2sr [uid];
						var new_scrollable_table_row_cell = td2sc [uid];
						if (new_scrollable_table_row == null || new_scrollable_table_row_cell == null) return;
						scrollable_rows [scrollable_table_row].cells [scrollable_table_row_cell].className = scrollable_table_row_cell_old_style;
						scrollable_table_row = new_scrollable_table_row;
						scrollable_table_row_cell = new_scrollable_table_row_cell;
						scrollable_table_row_cell_old_style = scrollable_rows [scrollable_table_row].cells [scrollable_table_row_cell].className;
						scrollable_rows [scrollable_table_row].cells [scrollable_table_row_cell].className = 'txt6';
						focus_on_first_input (scrollable_rows [scrollable_table_row].cells [scrollable_table_row_cell]);
						return false;
					}
					
				</script>
				
			</head>
			<body bgcolor=white leftMargin=0 topMargin=0 marginwidth="0" marginheight="0" name="body" id="body">

				<script for="body" event="onload">
				
					@{[ $_REQUEST{sid} ? <<EOK : '' ]}
						keepaliveID = setTimeout ("open('$_REQUEST{__uri}?keepalive=$_REQUEST{sid}', 'invisible'); clearTimeout (keepaliveID)", $timeout);
EOK

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
					
					for (var i = 0; i < scrollable_rows.length; i++) {
					
						var cells = scrollable_rows [i].cells;
						for (var j = 0; j < cells.length; j++) {
							var scrollable_cell = cells [j];
							td2sr [scrollable_cell.uniqueID] = i;
							td2sc [scrollable_cell.uniqueID] = j;
							scrollable_cell.onclick = td_on_click;
						}
					}
									
					scrollable_table = getElementById ('scrollable_table');
							
					if (scrollable_table) {				
				
						scrollable_table = scrollable_table.tBodies (0);
					
						scrollable_table_row = $_REQUEST{__scrollable_table_row};
						scrollable_table_row_cell = 0;

						if (scrollable_rows.length > 0) {
							if (scrollable_table_row > scrollable_rows.length - 1) {
								scrollable_table_row = scrollable_rows.length - 1;
							}
							scrollable_table_row_cell_old_style = scrollable_rows [scrollable_table_row].cells [scrollable_table_row_cell].className;
							scrollable_rows [scrollable_table_row].cells [scrollable_table_row_cell].className = 'txt6';
						}
						else {
							scrollable_table = null;
						}
						
					}
					
					var focused_inputs = getElementsByName ('$_REQUEST{__focused_input}');
										
					if (focused_inputs != null && focused_inputs.length > 0) {
						var focused_input = focused_inputs [0];
						focused_input.focus ();
						if (focused_input.type == 'radio') {
							focused_input.select ();
						}
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
					if (window.event.keyCode == 88 && window.event.altKey) document.location.href = '$_REQUEST{__uri}?type=_logout&sid=$_REQUEST{sid}&_salt=@{[rand]}';
					handle_basic_navigation_keys ();
					@{[ map {&{"handle_hotkey_$$_{type}"} ($_)} @scan2names ]}
				</script>						
				
				@{[ $_REQUEST{__help_url} ? <<EOHELP : '' ]}
					<script for="body" event="onhelp">
						window.open ('$_REQUEST{__help_url}', '_blank', 'toolbar=no,resizable=yes');
						event.returnValue = false;
					</script>						
EOHELP
				
				
				
				<div id="bodyArea" _style='height:100%; padding:0px; margin:0px'>
					$auth_toolbar			
					$menu
					$body
				</div>
				<iframe name=invisible src="${root}0.html" width=0 height=0>
				</iframe>
			</body>
		</html>
EOH
	
}

################################################################################

sub draw_form_field_button {
	my ($options, $data) = @_;
	my $s = $$data{$$options{name}};
	$s ||= $$options{value};
	$s =~ s/\"/\&quot\;/gsm; #"
	my $onclick = $$options{onclick} || '';
	$tabindex ++;
	return qq {<input type="button" name="_$$options{name}" value="$s" onClick="$onclick" tabindex=$tabindex>};
}

################################################################################

sub draw_menu {

	my ($types, $cursor) = @_;	
	
	@$types or return '';
	
	$_REQUEST {__no_navigation} and return '';
	
	my ($tr1, $tr2, $tr3, $divs) = ('', '', '', '');

	foreach my $type (@$types)	{
	
		next if $type -> {off};
	
		$conf -> {kb_options_menu} ||= {ctrl => 1, alt => 1};
	
		register_hotkey ($type, 'href', 'main_menu_' . $type -> {name}, $conf -> {kb_options_menu});
	
		$tr1 .= <<EOH;
			<td class=bgr8 rowspan=2><img src="/i/toolbars/n_left.gif" border=0></td>
			<td bgcolor=#ffffff><img height=1 src="$_REQUEST{__uri}0.gif" width=1 border=0></td>				
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


		my $onhover = '';
		if (ref $type -> {items} eq ARRAY) {
			$divs .= draw_vert_menu ($type -> {name}, $type -> {items});
			$onhover = qq {onmouseover="open_popup_menu ('$$type{name}')"} unless $type -> {no_page};
		}
		
#		my $href = $type -> {no_page} ? '#' : ("$_REQUEST{__uri}?type=$$type{name}&sid=$_REQUEST{sid}@{[$_REQUEST{period} ? '&period=' . $_REQUEST {period} : '']}@{[$type->{role} ? '&role=' . $type->{role} : '']}";

		if ($type -> {no_page}) {
			$type -> {href} = "javaScript:open_popup_menu('$$type{name}')";
		} 
		else {
			$type -> {href} ||= "/?type=$$type{name}";
			$type -> {href} .= "&role=$$type{role}" if $type -> {role};
			check_href ($type);
		}
		
		$tr2 .= <<EOH;
			<td class=bgr1><img height=20 src="$_REQUEST{__uri}0.gif" width=1 border=0></td>
			<td $onhover class=$tclass nowrap>&nbsp;&nbsp;<a class=$aclass id="main_menu_$$type{name}" href="$$type{href}">$$type{label}</a>&nbsp;&nbsp;</td>
EOH

		$tr3 .= <<EOH;
			<td class=bgr1><img height=1 src="$_REQUEST{__uri}0.gif" width=1 border=0></td>
			<td class=bgr1 nowrap><img height=1 src="$_REQUEST{__uri}0.gif" width=1 border=0></td>
EOH

	}

	return <<EOH;
		<table width="100%" class=bgr8 cellspacing=0 cellpadding=0 border=0>
			<tr>
				<td class=bgr8 width=7><img height=1 src="$_REQUEST{__uri}0.gif" width=7 border=0></td>
				$tr2
				<td class=bgr1><img height=20 src="$_REQUEST{__uri}0.gif" width=1 border=0></td>
				<td class=bgr8 width=100%><img height=1 src="$_REQUEST{__uri}0.gif" width=1 border=0></td>
			<tr>
				<td class=bgr8><img height=1 src="$_REQUEST{__uri}0.gif" width=1 border=0></td>
				$tr3
				<td class=bgr1><img height=1 src="$_REQUEST{__uri}0.gif" width=1 border=0></td>
				<td class=bgr8 width=100%><img height=1 src="$_REQUEST{__uri}0.gif" width=1 border=0></td>
				
		</table>	
		$divs
EOH
}

################################################################################

sub draw_vert_menu {

	my ($name, $types) = @_;
	
	my $tr2 = '';

	foreach my $type (@$types) {
	
		if ($type eq BREAK) {
		
			$tr2 .= <<EOH;
				<tr height=1>
					<td bgcolor=#485F70 colspan=3><img height=1 src=$_REQUEST{__uri}0.gif width=1 border=0></td>
				<tr>
					<td bgcolor=#485F70><img height=1 src=$_REQUEST{__uri}0.gif width=1 border=0></td>
					<td><img height=1 src=$_REQUEST{__uri}0.gif width=1 border=0></td>
					<td bgcolor=#485F70><img height=1 src=$_REQUEST{__uri}0.gif width=1 border=0></td>
EOH
		
		}
		else {
		
			$type -> {href} ||= "/?type=$$type{name}";
			$type -> {href} .= "&role=$$type{role}" if $type -> {role};
			check_href ($type);		
		
			$tr2 .= <<EOH;
				<tr height=1>
					<td bgcolor=#485F70 colspan=3><img height=1 src=$_REQUEST{__uri}0.gif width=1 border=0></td>
				<tr>
					<td bgcolor=#485F70><img height=20 src=$_REQUEST{__uri}0.gif width=1 border=0></td>
					<td 
						nowrap 
						onmouseover="this.style.background='#efefef'" 
						onmouseout="this.style.background='#d5d5d5'"
						onclick="parent.location.href='$$type{href}'"
						style="font-weight: normal; font-size: 11px; color: #000000; font-family: verdana; text-decoration: none"
					>
						&nbsp;&nbsp;$$type{label}&nbsp;&nbsp;
					</td>
					<td bgcolor=#485F70><img height=20 src=$_REQUEST{__uri}0.gif width=1 border=0></td>
EOH
		}
	
	}

	return <<EOH;
		<div id="vert_menu_$name" style="visibility:hidden; position:absolute; z-index:-100;">
			<table id="vert_menu_table_$name" width=1% bgcolor=#d5d5d5 cellspacing=0 cellpadding=0 border=0>
				$tr2
				<tr height=1>
					<td bgcolor=#485F70 colspan=3><img height=1 src=$_REQUEST{__uri}0.gif width=1 border=0></td>
			</table>
		</div>
EOH
	
}

################################################################################

sub draw_hr {

	my (%options) = @_;
	
	$options {height} ||= 1;
	$options {class}  ||= bgr8;	
	
	return <<EOH;
		<table border=0 cellspacing=0 cellpadding=0 width="100%">
			<tr><td class=$options{class}><img src="$_REQUEST{__uri}0.gif" width=1 height=$options{height}></td></tr>
		</table>
EOH
	
}

################################################################################

sub format_picture {

	my ($txt, $picture) = @_;
	
	my $result = $number_format -> format_picture ($txt, $picture);
	
	if ($_USER -> {demo_level} > 1) {
		$result =~ s{\d}{\*}g;
	}
	
	return $result;

}

################################################################################

sub draw_input_cell {

	my ($data, $options) = @_;
	
	$data -> {attributes} ||= {};
	$data -> {attributes} -> {class} ||= 'txt4';
	my $attributes = dump_attributes ($data -> {attributes});

	return "<td $attributes>" if $data -> {off};
	
	return draw_text_cell ($data, $options) if $_REQUEST {__read_only} || $data -> {read_only};
	
	$data -> {size} ||= 30;
				
	$data -> {a_class} ||= 'lnk4';

	my $txt = $data -> {label} || '';
	
	if ($data -> {picture}) {
		$txt = format_picture ($txt, $data -> {picture});
		$txt =~ s/^\s+//g; 
	}
	
			
	check_title ($data);
		
	return qq {<td $$data{title} $attributes><nobr><input onFocus="q_is_focused = true" onBlur="q_is_focused = false" type="text" name="$$data{name}" value="$txt" maxlength="$$data{max_len}" size="$$data{size}"></nobr></td>};

}

################################################################################

sub draw_checkbox_cell {

	my ($data) = @_;
	my $value = $data -> {value} || 1;
	
	my $checked = $data -> {checked} ? 'checked' : '';

	$data -> {attributes} ||= {};
	$data -> {attributes} -> {class} ||= 'txt4';

	my $attributes = dump_attributes ($data -> {attributes});

	return qq {<td $attributes>&nbsp;} if $data -> {off};	

	check_title ($data);

	return qq {<td $$data{title} $attributes><input type=checkbox name=$$data{name} $checked value='$value'></td>};
	
}

################################################################################

sub draw_text_cells {

	my $options = (ref $_[0] eq HASH) ? shift () : {};
		
	return join '', map { draw_text_cell ($_, $options) } @{$_[0]};
	
}


################################################################################

sub draw_text_cell {

	my ($data, $options) = @_;
	
	ref $data eq HASH or $data = {label => $data};	
		
#	return '' if $data -> {off};
	
#	$data -> {max_len} ||= $data -> {size} || $conf -> {max_len} || 30;
	$data -> {max_len} ||= $data -> {size} || $conf -> {size}  || $conf -> {max_len} || 30;
	
	$data -> {attributes} ||= {};
	$data -> {attributes} -> {class} ||= $options -> {is_total} ? 'header5' : 'txt4';
	$data -> {attributes} -> {align} ||= 'right' if $options -> {is_total};
			
	$options -> {a_class} ||= 'lnk4';
	$data -> {a_class} ||= $options -> {a_class};
	
	my $txt;
	
	if ($data -> {picture}) {	
		$txt = format_picture ($data -> {label}, $data -> {picture});
		$data -> {attributes} -> {align} ||= 'right';
	}
	else {
		$txt = trunc_string ($data -> {label}, $data -> {max_len});
	}
	
	unless ($data -> {no_nobr}) {
		$txt = '<nobr>' . $txt . '</nobr>';
	}
	
	$txt ||= '&nbsp;';
	
	$data -> {href}   ||= $options -> {href} unless $options -> {is_total};
	$data -> {target} ||= $options -> {target};
	if ($data -> {href} && !$_REQUEST {lpt}) {
		check_href ($data);
		my $target = $data -> {target} ? "target='$$data{target}'" : '';
		$txt = qq { <a class=$$data{a_class} $target href="$$data{href}" onFocus="blur()">$txt</a> };
	}
	
	my $attributes = dump_attributes ($data -> {attributes});

	return qq {<td $attributes>&nbsp;} if $data -> {off};	
	
	check_title ($data);
	
	return qq {<td $$data{title} $attributes>$txt</td>};

}

################################################################################

sub draw_tr {

	my ($options, @tds) = @_;
	
	return qq {<tr>@tds</tr>};

}

################################################################################

sub draw_one_cell_table {

	my ($options, $body) = @_;
	
	return <<EOH
	
		@{[ $options -> {js_ok_escape} ? js_ok_escape () : '' ]}
		
		<table cellspacing=0 cellpadding=0 width="100%">
				<form name=form action=$_REQUEST{__uri} method=post enctype=multipart/form-data target=invisible>
					<tr><td class=bgr8>$body
				</form>
		</table>
EOH

}

################################################################################

sub draw_table_header {

	my ($cell) = @_;
	
	if (ref $cell eq ARRAY) {
	
		my $line = join '', (map {draw_table_header ($_)} @$cell);
		
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
	
	check_title ($cell);
	
	$cell -> {attributes} ||= {};
	$cell -> {attributes} -> {class} ||= 'bgr4';
	
	my $attributes = dump_attributes ($cell -> {attributes});
	
	return "<th $attributes colspan=$$cell{colspan} $cell{title}>$$cell{label}\&nbsp;";

}

################################################################################

sub draw_table {

	my $headers = [];

	unless (ref $_[0] eq CODE or (ref $_[0] eq ARRAY and ref $_[0] -> [0] eq CODE)) {
		$headers = shift;
	}
	
	my ($tr_callback, $list, $options) = @_;
	
	return '' if $options -> {off};
		
	my $ths = @$headers ? '<thead>' . draw_table_header ($headers) . '</thead>' : '';
	
	my $trs = '';

	if (ref $options -> {title} eq HASH) {
		my $title = '';
		$options -> {title} -> {height} ||= 10;
		$title .= draw_hr (%{$options -> {title}});
		$title .= draw_window_title ($options -> {title}) if $options -> {title} -> {label};
		$options -> {title} = $title;
	}

	if (ref $options -> {top_toolbar} eq ARRAY) {
#		$_FLAG_ADD_LAST_QUERY_STRING = 1;
		$options -> {top_toolbar} = draw_toolbar (@{ $options -> {top_toolbar} });
#		$_FLAG_ADD_LAST_QUERY_STRING = 0;
	}

	if (ref $options -> {path} eq ARRAY) {
		$options -> {path} = draw_path ({}, $options -> {path});
	}

	if ($options -> {'..'} && !$_REQUEST{lpt}) {
	
		my $url = $_REQUEST {__path} -> [-2];
		
		$scrollable_row_id ++;
	
		$trs = <<EOH;
			<script for="body" event="onkeypress">
				if (window.event.keyCode == 27) {
					activate_link ('$url');
				}
			</script>
			<tr>
				@{[ draw_text_cell ({
					label => '..',
					href  => $url,
					attributes => {
						colspan => 0 + @$headers,
					},
				})]}
			</tr>
EOH
	
	}
	
	my @tr_callbacks = ref $tr_callback eq ARRAY ? @$tr_callback : ($tr_callback);
	
	my $n = 0;
	foreach our $i (@$list) {
		$i -> {__n} = $n++;
		$trs .= '<thead>' if $n == @$list && !$i -> {id};
		foreach my $callback (@tr_callbacks) {
#			$trs .= '<tr style="position:relative;left:0px;top:0px;z-index:1;">';
			$trs .= '<tr>';
			our $_FLAG_ADD_LAST_QUERY_STRING = 1;
			$trs .= &$callback ();
			undef $_FLAG_ADD_LAST_QUERY_STRING;
			$trs .= '</tr>';
			$scrollable_row_id ++;
		}
		$trs .= '</thead>' if $n == @$list && !$i -> {id};
	}
	
	$options -> {type}   ||= $_REQUEST{type};
	$options -> {action} ||= 'add';
	$options -> {name}   ||= 'form';
	
	my $hiddens = '';
	
	foreach my $key (keys %_REQUEST) {
		next if $key =~ /^_/ or $key =~/^(type|action|sid)$/;
		$hiddens .= qq {<input type=hidden name=$key value="$_REQUEST{$key}">};
	}
	
	my ($div_bra, $div_ket, $sliding_table) = ('', '');
	if ($options -> {height}) {
		$div_bra = "<div style='height:$$options{height}; overflow-y:scroll; padding:0px; margin:0px' id='$options'>";
		$div_ket = '</div>';
	}	
	
	return <<EOH
	
		$$options{title}
		$$options{path}
		$$options{top_toolbar}
		
		@{[ $options -> {js_ok_escape} ? js_ok_escape ({name => $options -> {name}, no_ok => $options -> {no_ok}}) : '' ]}
		
		<table cellspacing=0 cellpadding=0 width="100%"><tr><td class=bgr8>
		
			<form name=$$options{name} action=$_REQUEST{__uri} method=post enctype=multipart/form-data target=invisible>
			
				<input type=hidden name=type value=$$options{type}> 
				<input type=hidden name=action value=$$options{action}> 
				<input type=hidden name=sid value=$_REQUEST{sid}>
				$hiddens
		$div_bra
				<table cellspacing=1 cellpadding=5 width="100%" id="scrollable_table" lpt=$$options{lpt}>
					$ths					
						<tbody>
							$trs
						</tbody>
				</table>
		$div_ket
				$$options{toolbar}
			
			</form>
			
		</table>
EOH

}

################################################################################

sub draw_path {

	$_REQUEST{lpt} and return '';

	my ($options, $list) = @_;
	
	($list and ref $list eq ARRAY and @$list) or return '';

	$options -> {id_param} ||= 'id';
	$options -> {max_len} ||= $conf -> {max_len};
	$options -> {max_len} ||= 30;
	
	$path = '';
	
	my $nowrap = $options -> {multiline} ? '' : 'nowrap';
	
	my $n = 2;
	
	$_REQUEST {__path} = [];
	
	foreach my $item (@$list) {		
	
		my $name = trunc_string ($item -> {name}, $options -> {max_len});
	
		$path and $path .= '&nbsp;/&nbsp;';
		
		$path and $options -> {multiline} and $path .= '<br>' . ('&nbsp;&nbsp;' x ($n++));
		
		$id_param = $item -> {id_param};
		$id_param ||= $options -> {id_param};
		
		$item -> {cgi_tail} ||= $options -> {cgi_tail};
		
		my $url = "$_REQUEST{__uri}?type=$$item{type}&$id_param=$$item{id}&sid=$_REQUEST{sid}&$$item{cgi_tail}";
		
		push @{$_REQUEST {__path}}, $url;

		$path .= <<EOH;
			<a class=lnk1 href="$url">$name</a>
EOH
	
	}

	return draw_hr (height => 10) . <<EOH
		
		<table cellspacing=0 cellpadding=0 width="100%" border=0>
			<tr>
				<td class=bgr5>
					<table cellspacing=0 cellpadding=0 width="100%" border=0>
						<tr>
							<td class=bgr6 colspan=4><img height=1 src="$_REQUEST{__uri}0.gif" width=1 border=0></td>
						</tr>
						<tr>
<!--						
							<td><img height=14 hspace=4 src="/i/toolbars/4pt.gif" width=2 border=0></td>
-->							
							<td class='header6' $nowrap>&nbsp;$path&nbsp;</td>
							<td>
								<table cellspacing=0 cellpadding=0 width="100%" border=0>
									<tr>
										<td _background="/i/toolbars/4pt.gif" height=15><img height=15  hspace=0 src="$_REQUEST{__uri}0.gif" width=1 border=0></td>
									</tr>
								</table>
							</td>
							<td align=right><img height=15  src="$_REQUEST{__uri}0.gif" width=4 border=0></td>
						</tr>
						<tr>
							<td class=bgr8 colspan=4><img height=1 src="$_REQUEST{__uri}0.gif" width=1 border=0></td>
						</tr>
						<tr>
							<td class=bgr6 colspan=4><img height=1 src="$_REQUEST{__uri}0.gif" width=1 border=0></td>
						</tr>
					</table>
				</td>
			</tr>
		</table>
EOH

}

################################################################################

sub draw_window_title {

	my ($options) = @_;
	
	return '' if $options -> {off};
	
	return <<EOH
		<table cellspacing=0 cellpadding=0 width="100%"><tr><td class='header15'><img src="$_REQUEST{__uri}0.gif" width=1 height=20 align=absmiddle>&nbsp;&nbsp;&nbsp;$$options{label}</table>
EOH

}

################################################################################

sub draw_toolbar {

	my ($options, @buttons) = @_;
	
	return '' if $options -> {off};	
	
	$_REQUEST {__toolbars_number} ||= 0;
	
	my $form_name = $_REQUEST {__toolbars_number} ? 'toolbar_form_' . $_REQUEST {__toolbars_number} : 'toolbar_form';
	$_REQUEST {__toolbars_number} ++;
	
	my $buttons = join '', map { ref $_ eq HASH ? ( &{'draw_toolbar_' . ($$_{type} || 'button')} ($_) ) : $_ } @buttons;
	
	return <<EOH
		<table class=bgr5 cellspacing=0 cellpadding=0 width="100%" border=0>
			<form action=$_REQUEST{__uri} name=$form_name target="$$options{target}">
			
				@{[ map {<<EO} @{$options -> {keep_params}} ]}
					<input type=hidden name=$_ value=$_REQUEST{$_}>
EO
					<input type=hidden name=sid value=$_REQUEST{sid}>
				<tr>
					<td class=bgr0 colspan=15><img height=1 src="$_REQUEST{__uri}0.gif" width=1 border=0></td>
				</tr>
				<tr>
					<td class=bgr6 colspan=15><img height=1 src="$_REQUEST{__uri}0.gif" width=1 border=0></td>
				</tr>
				<tr>
					<td width=20>
						<table cellspacing=0 cellpadding=0 width=20 border=0>
							<tr>
								<td _background="/i/toolbars/6ptbg.gif"><img height=17 hspace=0 src="$_REQUEST{__uri}0.gif" width=1 border=0></td>
							</tr>
						</table>
					</td>
					$buttons
					<td width="100%">
						<table cellspacing=0 cellpadding=0 width="100%" border=0>
							<tr>
								<td _background="/i/toolbars/6ptbg.gif"><img height=17 hspace=0 src="$_REQUEST{__uri}0.gif" width=1 border=0></td>
							</tr>
						</table>
					</td>
					<td align=right><img height=23 src="$_REQUEST{__uri}0.gif" width=4 border=0></td>
				</tr>
				<tr>
					<td class=bgr8 colspan=15><img height=1 src="$_REQUEST{__uri}0.gif" width=1 border=0></td>
				</tr>
				<tr>
					<td class=bgr6 colspan=15><img height=1 src="$_REQUEST{__uri}0.gif" width=1 border=0></td>
				</tr>
			</form>
		</table>
EOH

}

################################################################################

sub draw_toolbar_button {

	my ($options) = @_;
	
	return '' if $options -> {off};
	
	$options -> {target} ||= '_self';
	
	$conf -> {kb_options_buttons} ||= {ctrl => 1, alt => 1};	
	
	register_hotkey ($options, 'href', $options, $conf -> {kb_options_buttons});
	
	check_href ($options);

	if ($options -> {confirm}) {
		my $salt = rand;
		my $msg = js_escape ($options -> {confirm});
		$options -> {href} = qq [javascript:if (confirm ($msg)) {window.open('$$options{href}', '$$options{target}')}];
	} 

	my ($bra, $ket) = ();
	if ($conf -> {core_show_icons} && $options -> {icon}) {	
		my $label = $options -> {label};
		$label =~ s{\<.*?\>}{}g;
		$bra = qq|<img src="/i/buttons/$$options{icon}.gif" alt="$label" border=0 hspace=0 vspace=1 align=absmiddle>&nbsp;|
	}
	else {
		$bra = '<b>[';
		$ket = ']</b>';
	}
	
	return <<EOH
		<td nowrap>&nbsp;<a class=lnk0 href="$$options{href}" id="$options" target="$$options{target}">${bra}$$options{label}${ket}</b></a></td>
		<td><img height=15 hspace=4 src="/i/toolbars/razd1.gif" width=2 border=0></td>
EOH

}

################################################################################

sub draw_toolbar_input_text {

	my ($options) = @_;
	
	return '' if $options -> {off};

	my $value = $options -> {value};
	$value ||= $_REQUEST{$$options{name}};
	
	$options -> {size} ||= 15;
	
	my $hiddens = '';
	
	$options -> {keep_params} ||= [keys %_REQUEST];
	
	foreach my $key (@{$options -> {keep_params}}) {
		next if $key eq $options -> {name} or $key =~ /^_/ or $key eq 'start' or $key eq 'sid';
		$hiddens .= qq {<input type=hidden name=$key value="$_REQUEST{$key}">};
	}
		
	return <<EOH
		<td nowrap>$$options{label}: <input type=text size=$$options{size} name=$$options{name} value="$value" onFocus="scrollable_table_is_blocked = true; q_is_focused = true" onBlur="scrollable_table_is_blocked = false; q_is_focused = false">$hiddens</td>
		<td><img height=15  hspace=4 src="/i/toolbars/razd1.gif" width=2 border=0></td>
EOH

}

################################################################################

sub draw_toolbar_input_submit {

	my ($options) = @_;
	return '' if $options -> {off};
	return <<EOH
		<td nowrap><input type=submit name="$$options{name}" value="$$options{label}"></td>
		<td><img height=15  hspace=4 src="/i/toolbars/razd1.gif" width=2 border=0></td>
EOH

}

################################################################################

sub draw_toolbar_pager {

	my ($options) = @_;
	
	$options -> {portion} ||= $conf -> {portion};

	my $start = $_REQUEST {start} + 0;

	my $label = '';	

	$conf -> {kb_options_pager} ||= $conf -> {kb_options_buttons};
	$conf -> {kb_options_pager} ||= {ctrl => 1, alt => 1};

	if ($start > $options -> {portion}) {
		$url = create_url (start => 0);
		$label .= qq {&nbsp;<a href="$url" class=lnk0 onFocus="blur()"><b>&lt;&lt;</b></a>&nbsp;};
	}

	if ($start > 0) {
		register_hotkey ({label => '&<'}, 'href', '_pager_prev', $conf -> {kb_options_pager});
		$url = create_url (start => ($start - $options -> {portion} < 0 ? 0 : $start - $options -> {portion}));
		$label .= qq {&nbsp;<a href="$url" class=lnk0 id="_pager_prev" onFocus="blur()"><b><u>&lt;</u></b></a>&nbsp;};
	}
	
	$options -> {total} or return qq {<td nowrap>$$i18n{toolbar_pager_empty_list}<td><img height=15  hspace=4 src="/i/toolbars/razd1.gif" width=2 border=0></td>};
	
#	$label .= qq {<input type=text size=4 name=start value=@{[$start+1]} onFocus="scrollable_table_is_blocked = true; q_is_focused = true" onBlur="scrollable_table_is_blocked = false; q_is_focused = false" onchange="s=document.toolbar_form.start.value; s=(isNaN(s) ? 1 : s); s=(s < 1 ? 1 : s); lp=$$options{total}; s=(s > lp ? lp : s); document.toolbar_form.start.value=s-1; toolbar_form.submit()">};
#	$label .= ' - ' . ($start + $$options{cnt}) . $$i18n{toolbar_pager_of} . $$options{total};
	
	$label .= ($start + 1) . ' - ' . ($start + $$options{cnt}) . $$i18n{toolbar_pager_of} . $$options{total};
	
	if ($start + $$options{cnt} < $$options{total}) {
	
		register_hotkey ({label => '&>'}, 'href', '_pager_next', $conf -> {kb_options_pager});
		$url = create_url (start => $start + $options -> {portion});
		$label .= qq {&nbsp;<a href="$url" class=lnk0 id="_pager_next" onFocus="blur()"><b><u>&gt;</u></b></a>&nbsp;};
	}
	
	return <<EOH
		<td nowrap>$label</td>
		<td><img height=15  hspace=4 src="/i/toolbars/razd1.gif" width=2 border=0></td>
EOH

}

################################################################################

sub draw_row_button {

	my ($options) = @_;	
	
	return '<td class=bgr0 valign=top nowrap width="1%">&nbsp;' if $options -> {off} || $_REQUEST {lpt};	
	
	check_href  ($options);

	if ($options -> {confirm}) {
		my $salt = rand;
		my $msg = js_escape ($options -> {confirm});
		$options -> {href} = qq [javascript:if (confirm ($msg)) {window.open('$$options{href}', '_self')}];
	} 
		
	if ($conf -> {core_show_icons}) {	
		my $label = $options -> {label};
		$options -> {label} = qq|<img src="/i/buttons/$$options{icon}.gif" alt="$$options{label}" border=0 hspace=0 vspace=0 align=absmiddle>|;
		$options -> {label} .= "&nbsp;$label" if $options -> {force_label};
	}
	else {
		$options -> {label} = "\&nbsp;[$$options{label}]\&nbsp;";
	}

	check_title ($options);

	return qq {<td $$options{title} class=bgr4 valign=top nowrap width="1%"><a class=lnk0 href="$$options{href}" onFocus="blur()" target="$$options{target}">$$options{label}</a>};

}

################################################################################

sub draw_row_buttons {

	my ($options, $buttons) = @_;

	return $options -> {off} ? 
		'<td class=bgr4 valign=top nowrap width="1%">&nbsp;':
		(join '', map {draw_row_button ($_)} @$buttons) . '</td>';

}

################################################################################

sub draw_form_field {

	my ($field, $data) = @_;
		
	if (ref $field eq ARRAY) {
	
		my $html = '';
	
		for (my $i = 0; $i < @$field; $i++) {		
			my $subfield = $field -> [$i];					
			$subfield -> {is_slave} = 1;
			$subfield -> {colspan} = $i == @$field - 1 ? $_REQUEST {__max_cols} - 2 * $i - 1 : 1;
			$html .= draw_form_field ($subfield, $data);		
		}
		
		return $html;
	
	}

	return '' if $field -> {off};
	
	my $type = $field -> {type};
	$type = 'static' if ($_REQUEST {__read_only} or $field -> {read_only}) and $type ne 'hgroup';	
	$type ||= 'string';
	
	my $html = &{"draw_form_field_$type"} ($field, $data);
	
	$conf -> {kb_options_focus} ||= $conf -> {kb_options_buttons};
	$conf -> {kb_options_focus} ||= {ctrl => 1, alt => 1};
	
	register_hotkey ($field, 'focus', '_' . $field -> {name}, $conf -> {kb_options_focus});

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

sub draw_form {

	my ($options, $data, $fields) = @_;
	
	if ($conf -> {core_auto_esc} && $_REQUEST {__last_query_string}) {
		my $esc_query_string = $_REQUEST {__last_query_string};
		$esc_query_string =~ y{-_.}{+/=};
		my $query_string = MIME::Base64::decode ($esc_query_string);
		my $salt = time (); #rand ();
		$query_string =~ s{salt\=[\d\.]+}{salt=$salt}g;
		$options -> {esc} = $_REQUEST {__uri} . '?' . $query_string;
	}	

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
	
	our $tabindex = 1;
	
	foreach my $field (@$fields) {
		next unless ref $field eq ARRAY;
		$max_cols = @$field if $max_cols < @$field;
	}
	
	$_REQUEST {__max_cols} = $max_cols * 2;

	foreach my $field (@$fields) {
					
		next if ref $field eq HASH and $field -> {off};
		next if ref $field eq ARRAY and @$field == 0;
		
		my $id_tr = ref $field eq HASH ? "tr_$$field{name}" : '';
					
		$trs .= "<tr id=\"$id_tr\">" . draw_form_field ($field, $data) . '</tr>';
	
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

			@{[ js_ok_escape ($options) ]}
			
			<form name=$name action=$_REQUEST{__uri} method=post enctype=multipart/form-data target=$target>
				<input type=hidden name=type value=$type> 
				<input type=hidden name=id value=$id> 
				<input type=hidden name=action value=$action> 
				<input type=hidden name=sid value=$_REQUEST{sid}>
				<input type=hidden name=__last_query_string value="$_REQUEST{__last_query_string}">
				@{[ map {<<EO} @{$options -> {keep_params}} ]}
					<input type=hidden name=$_ value=$_REQUEST{$_}>
EO
				$trs
			</form>
		</table>$bottom_toolbar
EOH

}

################################################################################

sub js_ok_escape {
	
	my ($options) = @_;
	
	$options -> {name} ||= 'form';
	$options -> {confirm_ok} ||= $i18n -> {confirm_ok};	
	$options -> {confirm_esc} ||= $i18n -> {confirm_esc};
	
	$options -> {confirm_ok} = js_escape ($options -> {confirm_ok});
	$options -> {confirm_esc} = js_escape ($options -> {confirm_esc});

	return <<EOH
	
		<script for="body" event="onkeypress">
		
			if (window.event.keyCode == 27 && (!is_dirty || window.confirm ($$options{confirm_esc}))) {
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

sub draw_form_field_string {

	my ($options, $data) = @_;
	
	$options -> {max_len} ||= $conf -> {max_len};	
	$options -> {max_len} ||= $options -> {size};
	$options -> {max_len} ||= 30;		
	
	my $s = $options -> {value};
	$s ||= $$data{$$options{name}};
	if ($options -> {picture}) {
		$s = format_picture ($s , $options -> {picture});
		$s =~ s/^\s+//g; 
	}
	
	$s =~ s/\"/\&quot\;/gsm; #";
	
	my $attributes = dump_attributes ($options -> {attributes});
	
	my $size = $options -> {size} ? "size=$$options{size} maxlength=$$options{size}" : "size=120";	
	
	$tabindex++;
	
	return qq {<input $attributes onFocus="scrollable_table_is_blocked = true; q_is_focused = true" onBlur="scrollable_table_is_blocked = false; q_is_focused = false" autocomplete="off" type="text" maxlength="$$options{max_len}" name="_$$options{name}" value="$s" $size onKeyPress="if (window.event.keyCode != 27) is_dirty=true" tabindex=$tabindex>};
	
}

################################################################################

sub draw_form_field_date {

	my ($options, $data) = @_;	
	$options -> {no_time} = 1;	
	return draw_form_field_datetime ($options, $data);

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
			$conf -> {format_d}   ||= '%d.%m.%Y';
			$options -> {format}  ||= $conf -> {format_d};
			$options -> {size}    ||= 11;
		}
		else {
			$conf -> {format_dt}  ||= '%d.%m.%Y %k:%M';
			$options -> {format}  ||= $conf -> {format_dt};
			$options -> {size}    ||= 16;
		}
	
	}
	
	$options -> {onClose} ||= 'null';
	
	my $s = $options -> {value};
	$s ||= $$data{$$options{name}};
	$s =~ s/\"/\&quot\;/gsm; #";
	
	$options -> {attributes} -> {id} = 'input_' . $options -> {name};
	
	$options -> {no_read_only} or $options -> {attributes} -> {readonly} = 1;
	
	my $attributes = dump_attributes ($options -> {attributes});
	
	my $size = $options -> {size} ? "size=$$options{size} maxlength=$$options{size}" : "size=30";	
	
	push @{$_REQUEST {__include_js}},  'jscalendar/calendar', 'jscalendar/lang/calendar-ru', 'jscalendar/calendar-setup';
	push @{$_REQUEST {__include_css}}, 'jscalendar/calendar-win2k-1';
	
	my $shows_time = $options -> {no_time} ? 'false' : 'true';
	
	my $clear_button = $options -> {no_clear_button} || $options -> {no_read_only} ? '' : qq{&nbsp;<button class="txt7" onClick="document.all._$$options{name}.value=''">X</button>};
	
	$tabindex++;
	
	return <<EOH
		<nobr>
		<input $attributes onFocus="scrollable_table_is_blocked = true; q_is_focused = true" onBlur="scrollable_table_is_blocked = false; q_is_focused = false" autocomplete="off" type="text" name="_$$options{name}" value="$s" $size onKeyPress="if (window.event.keyCode != 27) is_dirty=true" tabindex=$tabindex>
		<button id="calendar_trigger_$$options{name}" class="txt7">...</button>
		$clear_button
		</nobr>
		
		<script type="text/javascript">
			Calendar.setup(
				{
					inputField : "input_$$options{name}",
					ifFormat   : "$$options{format}",
					showsTime  : $shows_time,
					button     : "calendar_trigger_$$options{name}",
					onClose    : $$options{onClose}
				}
			);
		</script>

EOH
	
}

################################################################################

sub draw_form_field_file {
	my ($options, $data) = @_;	
	$options -> {size} ||= 60;
	$tabindex ++;
	return qq {<input onFocus="scrollable_table_is_blocked = true; q_is_focused = true" onBlur="scrollable_table_is_blocked = false; q_is_focused = false" type="file" name="_$$options{name}" size=$$options{size} onKeyPress="if (window.event.keyCode != 27) is_dirty=true" onChange="is_dirty=true; $$options{onChange}" tabindex=$tabindex>};
}

################################################################################

sub draw_form_field_hidden {
	my ($options, $data) = @_;
	my $s = $$data{$$options{name}};
	$s ||= $$options{value};
	$s =~ s/\"/\&quot\;/gsm; #"
	return qq {<input type="hidden" name="_$$options{name}" value="$s">};
}

################################################################################

sub draw_form_field_hgroup {
	my ($options, $data) = @_;
	map {$_ -> {label} .= '&nbsp;*' if $_ -> {mandatory}} @{$options -> {items}};
	map {$_ -> {label} = '' if $_ -> {off}} @{$options -> {items}};
	return join '&nbsp;&nbsp;', map {$_ -> {label} . ($_ -> {label} ? ': ' : '') . ($_ -> {off} ? '' : &{'draw_form_field_' . (($_REQUEST {__read_only} || $options -> {read_only} || $_ -> {read_only}) ? 'static' : $_ -> {type} ? $_ -> {type} : 'string')}($_, $data))} @{$options -> {items}};
}

################################################################################

sub draw_form_field_text {
	my ($options, $data) = @_;
	my $s = $$data{$$options{name}};
	$s =~ s/\"/\&quot\;/gsm; #"
	
	my $cols = $options -> {cols};
	$cols ||= 60;
	
	my $rows = $options -> {rows};
	$rows ||= 25;

	my $value = $options -> {value};
	$value ||= '';
	
	$tabindex++;

	return qq {<textarea onFocus="scrollable_table_is_blocked = true; q_is_focused = true" onBlur="scrollable_table_is_blocked = false; q_is_focused = false" rows=$rows cols=$cols name="_$$options{name}" value="$value" onKeyPress="if (window.event.keyCode != 27) is_dirty=true" tabindex=$tabindex>$s</textarea>};
}

################################################################################

sub draw_form_field_password {
	my ($options, $data) = @_;
	$options -> {size} ||= $conf -> {size} || 120;	
	$tabindex++;
	return qq {<input type="password" name="_$$options{name}" size="$$options{size}" onKeyPress="if (window.event.keyCode != 27) is_dirty=true" tabindex=$tabindex>};
}

################################################################################

sub draw_form_field_static {

	my ($options, $data) = @_;
	
	my $hidden_name = $$options{hidden_name};
	$hidden_name ||= $$options{name};

	my $hidden_value = $$options{hidden_value};
	$hidden_value ||= $$data{$$options{name}};
	$hidden_value ||= $$options{value};
	$hidden_value =~ s/\"/\&quot\;/gsm; #"
	
	my $value = $data -> {$options -> {name}};
	
	my $static_value = '';
	
	if (ref $value eq ARRAY) {
		
		foreach my $v (@$value) {
			$static_value .= ', ' if $static_value;
			foreach my $pv (@{$options -> {values}}) {
				$pv -> {id} eq $v or next;
				$static_value .= $pv -> {label};
			}						
		}
		
	}
	else {
		$static_value = 
			ref $options -> {values} eq ARRAY ? (map {$_ -> {label}} grep {$_ -> {id} == $value} @{$options -> {values}})[0] : 
			ref $options -> {values} eq HASH ?  $options -> {values} -> {$value} : 
			($options -> {value} || $value);
	}
				
		
		
	$static_value = format_picture ($static_value, $options -> {picture}) if $options -> {picture};	
		
	if ($options -> {href}) {
	
		check_href ($options);
		$options -> {a_class} ||= 'lnk4';
		$static_value = qq{<a href="$$options{href}" target="$$options{target}" class="$$options{a_class}">$static_value</a>}
	
	}

	return $$options{add_hidden} ? qq {$static_value <input type=hidden name="$hidden_name" value="$hidden_value">} : $static_value;
	
}

################################################################################

sub draw_form_field_radio {

	my ($options, $data) = @_;
	
	my $html = '';
		
	foreach my $value (@{$options -> {values}}) {
		$tabindex++;
		my $checked = $data -> {$options -> {name}} == $value -> {id} ? 'checked' : '';
		$html .= qq {<input onFocus="scrollable_table_is_blocked = true; q_is_focused = true" onBlur="scrollable_table_is_blocked = false; q_is_focused = false" type="radio" name="_$$options{name}" value="$$value{id}" $checked onClick="is_dirty=true" tabindex=$tabindex>&nbsp;$$value{label} <br>};
	}
		
	return $html;
	
}

################################################################################

sub draw_form_field_checkbox {

	my ($options, $data) = @_;
	
	my $s = $options -> {checked} || $data -> {$options -> {name}};
	
	$s =~ s/\"/\&quot\;/gsm; #"
	
	my $checked = $s ? 'checked' : '';
	
	$tabindex++;
	
	return qq {<input type="checkbox" name="_$$options{name}" value="1" $checked onChange="is_dirty=true" tabindex=$tabindex>};
	
}

################################################################################

sub draw_form_field_checkboxes {

	my ($options, $data) = @_;
	
	my $html = '';
	
	my $v = $data -> {$options -> {name}};
	
	if (ref $v eq ARRAY) {
	
		foreach my $value (@{$options -> {values}}) {
				
			my $checked = 0 + (grep {$_ eq $value -> {id}} @$v) ? 'checked' : '';

			my $id = 'div_' . $value;
			my $subhtml = '';
			my $subattr = '';
			
			if ($value -> {items} && @{$value -> {items}} > 0) {
			
			
				foreach my $subvalue (@{$value -> {items}}) {
									
					my $subchecked = 0 + (grep {$_ eq $subvalue -> {id}} @$v) ? 'checked' : '';
					
					$tabindex++;
					
					$subhtml .= qq {&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<input type="checkbox" name="_$$options{name}_$$subvalue{id}" value="1" $subchecked onChange="is_dirty=true" tabindex=$tabindex>&nbsp;$$subvalue{label} <br>};
				
				}

				my $display = $checked ? '' : 'style={display:none}';
				
				$subhtml = <<EOH;
					<div id="$id" $display>
						$subhtml
					</div>
EOH
			
				$subattr = qq{onClick="setVisible('$id', checked)"};
			
			}
		
			$tabindex++;

			$html .= qq {<input $subattr type="checkbox" name="_$$options{name}_$$value{id}" value="1" $checked onChange="is_dirty=true" tabindex=$tabindex>&nbsp;$$value{label} <br> $subhtml};
			
		}		
	
	}
	else {
	
		foreach my $value (@{$options -> {values}}) {
			my $checked = $v eq $value -> {id} ? 'checked' : '';
			$tabindex++;
			$html .= qq {<input type="checkbox" name="_$$options{name}" value="$$value{id}" $checked onChange="is_dirty=true" tabindex=$tabindex>&nbsp;$$value{label} <br>};
		}
		
	}
		
	if ($options -> {height}) {
		$html = <<EOH;
			<div style="height: $$options{height}px; overflow: auto;">
				$html
			</div>
EOH
	}
		
	return $html;
	
}

################################################################################

sub draw_toolbar_input_select {

	my ($options) = @_;
	
	my $html = '';
	
	$options -> {max_len} ||= $conf -> {max_len};
	
	if (defined $options -> {empty}) {
		$html .= qq {<option value=0 $selected>$$options{empty}</option>};
	}

	foreach my $value (@{$options -> {values}}) {		
		my $selected = (($value -> {id} eq $_REQUEST {$options -> {name}}) or ($value -> {id} eq $options -> {value})) ? 'selected' : '';
		my $label = trunc_string ($value -> {label}, $options -> {max_len});						
		$html .= qq {<option value="$$value{id}" $selected>$label</option>};
	}
		
	return <<EOH;
		<td>
		<select name="$$options{name}" onChange="submit()" onkeypress="typeAhead()">
			$html
		</select>
		</td>
		<td><img height=15  hspace=4 src="/i/toolbars/razd1.gif" width=2 border=0></td>
EOH
	
}

################################################################################

sub draw_toolbar_input_checkbox {

	my ($options) = @_;
	
	my $html = '';
	
	my $checked = $_REQUEST {$options -> {name}} ? 'checked' : '';
				
	return <<EOH;
		<td nowrap>
			$$options{label}:&nbsp;
		</td>
		<td>
			<input type=checkbox value=1 $checked name="$$options{name}" onClick="submit()">
		</td>
		<td><img height=15  hspace=4 src="/i/toolbars/razd1.gif" width=2 border=0></td>
EOH
	
}

################################################################################

sub draw_form_field_select {

	my ($options, $data) = @_;
	
	my $html = defined $options -> {empty} ? qq {<option value="0" $selected>$$options{empty}</option>\n} : '';
	
	$options -> {max_len} ||= $conf -> {max_len};
	
	foreach my $value (@{$options -> {values}}) {
		my $selected = (($value -> {id} eq $data -> {$options -> {name}}) or ($value -> {id} eq $options -> {value})) ? 'selected' : '';
		my $label = trunc_string ($value -> {label}, $options -> {max_len});						
		my $id = $value -> {id};
		$value -> {id} =~ s{\"}{\&quot;}g;
		$html .= qq {<option value="$$value{id}" $selected>$label</option>\n};
	}
	
	my $multiple = $options -> {rows} > 1 ? "multiple size=$$options{rows}" : '';
	
	$tabindex ++;
		
	return <<EOH;
		<select name="_$$options{name}" onChange="is_dirty=true; $$options{onChange}" onkeypress="typeAhead()" $multiple  tabindex='$tabindex'>
			$html
		</select>
EOH
	
}

################################################################################

sub draw_esc_toolbar {

	my ($options) = @_;
		
	$options -> {href} = $options -> {esc};
	$options -> {href} ||= "/?type=$_REQUEST{type}";
	check_href ($options);

	draw_centered_toolbar ($options, [
		@{$options -> {additional_buttons}},
		{
			icon => 'cancel', 
			label => $i18n -> {cancel}, 
			href => $options -> {href}, 
			id => 'esc'
		},
	])
	
}

################################################################################

sub draw_ok_esc_toolbar {

	my ($options) = @_;		
	
	$options -> {href} = $options -> {esc};
	$options -> {href} ||= "/?type=$_REQUEST{type}";
	check_href ($options);

	my $name = $options -> {name};
	$name ||= 'form';
	
	$options -> {label_ok}     ||= $i18n -> {ok};
	$options -> {label_cancel} ||= $i18n -> {cancel};

	draw_centered_toolbar ($options, [
		{
			icon => 'ok',     
			label => $options -> {label_ok}, 
#			href => '#', 
#			onclick => "document.$name.submit()",
			href => "javaScript:document.$name.submit()", 
			id   => 'ok',
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

sub draw_close_toolbar {
	
	my ($options) = @_;		

	draw_centered_toolbar ({}, [
		@{$options -> {additional_buttons}},
		{
			icon => 'ok',     
			label => $i18n -> {'close'}, 
			href => 'javascript:window.close()',
			id => 'esc',
		},
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
		{icon => 'back', label => $i18n -> {back}, href => $back, id => 'esc'},
		@{$options -> {additional_buttons}},
		{icon => 'next', label => $i18n -> {'next'}, href => '#', onclick => "document.$name.submit()"},
	])
	
}

################################################################################

sub draw_centered_toolbar_button {

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

	my ($bra, $ket, $icon) = ();
	if ($conf -> {core_show_icons} && $options -> {icon}) {	
		$icon = qq|<td><a onclick="$$options{onclick}" href="$$options{href}" target="$$options{target}"><img hspace=3 src="/i/buttons/$$options{icon}.gif" border=0></a></td>|
	}
	else {
		$bra = '<b>[';
		$ket = ']</b>';
	}
	
	return <<EOH
		$icon
		<td nowrap>&nbsp;<a class=lnk0 onclick="$$options{onclick}" id="$$options{id}" href="$$options{href}" target="$$options{target}">${bra}$$options{label}${ket}</a>&nbsp;</td>
		<td><img height=15 hspace=4 src="/i/toolbars/razd1.gif" width=2 border=0></td>
EOH

}

################################################################################

sub draw_centered_toolbar {

	$_REQUEST{lpt} and return '';

	my ($options, $list) = @_;

	my $colspan = 3 * (1 + @$list) + 1;

	return <<EOH;
	
		<table cellspacing=0 cellpadding=0 width="100%" border=0>
			<tr>
				<td class=bgr5>
					<table cellspacing=0 cellpadding=0 width="100%" border=0>
						<tr>
							<td class=bgr0 colspan=$colspan><img height=1 src="$_REQUEST{__uri}0.gif" width=1 border=0></td>
						</tr>
						<tr>
							<td class=bgr6 colspan=$colspan><img height=1 src="$_REQUEST{__uri}0.gif" width=1 border=0></td></tr>
								<tr>
									<td width="45%">
										<table cellspacing=0 cellpadding=0 width="100%" border=0>
											<tr>
												<td _background="/i/toolbars/6ptbg.gif"><img height=17 hspace=0 src="$_REQUEST{__uri}0.gif" width=1 border=0></td>
											</tr>
										</table>
									</td>
									<td><img height=15 hspace=4 src="/i/toolbars/razd1.gif" width=2 border=0></td>
									@{[ map {draw_centered_toolbar_button ($_)} @$list]}
									<td width="45%">
										<table cellspacing=0 cellpadding=0 width="100%" border=0>
											<tr>
												<td _background="/i/toolbars/6ptbg.gif"><img height=17 hspace=0 src="$_REQUEST{__uri}0.gif" width=1 border=0></td>
											</tr>
										</table>
									</td>
									<td align=right><img height=23 src="$_REQUEST{__uri}0.gif" width=4 border=0></td>
								</tr>
								<tr>
									<td class=bgr8 colspan=$colspan><img height=1 src="$_REQUEST{__uri}0.gif" width=1 border=0></td>
								</tr>
								<tr>
									<td class=bgr6 colspan=$colspan><img height=1 src="$_REQUEST{__uri}0.gif" width=1 border=0></td>
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

sub draw_auth_toolbar {

	$_REQUEST {__no_navigation} and return '';

	my ($options) = @_;		
	
	my $calendar = <<EOH;
		<td class=bgr1><img height=22 src="$_REQUEST{__uri}0.gif" width=4 border=0></td>
		<td class=bgr1><A class=lnk2>@{[ $_CALENDAR -> draw () ]}</A></td>
		<td class=bgr1><img height=22 src="$_REQUEST{__uri}0.gif" width=4 border=0></td>				
EOH

	$top_banner = interpolate ($conf -> {top_banner});
		
	my $exit_url = $conf -> {exit_url} || "$_REQUEST{__uri}?type=_logout&sid=$_REQUEST{sid}";
	
	return <<EOH;

		<table cellSpacing=0 cellPadding=0 border=0 width=100%>
			<tr><td class=bgr1><img height=1 src="$_REQUEST{__uri}0.gif" width=1 height=1 border=0></td></tr>
			<tr><td class=bgr6><img height=1 src="$_REQUEST{__uri}0.gif" width=1 height=1 border=0></td></tr>
		</table>
		<table cellSpacing=0 cellPadding=0 border=0 width=100%>
			<tr>
				<td class=bgr1><nobr>&nbsp;&nbsp;</nobr></td>

				<td class=bgr1><img height=22 src="$_REQUEST{__uri}0.gif" width=4 border=0></td>
				<td class=bgr1><nobr><A class=lnk2>$$i18n{User}: @{[ $_USER && $_USER -> {label} ? $_USER -> {label} : $i18n -> {not_logged_in}]}</a>&nbsp;&nbsp;</nobr></td>

				$calendar

				<td class=bgr1 nowrap width="100%"></td>							
				
				@{[ $options -> {lpt} ? <<EOLPT : '']}
				<td class=bgr1><img height=22 src="$_REQUEST{__uri}0.gif" width=4 border=0></td>
				<td class=bgr1><nobr><A class=lnk2 href="@{[ create_url (lpt => 1) ]}" target="_blank">[$$i18n{Print}]</a>&nbsp;&nbsp;</nobr></td>

				<td class=bgr1><img height=22 src="$_REQUEST{__uri}0.gif" width=4 border=0></td>
				<td class=bgr1><nobr><A class=lnk2 href="@{[ create_url (xls => 1, salt => rand) ]}" target="_blank">[MS Excel]</a>&nbsp;&nbsp;</nobr></td>
EOLPT

				@{[ $_REQUEST {__help_url} ? <<EOHELP : '' ]}
				<td class=bgr1><img height=22 src="$_REQUEST{__uri}0.gif" width=4 border=0></td>
				<td class=bgr1><nobr><A id="help" class=lnk2 href="$_REQUEST{__help_url}" target="_blank">[$$i18n{F1}]</A>&nbsp;&nbsp;</nobr></td>
EOHELP

				@{[ $$_USER{id} ? <<EOEXIT : '' ]}
				<td class=bgr1><img height=22 src="$_REQUEST{__uri}0.gif" width=4 border=0></td>
				<td class=bgr1><nobr><A class=lnk2 href="$exit_url">[$$i18n{Exit}]</A>&nbsp;&nbsp;</nobr></td>
EOEXIT

				<td class=bgr1><img height=22 src="$_REQUEST{__uri}0.gif" width=4 border=0></td>
				<td class=bgr1><img height=1 src="$_REQUEST{__uri}0.gif" width=7 border=0></td>
			</tr>
		</table>
		$top_banner
		<table cellSpacing=0 cellPadding=0 border=0 width=100%>
			<tr><td class=bgr7><img height=1 src="$_REQUEST{__uri}0.gif" width=1 height=1 border=0></td></tr>
			<tr><td class=bgr1><img height=1 src="$_REQUEST{__uri}0.gif" width=1 height=1 border=0></td></tr>
		</table>

EOH

}

################################################################################

sub draw_form_field_image {
	my ($options, $data) = @_;
	my $s = $$data{$$options{name}};
	$s =~ s/\"/\&quot\;/gsm; #"
	return <<EOS;
<input type="hidden" name="_$$options{name}" value="$$options{id_image}">
<img src="$$options{src}" id="$$options{name}_preview" width = "$$options{width}" height = "$$options{height}">
&nbsp;
<input type="button" value="$$i18n{Select}" onClick="window.open('$$options{new_image_url}', 'selectImage' , '');">
EOS

}

################################################################################

sub draw_form_field_iframe {
	
	my ($options, $data) = @_;

	check_href ($options);
	
	$options -> {width} ||= '100%';
	$options -> {height} ||= '100%';

	return <<EOH;
		<iframe name="$$options{name}" src="$$options{href}" width="$$options{width}" height="$$options{height}"></iframe>
EOH

}

################################################################################

sub draw_radio_cell {

	my ($options) = @_;
	my $value = $options -> {value} || 1;
	
	my $checked = $options -> {checked} ? 'checked' : '';

	$options -> {attributes} ||= {};
	$options -> {attributes} -> {class} ||= 'txt4';

	my $attributes = dump_attributes ($options -> {attributes});

	return qq {<td $attributes>&nbsp;} if $options -> {off};	

	check_title ($options);

	return qq {<td $$options{title} $attributes><input type=radio name=$$options{name} $checked value='$value'></td>};

}

################################################################################

sub draw_select_cell {

	my ($data, $options) = @_;

	$data -> {attributes} ||= {};
	$data -> {attributes} -> {class} ||= 'txt4';

	my $attributes = dump_attributes ($data -> {attributes});
	return qq {<td $attributes>&nbsp;} if $data -> {off};	

	my $html = defined $data -> {empty} ? qq {<option value="0">$$data{empty}</option>\n} : '';

	$data -> {max_len} ||= $conf -> {max_len};

	foreach my $value (@{$data -> {values}}) {
		my $selected = ($value -> {id} eq $data -> {value}) ? 'selected' : '';
		my $label = trunc_string ($value -> {label}, $data -> {max_len});						
		my $id = $value -> {id};
		$value -> {id} =~ s{\"}{\&quot;}g;
		$html .= qq {<option value="$$value{id}" $selected>$label</option>\n};
	}
	
	my $multiple = $data -> {rows} > 1 ? "multiple size=$$options{rows}" : '';

	return qq {<td $attributes><nobr><select name="$$data{name}" onChange="is_dirty=true; $$options{onChange}" onkeypress="typeAhead()" $multiple>$html</select></nobr></td>};
	
}

################################################################################

sub draw_form_field_htmleditor {
	
	my ($options, $data) = @_;
	
	return '' if $options -> {off};
	
	push @{$_REQUEST{__include_js}}, 'rte/fckeditor';
	
	my $s = $$data{$$options{name}};
		
	$s =~ s{\\}{\\\\}gsm;
	$s =~ s{\"}{\\\"}gsm;
	$s =~ s{\'}{\\\'}gsm;
	$s =~ s{[\n\r]+}{\\n}gsm;

	return <<EOS;
		<SCRIPT language="javascript">
<!--
var oFCKeditor_$$options{name} ;
oFCKeditor_$$options{name} = new FCKeditor('_$$options{name}', '$$options{width}', '$$options{height}', '$$options{toolbar}');
oFCKeditor_$$options{name}.Value = '$s';
oFCKeditor_$$options{name}.Create() ;
//-->
		</SCRIPT>
EOS
}

1;