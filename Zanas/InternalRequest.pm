package Zanas::InternalRequest;
require Zanas::Request::Upload;
use HTTP::Response;
use HTTP::Headers;

use File::Temp qw/:POSIX/;

################################################################################

sub new {

	my $proto = shift;
	
	my $class = ref ($proto) || $proto;

	my $self  = {};
	
	$self -> {connection} = shift;
	$self -> {request} = shift;
	
	CGI::initialize_globals ();

	if ($self -> {request} -> method eq 'POST') {

		my $fn = tmpnam ();
		open (T, ">$fn");
		binmode T;

		my $content = $self -> {request} -> content;
		print T $content;
		close (T);

		open (STDIN, "$fn");
		$self -> {Q} = new CGI ();
		close (STDIN);
		unlink $fn;
		
	}
	else {
		$self -> {Q} = new CGI ($ENV {'QUERY_STRING'});
	}

		
	$self -> {Filename} = '';
	
	$self -> {Document_root} = $ENV{DOCUMENT_ROOT};	
	
	$self -> {status} = 200;
	
	$self -> {headers} = new HTTP::Headers (
		Content_Type => 'text/html',
       	);

	bless ($self, $class);
	
	return $self;
	
}

################################################################################

sub internal_redirect {
	my $self = shift;	
	my $url = $_[0];
	$url =~ s{^/}{};
	$self -> {connection} -> send_redirect ('http://' . $ENV{HTTP_HOST} . '/' . $url);
#	$self -> status ($options -> {status} || 302);
#	$self -> header_out ('Location' => 'http://' . $ENV{HTTP_HOST} . $url);
#	$self -> send_http_header;
#	$_REQUEST {__response_sent} = 1;
}

################################################################################

sub args {
	return $ENV {QUERY_STRING};
}

################################################################################

sub header_in {
	my $self = shift;
	return $self -> {Q} -> http ($_ [0]);
}

################################################################################

sub content_type {
	my $self = shift;
	return $self -> {headers} -> content_type (@_);
}

################################################################################

sub content_encoding {
	my $self = shift;
	return $self -> {headers} -> content_encoding (@_);
}

################################################################################

sub status {
	my $self = shift;
	$self -> {status} = $_[0] if $_[0];
	return $self -> {status};
}

################################################################################

sub header_out {
	my $self = shift;	
	return $self -> {headers} -> header (@_);
}

################################################################################

sub send_http_header {
	
	my $self = shift;
	
	my $h = $self -> {headers} -> as_string;
	
	$h =~ s{[\015\012]+}{\015\012}gsm;
	
	$self -> {connection} -> send_basic_header;
	
	print STDOUT "$h\015\012";	
	
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
	my $path = $ENV{temp};
	$path =~ y{\\}{/}; 
	return "$path/docroot";
}

################################################################################

sub parms {
	my $self = shift;
	my %vars = $self -> {Q} -> Vars;
	return \%vars;	
}

################################################################################

sub param {
	my $self = shift;
	return $self -> {Q} -> param ($_ [0]);
}

################################################################################

sub upload {

	my $self = shift;
	my $q = $self -> {Q};

	my $param = $_ [0];
	return $self -> {$param} if ($self -> {$param});

	$self -> {$param} = Zanas::Request::Upload -> new ($q, $param);

	return $self -> {$param};
	
}

################################################################################

sub uri {
	my $self = shift;
#	return $self -> {Q} -> url (-path_info => 1);
	return $ENV {'PATH_INFO'} . '/';
}

################################################################################

sub header_only {
	my $self = shift;
	return $self -> {Q} -> request_method () eq 'HEAD';
}


################################################################################

sub print {

	my ($self, $html) = @_;
	
	my $response = new HTTP::Response ($self -> {status}, '', $self -> {headers}, $html);
	
	$self -> {connection} -> send_response ($response);
	
}

################################################################################

#package Apache::Constants;

#sub OK () {
#	return 200;
#} 

1;