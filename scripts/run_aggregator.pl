#!/usr/bin/perl
use strict;
use warnings;
use lib 'lib';    # This tells Perl where to find your modules

use SearchMerge::Aggregator;
use Data::Dumper qw( Dumper )
  ;               # A great module for printing complex data structures

# Create a new instance of our Aggregator class
my $aggregator = SearchMerge::Aggregator->new;

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
