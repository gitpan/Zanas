no warnings;

################################################################################

sub register_hotkey {
	return '';
}

################################################################################

sub hotkeys {
	return '';
}

################################################################################

sub hotkey {
	return '';
}

################################################################################

sub handle_hotkey_focus {
	return '';
}

################################################################################

sub handle_hotkey_href {
	return '';
}

################################################################################

sub js_escape {
	return '';
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

### ???	
		
	}
		
	my $menu = draw_menu ($page -> {menu}, $page -> {highlighted_type});
		
	my $auth_toolbar = draw_auth_toolbar ({lpt => $lpt});

	my $root = $_REQUEST{__uri};
	
	my $request_package = ref $apr;
	my $mod_perl = $ENV {MOD_PERL};
	$mod_perl ||= 'NO mod_perl AT ALL';
	
	my $timeout = 1000 * (60 * $conf -> {session_timeout} - 1);
								
	$_REQUEST {__content_type} = 'application/vnd.mozilla.xul+xml';
				
	return <<EOH;
<?xml version="1.0" encoding="$$i18n{_charset}"?>
<?xml-stylesheet href="chrome://global/skin" type="text/css"?>
<window 
	xmlns="http://www.mozilla.org/keymaster/gatekeeper/there.is.only.xul"
	xmlns:html="http://www.w3.org/1999/xhtml"
	title="$$conf{page_title}"
	hidechrome="1"	

		onload="

			netscape.security.PrivilegeManager.enablePrivilege(&quot;UniversalBrowserWrite&quot;);

			var menubar_visible     = window.menubar.visible;     window.menubar.visible = 0;
			var locationbar_visible = window.locationbar.visible; window.locationbar.visible = 0;
			var personalbar_visible = window.personalbar.visible; window.personalbar.visible = 0;
			var statusbar_visible   = window.statusbar.visible;   window.statusbar.visible = 0;
			var toolbar_visible     = window.toolbar.visible;     window.toolbar.visible = 0;

		"

		onunload="

			netscape.security.PrivilegeManager.enablePrivilege(&quot;UniversalBrowserWrite&quot;);

			window.menubar.visible = menubar_visible;
			window.locationbar.visible = locationbar_visible;
			window.personalbar.visible = personalbar_visible;
			window.statusbar.visible = statusbar_visible;
			window.toolbar.visible = toolbar_visible;     

		"
>
	<hbox flex="1">
		<vbox flex="1">
			$menu
			$body
		</vbox>
	</hbox>
	
</window>
EOH
	
}

################################################################################

sub draw_form_field_button {
	my ($options, $data) = @_;
	return '';
}

################################################################################

sub draw_menu {

	my ($types, $cursor) = @_;	
	
	my $result = '';
	

	foreach my $type (@$types) {

		$type -> {label} =~ s{\&}{}g;


		if ($type -> {no_page}) {
#			$type -> {href} = "javaScript:open_popup_menu('$$type{name}')";
		} 
		else {
			$type -> {href} ||= "/?type=$$type{name}";
			$type -> {href} .= "&role=$$type{role}" if $type -> {role};
			check_href ($type);
		}

		$type -> {href} =~ s{\&}{\&amp;}g;

		$result .= qq{<menu label="$$type{label}" value="$$type{href}" onclick="document.location='$$type{href}'">};
		$result .= qq{</menu>};
	}
	
	return <<EOH;
	
	<menubar>
		$result
	</menubar>
EOH
	
}

################################################################################

sub draw_vert_menu {
	my ($name, $types) = @_;
	return '';
}

################################################################################

sub draw_hr {
	my (%options) = @_;
	return '';
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
	return '';
}

################################################################################

sub draw_checkbox_cell {
	my ($data) = @_;
	return '';
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

	return qq {<listcell />} if $data -> {off};	
	
	my $ondblclick = '';
	if ($data -> {href}) {
		$data -> {href} =~ s{\&}{\&amp;}g;
		$ondblclick = qq{onclick="document.location='$$data{href}'"};
	}
		
	return qq {<listcell label="$$data{label}" $ondblclick />};

}

################################################################################

