package Zanas::Presentation::Skins::Classic;

BEGIN {
	require Zanas::Presentation::Skins::Generic;
	delete $INC {"Zanas/Presentation/Skins/Generic.pm"};
}

################################################################################

sub options {
	return {};
}

################################################################################

sub register_hotkey {

	my ($_SKIN, $hashref) = @_;

	$hashref -> {label} =~ s{\&(.)}{<u>$1</u>} or return undef;

	my $c = $1;
		
	if ($c eq '<') {
		return 37;
	}
	elsif ($c eq '>') {
		return 39;
	}
	elsif (lc $c eq '�') {
		return 186;
	}
	elsif (lc $c eq '�') {
		return 222;
	}
	else {
		$c =~ y{����������������������������������������������������������������}{qwertyuiop[]asdfghjkl;'zxcvbnm,.qwertyuiop[]asdfghjkl;'zxcvbnm,.};
		return (ord ($c) - 32);
	}

}

################################################################################

sub static_path {

	my ($package, $file) = @_;
	my $path = __FILE__;

	$path    =~ s{\.pm}{/$file};

	return $path;

};

################################################################################

sub draw_hr {

	my ($_SKIN, $options) = @_;
		
	return <<EOH;
		<table border=0 cellspacing=0 cellpadding=0 width="100%">
			<tr><td class=$$options{class}><img src="$_REQUEST{__uri}0.gif" width=1 height=$$options{height}></td></tr>
		</table>
EOH
	
}

################################################################################

sub draw_auth_toolbar {

	my ($_SKIN, $options) = @_;
		
	return <<EOH;
		<table cellSpacing=0 cellPadding=0 border=0 width=100%>
			<tr><td class=bgr1><img height=1 src="$_REQUEST{__uri}0.gif" width=1 height=1 border=0></td></tr>
			<tr><td class=bgr6><img height=1 src="$_REQUEST{__uri}0.gif" width=1 height=1 border=0></td></tr>
		</table>
		<table cellSpacing=0 cellPadding=0 border=0 width=100%>
			<tr>
				<td class=bgr1><nobr>&nbsp;&nbsp;</nobr></td>

				<td class=bgr1><img height=22 src="$_REQUEST{__uri}0.gif" width=4 border=0></td>
				<td class=bgr1><nobr><A class=lnk2>$$options{user_label}</a>&nbsp;&nbsp;</nobr></td>

				<td class=bgr1><img height=22 src="$_REQUEST{__uri}0.gif" width=4 border=0></td>
				<td class=bgr1><A class=lnk2>$$options{calendar}</A></td>
				<td class=bgr1><img height=22 src="$_REQUEST{__uri}0.gif" width=4 border=0></td>

				<td class=bgr1 nowrap width="100%"></td>							
				
				@{[ $_REQUEST {__help_url} ? <<EOHELP : '' ]}
				<td class=bgr1><img height=22 src="$_REQUEST{__uri}0.gif" width=4 border=0></td>
				<td class=bgr1><nobr><A TABINDEX=-1 id="help" class=lnk2 href="$_REQUEST{__help_url}" target="_blank">[$$i18n{F1}]</A>&nbsp;&nbsp;</nobr></td>
EOHELP
				<td class=bgr1><img height=22 src="$_REQUEST{__uri}0.gif" width=4 border=0></td>
				<td class=bgr1><img height=1 src="$_REQUEST{__uri}0.gif" width=7 border=0></td>
			</tr>
		</table>
		$$options{top_banner}

EOH

}

################################################################################

sub draw_window_title {

	my ($_SKIN, $options) = @_;
	
	return <<EOH
		<table cellspacing=0 cellpadding=0 width="100%"><tr><td class='header15'><img src="$_REQUEST{__uri}0.gif" width=1 height=20 align=absmiddle>&nbsp;&nbsp;&nbsp;$$options{label}</table>
EOH

}

################################################################################
# FORMS & INPUTS
################################################################################

sub _draw_bottom {

	my ($_SKIN, $options) = @_;
	
	unless ($options -> {menu}) {
		return <<EOH;
			<table cellspacing=0 cellpadding=0 width="100%">
				<tr>
					<td class=bgr6><img height=1 src="$_REQUEST{__uri}0.gif" width=1 border=0></td>
				</tr>
			</table>
EOH
	}
	
	
	my $items = $options -> {menu};
		
	my ($tr1, $tr2, $tr3) = ('', '');

	$tr3 .= qq{<td></td>};
	$tr2 .= qq{<td></td>};
	$tr1 .= qq{<td class='bgr6' width=100%><img src="$_REQUEST{__uri}0.gif" border=0 hspace=0 vspace=0 width=1 height=1></td>};

	my $class = $items -> [0] -> {is_active} ? 'bgr0' : 'bgr6';
	
	$tr1 .= qq{<td class='$class'><img src="$_REQUEST{__uri}0.gif" border=0 hspace=0 vspace=0 width=1 height=1></td>};

	$tr3 .= qq{<td rowspan=2 valign=top><img src="$_REQUEST{__uri}tab_l_${$$items[0]}{is_active}.gif" border=0 hspace=0 vspace=0 width=6 height=17></td>};

	for (my $i = 0; $i < 0 + @$items; $i++) {

		my $item = $items -> [$i];	
		my $active = $item -> {is_active};

		my $class = $active ? 'bgr0' : 'bgr6';

		$tr1 .= qq{<td class='$class'><img src="$_REQUEST{__uri}0.gif" border=0 hspace=0 vspace=0 width=1 height=1></td>};

		$tr2 .= qq{<td class="tabs-$active"><a id="$item" href="$$item{href}" class="main-menu"><nobr>&nbsp;$$item{label}&nbsp;</nobr></a></td>};

		$tr3 .= qq{<td background="$_REQUEST{__uri}tab_b_$active.gif"><img src="$_REQUEST{__uri}0.gif" border=0 hspace=0 vspace=0 width=1 height=2></td>};

		if ($i < -1 + @$items) {
			my $aa = $active . ($items -> [$i + 1] -> {is_active});
			my $class = $aa ne '00' ? 'bgr0' : 'bgr6';
			$tr1 .= qq{<td class='$class'><img src="$_REQUEST{__uri}0.gif" border=0 hspace=0 vspace=0 width=1 height=1></td>};
			$tr3 .= qq{<td rowspan=2><img src="$_REQUEST{__uri}tab_$aa.gif" border=0 hspace=0 vspace=0 width=8 height=17></td>};
		}
		else {
			my $class = $active ? 'bgr0' : 'bgr6';
			$tr1 .= qq{<td class='$class'><img src="$_REQUEST{__uri}0.gif" border=0 hspace=0 vspace=0 width=1 height=1></td>};
			$tr3 .= qq{<td rowspan=2 valign=top><img src="$_REQUEST{__uri}tab_r_${$$items[-1]}{is_active}.gif" border=0 hspace=0 vspace=0 width=6 height=17></td>};
		}

	}
			
	$tr3 .= qq{<td rowspan=2 valign=top><img src="$_REQUEST{__uri}0.gif" border=0 hspace=0 vspace=0 width=1 height=1></td>};
	$tr1 .= qq{<td class='bgr6' width=30><img src="$_REQUEST{__uri}0.gif" border=0 hspace=0 vspace=0 width=1 height=1></td>};

	return <<EOH;
		<table border=0 cellspacing=0 cellpadding=0 width=100%>
			<tr>$tr3
			<tr>$tr2
			<tr>$tr1
		<table>
EOH

}

################################################################################

