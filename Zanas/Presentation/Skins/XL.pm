package Zanas::Presentation::Skins::XL;

use Data::Dumper;

BEGIN {
	require Zanas::Presentation::Skins::Generic;
	delete $INC {"Zanas/Presentation/Skins/Generic.pm"};
}

################################################################################

sub options {
	return {
		no_buffering => 1,
	};
}

################################################################################

sub register_hotkey {

	my ($_SKIN, $hashref) = @_;
	$hashref -> {label} =~ s{\&}{}gsm;
	return undef;

}

################################################################################

sub draw_hr {
	my ($_SKIN, $options) = @_;
	$r -> print ('<p>&nbsp;</p>');
	return '';
}

################################################################################

sub draw_auth_toolbar {
	my ($_SKIN, $options) = @_;
	return '';
}

################################################################################

sub draw_window_title {

	my ($_SKIN, $options) = @_;
	$r -> print (<<EOH);
		<p style="font-family:Arial;font-size:12pt"><b><i>$$options{label}</i></b></p>
EOH
	return '';
}

################################################################################
# FORMS & INPUTS
################################################################################

sub start_form {

	my ($_SKIN, $options) = @_;
	$r -> print ($options -> {hr});
	$r -> print ($options -> {path});
	$r -> print (qq{<table border=1>});

}

################################################################################

sub start_form_row {
	$r -> print (qq{<tr>});
}

################################################################################

sub draw_form_row {
	my ($_SKIN, $row) = @_;
	foreach (@$row) {$r -> print ($_ -> {html})}
	$r -> print (qq{</tr>});
}

################################################################################

sub draw_form {

	my ($_SKIN, $options) = @_;
	$r -> print ('</table>');
	$r -> print ($options -> {bottom_toolbar});

	return '';

}

################################################################################

sub draw_path {

	my ($_SKIN, $options, $list) = @_;		
	return '';

}

################################################################################

sub draw_form_field {

	my ($_SKIN, $field, $data) = @_;
								
	if ($field -> {type} eq 'banner') {
		my $colspan     = 'colspan=' . ($field -> {colspan} + 1);
		return qq{<td $colspan nowrap align=center>$$field{html}</td>};
	}
	elsif ($field -> {type} eq 'hidden') {
		return '';
	}
				
	my $colspan     = $field -> {colspan}     ? 'colspan=' . $field -> {colspan}     : '';
	
	return (<<EOH);
		<td nowrap align=right><b>$$field{label}</b></td>
		<td $colspan>\n$$field{html}</td>
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
	return '';
}

################################################################################

sub draw_form_field_string {
	my ($_SKIN, $options, $data) = @_;
	return '';
}

################################################################################

sub draw_form_field_datetime {
	my ($_SKIN, $options, $data) = @_;
	return '';	
}

################################################################################

sub draw_form_field_file {
	my ($_SKIN, $options, $data) = @_;	
	return '';
}

################################################################################

sub draw_form_field_hidden {
	my ($_SKIN, $options, $data) = @_;
	return '';
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
	return $options -> {value};

}

################################################################################

sub draw_form_field_password {
	my ($_SKIN, $options, $data) = @_;
	return '';
}

################################################################################

sub draw_form_field_static {
		
	my ($_SKIN, $options, $data) = @_;
	
	my $html = '';

	if (ref $options -> {value} eq ARRAY) {
	
		for (my $i = 0; $i < @{$options -> {value}}; $i++) {
			$html .= ('<br>') if $i;
			$html .= ($options -> {value} -> [$i] -> {label});
		}
		
	}
	else {
		$html .= ($options -> {value});
	}
		
	return $html;
	
}

################################################################################

sub draw_form_field_checkbox {
	my ($_SKIN, $options, $data) = @_;
	return '';	
}

################################################################################

sub draw_form_field_radio {
	my ($_SKIN, $options, $data) = @_;
	return '';	
}

################################################################################

sub draw_form_field_select {
	my ($_SKIN, $options, $data) = @_;
	return '';
}

################################################################################

sub draw_form_field_checkboxes {
	my ($_SKIN, $options, $data) = @_;
	return '';
}

################################################################################

sub draw_form_field_image {
	my ($_SKIN, $options, $data) = @_;
	return '';
}

################################################################################

sub draw_form_field_iframe {	
	my ($_SKIN, $options, $data) = @_;
	return '';
}

################################################################################

sub draw_form_field_color {	
	my ($_SKIN, $options, $data) = @_;
	return '';
}

################################################################################

sub draw_form_field_htmleditor {	
	my ($_SKIN, $options, $data) = @_;
	return '';
}

################################################################################
# TOOLBARS
################################################################################

################################################################################

sub draw_toolbar {
	my ($_SKIN, $options) = @_;	
	return '';
}

################################################################################

sub draw_toolbar_break {
	my ($_SKIN, $options) = @_;
	return '';
}

################################################################################

sub draw_toolbar_button {
	my ($_SKIN, $options) = @_;
	return '';	
}

################################################################################

sub draw_toolbar_input_select {
	my ($_SKIN, $options) = @_;	
	return '';	
}

################################################################################

sub draw_toolbar_input_checkbox {
	my ($_SKIN, $options) = @_;	
	return '';
}

################################################################################

sub draw_toolbar_input_submit {
	my ($_SKIN, $options) = @_;
	return '';
}

################################################################################

sub draw_toolbar_input_text {
	my ($_SKIN, $options) = @_;
	return '';
}

################################################################################

