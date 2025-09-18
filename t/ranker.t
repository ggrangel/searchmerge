use Modern::Perl;
use Test::More import =>
  [qw( done_testing is is_deeply isa_ok ok plan subtest )];

# The module we are testing
use SearchMerge::Ranker;

# Create a sample dataset for testing
my @results = (
    {
        id     => 1,
        title  => 'Learning Perl by Randal L. Schwartz',
        source => 'OpenLibrary'
    },
    {
        id     => 2,
        title  => 'The Perl Programming Language',
        source => 'Wikipedia'
    },
    { id => 3, title => 'Programming in Python',    source => 'UnknownSource' },
    { id => 4, title => 'A cool thread about perl', source => 'Reddit' },
    { id => 5, title => 'Java for Dummies',         source => 'OpenLibrary' },
    { id => 6, source => 'Wikipedia' },    # No title
);

my $ranker = SearchMerge::Ranker->new();
isa_ok( $ranker, 'SearchMerge::Ranker', 'Ranker object created successfully' );

subtest 'calculate_score method tests' => sub {
    plan tests => 6;

    # Test case 1: Basic match with boost
    my $score1 = $ranker->calculate_score( $results[1], 'perl' );
    is( $score1, 2,
        'Correctly scores a single keyword match with Wikipedia boost (1 * 2)'
    );

    # Test case 2: Multiple matches with high boost
    my $score2 = $ranker->calculate_score( $results[0], 'learning perl' );
    is( $score2, 10,
        'Correctly scores multiple keywords with OpenLibrary boost (2 * 5)' );

    # Test case 3: Case-insensitivity
    my $score3 = $ranker->calculate_score( $results[1], 'PERL' );
    is( $score3, 2, 'Scoring is case-insensitive for the query' );

    # Test case 4: Low boost source
    my $score4 = $ranker->calculate_score( $results[3], 'perl' );
    is( $score4, 0.5,
        'Correctly applies low boost for Reddit source (1 * 0.5)' );

    # Test case 5: No keyword match
    my $score5 = $ranker->calculate_score( $results[4], 'perl' );
    is( $score5, 0, 'Correctly scores 0 for no match' );

    # Test case 6: Default boost for unknown source
    my $score6 = $ranker->calculate_score( $results[2], 'programming' );
    is( $score6, 1,
        'Correctly applies default boost of 1 for an unknown source' );
};

subtest 'rank method tests' => sub {
    plan tests => 4;

    my $query          = 'perl programming';
    my $ranked_results = $ranker->rank( \@results, $query );

    # Test 1: Check return type
    is( ref $ranked_results, 'ARRAY', 'rank() returns an array reference' );

    # Test 2: Check that all original items are returned
    is( @$ranked_results, 6, 'rank() returns the same number of results' );

    # Test 3: Check if the score key was added
    ok(
        exists $ranked_results->[0]{score},
        'rank() adds a "score" key to results'
    );

    my $empty_results = $ranker->rank( [], $query );
    is_deeply( $empty_results, [],
        'rank() handles an empty result set correctly' );
};

done_testing();