sub _draw_input_datetime {

	my ($_SKIN, $options) = @_;
		
#	$r -> header_in ('User-Agent') =~ /MSIE 5\.0/ or return draw_form_field_string (@_);
		
	$options -> {id} ||= '' . $options;
	
	$options -> {onClose}    ||= 'null';
	$options -> {onKeyDown}  ||= 'null';
	$options -> {onKeyPress} ||= 'if (window.event.keyCode != 27) is_dirty=true';

	$options -> {no_read_only} or $options -> {attributes} -> {readonly} = 1;
	
	my $attributes = dump_attributes ($options -> {attributes});
		
	my $shows_time = $options -> {no_time} ? 'false' : 'true';
		
	my $html = <<EOH;
		<nobr>
		<input 
			type="text" 
			name="$$options{name}" 
			$size 
			$attributes 
			autocomplete="off" 
			onFocus="scrollable_table_is_blocked = true; q_is_focused = true; this.select()" 
			onBlur="scrollable_table_is_blocked = false; q_is_focused = false" 
			onKeyPress="$$options{onKeyPress}" 
			onKeyDown="$$options{onKeyDown}"
		>
		<button id="calendar_trigger_$$options{id}" class="form-active-ellipsis">...</button>
EOH
	
	unless ($options -> {no_clear_button} || $options -> {no_read_only}) {
		$html .= qq{&nbsp;<button class="txt7" onClick="document.getElementById ('$options->{attributes}->{id}').value=''">X</button>};
	}
		
	$html .= <<EOH;
		</nobr>		
		<script type="text/javascript">
EOH

	if ($i18n -> {_calendar_lang} eq 'en') {
		$html .= <<EOJS;
			Calendar._DN = new Array ("Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday");
			Calendar._SDN = new Array ("Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun");
			Calendar._MN = new Array ("January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December");
			Calendar._SMN = new Array ("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec");
			Calendar._TT = {};
			Calendar._TT["INFO"] = "About the calendar";
			Calendar._TT["PREV_YEAR"] = "Prev. year (hold for menu)";
			Calendar._TT["PREV_MONTH"] = "Prev. month (hold for menu)";
			Calendar._TT["GO_TODAY"] = "Go Today";
			Calendar._TT["NEXT_MONTH"] = "Next month (hold for menu)";
			Calendar._TT["NEXT_YEAR"] = "Next year (hold for menu)";
			Calendar._TT["SEL_DATE"] = "Select date";
			Calendar._TT["DRAG_TO_MOVE"] = "Drag to move";
			Calendar._TT["PART_TODAY"] = " (today)";
			Calendar._TT["MON_FIRST"] = "Display Monday first";
			Calendar._TT["SUN_FIRST"] = "Display Sunday first";
			Calendar._TT["CLOSE"] = "Close";
			Calendar._TT["TODAY"] = "Today";
			Calendar._TT["TIME_PART"] = "(Shift-)Click or drag to change value";
			Calendar._TT["DEF_DATE_FORMAT"] = "%Y-%m-%d";
			Calendar._TT["TT_DATE_FORMAT"] = "%a, %b %e";
			Calendar._TT["WK"] = "wk";
EOJS
	}	
	elsif ($i18n -> {_calendar_lang} eq 'fr') {
		$html .= <<EOJS;
			Calendar._DN = new Array ("Dimanche", "Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche");
			Calendar._MN = new Array ("Janvier", "F�vrier", "Mars", "Avril", "Mai", "Juin", "Juillet", "Ao�t", "Septembre", "Octobre", "Novembre", "D�cembre");
			Calendar._TT = {};
			Calendar._TT["TOGGLE"] = "Changer le premier jour de la semaine";
			Calendar._TT["PREV_YEAR"] = "Ann�e pr�c. (maintenir pour menu)";
			Calendar._TT["PREV_MONTH"] = "Mois pr�c. (maintenir pour menu)";
			Calendar._TT["GO_TODAY"] = "Atteindre date du jour";
			Calendar._TT["NEXT_MONTH"] = "Mois suiv. (maintenir pour menu)";
			Calendar._TT["NEXT_YEAR"] = "Ann�e suiv. (maintenir pour menu)";
			Calendar._TT["SEL_DATE"] = "Choisir une date";
			Calendar._TT["DRAG_TO_MOVE"] = "D�placer";
			Calendar._TT["PART_TODAY"] = " (Aujourd'hui)";
			Calendar._TT["MON_FIRST"] = "Commencer par lundi";
			Calendar._TT["SUN_FIRST"] = "Commencer par dimanche";
			Calendar._TT["CLOSE"] = "Fermer";
			Calendar._TT["TODAY"] = "Aujourd'hui";
			Calendar._TT["DEF_DATE_FORMAT"] = "y-mm-dd";
			Calendar._TT["TT_DATE_FORMAT"] = "D, M d";
			Calendar._TT["WK"] = "wk";
EOJS
	}	
	else {
		$html .= <<EOJS;
			Calendar._DN = new Array ("�����������", "�����������", "�������", "�����", "�������", "�������", "�������", "�����������");
			Calendar._MN = new Array ("������", "�������", "����", "������", "���", "����", "����", "������", "��������", "�������", "������", "�������");
			Calendar._TT = {};
			Calendar._TT["TOGGLE"] = "������� ���� ������ ������ (��/��)";
			Calendar._TT["PREV_YEAR"] = "����. ��� (���������� ��� ����)";
			Calendar._TT["PREV_MONTH"] = "����. ����� (���������� ��� ����)";
			Calendar._TT["GO_TODAY"] = "�� �������";
			Calendar._TT["NEXT_MONTH"] = "����. ����� (���������� ��� ����)";
			Calendar._TT["NEXT_YEAR"] = "����. ��� (���������� ��� ����)";
			Calendar._TT["SEL_DATE"] = "������� ����";
			Calendar._TT["DRAG_TO_MOVE"] = "����������";
			Calendar._TT["PART_TODAY"] = " (�������)";
			Calendar._TT["MON_FIRST"] = "�������� ����������� ������";
			Calendar._TT["SUN_FIRST"] = "�������� ����������� ������";
			Calendar._TT["CLOSE"] = "�������";
			Calendar._TT["TODAY"] = "�������";
			Calendar._TT["DEF_DATE_FORMAT"] = "y-mm-dd";
			Calendar._TT["TT_DATE_FORMAT"] = "D, M d";
			Calendar._TT["WK"] = "���"; 
EOJS
	}	

	$html .= <<EOH;
			Calendar.setup(
				{
					inputField : "input$$options{name}",
					ifFormat   : "$$options{format}",
					showsTime  : $shows_time,
					button     : "calendar_trigger_$$options{id}",
					onClose    : $$options{onClose}
				}
			);
		</script>

EOH

	return $html;
	
}

################################################################################

sub draw_form {

	my ($_SKIN, $options) = @_;
		
	if ($_REQUEST {__only_field}) {
		my $html .= '';
		foreach my $row (@{$options -> {rows}}) {
			foreach (@$row) { $html .= $_ -> {html} };
		}
		return $html;	
	}
			
	my $html = $options -> {hr};
	
	$html .= _draw_bottom (@_);
	
	$html .= $options -> {path};
	
	$html .=  <<EOH;
		<table cellspacing=1 width="100%">
			<form 
				name="$$options{name}"
				target="$$options{target}"
				method="$$options{method}"
				enctype="$$options{enctype}"
				target="$$options{target}"
				action="$_REQUEST{__uri}"
			>
EOH
	
	foreach (@{$options -> {keep_params}}) {
		$html .= qq{\n\t\t\t\t<input type=hidden name="$$_{name}" value="$$_{value}">};
	}
	
	foreach my $row (@{$options -> {rows}}) {
		my $tr_id = $row -> [0] -> {tr_id};
		$html .= qq{<tr id="$tr_id">};
		foreach (@$row) { $html .= $_ -> {html} };
		$html .= qq{</tr>};
	}

	$html .=  '</form></table>';
	
	$html .= $options -> {bottom_toolbar};
	
	return $html;	

}


################################################################################

sub draw_path {

	my ($_SKIN, $options, $list) = @_;
		
	my $path = <<EOH;
		<table cellspacing=0 cellpadding=0 width="100%" border=0>
			<tr>
				<td class=bgr8>
					<table cellspacing=0 cellpadding=0 width="100%" border=0>
						<tr height=18>
							<td class=bgr0 $$options{nowrap}>&nbsp;
EOH

	if ($conf -> {core_show_icons} || $_REQUEST {__core_show_icons}) {
		$path .= qq{<img src="$_REQUEST{__uri}folder.gif" border=0 hspace=3 vspace=1 align=absmiddle>&nbsp;};
	}

	for (my $i = 0; $i < @$list; $i ++) {
	
		if ($i > 0) {
			$path .= '&nbsp;/&nbsp;';
			if ($options -> {multiline}) {
				$path .= '<br>';
				for (my $j = 0; $j < $i + 2; $j++) { $path .= '&nbsp;&nbsp;' }
			}
		}
		
		my $item = $list -> [$i];		
		
		$path .= qq{<a class=path ${\($$item{href} ? "href='$$item{href}'" : '')} TABINDEX=-1>$$item{label}</a>};
	
	}
	
	$path .= <<EOH;
&nbsp;</td>
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

	return $path;

}

################################################################################

