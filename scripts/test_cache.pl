#!/usr/bin/env perl
use Modern::Perl;
use lib 'lib';
use SearchMerge::Aggregator;

my $agg = SearchMerge::Aggregator->new;

say "Testing Cache Behavior\n";

# Test 1: Second search should be faster (cache hit)
my $start = time();
my $results1 = $agg->aggregate("perl modules");
my $time1 = time() - $start;

$start = time();
my $results2 = $agg->aggregate("perl modules");  # Same query
my $time2 = time() - $start;

say "First search:  ${time1}s";
say "Second search: ${time2}s";

if ($time2 < $time1 / 2) {
    say "Cache is working (second search was faster)";
} else {
    say "Cache might not be working";
}

if (@$results1 == @$results2) {
    say "Same number of results from cache";
} else {
    say "Different results from cache";
}

say "\n";
my $results3 = $agg->aggregate("python django");
# Should see "Cache miss" in output

say "\nDone!";
