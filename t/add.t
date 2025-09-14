#!/usr/bin/env perl
use strict;
use warnings;
use v5.20;
use lib 'lib';
use Test::More import => [ qw( BAIL_OUT done_testing is subtest use_ok ) ];

use_ok('Calculator') or BAIL_OUT("Cannot load Calculator module");

is( Calculator::add(2, 3), 5, '2 + 3 = 5' );
is( Calculator::add(-1, 1), 0, '-1 + 1 = 0' );

subtest 'Additional tests' => sub {
    is( Calculator::add(0, 0), 0, '0 + 0 = 0' );
    is( Calculator::add(-5, -5), -10, '-5 + -5 = -10' );
};

subtest 'decimal tests' => sub {
    is( Calculator::add(2.5, 3.5), 6.0, '2.5 + 3.5 = 6.0' );
    is( Calculator::add(-1.5, 1.5), 0.0, '-1.5 + 1.5 = 0.0' );
};

done_testing();