sub draw_form_field {

	my ($_SKIN, $field, $data) = @_;
	
	if ($_REQUEST {__only_field} && $_REQUEST {__only_field} eq $field -> {name}) {
		return $field -> {html};
	}
							
	if ($field -> {type} eq 'banner') {
		my $colspan     = 'colspan=' . ($field -> {colspan} + 1);
		return qq{<td class='form-$$field{state}-label' $colspan nowrap align=center>$$field{html}</td>};
	}
	elsif ($field -> {type} eq 'hidden') {
		return $field -> {html};
	}
				
	my $colspan     = $field -> {colspan}     ? 'colspan=' . $field -> {colspan}     : '';
	my $label_width = $field -> {label_width} ? 'width='   . $field -> {label_width} : '';	
	my $cell_width  = $field -> {cell_width}  ? 'width='   . $field -> {cell_width}  : '';
	
	return <<EOH;
		<td class='form-$$field{state}-label' nowrap align=right $label_width>\n$$field{label}</td>
		<td class='form-$$field{state}-inputs' $colspan $cell_width>\n$$field{html}</td>
EOH

}

################################################################################

sub draw_form_field_banner {
	my ($_SKIN, $field, $data) = @_;
	return $field -> {label};
}

################################################################################

sub draw_form_field_button {
	my ($_SKIN, $options, $data) = @_;
	return qq {<input type="button" name="_$$options{name}" value="$$options{value}" onClick="$$options{onclick}" tabindex=$tabindex>};
}

################################################################################

sub draw_form_field_string {
	my ($_SKIN, $options, $data) = @_;
	$options -> {attributes} -> {class} ||= 'form-active-inputs';
	return '<input type="text"' . dump_attributes ($options -> {attributes}) . ' onKeyPress="if (window.event.keyCode != 27) is_dirty=true" onKeyDown="tabOnEnter()" onFocus="scrollable_table_is_blocked = true; q_is_focused = true" onBlur="scrollable_table_is_blocked = false; q_is_focused = false">';
}

################################################################################

sub draw_form_field_datetime {

	my ($_SKIN, $options, $data) = @_;
		
	$options -> {attributes} -> {class} ||= 'form-active-inputs';	
	$options -> {name} = '_' . $options -> {name};
	$options -> {onKeyDown} ="tabOnEnter()";

	return $_SKIN -> _draw_input_datetime ($options);
	
}

################################################################################

sub draw_form_field_file {

	my ($_SKIN, $options, $data) = @_;	
		
	return <<EOH;
		<input 
			type="file"
			name="_$$options{name}"
			size=$$options{size}
			onFocus="scrollable_table_is_blocked = true; q_is_focused = true"
			onBlur="scrollable_table_is_blocked = false; q_is_focused = false"
			onChange="is_dirty=true; $$options{onChange}"
			tabindex=-1
		>
EOH

}

################################################################################

sub draw_form_field_hidden {
	my ($_SKIN, $options, $data) = @_;
	return qq {<input type="hidden" name="_$$options{name}" value="$$options{value}">};
}

################################################################################

sub draw_form_field_hgroup {

	my ($_SKIN, $options, $data) = @_;
	my $html = '';
	foreach my $item (@{$options -> {items}}) {
		next if $item -> {off};
		$html .= $item -> {label} if $item -> {label};
		$html .= $item -> {html};
		$html .= '&nbsp;';
	}
	return $html;
	
}

################################################################################

sub draw_form_field_text {

	my ($_SKIN, $options, $data) = @_;
	my $attributes = dump_attributes ($options -> {attributes});
	return <<EOH;
		<textarea 
			$attributes 
			onFocus="scrollable_table_is_blocked = true; q_is_focused = true" 
			onBlur="scrollable_table_is_blocked = false; q_is_focused = false" 
			rows=$$options{rows}
			cols=$$options{cols}
			name="_$$options{name}" 
			onchange="is_dirty=true;"
		>$$options{value}</textarea>
EOH

}

################################################################################

sub draw_form_field_password {
	my ($_SKIN, $options, $data) = @_;
	my $attributes = dump_attributes ($options -> {attributes});
	return qq {<input type="password" name="_$$options{name}" size="$$options{size}" onKeyPress="if (window.event.keyCode != 27) is_dirty=true" $attributes onKeyDown="tabOnEnter()" onFocus="scrollable_table_is_blocked = true; q_is_focused = true" onBlur="scrollable_table_is_blocked = false; q_is_focused = false">};
}

################################################################################

sub draw_form_field_static {
		
	my ($_SKIN, $options, $data) = @_;

	my $html = '';

	if ($options -> {href}) {
		my $state = $data -> {fake} == -1 ? 'deleted' : $_REQUEST {__read_only} ? 'passive' : 'active';
		$options -> {a_class} ||= "form-$state-inputs";
		$html = qq{<a href="$$options{href}" target="$$options{target}" class="$$options{a_class}">};
	}
	
	if (ref $options -> {value} eq ARRAY) {
	
		for (my $i = 0; $i < @{$options -> {value}}; $i++) {
			$html .= '<br>' if $i;
			$html .= $options -> {value} -> [$i] -> {label};
		}
		
	}
	else {
		$html .= $options -> {value};
	}
	
	
	if ($options -> {href}) {
		$html .= '</a>';
	}
	
	$html .= qq {<input type=hidden name="$$options{hidden_name}" value="$$options{hidden_value}">} if ($options -> {add_hidden});
	
	return $html;
	
}

################################################################################

sub draw_form_field_checkbox {

	my ($_SKIN, $options, $data) = @_;
	
	my $attributes = dump_attributes ($options -> {attributes});
	
	return qq {<input type="checkbox" name="_$$options{name}" $attributes $checked value=1 onChange="is_dirty=true" onKeyDown="tabOnEnter()">};
	
}

################################################################################

sub draw_form_field_radio {

	my ($_SKIN, $options, $data) = @_;
				
	my $html = '<table border=0 cellspacing=2 cellpadding=0 width=100%>';
	
	foreach my $value (@{$options -> {values}}) {
	
		delete $value -> {attributes} -> {name};
		delete $value -> {attributes} -> {value};
		delete $value -> {attributes} -> {id};
	
		my $attributes = dump_attributes ($value -> {attributes});

		$html .= qq {\n<tr><td valign=top width=1%><nobr><input $attributes id="$value" onFocus="scrollable_table_is_blocked = true; q_is_focused = true" onBlur="scrollable_table_is_blocked = false; q_is_focused = false" type="radio" name="_$$options{name}" value="$$value{id}" onClick="is_dirty=true" onKeyDown="tabOnEnter()">&nbsp;$$value{label}</nobr>};
							
		$value -> {html} or next;
		
		$html .= qq{\n\t\t<td><div style="display:expression(getElementById('$value').checked ? 'block' : 'none')">$$value{html}</div>};
				
	}
	
	$html .= '</table>';
		
	return $html;
	
}

################################################################################

sub draw_form_field_select {

	my ($_SKIN, $options, $data) = @_;
	
	my $attributes = dump_attributes ($options -> {attributes});
	
	my $html = <<EOH;
		<select 
			name="_$$options{name}"
			id="_$$options{name}_select"
			$attributes
			onKeyDown="tabOnEnter()"
			onChange="is_dirty=true; $$options{onChange}" 
			onKeyPress="typeAhead()" 
			style="visibility:expression(last_vert_menu [0] ? 'hidden' : '')"
		>
EOH
		
	if (defined $options -> {empty}) {
		$html .= qq {<option value="0" $selected>$$options{empty}</option>\n};
	}
		
	foreach my $value (@{$options -> {values}}) {
		$html .= qq {<option value="$$value{id}" $$value{selected}>$$value{label}</option>\n}; 
	}
	
	if (defined $options -> {other}) {
		$html .= qq {<option value=-1>${$$options{other}}{label}</option>};
	}

	$html .= '</select>';

	if (defined $options -> {other}) {
		$html .= <<EOH;
			<div id="_$$options{name}_div" style="{position:absolute; display:none; width:expression(getElementById('_$$options{name}_select').offsetParent.offsetWidth - 10)}">
				<iframe name="_$$options{name}_iframe" id="_$$options{name}_iframe" width=100% height=${$$options{other}}{height} src="$_REQUEST{__uri}0.html" application="yes">
				</iframe>
			</div>
EOH
	}

	return $html;
	
}

################################################################################

