use strict;
use warnings;

package Test::Warn::None;

use Test::Builder;

my $Test = Test::Builder->new;

use Carp qw(longmess);

use vars qw(
	$VERSION @EXPORT_OK @ISA $do_end_test
);

$VERSION = '0.02';

require Exporter;
@ISA = qw( Exporter );

@EXPORT_OK = qw(
	clear_warnings had_no_warnings warnings
);

$SIG{__WARN__} = \&catcher;

my @warnings;

$do_end_test = 1;

# the END blcok must be after the "use Test::Builder" to make sure it runs
# before Test::Builder's end block

END {
	had_no_warnings() if $do_end_test;
}

my $has_st = eval "require Devel::StackTrace" || 0;

sub catcher
{
	local $SIG{__WARN__};

	my $msg = shift;

	my $prev_test = $Test->current_test;
	my @tests = $Test->details;
	my $prev_test_name = $prev_test ? $tests[$prev_test - 1]->{name} : "";

	my $warn = {
		carp => longmess($msg),
		message => $msg,
		prev_test => $prev_test,
		prev_test_name => $prev_test_name,
	};

	$warn->{stack_trace} = Devel::StackTrace->new(
		ignore_class => __PACKAGE__
	) if $has_st;

	push(@warnings, $warn);

	return $msg;
}

sub had_no_warnings
{
	local $SIG{__WARN__};
	my $name = shift || "no warnings";

	my $ok;
	my $diag;
	if (@warnings == 0)
	{
		$ok = 1;
	}
	else
	{
		$ok = 0;
		$diag = "There were ".@warnings." warning(s)\n";
		$diag .= join("----------\n", map {warn_to_txt($_)}@warnings);
	}
	$Test->ok($ok, $name) || $Test->diag($diag);

	return $ok;
}

sub warn_to_txt
{
	local $SIG{__WARN__};
	my $warn = shift;

	return <<EOM;
Previous test $warn->{prev_test} '$warn->{prev_test_name}'
$warn->{carp}
EOM
}

sub clear_warnings
{
	local $SIG{__WARN__};
	@warnings = ();
}

sub warnings
{
	local $SIG{__WARN__};
	return @warnings;
}

sub builder
{
	local $SIG{__WARN__};
	if (@_)
	{
		$Test = shift;
	}
	return $Test;
}

1;

__END__

=head1 NAME

Test::Warn::None - Make sure you didn't emit any warnings while testing

=head1 SYNOPSIS

  use Test::Warn::None;

  # do lots of testing

=head1 DESCRIPTION

In general, your tests shouldn't produce warnings. This allows you to check
at the end of the script that they didn't. If they did produce them, you'll
get full details including a stack trace of what was going on when the warning
occurred.

If some of your tests B<should> produce warnings then you should be
capturing and checking them with L<Test::Warn>, that way L<Test::Warn::None>
will not see them and not complain.

=head1 USAGE

Simply by using the module, you automatically get an extra test at the end
of your script that checks that no warnings were emitted. So just stick

  use Test::Warn::None

at the top of your script and continue as normal.

If you want more control you can invoke the test manually at any time with
C<had_no_warnings()>.

The warnings your test has generated so far are stored are in array. You can
look inside and clear this whenever you want with C<warnings()> and
C<clear_warnings()>. However, it would be better to use the L<Test::Warn>
module if you want to go poking around inside the warnings.

=head1 OUTPUT

If warning is captured during your test then the details will output as part
of the diagnostics. You will get:

=over 2

=item o

the number and name of the test that was executed just before the warning
(if no test had been executed these will be 0 and '')

=item o

the message passed to C<warn>,

=item o

a full dump of the stack when warn was called, courtesy of the C<Carp>
module

=back

=head1 EXPORTABLE FUNCTIONS

=head2 had_no_warnings()

This checks that there have been warnings emitted by your test scripts.
Usually you will not call this explicitly as it is called automatically when
your script finishes.

=head2 clear_warnings()

This will clear the array of warnings that have been captured. If the array
is empty then a call to C<had_no_warnings()> will produce a pass result.

=head2 warnings()

This will return the array of warnings captured so far. Each element of this
array is a hashref with the following keys:

=over 2

=item o

B<prev_test>: the number of the test that executed before the warning was
produced, if no tests had executed, this will be 0.

=item o

B<prev_test_name>: the name of the test that executed before the warning was
produced, if no tests had executed, this will be "".

=item o

B<msg>: the captured warning message that your test emitted

=item o

B<carp>: the captured warning message that your test emitted plus a stack
trace generated by the L<Carp> module.

=item o

B<stack_trace>: A L<Devel::StackTrace> object, created at the time of the
warning. This will only be present if L<Devel::StackTrace> is installed.

=back

=head1 PITFALLS

When counting your tests for the plan, don't forget to include the test that
runs automatically when your script ends.

=head1 BUGS

None that I know of.

=head1 SEE ALSO

L<Test::More>, L<Test::Warn>

=head1 AUTHOR

Written by Fergal Daly <fergal@esatclear.ie>.

=head1 COPYRIGHT

Copyright 2003 by Fergal Daly E<lt>fergal@esatclear.ieE<gt>.

This program is free software and comes with no warranty. It is distributed
under the LGPL license

See the file F<LGPL> included in this distribution or
F<http://www.fsf.org/licenses/licenses.html>.

=cut
