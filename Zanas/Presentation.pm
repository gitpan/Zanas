no warnings;

use Data::Dumper;
use URI::Escape;

use Zanas::Presentation::MSIE_5;
#use Zanas::Presentation::Mozilla_3;
use Zanas::Presentation::Unsupported;

################################################################################

sub dump_attributes {
	my $attributes = $_[0];	
	return join ' ', map {"$_='" . $attributes -> {$_} . "'"} keys %$attributes;	
}

################################################################################

sub trunc_string {
	my ($s, $len) = @_;
	return length $s <= $len - 3 ? $s : substr ($s, 0, $len - 3) . '...';
}

################################################################################

sub create_url {

	my %over = @_;	
	my %param = %_REQUEST;
	$over {password} = '';
	while (my ($key, $value) = each %over) {
		$param {$key} = $value;
	}
	
	return '/?' . join ('&', map {($_ !~ /^_/ || $_ eq '__no_navigation') && $param {$_} ? ($_ . '=' . uri_escape ($param {$_})) : ()} keys %param);
	
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

}

1;
