#!/usr/bin/env perl
use Modern::Perl;
use Test::More import => [qw( done_testing is is_deeply like subtest )];
use Test::MockObject ();
use SearchMerge::Parser;

my $parser = SearchMerge::Parser->new;

# helper to create a fake HTTP::Response-like object
sub fake_response {
    my (%args) = @_;
    my $mock = Test::MockObject->new;
    $mock->mock( is_success => sub { $args{success} // 1 } );
    $mock->mock( body       => sub { $args{body}    // '' } );
    return $mock;
}

subtest 'Wikipedia parser' => sub {
    my $resp = fake_response(
        body => q{["query", ["Title1"], ["Description1"], ["/wiki/Title1"]]} );
    my $results = $parser->parse_source( 'Wikipedia', $resp );

    is( scalar @$results,       1,              "One result returned" );
    is( $results->[0]{title},   "Title1",       "Title parsed" );
    is( $results->[0]{snippet}, "Description1", "Description parsed" );
    is( $results->[0]{url},     "/wiki/Title1", "URL parsed" );
};

subtest 'OpenLibrary parser' => sub {
    my $resp = fake_response(
        body => q|{
          "docs": [
            { "title": "Book1", "author_name": ["Alice"], "first_publish_year": 2000, "key": "/books/OL1M" }
          ]
        }|
    );
    my $results = $parser->parse_source( 'OpenLibrary', $resp );

    is( scalar @$results, 1, "One result returned" );
    like( $results->[0]{snippet}, qr/by Alice/, "Author in snippet" );
    like( $results->[0]{snippet}, qr/2000/,     "Year in snippet" );
    is(
        $results->[0]{url},
        "https://openlibrary.org/books/OL1M",
        "URL built correctly"
    );
};

subtest 'Reddit parser' => sub {
    my $resp = fake_response(
        body => q|{
          "data": {
            "children": [
              { "data": { "title": "Post1", "selftext": "Long body text", "permalink": "/r/test/post1", "score": 10, "num_comments": 2, "subreddit": "testsub" } }
            ]
          }
        }|
    );
    my $results = $parser->parse_source( 'Reddit', $resp );

    is( scalar @$results,                   1,         "One result returned" );
    is( $results->[0]{title},               "Post1",   "Title parsed" );
    is( $results->[0]{metadata}{upvotes},   10,        "Upvotes parsed" );
    is( $results->[0]{metadata}{comments},  2,         "Comments parsed" );
    is( $results->[0]{metadata}{subreddit}, "testsub", "Subreddit parsed" );
};

subtest 'Unknown source' => sub {
    my $resp    = fake_response( body => '{}' );
    my $results = $parser->parse_source( 'UnknownSource', $resp );
    is_deeply( $results, [], "Unknown source returns empty list" );
};

subtest 'Unsuccessful response' => sub {
    my $resp    = fake_response( success => 0 );
    my $results = $parser->parse_source( 'Wikipedia', $resp );
    is_deeply( $results, [], "Unsuccessful response returns empty list" );
};

done_testing;

