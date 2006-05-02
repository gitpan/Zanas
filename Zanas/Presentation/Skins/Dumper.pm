package Zanas::Presentation::Skins::Dumper;

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

################################################################################

sub options {
	return {
		no_presentation => 1,
	};
}

################################################################################

sub draw_page {

	my ($_SKIN, $page) = @_;

	$_REQUEST {__content_type} ||= 'text/plain; charset=' . $i18n -> {_charset};
						
	return Dumper ({
		request => \%_REQUEST,
		user    => $_USER,
		content => $page -> {content},								
	}) if $_REQUEST {__dump};	

	return Dumper ({
		data    => $page -> {content},								
	}) if $_REQUEST {__d};

}

################################################################################

sub draw_error_page {

	my ($_SKIN, $page) = @_;

	$_REQUEST {__content_type} ||= 'text/plain; charset=' . $i18n -> {_charset};

	return Dumper ({error => {
		message => $_REQUEST {error},
		field   => $page -> {error_field},
	}}) if $_REQUEST {__d};

}

1;