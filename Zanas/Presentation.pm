use Data::Dumper;
use URI::Escape;

use Zanas::Presentation::MSIE_5;
use Zanas::Presentation::Mozilla_3;
use Zanas::Presentation::Unsupported;

=head1 NAME

Presentation.pm - ������������ ��������� ��������� ���.

=cut

################################################################################

sub trunc_string {
	my ($s, $len) = @_;
	return length $s <= $len - 3 ? $s : substr ($s, 0, $len - 3) . '...';
}

################################################################################

=head1 install_drawer

�������� ������������ ��������. ���������� �������� ��� ������ ������������ ���������� Apache.

=head2 �������������

	Zanas::install_drawer ('MSIE_5');

=cut

################################################################################

sub install_drawer {
	my ($drawer_name) = @_;
	$drawers or our $drawers = {};
	unless (exists $drawers -> {$drawer_name}) {
		eval "require Zanas::Presentation::$drawer_name";
		eval "\$drawers -> {\$drawer_name} = Zanas::Presentation::$drawer_name -> new ();";
	}
}


################################################################################

=head1 drawer_call

���������-"������", ���������� ������ ������� ��������. �� ������ �������������� ��������.

=head2 �������������

	return drawer_call ('draw_text_cell', @_);

=cut

################################################################################

sub drawer_call {
	my $sub_name = shift;
	&{"$$_USER{drawer_name}_$sub_name"} (@_);	
}

################################################################################

=head1 js_escape

�������������� ������ �������� � ���������� � ����� ������ javaScript �������.

=head2 �������������

	return js_escape ('������ ��-������');

=cut

################################################################################

sub js_escape {
	return drawer_call ('js_escape', @_);
}

################################################################################

=head1 create_url

��������� ��������� C<url> � ����������� ������ � ���� C<CGI>-����������, ����� ���� ���������������� � ���, ����� ������� ���������� � C<'_'>.

=head2 �������������


	# ������� url: /?sid=666&type=foo&_x=1&id=1

	my $url = create_url (id => 2, n => 5);

	# ������ $url eq '/?sid=666&type=foo&id=2&n=5'


=cut

################################################################################

sub create_url {

	my %over = @_;	
	my %param = %_REQUEST;
	while (my ($key, $value) = each %over) {
		$param {$key} = $value;
	}
	
	return '/?' . join ('&', map {$_ !~ /^_/ && $param {$_} ? ($_ . '=' . uri_escape ($param {$_})) : ()} keys %param);
	
}

################################################################################

=head1 check_href

��������� ��������� ���������� C<href> ��������� ����, ����������� �� ������, �� ������� ����������� ���������� C<sid> � C<_salt>. ��� C<javascript>-������ ��������� �������� ��� ���������.

=head2 �������������


	# ������� $options: {href => '/?type=foo&_x=1&id=1'}, sid = 666

	check_href ($options);

	# ������ $options: {href => '/?type=foo&_x=1&id=1&sid=666&_salt=0.357357387387'}


=cut

################################################################################