sub draw_form_field_checkboxes {

	my ($_SKIN, $options, $data) = @_;
	
	my $html = '';
	
	my $tabindex = $_REQUEST {__tabindex} + 1;
	
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

				my $display = $checked || $options -> {expand_all} ? '' : 'style={display:none}';
				
				$subhtml = <<EOH;
					<div id="$id" $display>
						$subhtml
					</div>
EOH
			
				$subattr = qq{onClick="setVisible('$id', checked)"} unless $options -> {expand_all};
			
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
			<div class="checkboxes" style="height:$$options{height}px;">
				$html
			</div>
EOH
	}
	
	$_REQUEST {__tabindex} = $tabindex;
	
	return $html;
	
}

################################################################################

sub draw_form_field_image {

	my ($_SKIN, $options, $data) = @_;
	
	return <<EOH;
		<input type="hidden" name="_$$options{name}" value="$$options{id_image}">
		<img src="$$options{src}" id="$$options{name}_preview" width = "$$options{width}" height = "$$options{height}">&nbsp;
		<input type="button" value="$$i18n{Select}" onClick="nope('$$options{new_image_url}', 'selectImage' , '');">
EOH

}

################################################################################

sub draw_form_field_iframe {
	
	my ($_SKIN, $options, $data) = @_;

	return <<EOH;
		<iframe name="$$options{name}" src="$$options{href}" width="$$options{width}" height="$$options{height}" application="yes"></iframe>
EOH

}

################################################################################

sub draw_form_field_color {
	
	my ($_SKIN, $options, $data) = @_;
	
	my $html = <<EOH;
		<table 
			align="absmiddle" 
			cellspacing=0
			cellpadding=0
			style="height:20px;width:40px;border:solid black 1px;background:#$$options{value}"
EOH
	
	if (!$_REQUEST {__read_only}) {
	
		$html .= <<EOH;
			onClick="
				var color = showModalDialog('$_REQUEST{__uri}colors.html', window, 'dialogWidth:600px;dialogHeight:400px;help:no;scroll:no;status:no');
				getElementById('td_color_$$options{name}').style.background = color;
				getElementById('input_color_$$options{name}').value = color.substr (1);
			"
EOH
	
	}
	
	$html .= <<EOH;
		>
			<tr height=20>
				<td id="td_color_$$options{name}" >
					<input id="input_color_$$options{name}" type="hidden" name="_$$options{name}" value="$$options{value}">
				</td>
			</tr>
		</table>
EOH

	return $html;

}

################################################################################

sub draw_form_field_htmleditor {
	
	my ($_SKIN, $options, $data) = @_;
	
	return '' if $options -> {off};
	
	push @{$_REQUEST{__include_js}}, 'rte/fckeditor';
	
	return <<EOH;
		<SCRIPT language="javascript">
			<!--
				var oFCKeditor_$$options{name};
				oFCKeditor_$$options{name} = new FCKeditor('_$$options{name}', '$$options{width}', '$$options{height}', '$$options{toolbar}');
				oFCKeditor_$$options{name}.Value = '$$options{value}';
				oFCKeditor_$$options{name}.Create ();
			//-->
		</SCRIPT>
EOH

}

################################################################################
# TOOLBARS
################################################################################

################################################################################

sub draw_toolbar {

	my ($_SKIN, $options) = @_;
	
	my $html = <<EOH;
		<table class=bgr8 cellspacing=0 cellpadding=0 width="100%" border=0>
			<form action=$_REQUEST{__uri} name=$form_name target="$$options{target}">
EOH

	foreach (@{$options -> {keep_params}}) {
		$html .= qq{<input type="hidden" name="$_" value="$_REQUEST{$_}">}	
	}

	$html .= <<EOH;
					<input type=hidden name=sid value=$_REQUEST{sid}>
					<input type=hidden name=__last_query_string value="$_REQUEST{__last_query_string}">
					<input type=hidden name=__last_scrollable_table_row value="$_REQUEST{__last_scrollable_table_row}">
					<input type=hidden name=__last_last_query_string value="$_REQUEST{__last_last_query_string}">

				<tr>
					<td class=bgr0 colspan=20><img height=1 src="$_REQUEST{__uri}0.gif" width=1 border=0></td>
				</tr>
				<tr>
					<td class=bgr6 colspan=20><img height=1 src="$_REQUEST{__uri}0.gif" width=1 border=0></td>
				</tr>
				<tr>
					<td class=bgr8 width=30><img height=1 src="$_REQUEST{__uri}0.gif" width=20 border=0></td>
EOH

	foreach (@{$options -> {buttons}}) {	$html .= $_ -> {html};	}

	$html .= <<EOH;
					<td class=bgr8 width=100%><img height=1 src="$_REQUEST{__uri}0.gif" width=1 border=0></td>
				</tr>
				<tr>
					<td class=bgr8 colspan=20><img height=1 src="$_REQUEST{__uri}0.gif" width=1 border=0></td>
				</tr>
				<tr>
					<td class=bgr6 colspan=20><img height=1 src="$_REQUEST{__uri}0.gif" width=1 border=0></td>
				</tr>
			</form>
		</table>
EOH

	return $html;

}

################################################################################

sub draw_toolbar_break {

	my ($_SKIN, $options) = @_;

	my $html = <<EOH;
					<td class=bgr8 width=100%><img height=1 src="$_REQUEST{__uri}0.gif" width=1 border=0></td>
				</tr>
				<tr>
					<td class=bgr8 colspan=20><img height=1 src="$_REQUEST{__uri}0.gif" width=1 border=0></td>
				</tr>
				<tr>
					<td class=bgr6 colspan=20><img height=1 src="$_REQUEST{__uri}0.gif" width=1 border=0></td>
				</tr>
EOH
	
	if ($options -> {break_table}) {		
		$html .= '</table><table class=bgr8 cellspacing=0 cellpadding=0 width="100%" border=0>';		
	}

	$html .= <<EOH;
				<tr>
					<td class=bgr0 colspan=20><img height=1 src="$_REQUEST{__uri}0.gif" width=1 border=0></td>
				</tr>
				<tr>
					<td class=bgr6 colspan=20><img height=1 src="$_REQUEST{__uri}0.gif" width=1 border=0></td>
				</tr>
				<tr>
					<td class=bgr8 width=30><img height=1 src="$_REQUEST{__uri}0.gif" width=20 border=0></td>
EOH

	return $html;

}

################################################################################

sub draw_toolbar_button {

	my ($_SKIN, $options) = @_;

	my $html = <<EOH;
		<td class="button" onmouseover="style.borderStyle='groove';style.borderColor='#FFFFFF';" onmouseout="style.borderStyle='solid';style.borderColor='#D6D3CE';" nowrap>&nbsp;<a TABINDEX=-1 class=button href="$$options{href}" $onclick id="$$options{id}" target="$$options{target}">
EOH

	if ($options -> {icon}) {
		$html .= qq {<img src="/i/buttons/$$options{icon}.gif" alt="$label" border=0 hspace=0 vspace=1 align=absmiddle>&nbsp;};
	}
	
	$html .= $options -> {label};

	$html .= <<EOH;
			</a>
		</td>
		<td><img height=15 vspace=1 hspace=4 src='$_REQUEST{__uri}razd1.gif' width=2 border=0></td>
EOH

	return $html;
	
}

################################################################################

sub draw_toolbar_input_select {

	my ($_SKIN, $options) = @_;
	
	my $html = '<td nowrap>';
		
	if ($options -> {label} && $options -> {show_label}) {
		$html .= $options -> {label};
		$html .= ': ';
	}
	
	$html .= <<EOH;
		<select name="$$options{name}" onChange="submit()" onkeypress="typeAhead()" style="visibility:expression(last_vert_menu [0] ? 'hidden' : '')">
EOH

	if (defined $options -> {empty}) {
		$html .= q {<option value=0>};
		$html .= $options -> {empty};
		$html .= q {</option>};
	}

	foreach my $value (@{$options -> {values}}) {		
		$html .= qq {<option value="$$value{id}" $$value{selected}>$$value{label}</option>};
	}

	$html .= "</select><td><img height=15 vspace=1 hspace=4 src='$_REQUEST{__uri}razd1.gif' width=2 border=0></td>";

	return $html;
	
}

################################################################################

sub draw_toolbar_input_checkbox {

	my ($_SKIN, $options) = @_;
	
	my $html = '<td nowrap>';
		
	if ($options -> {label}) {
		$html .= $options -> {label};
		$html .= ': ';
	}

	$html .= qq {<input type=checkbox value=1 $$options{checked} name="$$options{name}" onClick="submit()">};

	$html .= "<td><img height=15 vspace=1 hspace=4 src='$_REQUEST{__uri}razd1.gif' width=2 border=0></td>";
	
	return $html;

}

