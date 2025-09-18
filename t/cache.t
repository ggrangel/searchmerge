use Modern::Perl;
use Test::More import =>
  [qw( cmp_ok done_testing is is_deeply isa_ok note ok subtest use_ok )];
use Time::HiRes ();
use lib 'lib';

use_ok('SearchMerge::Aggregator');

my $agg = SearchMerge::Aggregator->new;
isa_ok( $agg, 'SearchMerge::Aggregator' );

subtest 'Cache performance' => sub {

    # First search (cache miss)
    my $start    = time();
    my $results1 = $agg->aggregate("perl modules");
    my $time1    = time() - $start;

    ok( defined $results1,        'First search returns results' );
    ok( ref $results1 eq 'ARRAY', 'Results are arrayref' );

    # Second search (should hit cache)
    $start = time();
    my $results2 = $agg->aggregate("perl modules");
    my $time2    = time() - $start;

    # Cache should make second search faster
    cmp_ok( $time2, '<', $time1 / 2, 'Cached search is at least 2x faster' );

    # Note the times for debugging
    note("First search: ${time1}s, Second search: ${time2}s");
    note( "Speed improvement: " . sprintf( "%.1fx", $time1 / $time2 ) )
      if $time2 > 0;
};

subtest 'Cache consistency' => sub {
    my $query = "perl testing " . time();    # Unique query

    # First call
    my $results1 = $agg->aggregate($query);
    ok( defined $results1, 'First call returns results' );

    # Second call (from cache)
    my $results2 = $agg->aggregate($query);
    ok( defined $results2, 'Cached call returns results' );

    # Should be same number of results
    is( scalar(@$results2), scalar(@$results1),
        'Cache returns same number of results' );

    # Should be identical data
    is_deeply( $results2, $results1, 'Cache returns identical results' );
};

subtest 'Cache isolation' => sub {
    my $results_perl   = $agg->aggregate("perl");
    my $results_python = $agg->aggregate("python");

    ok( defined $results_perl,   'Perl search returns results' );
    ok( defined $results_python, 'Python search returns results' );

    # Searching for perl again should still return perl results
    my $results_perl2 = $agg->aggregate("perl");
    is_deeply( $results_perl2, $results_perl,
        'Different queries cached separately' );
};

done_testing();