sub check_href {

	my ($options) = @_;
	
	if ($options -> {href} !~ /^(\#|java)/ and $options -> {href} !~ /\&sid=/) {	
		$options -> {href} .= "\&sid=$_REQUEST{sid}";
		$options -> {href} .= '&_salt=' . rand;
	}	
	
	if ($_REQUEST{period} and $options -> {href} !~ /^(\#|java)/ and $options -> {href} !~ /\&period=/) {
		$options -> {href} .= "\&period=$_REQUEST{period}";
	}	

}

################################################################################

=head1 draw_page

��������� ��������� �������� � �����. ������������ �������� ������������, �� ������ ���������� ��������.

=cut

################################################################################

sub draw_page {

	drawer_call ('draw_page', @_);
	
}

################################################################################

=head1 draw_menu

��������� ��������� ��������� ���� �������. ������������ �������� ������������, �� ������ ���������� ��������.

=cut

################################################################################

sub draw_menu {
	drawer_call ('draw_menu', @_);	
}

################################################################################

=head1 draw_hr

��������� ������������� ����������� �������� ������.

=head2 ���������

=over

=item height

������ � ��������	

=item class

CSS-����� ����, �� ��������� - ��� �������� (bgr8)	

=back

=head2 �������������

	draw_hr ({ height => 10 });

=cut

################################################################################

sub draw_hr {
	drawer_call ('draw_hr', @_);	
}

################################################################################

=head1 draw_text_cell

��������� ������ ������� (����������������, ������� �������) � �������� ��������� ����������. ���� ����� C<href> ��� ������ ������, �� �� ������������� �������������.

=head2 ���������

=over

=item label

�����, ������������ � ������

=item max_len

����������� ����� ������. �� ��������� $conf -> {max_len}. �� ��������� 30.

=item href

(���� �� C<undef>) ����������� � ������	

=item target

������� ����/����� ��� ������

=item attributes

�������������� HTML-�������� ��� ���� C<td>.

=item a_class

CSS-����� ������. �� ��������� ����� C<lnk4>. 

=back

=head2 �������������

	draw_text_cell ({ 
		label   => '$1 000 000',
		href    => '/?type=bank&action=pillage',
		target  => 'invisible',
		max_len => 255,
		attributes => {
			width => '1%',
			align => 'right',
		},
		a_class => 'red_hot_link'
	});

=cut

################################################################################

sub draw_text_cell {
	drawer_call ('draw_text_cell', @_);	
}

################################################################################

=head1 draw_tr

��������� ������ ������� �� �������� ������.

=head2 ���������

������ (����) �� �������� �����, ����� ������ HTML-����� ������.

=head2 �������������

	draw_tr ({}, $td1, $td2);

=cut

################################################################################

sub draw_tr {
	drawer_call ('draw_tr', @_);	
}

################################################################################

=head1 draw_one_cell_table

�������: ������� 100% ������ �� ���������� ������. ������������� ��� ������������� ���� ��������������, ������� �� ������������ � ����� C<draw_form>: ��������, ����, ������������ ��� Excel.

=head2 ���������

������ (����) �� �������� �����, ����� ���������� HTML.

=head2 �������������

	draw_one_cell_table ({}, $the_very_table);

=cut

################################################################################

sub draw_one_cell_table {
	drawer_call ('draw_one_cell_table', @_);
}

################################################################################

=head1 draw_table

��������� ������� ��� ������� �������.

=head2 ���������

���� ������ �������� -- C<ARRAYREF>, �� �� �������� ������ ����������.

��������� �������� -- C<callback>-�������, ���������� ��� ������ ������. ������ ����� �� C<callback>'� ��� ���������� C<$i>.

��������� �������� -- ������ �� ������ ������� (recordset).

���������, �������������� �������� -- �����.

=head2 �����

=over

=item off

���� ������, �� ����� ���������� ������ ������.

=head2 �������������

	draw_table (
	
		['�����', {label => '���', off => 0}, ''],
		
		sub {		
			draw_text_cell ({label => $i -> {id}}) . 
			draw_text_cell ({label => $i -> {name}, off => 0}) . 
			draw_row_buttons ({}, [{
				icon => 'delete', 
				label => '�������', 
				href => "/?type=mytype&action=delete&id=$$i{id}", 
				confirm => "������� $$i{name}?"
			}])				
		},
		
		$data,
		
		{off => @$data == 0}
		
	);

=cut

################################################################################

sub draw_table {
	drawer_call ('draw_table', @_);
}

################################################################################

=head1 draw_path

��������� ���� � �������� �������.

=head2 ���������

������ �������� -- �����:

=over

=item id_param

��� ���������, ������� ��������� C<id> �� ���������.

=back

��������� �������� -- ������ �� ������ ������� ������. ������ ����������� � content-���������.

��� ������� ����� ������������ ��������� C<name>, �� ��������� ����������� url. ���� ����� ��������� C<id_param>, �� �������� C<id> ��������� �� ��� C<'id'>, � ��� C<$id_param>. ��� ���������, ��������, ���� ������� C<id> �� ������� ����� ����������� ��� C<id_rubric>.

=head2 �������������

	draw_path ({}, [	
		{type => 'forms', name => '�����'},
		{type => 'forms', name => $form -> {label}, id => $form -> {id}},	
	])

=cut

################################################################################

sub draw_path {
	drawer_call ('draw_path', @_);
}

################################################################################

=head1 draw_window_title

��������� ��������� ����.

=head2 ���������

=over

=item label

��������� ����.

=item off

���� ������, �� ����� ���������� ������ ������.

=back

=head2 �������������

	draw_window_title ({
		label => '�� ����',
		off   => $no_title,
	})

=cut

################################################################################

sub draw_window_title {
	drawer_call ('draw_window_title', @_);
}

################################################################################

=head1 draw_toolbar

������� ������ � ��������.

=head2 ���������

������ �������� -- ����� (�� ������������, ���������������), ����� -- ������ HTML ������.

=head2 �������������

	draw_toolbar ({}, 
		
		draw_toolbar_button ({
			icon  => 'create',
			label => '��������',
			href  => '?type=mytype&action=create',
		}),
		
	)

=cut

################################################################################

sub draw_toolbar {
	drawer_call ('draw_toolbar', @_);
}

################################################################################

=head1 draw_toolbar_button

������, ������������ � ������. ����� ������ ������������� � C<href> �������������. ������� ������� ������ ������ �������� C<invisible>.

=head2 ���������

=over

=item icon

�������� ������

=item label

��������� �������

=item href

�����������

=back

=head2 �������������

	draw_toolbar_button ({
		icon  => 'create',
		label => '��������',
		href  => '?type=mytype&action=create',
	})

=cut

################################################################################

sub draw_toolbar_button {
	drawer_call ('draw_toolbar_button', @_);
}

################################################################################

=head1 draw_toolbar_input_text

����� ����� �������� ������, ������������ � ������. ������������ ��� ����������� ������ � ������� ��������.

=head2 ���������

=over

=item icon

�������� ������

=item label

��������� �������

=item q

��� ��������� CGI-���������

=back

=head2 �������������

	draw_toolbar_input_text ({
		icon   => 'tv',
		label  => '������',
		name   => 'q',
	}),

=cut

################################################################################

sub draw_toolbar_input_text {
	drawer_call ('draw_toolbar_input_text', @_);
}

################################################################################

=head1 draw_toolbar_pager

��������� �� ��������� ������� ������� (�����-�����, ������ ... �� ...). ��� �������������� ��������� ������� �� url. ����� ������� �������� ����������� CGI-���������� start.

=head2 ���������

=over

=item cnt

���������� ����� �� ������� ��������

=item total

����� ����� ����� � �������

=back

=head2 �������������

	draw_toolbar_pager ({
		cnt    => 0 + @{$data -> {forms}},
		total  => $data -> {cnt},
	})

=cut

################################################################################

sub draw_toolbar_pager {
	drawer_call ('draw_toolbar_pager', @_);
}

################################################################################

=head1 draw_row_button

��� ������� �� ���� �������� ��������. ����������� draw_row_buttons.

=cut

################################################################################

sub draw_row_button {
	drawer_call ('draw_row_button', @_);
}

################################################################################

=head1 draw_row_buttons

��� ������, ������������ � ������ �������. 

=head2 ���������

������� �����, ����� -- �������� ������. ������ �������� �������� ����:

=over

=item icon

��� ������

=item label

������������ ��������� ������

=back

=head2 �������������

	draw_row_buttons ({},	[
			{
				icon => 'delete', 
				label => '�������', 
				href => "/?type=forms\&action=delete_multiple\&n=$$i{n}\&id_form=$$data{id}\&period=" . $_CALENDAR -> period (), 
				confirm => "������� ������ $$i{n}?",
			},
		]
	))

=cut

################################################################################

sub draw_row_buttons {
	drawer_call ('draw_row_buttons', @_);
}


################################################################################

=head1 draw_form

����� ��� �������������� ��������� ����� �������. ���� ���������� ����� C<bottom_toolbar>, �� � �������� (HTML, ������� ���������� ������������ ���������� C<draw_centered_toolbar>) ����������� ����� �������� �������. � ��������� ������ ������ ������ ������������ ������������� � �������� ������ "OK" � "������", ������ ������ � ��������� ������ �� ����� C<esc>.

=head2 ���������

�����, ������, �������� �����.

�����:

=over

=item action

�������� CGI-��������� action. �� ��������� 'update'.

=item type

�������� CGI-��������� type. �� ��������� ����������� �� ��, ��� ��� ������� ��������.

=item id

�������� CGI-��������� id. �� ��������� ����������� �� ��, ��� ��� ������� ��������.

=item esc

������, �� ������� ���� ������ '������', ���� �� ������ ����� C<bottom_toolbar>.

=back

=head2 �������������

	draw_form ({esc => "/?type=forms&search=1"}, 
		{
			name   => 'form1',
			period => 1,
		}		
		[
			{
				name  => 'name',
				label => '������������� ���',
				mandatory => 1,
			},
			{
				name   => 'period',
				label  => '�������������',
				type   => 'radio',
				values => [
					{id => 1, label => '��������'},
					{id => 3, label => '�����������'},
				],
			},
		]
	);

=cut

################################################################################

sub draw_form {
	drawer_call ('draw_form', @_);
}

################################################################################

=head1 draw_form_field_string

��������� ���� ����� ���� 'string'. ���������� ������������� ��-��� C<draw_form>.

=head2 �����

=over

=item name

��� CGI-��������� � ������������ ����� � ������� C<$data>.

=item label

������������ ���

=item size

�������� ��������� C<size> � C<maxlength>

=back

=cut

################################################################################

sub draw_form_field_string {
	drawer_call ('draw_form_field_string', @_);
}

################################################################################

=head1 draw_form_field_hgroup

��������� ���� ����� ���� 'text': ������ �����, ������������� � ���� ������ �� �����������. ���������� ������������� ��-��� C<draw_form>.

=head2 �����

=over

=item label

������������ ���.

=item items

�������� ����� �����.

=back

=cut

################################################################################

sub draw_form_field_hgroup {
	drawer_call ('draw_form_field_hgroup', @_);
}

################################################################################

=head1 draw_form_field_text

��������� ���� ����� ���� 'text': C<textarea>. ���������� ������������� ��-��� C<draw_form>.

=head2 �����

=over

=item name

��� CGI-��������� � ������������ ����� � ������� C<$data>.

=item label

������������ ���

=back

=cut

################################################################################

sub draw_form_field_text {
	drawer_call ('draw_form_field_text', @_);
}

################################################################################

=head1 draw_form_field_hidden

��������� ���� ����� ���� 'text': C<textarea>. ���������� ������������� ��-��� C<draw_form>.

=head2 �����

=over

=item name

��� CGI-��������� � ������������ ����� � ������� C<$data>.

=item value

�������� �� ��� ������, ���� �� C<!$data{$$options{name}}>.

=back

=cut

################################################################################

sub draw_form_field_hidden {
	drawer_call ('draw_form_field_hidden', @_);
}

################################################################################

=head1 draw_form_field_checkbox

��������� ���� ����� ���� C<checkbox> �� ��������� 1. ���������� ������������� ��-��� C<draw_form>.

=head2 �����

=over

=item name

��� CGI-��������� � ������������ ����� � ������� C<$data>.

=item label

������������ ���

=back

=cut

################################################################################

sub draw_form_field_checkbox {
	drawer_call ('draw_form_field_checkbox', @_);
}

################################################################################

=head1 draw_form_field_checkboxes

��������� ������ ����� ����� ���� C<checkbox>. ���������� ������������� ��-��� C<draw_form>.

=head2 �����

=over

=item name

��� CGI-��������� � ������������ ����� � ������� C<$data>.

=item label

������������ ���

=item values

������ �� ������ ����:

	[
		{id => '�������� 1', label => '������ 1'},
		{id => '�������� 2', label => '������ 2'},
		
		. . .
		
		{id => '�������� n', label => '������ n'},
	]

=back

=cut

################################################################################

sub draw_form_field_checkboxes {
	drawer_call ('draw_form_field_checkboxes', @_);
}

################################################################################

=head1 draw_form_field_password

��������� ���� ����� ���� 'password'. ���������� ������������� ��-��� C<draw_form>.

=head2 �����

=over

=item name

��� CGI-��������� � ������������ ����� � ������� C<$data>.

=item label

������������ ���

=back

=cut

################################################################################

sub draw_form_field_password {
	drawer_call ('draw_form_field_password', @_);
}

################################################################################

=head1 draw_form_field_static

��������� ���� ����� ���� 'static': ����������, ��� �� ���� �����, � ����� �������� ����. ����� � ��� ������, ���� ����� ����� read only. ���������� ������������� ��-��� C<draw_form>.

=head2 �����

=over

=item name

��� CGI-��������� � ������������ ����� � ������� C<$data>.

=item label

������������ ���

=back

=cut

################################################################################

sub draw_form_field_static {
	drawer_call ('draw_form_field_static', @_);
}

################################################################################

=head1 draw_form_field_radio

��������� ������ �����������. ���������� ������������� ��-��� C<draw_form>.

=head2 �����

=over

=item name

��� CGI-��������� � ������������ ����� � ������� C<$data>.

=item label

������������ ���

=item values

������ �� ������ ����:

	[
		{id => '�������� 1', label => '������ 1'},
		{id => '�������� 2', label => '������ 2'},
		
		. . .
		
		{id => '�������� n', label => '������ n'},
	]

=back

=cut

################################################################################

sub draw_form_field_radio {
	drawer_call ('draw_form_field_radio', @_);
}

################################################################################

=head1 draw_form_field_select

��������� dropdown-������ ������. ���������� ������������� ��-��� C<draw_form>.

=head2 �����

=over

=item name

��� CGI-��������� � ������������ ����� � ������� C<$data>.

=item label

������������ ���

=item values

������ �� ������ ����:

	[
		{id => '�������� 1', label => '������ 1'},
		{id => '�������� 2', label => '������ 2'},
		
		. . .
		
		{id => '�������� n', label => '������ n'},
	]

=item empty

���� ������, �� � ������ ������ ����������� ������ ������ � ������ �������� � C<id=0>.

=back

=cut

################################################################################

sub draw_form_field_select {
	drawer_call ('draw_form_field_select', @_);
}

################################################################################

=head1 draw_esc_toolbar

������ ������ � ������� "������". �������� ������������� ��� ������ 
C<draw_form> ��� ������� ����� C<esc> � C<no_ok>.

=cut

################################################################################

sub draw_esc_toolbar {
	drawer_call ('draw_esc_toolbar', @_);
}

################################################################################

=head1 draw_ok_esc_toolbar

������ ������ � �������� "��" � "������". �������� ������������� ��� ������ 
C<draw_form> ��� ������� ����� C<esc>.

=cut

################################################################################

sub draw_ok_esc_toolbar {
	drawer_call ('draw_ok_esc_toolbar', @_);
}

################################################################################

=head1 draw_back_next_toolbar

������ ������ � �������� "�����" � "�����". �������� ������������� ��� ������ 
C<draw_form> ��� ������� ����� C<back>.

=cut

################################################################################

sub draw_back_next_toolbar {
	drawer_call ('draw_back_next_toolbar', @_);
}


################################################################################

=head1 draw_centered_toolbar_button

��������� ������ ��� ������ ��� ������ (���� OK/Cancel ��� Back/Next).

�����:

=over

=item href

������ � ������. ���� �� ������ �������� C<sid> � ������ �� C<javaScript>, �� ����� ����� ������������� �������������.

=item onclick

���������� ������� C<onclick>.

=item target

������� ���� (�����) ������. � ������� �� C<draw_toolbar_button>, �� ��������� �� C<invisible>, � �����.

=item label

������� �� ������.

=item icon

����������� �� ������ (���������������, �� ������������).

=back

=cut

################################################################################

sub draw_centered_toolbar_button {
	drawer_call ('draw_centered_toolbar_button', @_);
}

################################################################################

=head1 draw_centered_toolbar

������ ������ � ��������: ��������� � ��� �������, ����� ������ C<draw_form> 
������������ � ������.


=head2 ���������

�����, ������, �������� �����.

�����:

=over

=item action

�������� CGI-��������� action. �� ��������� 'update'.

=item esc

������, �� ������� ���� ������ '������'.

=back

=head2 �������������

	draw_centered_toolbar ({}, [
		{
			icon => 'ok',     
			label => '���������', 
			href => '#', 
			onclick => 'document.form.submit()',
		},		
		{	
			icon => 'cancel', 
			label => '���������', 
			href => "/?type=forms",
		},		
		{
			icon => 'tv', 
			label => '������������', 
			href => "javaScript:..."},
		} 
	])