################################################################################

sub draw_toolbar_input_submit {

	my ($_SKIN, $options) = @_;

	my $html = '<td nowrap>';
		
	if ($options -> {label}) {
		$html .= $options -> {label};
		$html .= ': ';
	}

	$html .= qq {<input type=submit name="$$options{name}" value="$$options{label}">};

	$html .= "<td><img height=15 vspace=1 hspace=4 src='$_REQUEST{__uri}razd1.gif' width=2 border=0></td>";
	
	return $html;

}

################################################################################

sub draw_toolbar_input_text {

	my ($_SKIN, $options) = @_;
	
	my $html = '<td nowrap>';
		
	if ($options -> {label}) {
		$html .= $options -> {label};
		$html .= ': ';
	}

	$html .= <<EOH;
		<input 
			onKeyPress="if (window.event.keyCode == 13) {form.submit()}" 
			type=text 
			size=$$options{size} 
			name=$$options{name} 
			value="$$options{value}" 
			onFocus="scrollable_table_is_blocked = true; q_is_focused = true" 
			onBlur="scrollable_table_is_blocked = false; q_is_focused = false"
			style="visibility:expression(last_vert_menu [0] ? 'hidden' : '')"
		>
EOH

	foreach my $key (@{$options -> {keep_params}}) {
		next if $key eq $options -> {name} or $key =~ /^_/ or $key eq 'start' or $key eq 'sid';
		$html .= qq {<input type=hidden name=$key value="$_REQUEST{$key}">};
	}

	$html .= "<td><img height=15 vspace=1 hspace=4 src='$_REQUEST{__uri}razd1.gif' width=2 border=0></td>";

	return $html;

}

################################################################################

sub draw_toolbar_input_datetime {

	my ($_SKIN, $options) = @_;

	$options -> {onClose}    = "function (cal) { cal.hide (); $$options{onClose}; cal.params.inputField.form.submit () }";	
	$options -> {onKeyPress} = "if (window.event.keyCode == 13) {this.form.submit()}";

	my $html = '<td nowrap>';
		
	if ($options -> {label}) {
		$html .= $options -> {label};
		$html .= ': ';
	}

	$html .= $_SKIN -> _draw_input_datetime ($options);

	$html .= "<td><img height=15 vspace=1 hspace=4 src='$_REQUEST{__uri}razd1.gif' width=2 border=0></td>";

	return $html;

}

################################################################################

sub draw_toolbar_pager {

	my ($_SKIN, $options) = @_;
		
	my $html = '<td nowrap>';
	
	if ($options -> {total}) {

		if ($options -> {rewind_url}) {
			$html .= qq {&nbsp;<a TABINDEX=-1 href="$$options{rewind_url}" class=lnk0 onFocus="blur()">&lt;&lt;</a>&nbsp;&nbsp;};
		}

		if ($options -> {back_url}) {
			$html .= qq {&nbsp;<a TABINDEX=-1 href="$$options{back_url}" class=lnk0 id="_pager_prev" onFocus="blur()">&lt;</a>&nbsp;&nbsp;};
		}
		
		$html .= ($options -> {start} + 1);
		$html .= ' - ';
		$html .= ($options -> {start} + $options -> {cnt});
		$html .= qq |$$i18n{toolbar_pager_of}<a TABINDEX=-1 class=lnk0 href="$$options{infty_url}">$$options{infty_label}</a>|;

		if ($options -> {next_url}) {
			$html .= qq {&nbsp;<a TABINDEX=-1 href="$$options{next_url}" class=lnk0 id="_pager_next" onFocus="blur()">&gt;</a>&nbsp;&nbsp;};
		}

	}
	else {	
		$html .= $i18n -> {toolbar_pager_empty_list};	
	}
	
	$html .= "<td><img height=15 vspace=1 hspace=4 src='$_REQUEST{__uri}razd1.gif' width=2 border=0></td>";

	return $html;

}

################################################################################

sub draw_centered_toolbar_button {

	my ($_SKIN, $options) = @_;
	
	my $html = <<EOH;
		<td class="button" onmouseover="style.borderStyle='groove';style.borderColor='#FFFFFF';" onmouseout="style.borderStyle='solid';style.borderColor='#D6D3CE';" nowrap>&nbsp;<a TABINDEX=-1 class=button href="$$options{href}" id="$$options{id}" target="$$options{target}">
EOH

	if ($options -> {icon}) {
		$html .= qq {<img src="/i/buttons/$$options{icon}.gif" alt="$label" border=0 hspace=0 vspace=1 align=absmiddle>&nbsp;}
	}

	$html .= <<EOH;
			$$options{label} 
		</a></td>
		<td><img height=15 vspace=1 hspace=4 src="$_REQUEST{__uri}razd1.gif" width=2 border=0></td>
EOH

	return $html;

}

################################################################################

sub draw_centered_toolbar {

	my ($_SKIN, $options, $list) = @_;

	our $__last_centered_toolbar_id = 'toolbar_' . int $list;
	
	my $colspan = 3 * (1 + $options -> {cnt}) + 1;

	my $html = <<EOH;
		<table cellspacing=0 cellpadding=0 width="100%" border=0 id="$__last_centered_toolbar_id">
			<tr>
				<td class=bgr8>
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
									<td><img height=15 vspace=1 hspace=4 src="$_REQUEST{__uri}razd1.gif" width=2 border=0></td>
EOH

	foreach (@$list) {
		$html .= $_ -> {html};
	}

	$html .= <<EOH;
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
							</td>
						</tr>
					</table>
				</td>
			</tr>
		</table>
	
EOH
	
	return $html;

}

################################################################################
# MENUS
################################################################################

################################################################################

sub draw_menu {

	my ($_SKIN, $_options) = @_;
	
	my @types = (@{$_options -> {left_items}}, BREAK, @{$_options -> {right_items}});
	
	my $colspan = 1 + @types;

	my $html = <<EOH;
		<table width="100%" class=bgr8 cellspacing=0 cellpadding=0 border=0 onmousemove="blockEvent ();">
			<tr>
				<td class=bgr8 colspan=$colspan width=100%><img height=2 src="$_REQUEST{__uri}0.gif" width=1 border=0></td>
			<tr>
EOH

	foreach my $type (@types) {
		
		if ($type eq BREAK) {
			$html .= qq{<td class=bgr8 width=100%><img height=1 src="$_REQUEST{__uri}0.gif" width=1 border=0></td>};
			next;
		}
		
		$html .= <<EOH;
			<td 
				onmouseover="
					if (last_main_menu) {
						last_main_menu.style.borderColor='#D6D3CE'; 
						last_main_menu.style.borderStyle='solid';
					}
					last_main_menu = this;
					this.style.borderColor='#FFFFFF'; 
					this.style.borderStyle='groove'; 
					$$type{onhover}
				" 
				onmouseout="
					if (hasMouse (this, event)) return;
					this.style.borderColor='#D6D3CE'; 
					this.style.borderStyle='solid';
					if (
						(event.y < 
							this.offsetTop 
							+ this.offsetParent.offsetTop 
							+ this.offsetParent.offsetParent.offsetTop 
							+ 2
						) && last_vert_menu [0]
					) {
						
						for (var i = 0; i < last_vert_menu.length; i++) {
							if (last_vert_menu [i]) last_vert_menu [i].style.display = 'none';
						}
						
					}				
				" 
				class="main-menu" 
				nowrap
			>&nbsp;<a class="main-menu" id="main_menu_$$type{name}" target="$$type{target}" href="$$type{href}" tabindex=-1>&nbsp;$$type{label}&nbsp;</a>&nbsp;</td>
EOH
			
	}

	$html .= <<EOH;
			<tr>
				<td class=bgr8 colspan=$colspan width=100%><img height=2 src="$_REQUEST{__uri}0.gif" width=1 border=0></td>
			<tr>
				<td class=bgr6 colspan=$colspan width=100%><img height=1 src="$_REQUEST{__uri}0.gif" width=1 border=0></td>
			<tr>
				<td class=bgr0 colspan=$colspan width=100%><img height=1 src="$_REQUEST{__uri}0.gif" width=1 border=0></td>
		</table>
EOH

	foreach my $type (@types) {
		$html .= $type -> {vert_menu};
	}

	return $html;
	
}

################################################################################

