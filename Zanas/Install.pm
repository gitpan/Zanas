package Zanas::Install;

package main;

use Term::ReadLine;
use File::Find;
use DBI;

sub shell {

	my $path = $INC{'Zanas/Install.pm'};
	
	$path =~ s{Install\.pm}{static/sample.tar.gz.pm};
	
	my $term = new Term::ReadLine 'Zanas application installation';
	
	my ($appname, $appname_uc, $instpath, $db, $user, $password, $group);
	
	while (1) {
	
		while (1) {
			$appname = $term -> readline ('Application name (lowercase): ');
			last if $appname =~ /[a-z_]+/
		}

		$appname_uc = uc $appname;	

		while (1) {
			my $default_instpath = $^O eq 'MSWin32' ? "G:\\do_work\\$appname" : "/var/projects/$appname";
			$instpath = $term -> readline ("Installation path [$default_instpath]: ");
			$instpath = $default_instpath if $instpath eq '';
			last if $instpath =~ /[\w\/]+/
		}

		while ($^O ne 'MSWin32') {
			$group = $term -> readline ("Users group [nogroup]: ");
			$group = "nogroup" if $group eq '';
			last if $group =~ /\w+/
		}

		while (1) {
			$db = $term -> readline ("Database name [$appname]: ");
			$db = $appname if $db eq '';
			last if $db =~ /\w+/
		}

		while (1) {
			$user = $term -> readline ("Database user [$appname]: ");
			$user = $appname if $user eq '';
			last if $user =~ /\w+/
		}

#		while (1) {
#			$password = $term -> readline ("Database password: ");
#			my $password1 = $term -> readline ("Database password (once again): ");
#			last if $password1 eq $password
#		}	
		
		$password = random_password ();

		print <<EOT;
			Application name:	$appname
			User group:		$group
			Database name:		$db
			Database user:		$user
EOT
			
		my $ok = $term -> readline ("Everything in its right place? (yes/NO): ");
		
		last if $ok eq 'yes';
		
	}
	
	-d $instpath and die ("Can't proceed: installation path exists.\n");
		
	print "Creating database... ";
	
	my $dbh = DBI -> connect ('DBI:mysql:mysql', '', '');	
	$dbh -> {RaiseError} = 1;
	
	$dbh -> ping or die ("Can't connect to MySQL!");
	
	$dbh -> do ("CREATE DATABASE $db");
	$dbh -> do ("GRANT ALL ON $db.* to $user\@localhost identified by '$password'");
	
	$dbh -> disconnect;	
	
	print "ok\n";

	print "Creating application directory... ";	
	if ($^O eq 'MSWin32') {
		`md $instpath`;
	}
	else {
		`mkdir $instpath`;
	}	
	print "ok\n";

	print "Copying application files... ";
	if ($^O eq 'MSWin32') {
		chdir $instpath;
		eval 'require Archive::Tar;';
		my $tar = Archive::Tar -> new ();
		$tar -> read ($path, 1);
		$tar -> extract ($tar -> list_files ());
	}
	else {
		`tar xzvf $path --directory=$instpath/`;
	}	
	print "ok\n";

	print "Renaming application files... ";
	if ($^O eq 'MSWin32') {
		rename "$instpath\\lib\\SAMPLE", "$instpath\\lib\\$appname_uc";
		rename "$instpath\\lib\\SAMPLE.pm", "$instpath\\lib\\$appname_uc.pm";
	}
	else {
		`mv $instpath/lib/SAMPLE $instpath/lib/$appname_uc`;
		`mv $instpath/lib/SAMPLE.pm $instpath/lib/$appname_uc.pm`;
	}	
	print "ok\n";
	
	our %substitutions = (
		SAMPLE => $appname_uc,
	);
	
	if ($^O eq 'MSWin32') {
		find (\&fix, "$instpath\\lib");
	}
	else {
		find (\&fix, "$instpath/lib");
	}	

	our %substitutions = (
		sample => $appname,
		SAMPLE => $appname_uc,
		"'do'" => "'$user'",
		"'z'" => "'$password'",
	);
	
	if ($^O eq 'MSWin32') {
		find (\&fix, "$instpath\\conf");
	}
	else {
		find (\&fix, "$instpath/conf");
	}	
	
	if ($^O ne 'MSWin32') {
		`chgrp -R $group $instpath`;	
		`chmod -R a+w $instpath`;
	}

	print <<EOT;

--------------------------------------------------------------------------------
Congratulations! A brand new bare bones Zanas.pm-based WEB application is 
insatlled successfully. 

Now you just have to add it to your Apache configuration. This may look 
like
	
	Listen 8000
	
	<VirtualHost _default_:8000>
		Include "$instpath/conf/httpd.conf"
	</VirtualHost>
	
in /etc/apache/httpd.conf. Don\'t forget to restart Apache. 

Best wishes. 

d.o.
--------------------------------------------------------------------------------

EOT

}

sub fix {

	my $fn = $File::Find::name;
	
	return unless $fn =~ /\.(pm|conf)$/;
	
	print "Fixing $fn...";
	
	open (IN, $fn) or die ("Can't open $fn: $!\n");
	open (OUT, '>' . $fn . '~') or die ("Can't write to $fn\~: $!\n");
	
	while (my $s = <IN>) {
		
		while (my ($from, $to) = each %substitutions) {
				
			$s =~ s{$from}{$to}g;
			
		}
		
		print OUT $s;
		
	}

	close (OUT);
	close (IN);
	
	unlink $fn;
	rename $fn . '~', $fn;
	
	print "ok\n";

}

sub random_password {

	my $password;
	my $_rand;

	my $password_length = $_[0];
	if (!$password_length) {
		$password_length = 10;
	}

	my @chars = split(/\s/,
	"a b c d e f g h i j k l m n o p q r s t u v w x y z 
	 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
	 - _ % # |
	 0 1 2 3 4 5 6 7 8 9");

	srand;

 	for (my $i = 0; $i <= $password_length; $i++) {
		$_rand = int (rand 67);
		$password .= $chars [$_rand];
	}
	
	return $password;
	
}

1;