=cut

################################################################################

sub draw_centered_toolbar {
	drawer_call ('draw_centered_toolbar', @_);	
}

################################################################################

=head1 draw_auth_toolbar

��������� ������� ������ � ���������, ������ ������������ � ������� ������.
������������ ��� ����� ��������� ��������, �� ������ ���������� ��������.

=cut

################################################################################

sub draw_auth_toolbar {
	drawer_call ('draw_auth_toolbar', @_);	
}

################################################################################

=head1 draw_calendar

��������� ��������� �� ������� ������.
������������ ��� ����� ��������� ��������, �� ������ ���������� ��������.

=cut

################################################################################

sub draw_calendar {
	drawer_call ('draw_calendar', @_);
}

################################################################################

sub draw_form_field_image {
	drawer_call ('draw_form_field_image', @_);
}

################################################################################

=head1 draw_form_field_string

��������� WYSIWYG-��������� ��� HTML. ���������� ������������� ��-��� C<draw_form>. �������� ������ ��� MSIE 5+.

=head2 �����

=over

=item name

��� CGI-��������� � ������������ ����� � ������� C<$data>.

=item label

������������ ���

=back

=cut

################################################################################

sub draw_form_field_htmleditor {
	drawer_call ('draw_form_field_htmleditor', @_);
}

1;
