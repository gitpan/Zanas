package Zanas::Request;
require Zanas::Request::Upload;

use Data::Dumper;

################################################################################

sub new {

	my $proto = shift;
	my $class = ref($proto) || $proto;
	
	my ($preconf, $conf) = @_;

	my $self  = {
		preconf => $preconf,
		conf => $conf,
	};
	
	undef @CGI::QUERY_PARAM;
	$self -> {Q} = new CGI;
	
#	if ($ENV{PATH_TRANSLATED} =~ /$ENV{DOCUMENT_ROOT}\/+index\.html/) {
#		$self -> {Filename} = '';
#	} else {
#		$ENV{PATH_TRANSLATED} =~ /$ENV{DOCUMENT_ROOT}\/+(.*)/;
#		$self -> {Filename} = $1;
#	}

#	$self -> {Filename} = $self -> {Q} -> script_name;
#	$self -> {Filename} = '/' if $self -> {Filename} =~ /index\.pl/;

	$self -> {Filename} = $ENV{PATH_INFO};
	$self -> {Filename} = '/' if $self -> {Filename} =~ /index\./;
	
	$self -> {Document_root} = $ENV{DOCUMENT_ROOT};
	$self -> {Out_headers} = {-type => 'text/html', -status=> 200};

	bless ($self, $class);

	return $self;
}

################################################################################

sub internal_redirect {

	my $self = shift;
	my $q = $self -> {Q};

	my $url = $_[0];
	
	unless ($url =~ /^http:\/\//) {
		$url =~ s{^/}{};
		$url = "http://$ENV{HTTP_HOST}/$url";
	}
	
#	my $http_host = $ENV {HTTP_X_FORWARDED_HOST} || $self -> {preconf} -> {http_host};
#	if ($http_host) {
#		substr ($url, index ($url, $ENV{HTTP_HOST}), length ($ENV{HTTP_HOST})) = $http_host;
#	}

	print $q -> redirect (-uri => $url);
	
}

################################################################################

sub args {
	return $ENV {QUERY_STRING};
}

################################################################################

sub header_in {
	my $self = shift;
	my $q = $self -> {Q};
	return $q -> http ($_ [0]);
}

################################################################################

sub content_type {

	my $self = shift;
	my $q = $self -> {Q};

	if ($_ [0]) {
		$self -> {Out_headers} -> {-type} = $_ [0];
	} else {
		return $self -> {Out_headers} -> {-type};
	}
	
}

################################################################################

sub content_encoding {

	my $self = shift;
	my $q = $self -> {Q};

	if ($_ [0]) {
		$self -> {Out_headers} -> {-content_encoding} = $_ [0];
	} else {
		return $self -> {Out_headers} -> {-content_encoding};
	}
	
}

################################################################################

sub status {

	my $self = shift;
	my $q = $self -> {Q};
	if ($_ [0]) {
		$self -> {Out_headers} -> {-status} = $_ [0];
	} else {
		return $self -> {Out_headers} -> {-status};
	}
	
}

################################################################################

sub header_out {

	my $self = shift;
	my $q = $self -> {Q};

	$self -> {Out_headers} -> {"-$_[0]"} = $_[1];
	
}

################################################################################

sub send_http_header {

	my $self = shift;
	my $q = $self -> {Q};

	my @params = ();
	
	foreach $header (keys %{$self -> {Out_headers}}) {
		push (@params, $header, $self -> {Out_headers} -> {$header});
	}
	
	print $q -> header (@params);
}

################################################################################

sub send_fd {

	my $self = shift;
	my $q = $self -> {Q};

	my $fh = CGI::to_filehandle($_ [0]);
	binmode($fh);

	my $buf;

	while (read ($fh, $buff, 8 * 2**10)) {
		print STDOUT $buff;
	}
	
}

################################################################################

sub filename {

	my $self = shift;

	return $self -> {Filename};
	
}

################################################################################

sub connection {

	my $self = shift;

	return $self;
	
}

################################################################################

sub remote_ip {

	return $ENV {REMOTE_ADDR};
	
}

################################################################################

sub document_root {

	my $self = shift;

	return $self -> {Document_root};
	
}

################################################################################

sub parms {

	my $self = shift;
	my $q = $self -> {Q};
	my %vars = $q -> Vars;
	return \%vars;
	
}

################################################################################

sub param {

	my $self = shift;
	my $q = $self -> {Q};

	return $q -> param ($_ [0]);
	
}

################################################################################

sub upload {

	my $self = shift;
	my $q = $self -> {Q};

	my $param = $_ [0];
	return $self -> {$param} if ($self -> {$param});

	$self -> {$param} = Zanas::Request::Upload -> new($q, $param);

	return $self -> {$param};
	
}

################################################################################

sub uri {
	my $self = shift;
	return $self -> {Q} -> url (-path_info => 1);
}

################################################################################

sub header_only {
	my $self = shift;
	return $self -> {Q} -> request_method () eq 'HEAD';
}

################################################################################

#package Apache::Constants;

#sub OK () {
#	return 200;
#} 

1;