sub draw_vert_menu {

	my ($_SKIN, $name, $types, $level) = @_;
		
	my $html = <<EOH;
		<div 
			id="vert_menu_$name" 
			style="display:none; position:absolute; z-index:100" 
			onmouseout="check_popup_menus(event)"
		>
			<table id="vert_menu_table_$name" width=1 bgcolor=#d5d5d5 cellspacing=0 cellpadding=0 border=0 border=1>
				<tr height=1>
					<td bgcolor=#D6D3CE colspan=4><img height=1 src=$_REQUEST{__uri}0.gif width=1 border=0></td>
					<td width=1 bgcolor=#424142 colspan=1><img height=1 src=$_REQUEST{__uri}0.gif width=1 border=0></td>
				</tr>
				<tr height=1>
					<td width=1 bgcolor=#D6D3CE><img height=1 src=$_REQUEST{__uri}0.gif width=1 border=0></td>
					<td width=1 bgcolor=#ffffff colspan=2><img height=1 src=$_REQUEST{__uri}0.gif width=1 border=0></td>
					<td width=1 bgcolor=#888888><img height=1 src=$_REQUEST{__uri}0.gif width=1 border=0></td>
					<td width=1 bgcolor=#424142><img height=1 src=$_REQUEST{__uri}0.gif width=1 border=0></td>
				</tr>
EOH

	foreach my $type (@$types) {
	
		if ($type eq BREAK) {

			$html .= <<EOH;
				<tr height=2>

					<td bgcolor=#D6D3CE width=1><img height=2 src=$_REQUEST{__uri}0.gif width=1 border=0></td>
					<td bgcolor=#ffffff width=1><img height=2 src=$_REQUEST{__uri}0.gif width=1 border=0></td>

					<td onmouseover="blockEvent ();" onmouseout="blockEvent ();">
						<table width=90% border=0 cellspacing=0 cellpadding=0 align=center minheight=2>
							<tr height=1><td bgcolor="#888888"><img height=1 src=$_REQUEST{__uri}0.gif width=1 border=0></td></tr>
							<tr height=1><td bgcolor="#ffffff"><img height=1 src=$_REQUEST{__uri}0.gif width=1 border=0></td></tr>
						</table>
					</td>
					<td width=1 bgcolor=#888888><img height=2 src=$_REQUEST{__uri}0.gif width=1 border=0></td>
					<td width=1 bgcolor=#424142><img height=2 src=$_REQUEST{__uri}0.gif width=1 border=0></td>
					
				</tr>
				
EOH
		
		}
		else {
		
			my $td = $type -> {items} ? <<EOH : qq{<td nowrap onmouseover="m_on(this)" onmouseout="m_off(this)" onclick="$$type{onclick}" class="vert-menu">&nbsp;&nbsp;$$type{label}&nbsp;&nbsp;</td>};
				<td onmouseover="blockEvent ();" onmouseout="blockEvent ();">
				<table width=100% border=0 cellspacing=0 cellpadding=0>
					<tr>
						<td         nowrap onmouseover="m_on(this)" onmouseout="m_off(this)" onclick="$$type{onclick}" class="vert-menu">&nbsp;&nbsp;$$type{label}&nbsp;&nbsp;</td>
						<td width=5 nowrap onmouseover="m_on(this)" onmouseout="m_off(this)" onclick="$$type{onclick}" class="vert-menu" align=right><font face=Marlett>8</font>&nbsp;</td>
					</tr>
				</table>
				</td>
EOH
		
			$html .= <<EOH;
				<tr>
					<td width=1 bgcolor=#D6D3CE><img height=1 src=$_REQUEST{__uri}0.gif width=1 border=0></td>
					<td width=1 bgcolor=#ffffff><img height=1 src=$_REQUEST{__uri}0.gif width=1 border=0></td>
					$td
					<td width=1 bgcolor=#888888><img height=1 src=$_REQUEST{__uri}0.gif width=1 border=0></td>
					<td width=1 bgcolor=#424142><img height=1 src=$_REQUEST{__uri}0.gif width=1 border=0></td>
				</tr>
EOH
		}
	
	}

	$html .= <<EOH;
				<tr height=1>
					<td width=1 bgcolor=#D6D3CE><img height=1 src=$_REQUEST{__uri}0.gif width=1 border=0></td>
					<td width=1 bgcolor=#888888 colspan=3><img height=1 src=$_REQUEST{__uri}0.gif width=1 border=0></td>
					<td width=1 bgcolor=#424142><img height=1 src=$_REQUEST{__uri}0.gif width=1 border=0></td>
				</tr>
				<tr height=1>
					<td width=1 bgcolor=#424142 colspan=5><img height=1 src=$_REQUEST{__uri}0.gif width=1 border=0></td>
				</tr>
			</table>
		</div>
EOH

	foreach my $type (@$types) {
		$html .= $type -> {vert_menu};
	}

	return $html;

}

################################################################################
# TABLES
################################################################################

################################################################################

sub js_set_select_option {
	my ($_SKIN, $name, $item, $fallback_href) = @_;	
	return ($fallback_href || $i) unless $_REQUEST {select};
	my $question = js_escape ($i18n -> {confirm_close_vocabulary} . ' ' . $item -> {label} . '?');
	$name ||= '_' . $_REQUEST {select};
	return 'javaScript:if (window.confirm(' . $question . ')) {parent.setSelectOption(' . js_escape ($name) . ', '	. $item -> {id} . ', ' . js_escape ($item -> {label}) . ');}';
}

################################################################################

sub draw_text_cell {

	my ($_SKIN, $data, $options) = @_;
	
	my $attributes = dump_attributes ($data -> {attributes});

	my $txt = '';
	
	unless ($data -> {off}) {

		$txt = $data -> {label};
		$txt =~ s{^\s+}{};
		$txt =~ s{\s+$}{};

		if ($data -> {bold} || $options -> {bold}) {
			$txt = '<b>' . $txt . '</b>';
		}

		if ($data -> {italic} || $options -> {italic}) {
			$txt = '<i>' . $txt . '</i>';
		}

		if ($data -> {strike} || $options -> {strike}) {
			$txt = '<strike>' . $txt . '</strike>';
		}
		
		$txt = '&nbsp;' . $txt . '&nbsp;';

		unless ($data -> {no_nobr}) {
			$txt = '<nobr>' . $txt . '</nobr>';
		}

		if ($data -> {href}) {
			$data -> {target} ||= '_self';
			$txt = qq { <a id="$$data{a_id}" class=$$data{a_class} target="$$data{target}" href="$$data{href}" onFocus="blur()">$txt</a> };
		}

		if ($data -> {status}) {
			$txt = qq {<img src='status_$data->{status}->{icon}.gif' border=0 alt='$data->{status}->{label}' align=absmiddle hspace=5>} . $txt;
		}		

	}


	return qq {\n\t<td $attributes>$txt</td>};

}

################################################################################

sub draw_radio_cell {

	my ($_SKIN, $data, $options) = @_;

	my $attributes = dump_attributes ($data -> {attributes});

	return qq {<td $$options{data} $attributes><input type=radio name=$$data{name} $$data{checked} value='$$data{value}'></td>};

}

################################################################################

sub draw_checkbox_cell {

	my ($_SKIN, $data, $options) = @_;

	my $attributes = dump_attributes ($data -> {attributes});

	return qq {<td $$options{data} $attributes><input type=checkbox name=$$data{name} $$data{checked} value='$$data{value}'></td>};

}

################################################################################

sub draw_select_cell {

	my ($_SKIN, $data, $options) = @_;

	my $attributes = dump_attributes ($data -> {attributes});

	my $multiple = $data -> {rows} > 1 ? "multiple size=$$data{rows}" : '';
	my $html = qq {<td $attributes><nobr><select name="$$data{name}" onChange="is_dirty=true; $$options{onChange}" onkeypress="typeAhead()" $multiple>};

	$html .= qq {<option value="0">$$data{empty}</option>\n} if defined $data -> {empty};

	foreach my $value (@{$data -> {values}}) {
		$html .= qq {<option value="$$value{id}" $$value{selected}>$$value{label}</option>\n};
	}
	
	$html .= qq {</select></nobr></td>};
	
	return $html;

}

################################################################################

sub draw_input_cell {

	my ($_SKIN, $data, $options) = @_;

	my $attributes = dump_attributes ($data -> {attributes});

	return qq {<td $$data{title} $attributes><nobr><input onFocus="q_is_focused = true; left_right_blocked = true;" onBlur="q_is_focused = false; left_right_blocked = false;" type="text" name="$$data{name}" value="$$data{label}" maxlength="$$data{max_len}" size="$$data{size}"></nobr></td>};

}

