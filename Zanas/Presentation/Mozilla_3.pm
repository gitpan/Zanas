################################################################################

sub Mozilla_3_draw_page {
	
	unless ($_REQUEST {'_frame'} or $_REQUEST {'error'}) {
	
		my $url = create_url () . '&_frame=1';
	
		return <<EOH;
		<html>
			<frameset rows="100%,1" border=0 frameborder=0 framespacing=0>
				<frame name="main" src="$url" frameborder=0 marginwidth=0 marginheight=0>
				</frame>
				<frame name="invisible" src="/i/0.html" frameborder=0 marginwidth=0 marginheight=0 noresize scrolling=no>
				</frame>
			</frameset>
		</html>
EOH
	
	}


	my ($page) = @_;
	
	my $body = '';

	if (1) {

		my ($selector, $renderrer);

		if ($_REQUEST {error}) {
		
			my $message = js_escape ($_REQUEST {error});
						
			my $html = <<EOH;
				<html>
					<head></head>
					<body bgcolor=d5d5d5 onLoad="alert($message);">
					</body>
				</html>				
EOH

			return $html;
			
		}
		else {
		
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
			
			$body = call_for_role ($renderrer, call_for_role ($selector));

		}

		
	} else {
	
		$body = "<p><br><br><center>Тип данных '$$page{type}' не определён. Сообщите администратору.";
		
	}	
	
	if ($_REQUEST{dbf}) {	
		return $body;
	}
	elsif ($_REQUEST{lpt}) {	
	
		$body =~ s{^.*?\<table[^\>]*lpt\=\"?1\"?[^\>]*\>}{<table border cellspacing=0 cellpadding=5>}sm; #"
	
		return <<EOH;
			<html>
				<head>
					<title>НПФ</title>
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
				<script>function nop () {}</script>
			</head>
			<body bgcolor=d5d5d5 leftmargin=0 topmargin=0 marginwidth=0 marginheight=0>
						
				@{[ 				
					draw_auth_toolbar ({lpt => $lpt}) 
				]}
				
				$menu
				$body
			</body>
		</html>
EOH
	
}

################################################################################

sub Mozilla_3_draw_menu {

	my ($types, $cursor) = @_;
	
	@$types or return '';

	my ($tr2, $tr3) = ('', '');

	foreach my $type (@$types)	{
	
		my ($abra, $aket) = $$type{name} eq $cursor ? ('<b>', '</b>') : ('', '');
		my $tcolor = $$type{name} eq $cursor ? 'efefef' : 'd5d5d5';

		$tr2 .= <<EOH;
			<td bgcolor=596084><img height=20 src="/i/0.gif" width=1 border=0></td>
			<td bgcolor=$tcolor nowrap>&nbsp;&nbsp;<a target="_top" href="/?type=$$type{name}&sid=$_REQUEST{sid}@{[$$type{search} ? '&search=1' : '']}">$abra<font color=000000 face='arial cyr' size=2>$$type{label}</font>$aket</a>&nbsp;&nbsp;</td>
EOH

		my $bgcolor = $$type{name} eq $cursor ? '596084' : 'd5d5d5';

		$tr3 .= <<EOH;
			<td bgcolor=596084><img height=1 src="/i/0.gif" width=1 border=0></td>
			<td bgcolor=596084 nowrap><img height=1 src="/i/0.gif" width=1 border=0></td>
EOH

	}

	return <<EOH;
		<table width="100%" bgcolor=d5d5d5 cellspacing=0 cellpadding=0 border=0>
			<tr>
				$tr2
				<td bgcolor=596084 width=1><img height=20 src="/i/0.gif" width=1 border=0></td>
				<td bgcolor=d5d5d5 width=300><img height=1 src="/i/0.gif" width=1 border=0></td>
			<tr>
				$tr3
				<td bgcolor=596084 width=1><img height=1 src="/i/0.gif" width=1 border=0></td>
				<td bgcolor=d5d5d5 width=300><img height=1 src="/i/0.gif" width=1 border=0></td>
		</table>	
EOH
}

################################################################################

sub Mozilla_3_draw_hr {

	my %options = @_;
	
	$options {height} ||= 1;
	$options {class}  ||= bgr8;	
	
	return <<EOH;
		<table border=0 cellspacing=0 cellpadding=0 width="100%">
			<tr><td class=$options{class}><img src="/i/0.gif" width=1 height=$options{height}></td></tr>
		</table>
EOH
	
}

################################################################################

sub Mozilla_3_draw_text_cell {

	my ($data) = @_;

	return '' if $data -> {off};

	my $txt = $data -> {label};
	
	$txt ||= '&nbsp;';
	
	$txt = "<font face='Arial Cyr' size=2 color=000000>$txt</font>";
	
	if ($data -> {href}) {
		$data -> {href} =~ /sid\=\d/ or $data -> {href} .= "\&sid=$_REQUEST{sid}";
		my $target = $data -> {target} ? "target='$$data{target}'" : '';
		$txt = qq { <a $target href="$$data{href}" target="_top">$txt</a> };
	}
	
	return qq {<td bgcolor=ffffff><nobr>$txt</nobr></td>};

}

################################################################################

sub Mozilla_3_draw_tr {

	my ($options, @tds) = @_;
	
	return qq {<tr>@tds</tr>};

}

################################################################################

sub Mozilla_3_draw_one_cell_table {

	my ($options, $body) = @_;
	
	return <<EOH
		<table cellspacing=0 cellpadding=0 width="100%">
				<form name=form action=/ method=post enctype=multipart/form-data target=invisible>
					<tr><td bgcolor=d5d5d5>$body
				</form>
		</table>
EOH

}

################################################################################

sub Mozilla_3_draw_table {

	my ($headers, $ths) = ([], '');

	unless (ref $_[0] eq CODE) {
		$headers = shift;
	}
		
	if (@$headers) {
		$ths = '<tr>' . (join '', map { ref $_ eq HASH ? ($$_{off} ? '' : "<th bgcolor=efefef><font face='Arial Cyr' size=2 color=000000>$$_{label}\&nbsp;") : "<th bgcolor=efefef><font face='Arial Cyr' size=2 color=000000>$_\&nbsp;" } @$headers);
	}
	
	my ($tr_callback, $list) = @_;
	
	my $trs = '';
	
	foreach our $i (@$list) {
		$trs .= '<tr>';
		$trs .= &$tr_callback ($item);
	}
	
	return <<EOH
		<table border cellspacing=1 cellpadding=5 width="100%">
			$ths
			$trs
		</table>
EOH

}

################################################################################

sub Mozilla_3_draw_path {

	$_REQUEST{lpt} and return '';

	my ($options, $list) = @_;
	
	$options -> {id_param} ||= 'id';
	
	$path = '';
	
	foreach my $item (@$list) {
	
		$path and $path .= '&nbsp;/&nbsp;';
		
		$id_param = $item -> {id_param};
		$id_param ||= $options -> {id_param};
		
		$path .= <<EOH;
			<a target="_top" href="/?type=$$item{type}&$id_param=$$item{id}&sid=$_REQUEST{sid}"><font color=000000 face='Arial cyr' size=2>$$item{name}</font></a>
EOH
	
	}

	return draw_hr (height => 10) . <<EOH
		<table cellspacing=0 cellpadding=0 width="100%" border=0>
			<tr>
				<td bgcolor=dededc>
					<table cellspacing=0 cellpadding=0 width="100%" border=0>
						<tr>
							<td bgcolor=888888 colspan=4><img height=1 src="/i/0.gif" width=1 border=0></td>
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
							<td bgcolor=d5d5d5 colspan=4><img height=1 src="/i/0.gif" width=1 border=0></td>
						</tr>
						<tr>
							<td bgcolor=888888 colspan=4><img height=1 src="/i/0.gif" width=1 border=0></td>
						</tr>
					</table>
				</td>
			</tr>
		</table>
EOH

}

################################################################################

sub Mozilla_3_draw_window_title {

	my ($options) = @_;
	
	return '' if $options -> {off};

	return <<EOH
		<table cellspacing=0 cellpadding=3 width="100%"><tr><td bgcolor=8e8e8e>&nbsp;&nbsp;&nbsp;<font color=ffffff face='Arial cyr' size=3><b>$$options{label}</b></font></table>
EOH

}

################################################################################

sub Mozilla_3_draw_toolbar {

	my ($options, @buttons) = @_;

	return '' if $options -> {off};
	
	my $colspan = 2 * @buttons + 3;
	
	return <<EOH
		<table bgcolor=dededc cellspacing=0 cellpadding=0 width="100%" border=0>
			<form action="/">
				<input type=hidden name=sid value=$_REQUEST{sid}>
				<tr>
					<td bgcolor=ffffff colspan=$colspan><img height=1 src="/i/0.gif" width=1 border=0></td>
				</tr>
				<tr>
					<td bgcolor=888888 colspan=$colspan><img height=1 src="/i/0.gif" width=1 border=0></td>
				</tr>
				<tr>
					<td width=20>&nbsp;</td>
					@buttons
					<td width="100%">&nbsp;</td>
					<td align=right><img height=23 src="/i/0.gif" width=4 border=0></td>
				</tr>
				<tr>
					<td bgcolor=d5d5d5 colspan=$colspan><img height=1 src="/i/0.gif" width=1 border=0></td>
				</tr>
				<tr>
					<td bgcolor=888888 colspan=$colspan><img height=1 src="/i/0.gif" width=1 border=0></td>
				</tr>
			</form>
		</table>
EOH

}

################################################################################

sub Mozilla_3_draw_toolbar_button {

	my ($options) = @_;
	
	return <<EOH
		<td nowrap>&nbsp;<a target="invisible" class=lnk0 href="$$options{href}&sid=$_REQUEST{sid}"><font color=000000 face='Arial cyr' size=2><b>[$$options{label}]</b></font></a></td>
		<td><img height=15  hspace=4 src="/i/toolbars/razd1.gif" width=2 border=0></td>
EOH

}

################################################################################

sub Mozilla_3_draw_toolbar_input_text {

	my ($options) = @_;
	
	return <<EOH
		<td nowrap><font face='Arial cyr' size=2>$$options{label}: <input type=text name=$$options{name} value="$_REQUEST{$$options{name}}"><input type=hidden name=search value=1><input type=hidden name=type value="$_REQUEST{type}"></font></td>
		<td><img height=15  hspace=4 src="/i/toolbars/razd1.gif" width=2 border=0></td>
EOH

}

################################################################################

sub Mozilla_3_draw_toolbar_pager {

	my ($options) = @_;

	my $start = $_REQUEST {start} + 0;

	my $label = '';
	
	if ($start > 0) {
		$url = create_url (start => $start - $conf -> {portion});
		$label .= qq {&nbsp;<a target="_top" href="$url"><font color=000000 face='Arial cyr' size=2><b>&lt;&lt;</b></font></a>&nbsp;};
	}
	
	$label .= ($start + 1) . ' - ' . ($start + $$options{cnt}) . ' из ' . $$options{total};
	
	if ($start + $$options{cnt} < $$options{total}) {
		$url = create_url (start => $start + $conf -> {portion});
		$label .= qq {&nbsp;<a target="_top" href="$url" class=lnk0><font color=000000 face='Arial cyr' size=2><b>&gt;&gt;</b></font></a>&nbsp;};
	}
	
	return <<EOH
		<td nowrap><font face='Arial cyr' size=2>$label</font></td>
		<td><img height=15  hspace=4 src="/i/toolbars/razd1.gif" width=2 border=0></td>
EOH

}

################################################################################

sub Mozilla_3_js_escape {
	my ($s) = @_;	
	$s =~ y/\"/\'/;
	$s =~ s/([^\w])/\\$1/gsm;	
	return "'$s'";	
}

################################################################################

sub Mozilla_3_draw_row_button {

	my ($options) = @_;
	
	return '' if $options -> {off};

	if ($options -> {confirm}) {
		my $salt = rand;
		my $msg = js_escape ($options -> {confirm});
		$options -> {onclick} = qq [if (confirm ($msg)) {window.open('$$options{href}&_salt=$salt&sid=$_REQUEST{sid}', '_top')}];
		$options -> {href} = '#';
		
	} else {
		$options -> {href} .= "&sid=$_REQUEST{sid}";
	}

	my $target = $options -> {href} eq '#' ? '' : 'target="_top"';

	return qq {\&nbsp;<a title="$$options{label}" $target href="$$options{href}" onclick="$$options{onclick}"><font color=000000 face='Arial cyr' size=2><b>[$$options{label}]</b></font></a>\&nbsp;};

}

################################################################################

sub Mozilla_3_draw_row_buttons {

	my ($options, $buttons) = @_;

	return '<td bgcolor=efefef valign=top nowrap width="1%">' . (join '', map {draw_row_button ($_)} @$buttons) . '</td>';

}

################################################################################

sub Mozilla_3_draw_form {

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
	
#		my ($c1, $c2) = $n++ % 2 ? (5, 4) : (4, 0);
		
		my $bgcolor = $n++ % 2 ? 'efefef' : 'ffffff';
		
		$trs .= $type eq 'hidden' ? $html : <<EOH;
			<tr bgcolor=$bgcolor>
				<td bgcolor=$bgcolor nowrap align=right width="20%"><font face='Arial cyr' size=2>$$field{label}: </font></td>
				<td bgcolor=$bgcolor><font face='Arial cyr' size=2>$html</font></td></tr>
EOH
	
	}
	
	my $path = $data -> {path} ? draw_path ({}, $data -> {path}) : '';
	
	my $bottom_toolbar = 
		$options -> {bottom_toolbar} ? $options -> {bottom_toolbar} :		
		$options -> {back} ? draw_back_next_toolbar ($options) :
		draw_ok_esc_toolbar ($options);

	return <<EOH
		$path
		<table border cellspacing=1 cellpadding=5 width="100%">
			<form name=form action=/ method=post enctype=multipart/form-data target=invisible>
				<input type=hidden name=type value=$type> 
				<input type=hidden name=id value=$id> 
				<input type=hidden name=action value=$action> 
				<input type=hidden name=sid value=$_REQUEST{sid}>
				$trs
			</form>
		</table>
		$bottom_toolbar
EOH

}

################################################################################

sub Mozilla_3_draw_form_field_string {
	my ($options, $data) = @_;
	my $s = $$data{$$options{name}};
	$s =~ s/\"/\&quot\;/gsm; #"
	my $size = $options -> {size} ? "size=$$options{size} maxlength=$$options{size}" : "size=80";	
	return qq {<input type="text" name="_$$options{name}" value="$s" $size>};
}

################################################################################

sub Mozilla_3_draw_form_field_hgroup {
	my ($options, $data) = @_;
	return join '&nbsp;&nbsp;', map {$_ -> {label} . ': ' . &{'draw_form_field_' . $_ -> {type}}($_, $data)} @{$options -> {items}};
}

################################################################################

sub Mozilla_3_draw_form_field_text {
	my ($options, $data) = @_;
	my $s = $$data{$$options{name}};
	$s =~ s/\"/\&quot\;/gsm; #"
	return qq {<textarea rows=25 cols=60 name="_$$options{name}">$s</textarea>};
}

################################################################################

sub Mozilla_3_draw_form_field_hidden {
	my ($options, $data) = @_;
	my $s = $$data{$$options{name}};
	$s ||= $$options{value};
	$s =~ s/\"/\&quot\;/gsm; #"
	return qq {<input type="hidden" name="_$$options{name}" value="$s">};
}

################################################################################

sub Mozilla_3_draw_form_field_password {
	my ($options, $data) = @_;
	return qq {<input type="password" name="_$$options{name}" size=120>};
}

################################################################################

sub Mozilla_3_draw_form_field_static {
	my ($options, $data) = @_;
	return $$data{$$options{name}};
}

################################################################################

sub Mozilla_3_draw_form_field_checkbox {

	my ($options, $data) = @_;
	
	my $s = $$data{$$options{name}};
	
	$s =~ s/\"/\&quot\;/gsm; #"
	
	my $checked = $s ? 'checked' : '';
	
	return qq {<input type="checkbox" name="_$$options{name}" value="1" $checked>};
	
}

################################################################################

sub Mozilla_3_draw_form_field_checkboxes {

	my ($options, $data) = @_;
	
	my $html = '';
	
	foreach my $value (@{$options -> {values}}) {
		my $checked = $data -> {$options -> {name}} == $value -> {id} ? 'checked' : '';
		$html .= qq {<input type="checkbox" name="_$$options{name}" value="$$value{id}" $checked>&nbsp;$$value{label} <br>};
	}
		
	return $html;
	
}

################################################################################

sub Mozilla_3_draw_form_field_radio {

	my ($options, $data) = @_;
	
	my $html = '';
	
	foreach my $value (@{$options -> {values}}) {
		my $checked = $data -> {$options -> {name}} == $value -> {id} ? 'checked' : '';
		$html .= qq {<input type="radio" name="_$$options{name}" value="$$value{id}" $checked>&nbsp;$$value{label} <br>};
	}
		
	return $html;
	
}

################################################################################

sub Mozilla_3_draw_form_field_select {

	my ($options, $data) = @_;
	
	my $html = '';
	
	foreach my $value (@{$options -> {values}}) {
		my $selected = $data -> {$options -> {name}} == $value -> {id} ? 'selected' : '';
		$html .= qq {<option value="$$value{id}" $selected>$$value{label}</option>};		
	}
		
	return <<EOH;
		<select name="_$$options{name}">
			$html
		</select>
EOH
	
}

################################################################################

sub Mozilla_3_draw_ok_esc_toolbar {

	my ($options) = @_;
	
	my $esc = $options -> {esc};
	$esc ||= "/?type=$_REQUEST{type}";
	
	draw_centered_toolbar ($options, [
		{icon => 'ok',     label => 'применить', href => '#', onclick => 'document.form.submit()'},
		{icon => 'cancel', label => 'вернуться', href => "$esc&sid=$_REQUEST{sid}"},
	])
	
}

################################################################################

sub Mozilla_3_draw_back_next_toolbar {

	my ($options) = @_;
	
	my $type = $options -> {type};
	$type ||= $_REQUEST {type};
	
	my $back = $options -> {back};
	$back ||= "/?type=$type";
	
	draw_centered_toolbar ($options, [
		{icon => 'back', label => '&lt;&lt; назад', href => $back},
		{icon => 'next', label => 'продолжить &gt;&gt;', href => '#', onclick => 'document.form.submit()'},
	])
	
}

################################################################################

sub Mozilla_3_draw_centered_toolbar_button {

	my ($options) = @_;
	
	if ($options -> {href} !~ /^java/ and $options -> {href} !~ /\&sid=/ and $options -> {href} ne '#') {	
		$options -> {href} .= "\&sid=$_REQUEST{sid}";
	}
	
	my $target = $options -> {href} eq '#' ? '' : 'target="_top"';
			
	return <<EOH
		<!--<td><a onclick="$$options{onclick}" target="_top" href="$$options{href}" target="$$options{target}"><img hspace=3 src="/i/buttons/$$options{icon}.gif" border=0></a></td>-->
		<td nowrap>&nbsp;<a class=lnk0 onclick="$$options{onclick}"  $target href="$$options{href}" target="$$options{target}"><font face="Arial cyr" size=2 color=000000><b>[$$options{label}]</b></font></a>&nbsp;</td>
		<td><img height=15 hspace=4 src="/i/toolbars/razd1.gif" width=2 border=0></td>
EOH

}

################################################################################

sub Mozilla_3_draw_centered_toolbar {

	$_REQUEST{lpt} and return '';

	my ($options, $list) = @_;

	my $colspan = 3 * (1 + @$list) + 1;

	return <<EOH;
	
		<table cellspacing=0 cellpadding=0 width="100%" border=0>
			<tr>
				<td bgcolor=dededc>
					<table cellspacing=0 cellpadding=0 width="100%" border=0>
						<tr>
							<td bgcolor=ffffff colspan=$colspan><img height=1 src="/i/0.gif" width=1 border=0></td>
						</tr>
						<tr>
							<td bgcolor=888888 colspan=$colspan><img height=1 src="/i/0.gif" width=1 border=0></td></tr>
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
									<td bgcolor=d5d5d5 colspan=$colspan><img height=1 src="/i/0.gif" width=1 border=0></td>
								</tr>
								<tr>
									<td bgcolor=888888 colspan=$colspan><img height=1 src="/i/0.gif" width=1 border=0></td>
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

sub Mozilla_3_draw_auth_toolbar {

	my $options = shift;
	
	my $calendar = <<EOH;
		&nbsp;&nbsp;<font face='Arial cyr' size=2 color=ffffff>@{[ $_CALENDAR -> draw () ]}</font>
EOH

	return <<EOH;

		<table cellSpacing=0 cellPadding=0 border=0 width=100%>
			<tr><td bgcolor=596084><img height=1 src="/i/0.gif" width=1 height=1 border=0></td></tr>
			<tr><td bgcolor=888888><img height=1 src="/i/0.gif" width=1 height=1 border=0></td></tr>
		</table>
		
		<table cellspacing=0 cellpadding=0 border=0 width=100%>
			<tr>
				<td bgcolor=596084><nobr>&nbsp;&nbsp;</nobr></td>
				<td bgcolor=596084><nobr><font face='Arial cyr' size=2 color=ffffff>Пользователь: @{[ $_USER ? $_USER -> {name} : 'Пользователь неопределён']}</a>&nbsp;&nbsp;</font>$calendar</nobr></td>
				
				@{[ $_USER ? <<EOEXIT : '' ]}
				<td bgcolor=596084 align=right><nobr><A class=lnk2 href="/" target="_top"><font face='Arial cyr' size=2 color=ffffff>[Выход]</font></A>&nbsp;&nbsp;</nobr></td>
EOEXIT
			</tr>
		</table>
		<table cellSpacing=0 cellPadding=0 border=0 width=100%>
			<tr><td bgcolor=b0b0b0><img height=1 src="/i/0.gif" width=1 height=1 border=0></td></tr>
			<tr><td bgcolor=596084><img height=1 src="/i/0.gif" width=1 height=1 border=0></td></tr>
		</table>

EOH

}

################################################################################

sub Mozilla_3_draw_calendar {

	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime (time);
	
	$year += 1900;
	
	return "<nobr>Сегодня: $mday $month_names[$mon] $year</nobr>";

	
#	$html  = '&nbsp;<a class=lnk2 target="_top" href="' . create_url (period => $_CALENDAR -> period - 12 ) . '">&lt;&lt;</a>';
#	$html .= '&nbsp;<a class=lnk2 target="_top" href="' . create_url (period => $_CALENDAR -> period - $_CALENDAR -> granularity ) . '">&lt;</a>' if $_CALENDAR -> granularity < 12;
#	$html .= '&nbsp;<a class=lnk2>';
	
#	if ($_CALENDAR -> granularity < 12) {	
		
#		if ($_CALENDAR -> granularity == 1) {
#			$html .= $month_names [$_CALENDAR -> number];
#		}
#		else {
#			$html .= (1 + $_CALENDAR -> number) . '&nbsp;';
#			my ($g) = grep {$_ -> {id} == $_CALENDAR -> granularity} @$periods;		
#			$html .= $g -> {label};
#		}
				
#		$html .= '&nbsp;';
	
#	}
	
#	$html .= $_CALENDAR -> year . '</a>&nbsp;';
#	$html .= '&nbsp;<a class=lnk2 target="_top" href="' . create_url (period => $_CALENDAR -> period + $_CALENDAR -> granularity ) . '">&gt;</a>' if $_CALENDAR -> granularity < 12;
#	$html .= '&nbsp;<a class=lnk2 target="_top" href="' . create_url (period => $_CALENDAR -> period + 12 ) . '">&gt;&gt;</a>';
	
#	return $html;

}

1;