sub draw_tr {
	my ($options, @tds) = @_;
	return '';	
}

################################################################################

sub draw_one_cell_table {
	my ($options, $body) = @_;
	return '';	
}

################################################################################

sub draw_table_header {

	my ($cell) = @_;

	return (join '', map {draw_table_header ($_)} @$cell) if ref $cell eq ARRAY;
	
	return "<listheader flex='1' label='$cell' />" unless ref $cell;
	
	return '' if $cell -> {off};
		
	return "<listheader flex='1' label='$$cell{label}' />";
	
}

################################################################################

sub draw_table {

	my $headers = [];

	unless (ref $_[0] eq CODE or (ref $_[0] eq ARRAY and ref $_[0] -> [0] eq CODE)) {
		$headers = shift;
	}

	my $listhead = '<listhead>' . draw_table_header ($headers) . '</listhead>';
	
	$listhead .= '<listcols>';
	for (my $i = 1; $i <= @$headers; $i++) {
		$listhead .= "<listcol flex='1'/>";
	}	
	$listhead .= '</listcols>';
	
	my ($tr_callback, $list, $options) = @_;
	
	$options -> {title} -> {label} = $__window_title;
	undef $__window_title;
	
	if (ref $options -> {top_toolbar} eq ARRAY) {
#		$_FLAG_ADD_LAST_QUERY_STRING = 1;
		$options -> {top_toolbar} = draw_toolbar (@{ $options -> {top_toolbar} });
#		$_FLAG_ADD_LAST_QUERY_STRING = 0;
	}
	
	return '' if $options -> {off};
	
	my $trs = '';

	my @tr_callbacks = ref $tr_callback eq ARRAY ? @$tr_callback : ($tr_callback);
	
	my $n = 0;
	foreach our $i (@$list) {
		$i -> {__n} = $n++;
		foreach my $callback (@tr_callbacks) {
			$trs .= '<listitem>';
			our $_FLAG_ADD_LAST_QUERY_STRING = 1;
			$trs .= &$callback ();
			undef $_FLAG_ADD_LAST_QUERY_STRING;
			$trs .= '</listitem>' . "\n";
			$scrollable_row_id ++;
		}
	}

	return <<EOH;
	<groupbox>
		<caption label="${$$options{title}}{label}" />
		$$options{top_toolbar}
		<listbox style="height:expression(document.documentElement.offsetHeight);">
			$listhead
			$trs
		</listbox>
	</groupbox>
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

	return '';	
	
}

################################################################################

sub draw_window_title {

	my ($options) = @_;		
	
	return '' if $options -> {off};
	
	$__window_title = $options -> {label};

	return '';	

}

################################################################################

sub draw_toolbar {

	my ($options, @buttons) = @_;
	
	return '' if $options -> {off};	

	my $buttons = join '', map { ref $_ eq HASH ? ( &{'draw_toolbar_' . ($$_{type} || 'button')} ($_) ) : $_ } @buttons;

	return <<EOH;
		<toolbar>
			$buttons
		</toolbar>
EOH
	
}

################################################################################

sub draw_toolbar_button {

	my ($options) = @_;
	
	return '' if $options -> {off};
	
	$options -> {label} =~ s{\&}{}g;
	
	return <<EOH;	
		<toolbarbutton label="$$options{label}" />
EOH

}

################################################################################

sub draw_toolbar_input_text {

	my ($options) = @_;
	
	return '' if $options -> {off};

	my $value = $options -> {value};
	$value ||= $_REQUEST{$$options{name}};
	
	$options -> {size} ||= 15;
	
	return '';	

}

################################################################################

sub draw_toolbar_input_submit {

	my ($options) = @_;
	return '' if $options -> {off};

	return '';	

}

################################################################################

sub draw_toolbar_pager {

	my ($options) = @_;
	
	$options -> {portion} ||= $conf -> {portion};

	my $start = $_REQUEST {start} + 0;

	my $label = '';	

	$conf -> {kb_options_pager} ||= $conf -> {kb_options_buttons};
	$conf -> {kb_options_pager} ||= {ctrl => 1, alt => 1};

	return '';	

}

