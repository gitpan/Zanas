################################################################################

sub MSIE_5_register_hotkey {

	my ($hashref, $type, $data) = @_;

	$hashref -> {label} =~ s{\&(.)}{<u>$1</u>} or return;
	
	my $c = $1;
	
	my $code = 0;
	
	if ($c eq '<') {
		$code = 37; #188;
	}
	elsif ($c eq '>') {
		$code = 39; #190;
	}
	else {
		$c =~ y{����������������������������������������������������������������}{qwertyuiop[]asdfghjkl;'zxcvbnm,.qwertyuiop[]asdfghjkl;'zxcvbnm,.};
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
		
		eval {
			$body = call_for_role ($renderrer, call_for_role ($selector));
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
					<title>���</title>
				</head>
				<body bgcolor=white leftMargin=0 topMargin=0 marginwidth="0" marginheight="0">
					$body
				</body>
			</html>
EOH

	}
	
	$_USER -> {role} eq 'admin' and $_REQUEST{id} or my $lpt = $body =~ s{<table[^\>]*lpt\=\"?1\"?[^\>]*\>}{\<table cellspacing\=1 cellpadding\=5 width\=100\%\>}gsm; #"
	
	my $menu = draw_menu ($page -> {menu}, $page -> {highlighted_type});
	
	return <<EOH;
		<html>
			<head>
				<title>$$conf{page_title}</title>
				<LINK href="/i/new.css" type=text/css rel=STYLESHEET>
				<script src="/i/js.js">
				</script>
				<script>
					var scrollable_table = null;
					var scrollable_table_row = 0;
					var scrollable_table_row_cell = 0;						
					var scrollable_table_row_cell_old_style = '';
					var is_dirty = false;					
					var scrollable_table_is_blocked = false;
				</script>
				<SCRIPT language="javascript" src="/i/rte/fckeditor.js"></SCRIPT>
			</head>
			<body bgcolor=white leftMargin=0 topMargin=0 marginwidth="0" marginheight="0" name="body" id="body">

				<script for="body" event="onload">
				
					scrollable_table = getElementById ('scrollable_table');
							
					if (scrollable_table) {				
				
						scrollable_table = scrollable_table.tBodies (0);
					
						scrollable_table_row = 0;
						scrollable_table_row_cell = 0;

						if (scrollable_table.rows.length > 0) {
							scrollable_table_row_cell_old_style = scrollable_table.rows [scrollable_table_row].cells [scrollable_table_row_cell].className;
							scrollable_table.rows [scrollable_table_row].cells [scrollable_table_row_cell].className = 'txt6';
						}
						else {
							scrollable_table = null;
						}
						
					}
					
					var inputs = document.body.getElementsByTagName ('input');
					if (inputs != null) {
						for (var i = 0; i < inputs.length; i++) {
							if (inputs [i].type != 'text') continue;
							inputs [i].focus ();
							break;
						}					
					}

				</script>

				<script for="body" event="onkeydown">
								
					if (window.event.keyCode == 88 && window.event.altKey) {
							
						document.location.href = '/?_salt=@{[rand]}';
							
					}

					if (scrollable_table && !scrollable_table_is_blocked) {
				
						if (window.event.keyCode == 40 && scrollable_table_row < scrollable_table.rows.length - 1) {

							scrollable_table.rows [scrollable_table_row].cells [scrollable_table_row_cell].className = scrollable_table_row_cell_old_style;
							scrollable_table_row ++;
							scrollable_table_row_cell_old_style = scrollable_table.rows [scrollable_table_row].cells [scrollable_table_row_cell].className;
							scrollable_table.rows [scrollable_table_row].cells [scrollable_table_row_cell].className = 'txt6';
							scrollable_table.rows [scrollable_table_row].cells [scrollable_table_row_cell].scrollIntoView (false);
							event.returnValue = false;						

						}

						if (window.event.keyCode == 38 && scrollable_table_row > 0) {

							scrollable_table.rows [scrollable_table_row].cells [scrollable_table_row_cell].className = scrollable_table_row_cell_old_style;
							scrollable_table_row --;
							scrollable_table_row_cell_old_style = scrollable_table.rows [scrollable_table_row].cells [scrollable_table_row_cell].className;
							scrollable_table.rows [scrollable_table_row].cells [scrollable_table_row_cell].className = 'txt6';					
							scrollable_table.rows [scrollable_table_row].cells [scrollable_table_row_cell].scrollIntoView ();
							event.returnValue = false;

						}

						if (window.event.keyCode == 37 && scrollable_table_row_cell > 0) {

							scrollable_table.rows [scrollable_table_row].cells [scrollable_table_row_cell].className = scrollable_table_row_cell_old_style;
							scrollable_table_row_cell --;
							scrollable_table_row_cell_old_style = scrollable_table.rows [scrollable_table_row].cells [scrollable_table_row_cell].className;
							scrollable_table.rows [scrollable_table_row].cells [scrollable_table_row_cell].className = 'txt6';
							event.returnValue = false;

						}

						if (window.event.keyCode == 39 && scrollable_table_row_cell < scrollable_table.rows [scrollable_table_row].cells.length - 1) {

							scrollable_table.rows [scrollable_table_row].cells [scrollable_table_row_cell].className = scrollable_table_row_cell_old_style;
							scrollable_table_row_cell ++;
							scrollable_table_row_cell_old_style = scrollable_table.rows [scrollable_table_row].cells [scrollable_table_row_cell].className;
							scrollable_table.rows [scrollable_table_row].cells [scrollable_table_row_cell].className = 'txt6';
							event.returnValue = false;

						}

						if (window.event.keyCode == 13) {
							
							var children = scrollable_table.rows [scrollable_table_row].cells [scrollable_table_row_cell].getElementsByTagName ('a');
							if (children != null) document.location.href = children [0].href + '&_salt=@{[rand]}';
							
						}
						
					}

					@{[ map {&{"MSIE_5_handle_hotkey_$$_{type}"} ($_)} @scan2names ]}				
							
				</script>
						
				@{[ 				
					draw_auth_toolbar ({lpt => $lpt}) 
				]}
				
				$menu
				$body
				<iframe name=invisible src="/i/0.html" width=0 height=0>
				</iframe>
			</body>
		</html>
EOH
	
}

################################################################################

sub MSIE_5_draw_menu {

	my ($types, $cursor) = @_;
	
	@$types or return '';

	my ($tr1, $tr2, $tr3) = ('', '', '');

	foreach my $type (@$types)	{
	
		MSIE_5_register_hotkey ($type, 'href', 'main_menu_' . $type -> {name});
	
		$tr1 .= <<EOH;
			<td class=bgr8 rowspan=2><img src="/i/toolbars/n_left.gif" border=0></td>
			<td bgcolor=#ffffff><img height=1 src="/i/0.gif" width=1 border=0></td>				
			<td class=bgr8 rowspan=2><img src="/i/toolbars/n_right.gif" border=0></td>
EOH
	
		my $aclass = $$type{name} eq $cursor ? 'lnk1' : 'lnk0';
		my $tclass = $$type{name} eq $cursor ? 'bgr4' : 'bgr8';

		$tr2 .= <<EOH;
			<td class=bgr1><img height=20 src="/i/0.gif" width=1 border=0></td>
			<td class=$tclass nowrap>&nbsp;&nbsp;<a class=$aclass id="main_menu_$$type{name}" href="/?type=$$type{name}&sid=$_REQUEST{sid}@{[$_REQUEST{period} ? '&period=' . $_REQUEST {period} : '']}">$$type{label}</a>&nbsp;&nbsp;</td>
EOH

		$tr3 .= <<EOH;
			<td class=bgr1><img height=1 src="/i/0.gif" width=1 border=0></td>
			<td class=bgr1 nowrap><img height=1 src="/i/0.gif" width=1 border=0></td>
EOH

	}

	return <<EOH;
		<table width="100%" class=bgr8 cellspacing=0 cellpadding=0 border=0>
			<tr>
				<td class=bgr8 width=7><img height=1 src="/i/0.gif" width=7 border=0></td>
				$tr2
				<td class=bgr1><img height=20 src="/i/0.gif" width=1 border=0></td>
				<td class=bgr8 width=100%><img height=1 src="/i/0.gif" width=1 border=0></td>
			<tr>
				<td class=bgr8><img height=1 src="/i/0.gif" width=1 border=0></td>
				$tr3
				<td class=bgr1><img height=1 src="/i/0.gif" width=1 border=0></td>
				<td class=bgr8 width=100%><img height=1 src="/i/0.gif" width=1 border=0></td>
				
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
			<tr><td class=$options{class}><img src="/i/0.gif" width=1 height=$options{height}></td></tr>
		</table>
EOH
	
}

################################################################################

sub MSIE_5_draw_text_cell {

	my ($data) = @_;
	
	return '' if $data -> {off};

	my $txt = $data -> {label};
	
	if ($data -> {href}) {
		check_href ($data);
		my $target = $data -> {target} ? "target='$$data{target}'" : '';
		$txt = qq { <a class=lnk4 $target href="$$data{href}" onFocus="blur()">$txt</a> };
	}
	
	return qq {<td class=txt4><nobr>$txt</nobr></td>};

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

sub MSIE_5_draw_table {

	my ($headers, $ths) = ([], '');

	unless (ref $_[0] eq CODE) {
		$headers = shift;
	}
	
	if (@$headers) {
		$ths = '<tr>' . (join '', map { ref $_ eq HASH ? ($$_{off} ? '' : "<th class=bgr4>$$_{label}\&nbsp;") : "<th class=bgr4>$_\&nbsp;" } @$headers);
	}

	my ($tr_callback, $list) = @_;
	
	my $trs = '';
	
	foreach our $i (@$list) {
		$trs .= '<tr>';
		$trs .= &$tr_callback ($item);
	}
	
	return <<EOH
		<table cellspacing=0 cellpadding=0 width="100%"><tr><td class=bgr8>
			<table cellspacing=1 cellpadding=5 width="100%" id="scrollable_table">
				<thead>
					$ths
				</thead>
				<tbody>
					$trs
				</tbody>
			</table>
		</table>
EOH

}

################################################################################

sub MSIE_5_draw_path {

	$_REQUEST{lpt} and return '';

	my ($options, $list) = @_;
	
	$options -> {id_param} ||= 'id';
	
	$path = '';
	
	foreach my $item (@$list) {
	
		$path and $path .= '&nbsp;/&nbsp;';
		
		$id_param = $item -> {id_param};
		$id_param ||= $options -> {id_param};
		
		$path .= <<EOH;
			<a class=lnk1 href="/?type=$$item{type}&$id_param=$$item{id}&sid=$_REQUEST{sid}">$$item{name}</a>
EOH
	
	}

	return draw_hr (height => 10) . <<EOH
		<table cellspacing=0 cellpadding=0 width="100%" border=0>
			<tr>
				<td class=bgr5>
					<table cellspacing=0 cellpadding=0 width="100%" border=0>
						<tr>
							<td class=bgr6 colspan=4><img height=1 src="/i/0.gif" width=1 border=0></td>
						</tr>
						<tr>
							<td><img height=14 hspace=4 src="/i/toolbars/4pt.gif" width=2 border=0></td>
							<td class=header6 nowrap>&nbsp;$path&nbsp;</td>
							<td width="100%">
								<table cellspacing=0 cellpadding=0 width="100%" border=0>
									<tr>
										<td _background="/i/toolbars/4pt.gif" height=15><img height=15  hspace=0 src="/i/0.gif" width=1 border=0></td>
									</tr>
								</table>
							</td>
							<td align=right><img height=15  src="/i/0.gif" width=4 border=0></td>
						</tr>
						<tr>
							<td class=bgr8 colspan=4><img height=1 src="/i/0.gif" width=1 border=0></td>
						</tr>
						<tr>
							<td class=bgr6 colspan=4><img height=1 src="/i/0.gif" width=1 border=0></td>
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
	
	return <<EOH
		<table cellspacing=0 cellpadding=0 width="100%"><tr><td class=header15><img src="/i/0.gif" width=1 height=20 align=absmiddle>&nbsp;&nbsp;&nbsp;$$options{label}</table>
EOH

}

################################################################################

sub MSIE_5_draw_toolbar {

	my ($options, @buttons) = @_;
	
	return '' if $options -> {off};
	
	return <<EOH
		<table class=bgr5 cellspacing=0 cellpadding=0 width="100%" border=0>
			<form action=/>
				<input type=hidden name=sid value=$_REQUEST{sid}>
				<tr>
					<td class=bgr0 colspan=15><img height=1 src="/i/0.gif" width=1 border=0></td>
				</tr>
				<tr>
					<td class=bgr6 colspan=15><img height=1 src="/i/0.gif" width=1 border=0></td>
				</tr>
				<tr>
					<td width=20>
						<table cellspacing=0 cellpadding=0 width=20 border=0>
							<tr>
								<td _background="/i/toolbars/6ptbg.gif"><img height=17 hspace=0 src="/i/0.gif" width=1 border=0></td>
							</tr>
						</table>
					</td>
					@buttons
					<td width="100%">
						<table cellspacing=0 cellpadding=0 width="100%" border=0>
							<tr>
								<td _background="/i/toolbars/6ptbg.gif"><img height=17 hspace=0 src="/i/0.gif" width=1 border=0></td>
							</tr>
						</table>
					</td>
					<td align=right><img height=23 src="/i/0.gif" width=4 border=0></td>
				</tr>
				<tr>
					<td class=bgr8 colspan=15><img height=1 src="/i/0.gif" width=1 border=0></td>
				</tr>
				<tr>
					<td class=bgr6 colspan=15><img height=1 src="/i/0.gif" width=1 border=0></td>
				</tr>
			</form>
		</table>
EOH

}

################################################################################

sub MSIE_5_draw_toolbar_button {

	my ($options) = @_;
	
	MSIE_5_register_hotkey ($options, 'href', $options);
	
	check_href ($options);
	
	return <<EOH
		<td nowrap>&nbsp;<a class=lnk0 href="$$options{href}" id="$options"><b>[$$options{label}]</b></a></td>
		<td><img height=15 hspace=4 src="/i/toolbars/razd1.gif" width=2 border=0></td>
EOH

}

################################################################################

sub MSIE_5_draw_toolbar_input_text {

	my ($options) = @_;
	
	return <<EOH
		<td nowrap>$$options{label}: <input type=text name=$$options{name} value="$_REQUEST{$$options{name}}" onFocus="scrollable_table_is_blocked = true" onBlur="scrollable_table_is_blocked = false"><input type=hidden name=search value=1><input type=hidden name=type value="$_REQUEST{type}"></td>
		<td><img height=15  hspace=4 src="/i/toolbars/razd1.gif" width=2 border=0></td>
EOH

}

################################################################################

sub MSIE_5_draw_toolbar_pager {

	my ($options) = @_;

	my $start = $_REQUEST {start} + 0;

	my $label = '';	

	if ($start > $conf -> {portion}) {
		$url = create_url (start => 0);
		$label .= qq {&nbsp;<a href="$url" class=lnk0 onFocus="blur()"><b>&lt;&lt;</b></a>&nbsp;};
	}

	if ($start > 0) {
		MSIE_5_register_hotkey ({label => '&<'}, 'href', '_pager_prev');
		$url = create_url (start => $start - $conf -> {portion});
		$label .= qq {&nbsp;<a href="$url" class=lnk0 id="_pager_prev" onFocus="blur()"><b><u>&lt;</u></b></a>&nbsp;};
	}
	
	$label .= ($start + 1) . ' - ' . ($start + $$options{cnt}) . ' �� ' . $$options{total};
	
	if ($start + $$options{cnt} < $$options{total}) {
		MSIE_5_register_hotkey ({label => '&>'}, 'href', '_pager_next');
		$url = create_url (start => $start + $conf -> {portion});
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
	
	return '' if $options -> {off};
	
	check_href ($options);
	
	if ($options -> {confirm}) {
		my $salt = rand;
		my $msg = js_escape ($options -> {confirm});
		$options -> {href} = qq [javascript:if (confirm ($msg)) {window.open('$$options{href}', '_self')}];
	} 

	return qq {<a class=lnk0 title="$$options{label}" href="$$options{href}" onFocus="blur()">\&nbsp;<b>[$$options{label}]</b>\&nbsp;</a>};

}

################################################################################

sub MSIE_5_draw_row_buttons {

	my ($options, $buttons) = @_;

	return '<td class=bgr4 valign=top nowrap width="1%">' . (join '', map {draw_row_button ($_)} @$buttons) . '</td>';

}

################################################################################

sub MSIE_5_draw_form {

	my ($options, $data, $fields) = @_;
	
	my $action = $options -> {action};
	$action ||= 'update';
	
	my $type = $options -> {type};
	$type ||= $_REQUEST{type};

	my $id = $options -> {id};
	$id ||= $_REQUEST{id};

	my $trs = '';
	my $n = 0;	
	
	foreach my $field (@$fields) {
	
		next if $field -> {off};
		
		my $type = $field -> {type};
		$type ||= 'string';
		
		my $html = &{"draw_form_field_$type"} ($field, $data);
	
		my ($c1, $c2) = $n++ % 2 ? (5, 4) : (4, 0);
		
		MSIE_5_register_hotkey ($field, 'focus', '_' . $field -> {name});
				
		$trs .= $type eq 'hidden' ? $html : <<EOH;
			<tr>
				<td class=header$c1 nowrap align=right width="20%">$$field{label}: </td>
				<td class=bgr$c2>$html</td></tr>
EOH
	
	}
	
	my $path = $data -> {path} ? draw_path ({}, $data -> {path}) : '';
	
	my $bottom_toolbar = 
		$options -> {bottom_toolbar} ? $options -> {bottom_toolbar} :		
		$options -> {back} ? draw_back_next_toolbar ($options) :
		draw_ok_esc_toolbar ($options);

	return <<EOH
$path<table cellspacing=1 cellpadding=5 width="100%">

			@{[ MSIE_5_js_ok_escape () ]}
			
			<form name=form action=/ method=post enctype=multipart/form-data target=invisible>
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

	return <<EOH
	
		<script for="body" event="onkeypress">
		
			if (window.event.keyCode == 27 && (!is_dirty || window.confirm ('���� ��� ���������� ������?'))) {
				window.location.href = document.getElementById ('esc').href + '&_salt=@{[rand]}';
			}
		
			if (window.event.keyCode == 10 && window.confirm ('��������� ������?')) {
				document.form.submit ();
			}
													
		</script>
		
EOH

}

################################################################################

sub MSIE_5_draw_form_field_string {
	my ($options, $data) = @_;
	my $s = $$data{$$options{name}};
	$s =~ s/\"/\&quot\;/gsm; #"
	my $size = $options -> {size} ? "size=$$options{size} maxlength=$$options{size}" : "size=120";	
	return qq {<input type="text" name="_$$options{name}" value="$s" $size onKeyPress="if (window.event.keyCode != 27) is_dirty=true">};
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
	return join '&nbsp;&nbsp;', map {$_ -> {label} . ': ' . &{'draw_form_field_' . $_ -> {type}}($_, $data)} @{$options -> {items}};
}

################################################################################

sub MSIE_5_draw_form_field_text {
	my ($options, $data) = @_;
	my $s = $$data{$$options{name}};
	$s =~ s/\"/\&quot\;/gsm; #"
	return qq {<textarea rows=25 cols=120 name="_$$options{name}" onKeyPress="if (window.event.keyCode != 27) is_dirty=true">$s</textarea>};
}

################################################################################

sub MSIE_5_draw_form_field_password {
	my ($options, $data) = @_;
	return qq {<input type="password" name="_$$options{name}" size=120 onKeyPress="if (window.event.keyCode != 27) is_dirty=true">};
}

################################################################################

sub MSIE_5_draw_form_field_static {
	my ($options, $data) = @_;
	return $$data{$$options{name}};
}

################################################################################

sub MSIE_5_draw_form_field_radio {

	my ($options, $data) = @_;
	
	my $html = '';
	
	foreach my $value (@{$options -> {values}}) {
		my $checked = $data -> {$options -> {name}} == $value -> {id} ? 'checked' : '';
		$html .= qq {<input type="radio" name="_$$options{name}" value="$$value{id}" $checked onClick="is_dirty=true">&nbsp;$$value{label} <br>};
	}
		
	return $html;
	
}

################################################################################

sub MSIE_5_draw_form_field_checkbox {

	my ($options, $data) = @_;
	
	my $s = $$data{$$options{name}};
	
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
	
	foreach my $value (@{$options -> {values}}) {
		my $selected = $data -> {$options -> {name}} == $value -> {id} ? 'selected' : '';
		$html .= qq {<option value="$$value{id}" $selected>$$value{label}</option>};		
	}
		
	return <<EOH;
		<select name="_$$options{name}" onChange="is_dirty=true">
			$html
		</select>
EOH
	
}

################################################################################

sub MSIE_5_draw_ok_esc_toolbar {

	my ($options) = @_;
		
	my $esc = $options -> {esc};
	$esc ||= "/?type=$_REQUEST{type}";
	
	draw_centered_toolbar ($options, [
		{icon => 'ok',     label => '���������', href => '#', onclick => 'document.form.submit()'},
		{icon => 'cancel', label => '���������', href => "$esc&sid=$_REQUEST{sid}", id => 'esc'},
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
		{icon => 'back', label => '&lt;&lt; �����', href => $back, id => 'esc'},
		{icon => 'next', label => '���������� &gt;&gt;', href => '#', onclick => 'document.form.submit()'},
	])
	
}

################################################################################

sub MSIE_5_draw_centered_toolbar_button {

	my ($options) = @_;
	
	check_href ($options);
	
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
							<td class=bgr0 colspan=$colspan><img height=1 src="/i/0.gif" width=1 border=0></td>
						</tr>
						<tr>
							<td class=bgr6 colspan=$colspan><img height=1 src="/i/0.gif" width=1 border=0></td></tr>
								<tr>
									<td width="45%">
										<table cellspacing=0 cellpadding=0 width="100%" border=0>
											<tr>
												<td _background="/i/toolbars/6ptbg.gif"><img height=17 hspace=0 src="/i/0.gif" width=1 border=0></td>
											</tr>
										</table>
									</td>
									<td><img height=15 hspace=4 src="/i/toolbars/razd1.gif" width=2 border=0></td>
									@{[ map {draw_centered_toolbar_button ($_)} @$list]}
									<td width="45%">
										<table cellspacing=0 cellpadding=0 width="100%" border=0>
											<tr>
												<td _background="/i/toolbars/6ptbg.gif"><img height=17 hspace=0 src="/i/0.gif" width=1 border=0></td>
											</tr>
										</table>
									</td>
									<td align=right><img height=23 src="/i/0.gif" width=4 border=0></td>
								</tr>
								<tr>
									<td class=bgr8 colspan=$colspan><img height=1 src="/i/0.gif" width=1 border=0></td>
								</tr>
								<tr>
									<td class=bgr6 colspan=$colspan><img height=1 src="/i/0.gif" width=1 border=0></td>
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

	my ($options) = @_;
	
	my $calendar = <<EOH;
		<td class=bgr1><img height=22 src="/i/0.gif" width=4 border=0></td>
		<td class=bgr1><A class=lnk2>@{[ $_CALENDAR -> draw () ]}</A></td>
		<td class=bgr1><img height=22 src="/i/0.gif" width=4 border=0></td>				
EOH

	return <<EOH;

		<table cellSpacing=0 cellPadding=0 border=0 width=100%>
			<tr><td class=bgr1><img height=1 src="/i/0.gif" width=1 height=1 border=0></td></tr>
			<tr><td class=bgr6><img height=1 src="/i/0.gif" width=1 height=1 border=0></td></tr>
		</table>
		<table cellSpacing=0 cellPadding=0 border=0 width=100%>
			<tr>
				<td class=bgr1><nobr>&nbsp;&nbsp;</nobr></td>

				<td class=bgr1><img height=22 src="/i/0.gif" width=4 border=0></td>
<!--				
				<td class=bgr1><img src="/i/top_tb_icons/user.gif" border=0 hspace=3 align=absmiddle></td>
-->				
				<td class=bgr1><nobr><A class=lnk2>������������: @{[ $_USER ? $_USER -> {label} : '������������ ����������']}</a>&nbsp;&nbsp;</nobr></td>

				$calendar

				<td class=bgr1 nowrap width="100%"></td>							
				
				@{[ $options -> {lpt} ? <<EOLPT : '']}
				<td class=bgr1><img height=22 src="/i/0.gif" width=4 border=0></td>
<!--				
				<td class=bgr1><img src="/i/top_tb_icons/gear.gif" border=0 hspace=3 align=absmiddle></td>
-->				
				<td class=bgr1><nobr><A class=lnk2 href="@{[ create_url (lpt => 1) ]}" target="_blank">[������]</a>&nbsp;&nbsp;</nobr></td>

				<td class=bgr1><img height=22 src="/i/0.gif" width=4 border=0></td>
<!--				
				<td class=bgr1><img src="/i/top_tb_icons/stat.gif" border=0 hspace=3 align=absmiddle></td>
-->				
				<td class=bgr1><nobr><A class=lnk2 href="@{[ create_url (xls => 1) ]}" target="_blank">[MS Excel]</a>&nbsp;&nbsp;</nobr></td>
EOLPT

				@{[ $_USER ? <<EOEXIT : '' ]}
				<td class=bgr1><img height=22 src="/i/0.gif" width=4 border=0></td>
<!--				
				<td class=bgr1><img src="/i/top_tb_icons/exit.gif" border=0 hspace=3 align=absmiddle></td>
-->				
				<td class=bgr1><nobr><A class=lnk2 href="/">[�����]</A>&nbsp;&nbsp;</nobr></td>
EOEXIT

				<td class=bgr1><img height=22 src="/i/0.gif" width=4 border=0></td>
				<td class=bgr1><img height=1 src="/i/0.gif" width=7 border=0></td>
			</tr>
		</table>
		<table cellSpacing=0 cellPadding=0 border=0 width=100%>
			<tr><td class=bgr7><img height=1 src="/i/0.gif" width=1 height=1 border=0></td></tr>
			<tr><td class=bgr1><img height=1 src="/i/0.gif" width=1 height=1 border=0></td></tr>
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
<input type="button" value="�������" onClick="window.open('$$options{new_image_url}', 'selectImage' , '');">
EOS

}

################################################################################

sub MSIE_5_draw_form_field_htmleditor {
	my ($options, $data) = @_;
	my $s = $$data{$$options{name}};
		
	$s =~ s{\"}{\\\"}gsm;
	$s =~ s{\'}{\\\'}gsm;
	$s =~ s{[\n\r]+}{\\n}gsm;

	return <<EOS;
		<SCRIPT language="javascript">
<!--
var oFCKeditor_$$options{name} ;
oFCKeditor_$$options{name} = new FCKeditor('_$$options{name}') ;
oFCKeditor_$$options{name}.Value = '$s';
oFCKeditor_$$options{name}.Create() ;
//-->
		</SCRIPT>
EOS
}



1;