sub draw_toolbar_input_datetime {
	my ($_SKIN, $options) = @_;
	return '';
}

################################################################################

sub draw_toolbar_pager {
	my ($_SKIN, $options) = @_;
	return '';
}

################################################################################

sub draw_centered_toolbar_button {
	my ($_SKIN, $options) = @_;	
	return '';
}

################################################################################

sub draw_centered_toolbar {
	my ($_SKIN, $options, $list) = @_;
	return '';
}

################################################################################
# MENUS
################################################################################

################################################################################

sub draw_menu {
	my ($_SKIN, $_options) = @_;	
	return '';	
}

################################################################################

sub draw_vert_menu {
	my ($_SKIN, $name, $types) = @_;	
	return '';
}


################################################################################
# TABLES
################################################################################

################################################################################

sub js_set_select_option {
	my ($_SKIN, $name, $item, $fallback_href) = @_;	
	return '';
}

################################################################################

sub draw_text_cell {

	my ($_SKIN, $data, $options) = @_;
	
	delete $data -> {attributes} -> {class};
	
	$data -> {attributes} -> {style} = 'padding:5px;';
	
	if ($data -> {picture}) {
		$data -> {attributes} -> {style} .= "mso-number-format:$data->{picture};";
	}
	else {
		$data -> {attributes} -> {style} .= "mso-number-format:\\\@;";
	}
	
	my $attributes = dump_attributes ($data -> {attributes});

	my $txt = '';
	
	unless ($data -> {off}) {

		$txt = $data -> {label};
		$txt =~ s{^\s+}{};
		$txt =~ s{\s+$}{};

		unless ($data -> {no_nobr}) {
			$txt = '<nobr>' . $txt . '</nobr>';
		}

		if ($data -> {bold} || $options -> {bold} || $options -> {is_total}) {
			$txt = '<b>' . $txt . '</b>';
		}

		if ($data -> {italic} || $options -> {italic}) {
			$txt = '<i>' . $txt . '</i>';
		}

		if ($data -> {strike} || $options -> {strike}) {
			$txt = '<strike>' . $txt . '</strike>';
		}
		
	}
			
	$r -> print (qq {\n\t<td $attributes>$txt</td>});
	return '';

}

################################################################################

sub draw_radio_cell {
	my ($_SKIN, $data, $options) = @_;
	$r -> print ('<td>&nbsp;</td>');
	return '';
}

################################################################################

sub draw_checkbox_cell {
	my ($_SKIN, $data, $options) = @_;
	$r -> print ('<td>&nbsp;</td>');
	return '';
}

################################################################################

sub draw_select_cell {
	my ($_SKIN, $data, $options) = @_;
	$r -> print ('<td>&nbsp;</td>');
	return '';
}

################################################################################

sub draw_input_cell {
	my ($_SKIN, $data, $options) = @_;
	return draw_text_cell (@_);
}

################################################################################

sub draw_row_button {
	my ($_SKIN, $options) = @_;
	return '' if $conf -> {core_hide_row_buttons} == 2;	
	$r -> print ('<td nowrap width="1%">&nbsp;</td>');
	return '';
}

####################################################################

sub draw_table_header {

	my ($_SKIN, $data_rows, $html_rows) = @_;
	
	my $html = '<thead>';
	foreach (@$html_rows) {$html .= $_};
	$html .= '</thead>';

	return $html;
	
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
	my $attributes = dump_attributes ($cell -> {attributes});
	
	return "<th $attributes>\&nbsp;$$cell{label}\&nbsp;</th>";

}

####################################################################

sub start_table {

	my ($_SKIN, $options) = @_;

	$r -> print ($options -> {title});
	$r -> print (qq {<table border=1>\n});
	$r -> print ($options -> {header}) if $options -> {header};
	$r -> print (qq {<tbody>\n});
	
	return '';

}

####################################################################

sub start_table_row {
	my ($_SKIN) = @_;
	$r -> print ('<tr>');
	return '';
}

####################################################################

sub draw_table_row {
	my ($_SKIN, $row) = @_;
	$r -> print ('</tr>');
	return '';
}

####################################################################

sub draw_table {

	my ($_SKIN, $tr_callback, $list, $options) = @_;
	
	$r -> print ('</tbody></table>');

	return '';

}

################################################################################

sub draw_one_cell_table {

	my ($_SKIN, $options, $body) = @_;	
	return '';			

}

################################################################################

sub draw_error_page {
	my ($_SKIN, $page) = @_;
	return $message;
}

################################################################################

sub start_page {

	$r -> content_type ('application/octet-stream');
	$r -> header_out ('Content-Disposition' => "attachment;filename=$$conf{page_title}.xls"); 	
	$r -> send_http_header ();

	$_REQUEST {__response_sent} = 1;

	$_REQUEST {_xml} = "<xml>$_REQUEST{_xml}</xml>" if $_REQUEST{_xml};

	$r -> print (<<EOH);
		<html xmlns:x="urn:schemas-microsoft-com:office/excel" xmlns:o="urn:schemas-microsoft-com:office:office">
			<head>
				<title>$$i18n{_page_title}</title>
				<meta http-equiv=Content-Type content="text/html; charset=$$i18n{_charset}">
				$_REQUEST{_xml}
				</head>
				<body bgcolor=white leftMargin=0 topMargin=0 marginwidth="0" marginheight="0">
EOH

}

################################################################################

sub draw_page {

	my ($_SKIN, $page) = @_;
	$r -> print ('</body></html>');

}

1;