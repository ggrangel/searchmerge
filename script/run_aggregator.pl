#!/usr/bin/perl
use strict;
use warnings;
use lib 'lib';    # Adjust the path to your lib directory if needed

use SearchMerge::RateLimiter::TokenBucket;
use SearchMerge::Aggregator;
use Data::Dumper qw( Dumper );

# Create a new instance of our Aggregator class
my $aggregator = SearchMerge::Aggregator->new(
    rate_limiter => SearchMerge::RateLimiter::TokenBucket->new(
        tokens      => 5,
        max_tokens  => 5,
        refill_rate => 1
    )
);

# Define a test query
my $query = 'Perl';

# Call the aggregate method
print "Aggregating results for: '$query'...\n";
my @results = $aggregator->aggregate($query);

# Print the results using Data::Dumper for easy inspection
print "----------------------------------\n";
print "Aggregated Results:\n";
print Dumper(@results);    # The backslash creates a reference to the array

print "----------------------------------\n";
print "Done.\n";
