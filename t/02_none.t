use strict;
use warnings;
use Test::Tester;
use Test::More qw(no_plan);
use Test::NoWarnings qw( had_no_warnings warnings clear_warnings );

Test::NoWarnings::builder(Test::Tester::capture());

sub a {
    &b;
}

sub b {
    warn shift;
}

SCOPE: {
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

    # 5.8.5 changed Carp's behaviour when the string ends in a \n
    # the monkey business is because 5.005 throws a "used only
    # once" warning for $Carp::VERSION
    my $cv   = do { no warnings; $Carp::VERSION };
    my $base = $cv >= 1.03;
    my @carp = split("\n", $warn->getCarp);

    like($carp[$base+1], '/main::b/', "carp level b");
    like($carp[$base+2], '/main::a/', "carp level a");

    SKIP: {
        eval { require Devel::StackTrace }
          or skip("Devel::StackTrace not installed", 1);

        isa_ok($warn->getTrace, "Devel::StackTrace");
    }
}

SCOPE: {
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
