use Data::Dumper;
use URI::Escape;

use Zanas::Presentation::MSIE_5;
#use Zanas::Presentation::Mozilla_3;
use Zanas::Presentation::Unsupported;

=head1 NAME

Presentation.pm - подпрограммы отрисовки элементов ГИП.

=cut

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

=head1 create_url

Процедура генерации C<url> с сохранением сессии и всех C<CGI>-параметров, кроме явно переопределяемых и тех, имена которых начинаются с C<'_'>.

=head2 Использование


	# Текущий url: /?sid=666&type=foo&_x=1&id=1

	my $url = create_url (id => 2, n => 5);

	# Теперь $url eq '/?sid=666&type=foo&id=2&n=5'


=cut

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
	
	$result .= ' DESC' if $_REQUEST {desc};
	
	return $result;

}

################################################################################

=head1 check_href

Процедура коррекции компонента C<href> заданного хэша, переданного по ссылке, на предмет расстановки параметров C<sid> и C<_salt>. Для C<javascript>-ссылок оставляет аргумент без изменения.

=head2 Использование


	# Текущий $options: {href => '/?type=foo&_x=1&id=1'}, sid = 666

	check_href ($options);

	# Теперь $options: {href => '/?type=foo&_x=1&id=1&sid=666&_salt=0.357357387387'}


=cut

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
