use strict;

use Test::More qw(no_plan);

use Test::Tester;

use Test::Warn::None qw( had_no_warnings warnings clear_warnings );

Test::Warn::None::builder(Test::Tester::capture());

sub a
{
	&b;
}

sub b
{
	warn shift;
}

{
	check_test(
		sub {
			had_no_warnings("check warns");
		},
		{
			actual_ok => 1,
		},
		"no warns"
	);

	my ($prem, $result) = check_test(
		sub {
			a("hello there");
			had_no_warnings("check warns");
		},
		{
			actual_ok => 0,
		},
		"1 warn"
	);

	like($result->{diag}, '/^There were 1 warning\\(s\\)/', "1 warn diag");
	like($result->{diag}, "/Previous test 0 ''/", "1 warn diag test num");
	like($result->{diag}, '/hello there/', "1 warn diag has warn");

	my ($warn) = warnings();

	my @carp = split("\n", $warn->{carp});
	like($carp[1], '/main::b/', "carp level b");
	like($carp[2], '/main::a/', "carp level a");

	SKIP: {
		my $has_st = eval "require Devel::StackTrace" || 0;

		skip("Devel::StackTrace not installed", 1) unless $has_st;
		isa_ok($warn->{stack_trace}, "Devel::StackTrace");
	}
}

{
	clear_warnings();
	check_test(
		sub {
			had_no_warnings("check warns");
		},
		{
			actual_ok => 1,
		},
		"clear warns"
	);

	my ($prem, $empty_result, $result) = check_tests(
		sub {
			had_no_warnings("check warns empty");
			warn "hello once";
			warn "hello twice";
			had_no_warnings("check warns");
		},
		[
			{
				actual_ok => 1,
			},
			{
				actual_ok => 0,
			},
		],
		"2 warn"
	);

	like($result->{diag}, '/^There were 2 warning\\(s\\)/', "2 warn diag");
	like($result->{diag}, "/Previous test 1 'check warns empty'/", "2 warn diag test num");
	like($result->{diag}, '/hello once.*hello twice/s', "2 warn diag has warn");
}