################################################################################

sub draw_row_button {

	my ($_SKIN, $options) = @_;

	if ($options -> {off} || $_REQUEST {lpt}) {	
		return $conf -> {core_hide_row_buttons} == 2 ? '' : '<td class=bgr0 valign=top nowrap width="1%">&nbsp;</td>';
	}
	
	if ($conf -> {core_show_icons} || $_REQUEST {__core_show_icons}) {
		my $label = $options -> {label};
		$options -> {label} = qq|<img src="/i/buttons/$$options{icon}.gif" alt="$$options{label}" border=0 hspace=0 vspace=0 align=absmiddle>|;
		$options -> {label} .= "&nbsp;$label" if $options -> {force_label} || $conf -> {core_hide_row_buttons} > -1;
	}
	else {
		$options -> {label} = "\&nbsp;[$$options{label}]\&nbsp;";
	}
	
	my $vert_line = {label => $options -> {label}, href => $options -> {href}};
	$vert_line -> {label} =~ s{[\[\]]}{}g;
	push @{$_SKIN -> {__current_row} -> {__types}}, $vert_line;
		
	if ($conf -> {core_hide_row_buttons} == 2) {
		return '';
	}
	elsif ($conf -> {core_hide_row_buttons} == 1) {
		return $_SKIN -> draw_text_cell ({label => '&nbsp;'});
	}
	else {
		return qq {<td $$options{title} class="row-button" valign=top nowrap width="1%"><a TABINDEX=-1 class="row-button" href="$$options{href}" target="$$options{target}">$$options{label}</a></td>};
	}

}

####################################################################

sub draw_table_header {
	
	my ($_SKIN, $data_rows, $html_rows) = @_;
	my $html = '<thead>';
	foreach (@$html_rows) {$html .= $_};
	$html .= '</thead>';
	
}

####################################################################

sub draw_table_header_row {
	
	my ($_SKIN, $data_cells, $html_cells) = @_;
	
	my $html = '<tr>';
	foreach (@$html_cells) {$html .= $_};
	$html .= '</tr>';
	
	return $html;
	
}

####################################################################

sub draw_table_header_cell {
	
	my ($_SKIN, $cell) = @_;
	
	return '' if $cell -> {hidden} || $cell -> {off} || (!$cell -> {label} && $conf -> {core_hide_row_buttons} == 2);

	$cell -> {label} .= "\&nbsp;\&nbsp;<a class=lnk4 href=\"$$cell{href_asc}\"><b>\&uarr;</b></a>"  if $cell -> {href_asc};
	$cell -> {label} .= "\&nbsp;\&nbsp;<a class=lnk4 href=\"$$cell{href_desc}\"><b>\&darr;</b></a>" if $cell -> {href_desc};

	if ($cell -> {href}) {
		$cell -> {label} = "<a class=lnk4 href=\"$$cell{href}\"><b>" . $cell -> {label} . "</b></a>";
	}	

	my $attributes = dump_attributes ($cell -> {attributes});
	
	return "<th $attributes $$cell{title}>\&nbsp;$$cell{label}\&nbsp;</th>";

}

####################################################################

sub draw_table {

	my ($_SKIN, $tr_callback, $list, $options) = @_;

	$options -> {height}     ||= 10000;
	$options -> {min_height} ||= 200;
	
	$$options{toolbar} =~ s{^\s+}{}sm;
	$$options{toolbar} =~ s{\s+$}{}sm;

	my $html = <<EOH;
	
		$$options{title}
		$$options{path}
		$$options{top_toolbar}
		
		<table cellspacing=0 cellpadding=0 width="100%">		
			<tr>		
				<form name=$$options{name} action=$_REQUEST{__uri} method=post enctype=multipart/form-data target=invisible>
					<input type=hidden name=type value=$$options{type}>
					<input type=hidden name=action value=$$options{action}>
					<input type=hidden name=sid value=$_REQUEST{sid}>
					<input type=hidden name=__last_query_string value="$_REQUEST{__last_last_query_string}">
					<input type=hidden name=__last_scrollable_table_row value="$_REQUEST{__last_scrollable_table_row}">
EOH

	foreach my $key (keys %_REQUEST) {
		next if $key =~ /^_/ or $key =~/^(type|action|sid|__last_query_string)$/;
		$html .= qq {<input type=hidden name=$key value="$_REQUEST{$key}">\n};
	}

	$html .= qq {<td class=bgr8><div class="table-container" style="height: expression(actual_table_height(this,$$options{min_height},$$options{height},'$__last_centered_toolbar_id'));"><table cellspacing=1 cellpadding=0 width="100%" id="scrollable_table" lpt=$$options{lpt}>\n};

	$html .= $options -> {header} if $options -> {header};

	$html .= qq {<tbody>\n};

	if ($options -> {dotdot}) {
		$html .= $options -> {dotdot};
	}

	my $menus = '';

	foreach our $i (@$list) {
		
		foreach my $tr (@{$i -> {__trs}}) {
			
			
			$html .= "<tr id='$$i{__tr_id}'";
			
			if (@{$i -> {__types}} && $conf -> {core_hide_row_buttons} > -1 && !$_REQUEST {lpt}) {
				$menus .= $i -> {__menu};
				$html  .= qq{ oncontextmenu="open_popup_menu('$i'); blockEvent ();"};
			}

			$html .= '>';
			$html .= $tr;
			$html .= '</tr>';
			
		}
		
	}

	$html .= <<EOH;
			</tbody></table></div>$$options{toolbar}</td></form></tr></table>
		$menus
		
EOH

	$__last_centered_toolbar_id = '';
		
	return $html;

}

################################################################################

sub draw_one_cell_table {

	my ($_SKIN, $options, $body) = @_;
	
	return <<EOH			
		<table cellspacing=0 cellpadding=0 width="100%">
				<form name=form action=$_REQUEST{__uri} method=post enctype=multipart/form-data target=invisible>
					<tr><td class=bgr8>$body</td></tr>
				</form>
		</table>
EOH

}

################################################################################

sub draw_error_page {

	my ($_SKIN, $page) = @_;

	my $html = <<EOH;
		<html>
			<head></head>
			<body onLoad="
EOH

	if ($page -> {error_field}) {
		$html .= <<EOJ;
			var e = window.parent.document.getElementsByName('$page->{error_field}'); 
			if (e && e[0]) { e[0].focus () }				
EOJ
	}

	my $message = js_escape ($_REQUEST {error});
								
	$html .= <<EOH;
		history.go (-1); 
		alert ($message);
		window.parent.document.body.style.cursor = 'normal';
	">
				</body>
			</html>				
EOH

	return $html;

}

################################################################################

sub start_page {
}

################################################################################

