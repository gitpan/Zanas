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

sub run {

print STDERR "Zanas::Dawdler: start\n";

	our $PACKAGE_ROOT = abs_path ('lib') . '/';

	my $self = new Zanas::Dawdler;

	$self -> {preconf} -> {dawdler} -> {activity_period} ||= 60 * 60 - 5;
	$self -> {preconf} -> {dawdler} -> {sleep_period}    ||= 1;
	$self -> {finish_time} = time () + $self -> {preconf} -> {dawdler} -> {activity_period};

	$preconf ||= $self -> {preconf};
	
	sql_reconnect ();
	
	$model_update -> assert (

		default_columns => {
			id   => {TYPE_NAME  => 'int', _EXTRA => 'auto_increment', _PK => 1},
		},	

		tables => {		
			dawdler_tasks => {
				columns => {
					parent =>   {TYPE_NAME => 'int'},
					pid =>      {TYPE_NAME => 'int'},
					package =>  {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
					sub =>      {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
					args =>     {TYPE_NAME => 'text'},
					deadline => {TYPE_NAME => 'datetime'},
				},
			},

			dawdler_log => {
				columns => {
					parent =>  {TYPE_NAME => 'int'},
					id_task => {TYPE_NAME => 'int'},
					pid =>     {TYPE_NAME => 'int'},
					action =>  {TYPE_NAME => 'tinyint'},
					package => {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
					sub =>     {TYPE_NAME => 'varchar', COLUMN_SIZE => 255},
					args =>    {TYPE_NAME => 'text'},
					dt =>      {TYPE_NAME => 'timestamp'},
				},
			},

		},

	);
		
	sql_do ("INSERT INTO dawdler_log (parent, id_task, package, sub, args, pid, action) VALUES (0, 0, '', '', '', ?, 3)", $$);
	
	foreach my $task (@{$self -> {preconf} -> {dawdler} -> {tasks}}) {		
		sql_select_scalar ('SELECT COUNT(*) FROM dawdler_tasks WHERE package=? AND sub=? AND args=?', $task -> {package}, $task -> {sub}, freeze ($task -> {args})) or
			$self -> schedule (0, $task -> {package}, $task -> {sub}, 0, @{$task -> {args}});
	}

	sql_do ('UPDATE dawdler_tasks SET pid = NULL');
	
	while (1) {
		last if time () > $self -> {finish_time};
		$self -> _launch_todos;

print STDERR " Zanas::Dawdler: sleeping...\n";

		sleep ($self -> {preconf} -> {dawdler} -> {sleep_period});
	}
	
	sql_reconnect ();	
	sql_do ("INSERT INTO dawdler_log (parent, id_task, package, sub, args, pid, action) VALUES (0, 0, '', '', '', ?, 4)", $$);

	$db -> disconnect;
	
}

1;