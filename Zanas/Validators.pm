################################################################################

sub vld_date {

	my ($name, $nullable) = @_;
	
	$name = "_" . $name;
	
	if (!$_REQUEST {$name} && $nullable) {
		delete $_REQUEST {$name};
		return undef;
	}
	
	my ($_sec, $_min, $_hour, $_mday, $_mon, $_year, $_wday, $_yday, $_isdst) = localtime (time);
	
	my ($day, $month, $year) = split /\D+/, $_REQUEST {$name};
	
	local $SIG {__DIE__} = 'DEFAULT';

	if (!$year) {
		$year = $_year + 1900;
	}
	elsif ($year < 100) {
		my $now_year = $_year + 1900;
		$now_year =~ /(\d\d)(\d\d)/;
		my $now_year_100 = $now_year % 100;
		my $century = $now_year - $now_year_100;
		$century -= 100 if ($year > $now_year + 10);
		$year += $century;
	}	
	elsif ($year < 1000) {
		die "#${name}#:����������� ����� ���\n";
	}
	

	$month > 0  or die "#${name}#:����������� ����� �����\n";
	$month < 13 or die "#${name}#:����������� ����� �����\n";
	
	$day   > 0  or die "#${name}#:����������� ����� ����\n";
	$day   < 32 or die "#${name}#:����������� ����� ����\n";

	$_REQUEST {$name} = sprintf ('%04d-%02d-%02d', $year, $month, $day);
		
	return ($year, $month, $day);

}

################################################################################

sub vld_unique {

	my ($table, $options) = @_;
	
	$options -> {field} ||= 'label';
	$options -> {value} ||= $_REQUEST {'_' . $options -> {field}};
	$options -> {id}    ||= $_REQUEST {id};
	
	my $id = sql_select_scalar ("SELECT id FROM $table WHERE $$options{field} = ? AND fake = 0 AND id <> ? LIMIT 1", $options -> {value}, $options -> {id});

	return $id ? 0 : 1;

}

################################################################################

sub vld_noref {

	my ($table, $options) = @_;
	
	$options -> {data_field} ||= 'label';
	
	unless ($options -> {field}) {
		$options -> {field} = 'id_' . $_REQUEST {type};
		$options -> {field} =~ s{s$}{};
	}
	
	$options -> {id} ||= $_REQUEST {id};
	
	$options -> {message} ||= '�� ������ ������ ��������� "$label". �������� ����������.';
	
	my $label = sql_select_scalar ("SELECT $$options{data_field} FROM $table WHERE $$options{field} = ? AND fake = 0 LIMIT 1", $options -> {id});
	
	return undef unless $label;
	
	my $message = $options -> {message};
	$message    =~ s{\$label}{$label};
	$message    .= "\n";
	
	local $SIG {__DIE__} = 'DEFAULT';
	
	die $message;

}

################################################################################

sub vld_inn_10 {

	my ($name, $nullable) = @_;
	
	$name = "_" . $name;
	
	if (!$_REQUEST {$name} && $nullable) {
		delete $_REQUEST {$name};
		return undef;
	}
	
	$_REQUEST {$name} =~ /^\d{10}$/ or return "#$name#:��� ��� ������ �������� �� 10 �������� ����";
	
	my @n = split //, $_REQUEST {$name};
		
	my $checksum =
		$n [0] * 2  +
		$n [1] * 4  +
		$n [2] * 10 +
		$n [3] * 3  +
		$n [4] * 5  +
		$n [5] * 9  +
		$n [6] * 4  +
		$n [7] * 6  +
		$n [8] * 8;
			
	$checksum = $checksum % 11;		
	$checksum = $checksum % 10 if $checksum > 9;
		
	$checksum == 0 + substr ($_REQUEST {$name}, -1, 1) or return "#$name#:�� �������� ����������� ����� ���";

	return undef;

}

################################################################################

sub vld_okpo {

	my ($name, $nullable) = @_;
	
	$name = "_" . $name;
	
	if (!$_REQUEST {$name} && $nullable) {
		delete $_REQUEST {$name};
		return undef;
	}
	
	$_REQUEST {$name} =~ /^\d{8}$/ or return "#$name#:��� ���� ������ �������� �� 8 �������� ����";
	
	my @n = split //, $_REQUEST {$name};
		
	my $checksum_1 =
		$n [0] * 1 +
		$n [1] * 2 +
		$n [2] * 3 +
		$n [3] * 4 +
		$n [4] * 5 +
		$n [5] * 6 +
		$n [6] * 7;
		
	$checksum_1 = $checksum_1 % 11;		

	my $checksum_2 =
		$n [0] * 3 +
		$n [1] * 4 +
		$n [2] * 5 +
		$n [3] * 6 +
		$n [4] * 7 +
		$n [5] * 8 +
		$n [6] * 9;
		
	$checksum_2 = $checksum_2 % 11;		
	$checksum_2 = 0 if $checksum_2 == 10;
	
	if ($checksum_1 > 9) {
		$checksum_2 == 0 + substr ($_REQUEST {$name}, -1, 1) or return "#$name#:�� �������� ����������� ����� ����";
	}
	else {
		$checksum_1 == 0 + substr ($_REQUEST {$name}, -1, 1) or return "#$name#:�� �������� ����������� ����� ����";
	}

	return undef;

}

################################################################################

sub vld_ogrn {

	my ($name, $nullable) = @_;
	
	$name = "_" . $name;
	
	if (!$_REQUEST {$name} && $nullable) {
		delete $_REQUEST {$name};
		return undef;
	}
	
	$_REQUEST {$name} =~ /^\d{13}$/ or return "#$name#:��� ���� ������ �������� �� 13 �������� ����";
	$_REQUEST {$name} =~ /^[12]/ or return "#$name#:1-� ����� ���� ����� ���� ������ 1 (�������� �����) ��� 2 (���� �����)";
	(0 + substr ($_REQUEST {_ogrn}, -1, 1) == (substr ($_REQUEST {$name}, 0, 12)) % 11) or return "#$name#:�� �������� ����������� ����� ����";

	return undef;

}

1;