################################################################################

sub draw_row_button {

	my ($options) = @_;	
	return '';	

}

################################################################################

sub draw_row_buttons {

	my ($options, $buttons) = @_;
	return '';	

}

################################################################################

sub draw_form_field {

	my ($field, $data) = @_;
	return '';	
		
}

################################################################################

sub draw_form {

	my ($options, $data, $fields) = @_;
	return '';	
	
}

################################################################################

sub js_ok_escape {
	
	my ($options) = @_;
	return '';	
	
}

################################################################################

sub draw_form_field_string {

	my ($options, $data) = @_;
	
	$options -> {max_len} ||= $conf -> {max_len};	
	$options -> {max_len} ||= $options -> {size};
	$options -> {max_len} ||= 30;		
	return '';	
		
}

################################################################################

sub draw_form_field_date {

	my ($options, $data) = @_;	
	$options -> {no_time} = 1;	
	return draw_form_field_datetime ($options, $data);
	return '';	

}

################################################################################

sub draw_form_field_datetime {

	my ($options, $data) = @_;
	return '';	

}

################################################################################

sub draw_form_field_file {
	my ($options, $data) = @_;	
	return '';	
}

################################################################################

sub draw_form_field_hidden {
	my ($options, $data) = @_;
	return '';	
}

################################################################################

sub draw_form_field_hgroup {
	my ($options, $data) = @_;
	return '';	
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
	
	return '';	

}

################################################################################

sub draw_form_field_password {
	my ($options, $data) = @_;
	$options -> {size} ||= $conf -> {size} || 120;	
	return '';	
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

	return '';	
	
}

################################################################################

sub draw_form_field_radio {

	my ($options, $data) = @_;
	
	my $html = '';

	return '';	
					
}

################################################################################

sub draw_form_field_checkbox {

	my ($options, $data) = @_;
	
	my $s = $options -> {checked} || $data -> {$options -> {name}};
	
	$s =~ s/\"/\&quot\;/gsm; #"
	
	my $checked = $s ? 'checked' : '';
		
	return '';	

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
			
	return '';	

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
			
	return '';	

}

################################################################################

sub draw_toolbar_input_checkbox {

	my ($options) = @_;
	
	my $html = '';
	
	my $checked = $_REQUEST {$options -> {name}} ? 'checked' : '';
					
	return '';	

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
			
	return '';	

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
	]);
	
	return '';	

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
	]);

	return '';	
	
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
	]);

	return '';	
	
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
	]);
	
	return '';
	
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
	
	return '';
	
}

################################################################################

sub draw_centered_toolbar {

	$_REQUEST{lpt} and return '';

	my ($options, $list) = @_;

	my $colspan = 3 * (1 + @$list) + 1;

	return '';	

}

################################################################################

sub draw_auth_toolbar {

	return '';	

}

################################################################################

sub draw_form_field_image {
	my ($options, $data) = @_;
	my $s = $$data{$$options{name}};
	$s =~ s/\"/\&quot\;/gsm; #"
	return '';	
}

################################################################################

sub draw_form_field_iframe {
	
	my ($options, $data) = @_;

	check_href ($options);
	
	$options -> {width} ||= '100%';
	$options -> {height} ||= '100%';

	return '';	

}

################################################################################

sub draw_radio_cell {

	my ($options) = @_;
	my $value = $options -> {value} || 1;
	
	my $checked = $options -> {checked} ? 'checked' : '';

	$options -> {attributes} ||= {};
	$options -> {attributes} -> {class} ||= 'txt4';

	my $attributes = dump_attributes ($options -> {attributes});

#	return qq {<td $attributes>&nbsp;} if $options -> {off};	

	check_title ($options);

#	return qq {<td $$options{title} $attributes><input type=radio name=$$options{name} $checked value='$value'></td>};

	return '';	

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

#	return qq {<td $attributes><nobr><select name="$$data{name}" onChange="is_dirty=true; $$options{onChange}" onkeypress="typeAhead()" $multiple>$html</select></nobr></td>};

	return '';	
	
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

	return '';	

}

1;