package Zanas::Dawdler;

use Cwd 'abs_path';
use Storable qw ( freeze thaw );
use Data::Dumper;
use Zanas;

use lib 'lib';

$| = 1;

################################################################################

sub new {
	my ($class, %self) = @_;
	my $self = bless \%self, $class;
	$self -> {preconf} ||= $self -> _read_preconf;
	our $preconf = $self -> {preconf};
	return $self;
}

################################################################################

sub _read_preconf {

	open (C, 'conf/httpd.conf') or die ("Can't open httpd.conf: $!\n");
	my $src = join '', (<C>);
	close (C);
	
	$src =~ /\$preconf.*?\;/gsm;
	$src = $&;
	$src or die "ERROR: can't parse httpd.conf.\n";
	eval $src;
	$preconf -> {db_dsn} =~ /database=(\w+)/;
	$preconf -> {db_name} = $1;
	return $preconf;
}

################################################################################

sub schedule {

	my ($self, $parent, $package, $sub, $time, @args) = @_;
	$conf ||= $self -> {conf};
	sql_reconnect ();	
	sql_do ('INSERT INTO dawdler_tasks (parent, package, sub, deadline, args) VALUES (?, ?, ?, ?, ?)', $parent, $package, $sub, $time, freeze (\@args));
	
}

################################################################################

sub _launch_todos {

	my ($self) = @_;
	$conf ||= $self -> {conf};

	sql_reconnect ();	

	my $todo_list = sql_select_all ('SELECT * FROM dawdler_tasks WHERE deadline < now() AND pid IS NULL');

print STDERR " Zanas::Dawdler: todo_list is", Dumper ($todo_list);
	
	foreach my $todo (@$todo_list) {
				
		my $child_pid = fork ();
		
		defined $child_pid or die ("Can't fork: $!");
		
		if ($child_pid) {

print STDERR "  Zanas::Dawdler [$$]: forked $child_pid\n";

			sql_do ('UPDATE dawdler_tasks SET pid = ? WHERE id = ?', $child_pid, $todo -> {id});
		}
		else {

print STDERR "  Zanas::Dawdler [$$]: going to launch $$todo{package}::$$todo{sub}\n";

			sql_reconnect ();	
			sql_do ('INSERT INTO dawdler_log (parent, id_task, package, sub, args, pid, action) VALUES (?, ?, ?, ?, ?, ?, 1)', $todo -> {parent}, $todo -> {id}, $todo -> {package}, $todo -> {sub}, $todo -> {args}, $$);
			
			require_fresh ($todo -> {package});
print STDERR "  Zanas::Dawdler [$$]: $todo -> {package}: " . Dumper (\%{$todo -> {package} . '::'});
			&{"$$todo{package}::$$todo{sub}"}($self, $todo -> {parent}, $todo -> {id}, @{thaw ($todo -> {args})});
			
			sql_reconnect ();	
			sql_do ('INSERT INTO dawdler_log (parent, id_task, package, sub, args, pid, action) VALUES (?, ?, ?, ?, ?, ?, 2)', $todo -> {parent}, $todo -> {id}, $todo -> {package}, $todo -> {sub}, $todo -> {args}, $$);
			sql_do ('DELETE FROM dawdler_tasks WHERE id = ?', $todo -> {id});

print STDERR "  Zanas::Dawdler [$$]: $$todo{package}::$$todo{sub} completed \n";

		}
		
	}

}

################################################################################

sub qu_debug_log {
	my ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller (1);
	print STDERR "${package}::${subroutine} [$$] $_[0] \n";
	eval {
		sql_do ("INSERT INTO __qu_log (sub, pid, msg) VALUES (?, ?, ?)", $subroutine, $$, $_[0]);
	};
}








































################################################################################

sub qu_reload {

qu_debug_log ('Started');

	unless ($preconf -> {qu}) {
qu_debug_log ('No $preconf -> {qu} -- bailing out');
		return;
	}

	$preconf -> {qu} -> {timeout}           ||= 60;
	$preconf -> {qu} -> {sleep_after_job}   ||= 1;
	$preconf -> {qu} -> {sleep_after_sleep} ||= 30;
	
	sql_reconnect ();
	
qu_debug_log ('DB connected');	
	
	$model_update -> assert (

		default_columns => {
			id   => {TYPE_NAME  => 'int', _EXTRA => 'auto_increment', _PK => 1},
		},	

		tables => {		
		
			__qu_tasks => {
			
				columns => {
				
					name =>            {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
					parent =>          {TYPE_NAME => 'int'},
					sub =>             {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
					args =>            {TYPE_NAME => 'logntext'},

					pid =>             {TYPE_NAME => 'int'},
					started =>         {TYPE_NAME => 'timestamp'},
					
				},
				
			},

			__qu_log => {
			
				columns => {
				
					id_task => {TYPE_NAME => 'int'},
					pid =>     {TYPE_NAME => 'int'},
					action =>  {TYPE_NAME => 'tinyint'},
					sub =>     {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
					arg1 =>    {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
					arg2 =>    {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
					arg3 =>    {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
					dt =>      {TYPE_NAME => 'timestamp'},			
					msg =>     {TYPE_NAME => 'text'},
					
				},
				
			},

		},

	);
		
qu_debug_log ('DB model asserted');			
					
}

################################################################################

sub qu_schedule {

	my ($options, $sub, @args) = @_;
	
	sql_do (
		'INSERT INTO __qu_tasks (name, parent, sub, args, due) VALUES (?, ?, ?, ?, ?)', 
		$options -> {name}, 
		$__qu_id_task, 
		$sub, 
		b64u_freeze (\@args),
		$options -> {due}, 
	);

}

1;