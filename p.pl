use File::Find;

open (O, ">f.html");

find (sub {

	print O "<h1>$File::Find::name</h1>\n<pre>";
	
	next if -d $_;
	next if $_ =~ /\.pl/;
	next if $_ =~ /\.html/;

	open (F, $_);
	
	while (<F>) {
		print O $_;
	}
	
	close (F);

	print O "</pre>\n";

}, '.');

close (O);
