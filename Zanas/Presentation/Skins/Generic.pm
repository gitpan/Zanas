################################################################################

sub js_escape {
	my ($s) = @_;	
	$s =~ s/\"/\'/gsm; #"
	$s =~ s{[\n\r]+}{ }gsm;
	$s =~ s{\\}{\\\\}g; #'
	$s =~ s{\'}{\\\'}g; #'
	return "'$s'";	
}

################################################################################

sub dump_attributes {
		
	my $html = '';
	
	foreach my $k (keys %{$_[0]}) { 
		$v = $_[0] -> {$k};
		next if $v eq '';
		$html .= ' ';
		$html .= $k;
		$html .= "='";
#		$v =~ s{\'}{\\\'}g; #'
		$v =~ s{\'}{&#39;}g; #'
		$html .= $v;
		$html .= "'";
	}
	
	return $html;
	
}

1;