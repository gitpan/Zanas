use Zanas::Presentation;
use Zanas::Content;
use Zanas::Apache;

################################################################################

sub require_fresh {

	my ($module_name) = @_;	
	
	if ($_USER and $$_USER{role} and $module_name =~ /Content|Presentation/) {
	
		my $specific_module_name = $module_name;
		
		$specific_module_name =~ s/(Content|Presentation)/$$_USER{role}::$1/;
		
		my $error;
		
		eval {$error = require_fresh_internal ($specific_module_name)};
		
		return unless $error;
		
	}
	
	require_fresh_internal ($module_name, 1);

}

################################################################################

sub fix_module_for_role {

	my ($file_name) = @_;
	
	my $tmp_file_name = $file_name . '~';
	
	open (IN, $file_name) or die "Cannot open $file_name: $!\n";
	open (OUT, ">$tmp_file_name") or die "Cannot write to $tmp_file_name: $!\n";
	
	my $suffix = ($_USER and $$_USER{role}) ? '_for_' . $_USER -> {role} : '';
	
	while (my $s = <IN>) {
	
		$s =~ s/sub\s+get_menu\w*/sub get_menu$suffix/;
		
		print OUT $s;
		
	}
	
	close (OUT);
	close (IN);	

}

################################################################################

sub require_fresh_internal {

	my ($module_name, $fatal) = @_;	

	if ($conf -> {core_spy_modules}) {
		
		my $file_name = $module_name;

		$file_name =~ s{::}{\/}g;

		my $inc_key = $file_name . '.pm';

		$file_name =~ s{^(.+?)\/}{\/};
		$file_name = $PACKAGE_ROOT . $file_name . '.pm';
		
		-f $file_name or return "File not found: $file_name\n";
		
		fix_module_for_role ($file_name) if $conf -> {core_fix_modules} and $module_name =~ /Content|Presentation/;

		my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $last_modified, $ctime, $blksize, $blocks) = stat ($file_name);

		my $last_load = $INC_FRESH {$module_name} + 0;

		my $need_refresh = $last_load < $last_modified;

		$need_refresh or return;

#		eval { do $file_name };

		delete $INC {$inc_key};

		eval "require $module_name";

	}	
	
	else {
		
		eval "require $module_name";

	}

	$INC_FRESH {$module_name} = time;

        if ($@ and $fatal) {
		$_REQUEST {error} = $@;
		print STDERR "require_fresh: error load module $module_name: $@\n";
        }	
        
        return $@;
	
}

################################################################################

BEGIN {

	our %INC_FRESH = ();
	
	while (my ($name, $path) = each %INC) {

		delete $INC {$name} if $name =~ m{Zanas[\./]}; 

	}

	our $PACKAGE_ROOT = $INC {__PACKAGE__ . '/Config.pm'};
	
	$PACKAGE_ROOT ||= '';

	$PACKAGE_ROOT =~ s{\/Config\.pm}{};

	if ($conf -> {core_load_modules}) {


		opendir (DIR, "$PACKAGE_ROOT/Content") || die "can't opendir $PACKAGE_ROOT/Content: $!";
		my @files = grep {/\.pm$/} map { "Content/$_" } readdir(DIR);
		closedir DIR;	

		opendir (DIR, "$PACKAGE_ROOT/Presentation") || die "can't opendir $PACKAGE_ROOT/Presentation: $!";
		push @files, grep {/\.pm$/} map { "Presentation/$_" } readdir(DIR);
		closedir DIR;	

		foreach my $file (@files) {

			$file =~ s{\.pm$}{};
			$file =~ s{\/}{\:\:};

			require_fresh (__PACKAGE__ . "::$file");

		}
	
	}
		
}

################################################################################

package Zanas;

$VERSION = '0.62';

=head1 NAME

Zanas - Web application construction set.

=head1 DESCRIPTION

Zanas is a set of naming conventions, utility functions, and a basic Apache request handler that help to quickly build robust, efficient and good-looking Web interfaces with standard design. The last doesn't mean that you can't alter hardcoded HTML fragments at all. But building public Web sites with original graphics and layout is not the primary goal of Zanas development. Zanas is good (I hope) for developing client database editing GUIs ('thin clients') and is conditionnally comparable to Windows API and java Swing.

Zanas' basic features are:

=over

=item GUI base

usable set of HTML widgets (forms, toolbars, etc);

=item sessions

session management subsystem with transparent query rewriting;

=item js alerting

server side error handling and data validation with client javaScript notifications without page reloading (yes, it really is);