sub draw_page {

	my ($_SKIN, $page) = @_;

	if ($_REQUEST {__only_form}) {

		$page -> {body} =~ s{\\}{\\\\}gsm;
		$page -> {body} =~ s{\"}{\\\"}gsm; #"
		$page -> {body} =~ s{[\n\r\s]+}{ }gsm;

		return <<EOH;
		<body onLoad="main()">
			<script>
				function main () {
					window.parent.document.forms ['$_REQUEST{__only_form}'].elements ['_$_REQUEST{__only_field}'].outerHTML = "$page->{body}";
					window.parent.document.forms ['$_REQUEST{__only_form}'].elements ['_$_REQUEST{__only_field}'].focus ();
				}
			</script>
		</body>
EOH
	}
		
	$_REQUEST {__scrollable_table_row} ||= 0;
	
	my $meta_refresh = $_REQUEST {__meta_refresh} ? qq{<META HTTP-EQUIV=Refresh CONTENT="$_REQUEST{__meta_refresh}; URL=@{[create_url()]}&__no_focus=1">} : '';	

	my $root = $_REQUEST{__uri};
	
	my $request_package = ref $apr;
	my $mod_perl = $ENV {MOD_PERL};
	$mod_perl ||= 'NO mod_perl AT ALL';
	
	my $timeout = 1000 * (60 * $conf -> {session_timeout} - 1);
	
	$_REQUEST {__select_rows} += 0;
	
	my $static_salt = $Zanas_VERSION_NAME;
	$static_salt .= '_00000';
	if ($_REQUEST {sid}) {
		$static_salt .= $_REQUEST {sid};
	}
	else {
		$static_salt .= $$ . time ();
		$static_salt =~ s{\.}{}g;
	}
						
	return <<EOH;
		<html>		
			<head>
				<title>$$i18n{_page_title}</title>
								
				<meta name="Generator" content="Zanas ${Zanas::VERSION} / $$SQL_VERSION{string}; parameters are fetched with $request_package; gateway_interface is $ENV{GATEWAY_INTERFACE}; $mod_perl is in use">
				<meta http-equiv=Content-Type content="text/html; charset=$$i18n{_charset}">
				
				$meta_refresh
				
				<LINK href="${root}zanas_${static_salt}.css" type=text/css rel=STYLESHEET>
				@{[ map {<<EOJS} @{$_REQUEST{__include_css}} ]}
					<LINK href="/i/$_.css" type=text/css rel=STYLESHEET>
EOJS

					<script src="${root}navigation_${static_salt}.js">
					</script>
				@{[ map {<<EOCSS} @{$_REQUEST{__include_js}} ]}
					<script type="text/javascript" src="/i/${_}.js">
					</script>
EOCSS
			
				<script>
					var select_rows = $_REQUEST{__select_rows};
					var scrollable_table = null;
					var scrollable_table_row = 0;
					var scrollable_table_row_id = 0;
					var scrollable_table_row = 0;
					var scrollable_table_row_length = 0;
					var scrollable_table_row_cell_old_style = '';
					var is_dirty = false;					
					var scrollable_table_is_blocked = false;
					var q_is_focused = false;					
					var left_right_blocked = false;					
					var scrollable_rows = new Array();		
					var td2sr = new Array ();
					var td2sc = new Array ();
					var last_vert_menu = new Array ();
					last_vert_menu [0] = null;
					last_vert_menu [1] = null;
					last_vert_menu [2] = null;
					last_vert_menu [3] = null;
					last_vert_menu [4] = null;
					var last_main_menu = null;
					var ms_word = null;
					
					function td_on_click () {
						var uid = window.event.srcElement.uniqueID;
						var new_scrollable_table_row = td2sr [uid];
						var new_scrollable_table_row_cell = td2sc [uid];
						if (new_scrollable_table_row == null || new_scrollable_table_row_cell == null) return;
						scrollable_rows [scrollable_table_row].cells [scrollable_table_row_cell].className = scrollable_table_row_cell_old_style;
						scrollable_table_row = new_scrollable_table_row;
						scrollable_table_row_cell = new_scrollable_table_row_cell;
						scrollable_table_row_cell_old_style = scrollable_rows [scrollable_table_row].cells [scrollable_table_row_cell].className;
						scrollable_rows [scrollable_table_row].cells [scrollable_table_row_cell].className += ' row-cell-hilite';
						focus_on_first_input (scrollable_rows [scrollable_table_row].cells [scrollable_table_row_cell]);
						return false;
					}
					
					
					function body_on_load () {

						@{[ $_REQUEST{__no_focus} ? '' : 'window.focus ();' ]}

						@{[ $_REQUEST{sid} ? <<EOK : '' ]}
							keepaliveID = setTimeout ("open('$_REQUEST{__uri}?keepalive=$_REQUEST{sid}', 'invisible'); clearTimeout (keepaliveID)", $timeout);
EOK

						$_REQUEST{__doc_on_load}

						@{[ $_REQUEST {__pack} ? <<EOF : '']}
							var newWidth  = document.all ['bodyArea'].offsetWidth + 10;
							var newHeight = document.all ['bodyArea'].offsetHeight + 30;
							window.resizeTo (newWidth, newHeight);						
							window.moveTo ((screen.width - newWidth) / 2, (screen.height - newHeight) / 2);
EOF

						if (!document.body.getElementsByTagName) return;

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
								scrollable_cell.oncontextmenu = td_on_click;
							}
						}

						scrollable_table = document.getElementById ('scrollable_table');

						if (scrollable_table) {				

							scrollable_table = scrollable_table.tBodies (0);

							scrollable_table_row = $_REQUEST{__scrollable_table_row};
							scrollable_table_row_cell = 0;

							if (scrollable_rows.length > 0) {
								if (scrollable_table_row > scrollable_rows.length - 1) {
									scrollable_table_row = scrollable_rows.length - 1;
								}
								scrollable_table_row_cell_old_style = scrollable_rows [scrollable_table_row].cells [scrollable_table_row_cell].className;
								scrollable_rows [scrollable_table_row].cells [scrollable_table_row_cell].className += ' row-cell-hilite';
							}
							else {
								scrollable_table = null;
							}

						}

						var focused_inputs = document.getElementsByName ('$_REQUEST{__focused_input}');

						if (focused_inputs != null && focused_inputs.length > 0) {
							var focused_input = focused_inputs [0];
							focused_input.focus ();
							if (focused_input.type == 'radio') {
								focused_input.select ();
							}
						}
						else {	

							var forms = document.forms;
							if (forms != null) {

								var done = 0;

								for (var i = 0; i < forms.length; i++) {

									var elements = forms [i].elements;

									if (elements != null) {

										for (var j = 0; j < elements.length; j++) {

											var element = elements [j];

											if (element.tagName == 'INPUT' && element.name == 'q') {
												break;
											}

											if (
												   (element.tagName == 'INPUT'  && (element.type == 'text' || element.type == 'checkbox' || element.type == 'radio'))
												||  element.tagName == 'TEXTAREA') 
											{
												element.focus ();
												done = 1;
												break;
											}										

										}									

									}

									if (done) {
										break;
									}

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

						$_REQUEST{__on_load}
					
					}
					
					
				</script>
				
			</head>
			<body 
				bgcolor=white 
				leftMargin=0 
				topMargin=0 
				marginwidth=0 
				marginheight=0 
				name="body" 
				id="body"
				scroll="auto"
				onload= "body_on_load (); try {StartClock ()} catch (e) {}"
				onbeforeunload="document.body.style.cursor = 'wait'"
				onunload=" try {KillClock ()} catch (e) {}"
				onmousemove="check_popup_menus(event)"
				onkeydown="
				
					if (window.event.keyCode == 88 && window.event.altKey) {
						document.location.href = '$_REQUEST{__uri}?type=_logout&sid=$_REQUEST{sid}&salt=@{[rand]}';
						blockEvent ();
					}
					
					handle_basic_navigation_keys ();
					
					@{[ map {&{"handle_hotkey_$$_{type}"} ($_)} @{$page->{scan2names}} ]}
					
				"						
			>
				
				@{[ $_REQUEST{__help_url} ? <<EOHELP : '' ]}
					<script for="body" event="onhelp">
						nope ('$_REQUEST{__help_url}', '_blank', 'toolbar=no,resizable=yes');
						event.returnValue = false;
					</script>						
EOHELP
				
				<div id="bodyArea" _style='height:100%; padding:0px; margin:0px'>
					<iframe name=invisible src="${root}0.html" width=0 height=0 application="yes" style="display:none">
					</iframe>
					$$page{auth_toolbar}
					$$page{menu}
					$$page{body}
				</div>				
			</body>
		</html>
EOH

}

################################################################################

sub handle_hotkey_focus {

	my ($r) = @_;
	
	<<EOJS
		if (window.event.keyCode == $$r{code} && window.event.altKey && window.event.ctrlKey) {
			document.form.$$r{data}.focus ();
			blockEvent ();
		}
EOJS

}

################################################################################

sub handle_hotkey_href {

	my ($r) = @_;
	
	my $ctrl = $r -> {ctrl} ? '' : '!';
	my $alt  = $r -> {alt}  ? '' : '!';
	
	my $condition = 
		$r -> {off}     ? '0' :
		$r -> {confirm} ? 'window.confirm(' . js_escape ($r -> {confirm}) . ')' : 
		'1';

	if ($r -> {href}) {
			
		return <<EOJS
			if (window.event.keyCode == $$r{code} && $alt window.event.altKey && $ctrl window.event.ctrlKey) {
				if ($condition) {
					nope ('$$r{href}&__from_table=1&salt=' + Math.random () + '&' + scrollable_rows [scrollable_table_row].id, '_self');
				}
				blockEvent ();
			}
EOJS

	}
	else {
		
		return <<EOJS
			if (window.event.keyCode == $$r{code} && $alt window.event.altKey && $ctrl window.event.ctrlKey) {
				if ($condition) {
					var a = document.getElementById ('$$r{data}');
					activate_link (a.href, a.target);
				}
				blockEvent ();
			}
EOJS
	}

}

1;