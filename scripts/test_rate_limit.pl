#!/usr/bin/env perl
use Modern::Perl;
use lib 'lib';
use SearchMerge::RateLimiter;
use Time::HiRes qw(time);

my $limiter = SearchMerge::RateLimiter->new;

say "Testing rate limiting...";

for my $i (1..5) {
    my $start = time();
    
    # This should be rate limited (100 req/sec = 0.01s between requests)
    $limiter->wait_if_needed('OpenLibrary');
    
    my $elapsed = time() - $start;
    say sprintf("Request %d: waited %.3f seconds", $i, $elapsed);
}

say "\nTrying different sources:";
$limiter->wait_if_needed('Wikipedia');
say "Wikipedia: OK";