=item logging

action logging is a part of core process, additionl API calls aren't needed;

=item fake records

handling of temporary records that are only visible on creation forms and wizards;

=back

=head1 DESIGN PRINCIPLES

There is a whole a lot of univesal web application platforms. So, why develop another one instead of using some mature product? 'Cause we've already tried many of this and have'nt found a good one. 

When developing Zanas, we use the following principles:

=over

=item no OO

HTTP is nothing else than evaluting string functions with sets of named parameters. Request handler must do nothing else than decompose the top function to some more primitive functions. So, Zanas is purely procedure-oriented framework.

=item content/presentation separation

Request handler reduce the top function f (x) to a superposition of a content and a presentation function: c (x) and p (c, x), where c (x) can't produce any HTML fragment in its result and p (c, x) can't use any info stored in the database.

	f (x) = p (c (x), x). 

=item URL discipline and strict callback naming

Content and presentation functions can be reduced to swithes between some elementary callback functions, where the switch is directly governed by known CGI parameters. Say, for C<url='/?type=users'> C<c == select_users> and C<p == draw_users>.

=item no ASP

Perl is ideal for implementing templating languages. That's why people love to implement new templating languages in Perl. But most of them ignore the fact that Perl I<is already> a templating language. Heredoc syntax is much more usable than any ASP-like. And it doesn't require any additional processing: everything is done by the Perl interpreter.

=item no XML

Nested Perl datastructures like list-of-hashes and more complex offer the same functionnality as the  XML DOM model. And it doesn't require any external libraries: everything is done by the Perl interpreter.

=item no XSLT

It would be very strange to use XSLT without XML, but we must underline here that there was one more reason to not use XSLT. Its syntax is even much crappier and less flexible than ASP-like.

=item no cacheing

We claim ourself unable to develop a universal and effective transparent cacheing system with authomatic dependencies tracking. (Can anybody do it?) And we don't need a memory hog with multiple obsolete copies of DB content accessible with some sophisticated API.

=back

=head1 MAGIC CGI PARAMETERS

The next CGI parameters have special meaning in Zanas URLs and can be used only as described.

=over

=item sid

Session ID. If not set, the client is automatically redirected to the logon screen.

=item type

Type of the current screen. Can have values like C<'users'> or, for example, C<'users_creation_wizard_step_2'>. Influences the callback functions selection and the main menu rendering.

=item id

Current object ID. Influences the callback functions selection. When set, the screen presents detailed info of one object, otherwise, it contains some search results.

=item action

Name of the action to execute. If set, the request handler executes some editing callback, then evalutes the new URL where C<action> is unset and redirects the client there.

=item salt

Fake random parameter for preventing the client HTML cacheing.

=back

=head1 GLOBAL VARIABLES

The next variables are accessible in all callback subs.

=over

=item %_REQUEST

The hash of CGI parameters and its values

=item $_USER

The hashref containing the current user information:
	
	{
		id   => ...
		name => ...
		role => ... 
	}

=back

=head1 CALLBACK SUBS

Under differnent circumstances, Zanas Apache request handler executes appropriate callback subs. The name of the callback to execute depends on current program context, C<type> value and the role of the current user. 

Suppose that the context imply the callback name C<$my_callback>, C<$_REQUEST{type}> is C<$type> and C<$$_USER {role}> is C<$role>. In this case, if the sub named "${my_callback}_${type}_for_${role}" is defined, it will be called. Otherwise, if the sub named "${my_callback}_${type}" is defined, it will be called. Otherwise, undef value will be used instead of missing sub result.

In the next sections, "${my_callback}_${type}_for_${role}" always means one of 3 cases described above.

=over

=item validate_{$action}_${type}_for_${role}

This sub must analyze the values of parameters in C<%_REQUEST> hash for consistency. In most cases, the object id is stored in C<$_REQUEST {id}> and the names of all other fields are underscore prefixed (C<$_REQUEST {_name}>, C<$_REQUEST {_login}>, C<$_REQUEST {_password}> etc). 

If everythig's OK, the validator must return C<undef>. Otherwise, the return value is an error code. We'll call it C<$error>. So, if C<$error> is defined, an error message template C<$$error_messages {"{$action}_${type}_${error}"}> is interpolated as a qq-string and then sent to the user as the error message.

For example, if the sub C<validate_update_users_for_admin> returns C<'duplicate_login'>, C<$_REQUEST {_login} eq 'scott'> and C<$$error_messages {"update_users_duplicate_login"} eq 'Duplicate login: \'$_REQUEST{_login}\''>, then the error message will be C<"Duplicate login: 'scott'">.

