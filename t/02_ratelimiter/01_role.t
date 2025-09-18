#!/usr/bin/env perl
use strict;
use warnings;
use Test::More import => [qw( can_ok done_testing ok use_ok )];
use lib 'lib';

# Test that implementations fulfill the role
use_ok('SearchMerge::Role::RateLimiter');
use_ok('SearchMerge::RateLimiter::MinimumInterval');
use_ok('SearchMerge::RateLimiter::TokenBucket');

# Verify implementations consume the role
{
    my $min_interval = SearchMerge::RateLimiter::MinimumInterval->new;
    ok(
        $min_interval->does('SearchMerge::Role::RateLimiter'),
        'MinimumInterval implements RateLimiter role'
    );

    my $token_bucket = SearchMerge::RateLimiter::TokenBucket->new;
    ok(
        $token_bucket->does('SearchMerge::Role::RateLimiter'),
        'TokenBucket implements RateLimiter role'
    );
}

# Test required methods exist
{
    my $min_interval = SearchMerge::RateLimiter::MinimumInterval->new;
    can_ok( $min_interval, qw(wait_if_needed) );

    my $token_bucket = SearchMerge::RateLimiter::TokenBucket->new;
    can_ok( $token_bucket, qw(wait_if_needed) );
}

done_testing();
