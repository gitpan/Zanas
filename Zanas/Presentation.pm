no warnings;

use Data::Dumper;
use URI::Escape;
use MIME::Base64;

use Zanas::Presentation::MSIE_5;
#use Zanas::Presentation::Mozilla_3;
#use Zanas::Presentation::Unsupported;

################################################################################

sub dump_attributes {
	my $attributes = $_[0];	
	return join ' ', map {"$_='" . $attributes -> {$_} . "'"} keys %$attributes;	
}

################################################################################

sub trunc_string {
	my ($s, $len) = @_;
	return $s if $_REQUEST {xls};
	return length $s <= $len - 3 ? $s : substr ($s, 0, $len - 3) . '...';
}

################################################################################

sub create_url {

	my %over = @_;	
	$over {salt} = defined ($over {salt}) ? $over {salt} : rand ();
	my %param = %_REQUEST;
	$over {password} = '';
	while (my ($key, $value) = each %over) {
		$param {$key} = $value;
	}
	
	return $_REQUEST {__uri} . '?' . join ('&', map {($_ !~ /^_/ || $_ eq '__no_navigation' || $_ eq '__last_query_string') && $param {$_} ? ($_ . '=' . uri_escape ($param {$_})) : ()} keys %param);
	
}

################################################################################

sub hrefs {
	my ($order) = @_;
	
	return $order ? (
		href      => create_url (order => $order, desc => 0),
		href_asc  => create_url (order => $order, desc => 0),
		href_desc => create_url (order => $order, desc => 1),
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
	$options -> {title} = qq{title="$$options{title}"} if length $options -> {title};

}

################################################################################

sub check_href {

	my ($options) = @_;	
	
	if (ref $options -> {href} eq HASH) {
		$options -> {href} = create_url (%{$options -> {href}});
	}
	
	if ($options -> {href} !~ /^(\#|java|\/i\/)/ and $options -> {href} !~ /[\&\?]sid=/) {
		$options -> {href} .= "\&sid=$_REQUEST{sid}";
		$options -> {href} .= '&_salt=' . rand;
	}	
	
	if ($_REQUEST{period} and $options -> {href} !~ /^(\#|java)/ and $options -> {href} !~ /\&period=/) {
		$options -> {href} .= "\&period=$_REQUEST{period}";
	}
	
	if ($_REQUEST {__uri} ne '/' && $options -> {href} =~ m{^\/\?}) {
		$options -> {href} =~ s{^\/\?}{$_REQUEST{__uri}\?};
	}

	if ($_FLAG_ADD_LAST_QUERY_STRING && $conf -> {core_auto_esc} && $options -> {href} !~ /^(\#|java|\/i\/)/) {
	
		my $query_string = $ENV {QUERY_STRING};
		$query_string =~ s{\&?__scrollable_table_row=\d*}{}g;
		$query_string .= "&__scrollable_table_row=$scrollable_row_id";
		
		my $esc_query_string = MIME::Base64::encode ($query_string);
		$esc_query_string =~ y{+/=}{-_.};
	
		$options -> {href} .= "&__last_query_string=$esc_query_string";
		
	}		


}

################################################################################

sub draw__info {

	my ($data) = @_;
	
	draw_table (
	
		sub {
			draw_text_cells ({}, [
				$i -> {id},
				{label => $i -> {label}, max_len => 10000000},
			])
		},
		
		$data,
		
		{		
			
			title => {label => 'Информация о версиях'},
			
			lpt => 1,
			
		},
	
	);
	
}

1;