=item do_{$action}_${type}_for_${role}

This sub must execute the C<$action>. Note that you can choose the next screen shown to the user by manipulating the C<%_REQUEST> hash. For example, it's usual to set the C<id> parameter after creating new object:

	sub do_create_users_for_admin {
	
		sql_do ("INSERT INTO ... ");
		
		$_REQUEST {id} = sql_last_insert_id ();
	
	}

The client window will be rediredted to "/?type=users&id=1&sid=...".

=item get_item_of_${type}_for_${role}

This sub must fetch the info for the screen of type C<$type> having the obgect id C<$_REQUEST {id}> and the role C<${role}>. Usually it's a reference to a hash, may be nested.

=item select_${type}_for_${role}

This sub must fetch the info for the screen of type C<$type> and the role C<${role}>. Usually it's a reference to a list of references to hashes, may be nested.

=item draw_item_of_${type}_for_${role}

This sub must render the screen of type C<$type> having the obgect id C<$_REQUEST {id}> and the role C<${role}> as HTML. The info fetched with C<get_item_of_${type}_for_${role}> is passed as its 1st parameter.

=item draw_${type}_for_${role}

This sub must render the screen of type C<$type> sand the role C<${role}> as HTML. The info fetched with C<select_${type}_for_${role}> is passed as its 1st parameter.

=back

=head1 HTTP REQUEST HANDLING

=head2 SESSION CHECKING

First of all, the handler checks for the C<sid> param and, if the session is alive, it sets the C<$USER> variable, otherwise, redirects the client to the logon screen. 

=head2 EDITING REQUEST

If the C<action> CGI parameter is set, then the sub named C<validate_{$action}_${type}_for_${role}> is invoked. If if returns a non-empty error message, it's logged and presented with a js popup window. Otherwise the sub named C<do_{$action}_${type}_for_${role}> is invoked, then the client is redirected to the new URL composed from all C<%_REQUEST> key-value pairs except C<action> and those which names start with an C<'_'>.

In any case, the HTTP response has status 200 (OK) and contains a tiny HTML document consisting of a singular C<body> tag with a non-empty C<onLoad> event handler. When an error occurs, this handler displays the message in a js popup window. Otherwise the C<onLoad> handler opens the new URL in the top browser window.

Every conventional HTML page generated by Zanas Apache handler has a zero sized internal frame called C<invisible>. In order to improve the GUI usability, every anchor with non-empty C<action> parameter value in its href and every form with a non-empty value for C<action> input must use C<invisible> as the target:

	<a href="/type=folder&action=create" target="invisible">[New Folder]</a>
	
	<form action="/" target="invisible">
		...
	</form>
	


Standard Zanas HTML rendering API does this automatically.

=head2 OBJECT BROWSING REQUEST

If the C<action> CGI parameter is unset and C<id> CGI parameter is set, then the HTML resuls from the superposition of C<draw_item_of_${type}_for_${role}> and C<get_item_of_${type}_for_${role}> callbacks.

=head2 SELECTION BROWSING REQUEST

If both C<action> and C<id> CGI parameters are unset, then the HTML resuls from the superposition of C<draw_${type}_for_${role}> and C<select_${type}_for_${role}> callbacks.

=head1 MODULES STRUCTURE

Zanas modules don't have a C<package> directive. All the stuff is loaded in one package. 

Callback subs must be placed in strictly named .pm files. Suppose that you've chosen C<$applib> as your application library root and have placed it in your C<@INC> array. Then, create C<$applib/Content> and C<$applib/Presentation> directories. 

Now, all content callbacks (C<validate_{$action}_${type}_for_${role}>, C<do_{$action}_${type}_for_${role}>, C<get_item_of_${type}_for_${role}> and C<select_${type}_for_${role}>) must be defined in C<$applib/Content/${type}.pm> and presentation callbacks (C<draw_item_of_${type}_for_${role}> and C<draw_${type}_for_${role}>) in C<$applib/Presentation/${type}.pm>.

	$applib
		Content
			roles.pm
			users.pm
		Presentation
			roles.pm
			users.pm
			

=head1 SEE ALSO

Zanas::Presentation

=head1 AUTHORS

Dmitry Ovsyanko <do@zanas.ru>
Pavel Kudryavtzev <pashka@zanas.ru>
Yaroslav Ivanov <... hekima ...>

1;