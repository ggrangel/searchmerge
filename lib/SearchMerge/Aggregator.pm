package SearchMerge::Aggregator;
use Modern::Perl;
use Moo;
use Mojo::UserAgent;
use Mojo::Promise;
use Data::Dumper ();
use SearchMerge::Cache;
use SearchMerge::Parser;
use SearchMerge::RateLimiter;
use SearchMerge::Ranker;

has ua => (
    is      => 'lazy',
    default => sub { Mojo::UserAgent->new },
);

has parser => (
    is      => 'lazy',
    default => sub { SearchMerge::Parser->new },
);

has cache => (
    is      => 'lazy',
    default => sub { SearchMerge::Cache->new },
);

has rate_limiter => (
    is      => 'lazy',
    default => sub { SearchMerge::RateLimiter->new },
);

has ranker => (
    is      => 'lazy',
    default => sub { SearchMerge::Ranker->new },
);

my @sources = (
    {
        name => 'Wikipedia',
        url  =>
'https://en.wikipedia.org/w/api.php?action=opensearch&limit=2&format=json&search='
    },
    {
        name => 'OpenLibrary',
        url  => 'https://openlibrary.org/search.json?limit=2&q='
    },

    # {
    #     name => 'Reddit',
    #     url  => 'https://www.reddit.com/search.json?limit=2&q='
    # },
    # {
    #     name => 'Archive.org',
    #     url  => 'https://archive.org/advancedsearch.php?q=',
    # },
    # {
    #     name => 'Github',
    #     url  => 'https://api.github.com/search/repositories?q='
    # },
);

sub aggregate {
    my ( $self, $query ) = @_;

    if ( my $cached = $self->cache->get($query) ) {
        say "Cache hit for $query";
        return $cached;
    }
    else {
        say "Cache miss for $query";
    }

    my @sources_requests = map {
        {
            name     => $_->{name},
            url      => $_->{url},
            full_url => $_->{url} . Mojo::Util::url_escape($query),
        }
    } @sources;

    my @promises = map {
        my $source = $_;

        $self->rate_limiter->wait_if_needed( $source->{name} );

        say "Creating promise for ", $source->{name}, "";

        # Store source info with the promise result
        $self->ua->get_p( $source->{full_url} )->then(
            sub {
                my $tx = shift;
                return {
                    source => $source->{name},
                    tx     => $tx,
                };
            }
        );
    } @sources_requests;
    say "Created ", scalar(@promises), " promises";

    my @results;

    for my $source (@sources_requests) {
        say "Scheduling request to ", $source->{name}, " at ",
          $source->{full_url};

        my $tx = $self->ua->get( $source->{full_url} );

        if ( $tx->res && $tx->res->is_success ) {
            say "Query to ", $tx->req->url, " succeeded";
            my $parsed =
              $self->parser->parse_source( $source->{name}, $tx->res );
            push @results, @$parsed;
        }
        else {
            say "Query to ", $tx->req->url, " failed";
        }
    }

    say "DEBUG: After wait, results count: ", scalar(@results);

    my $ranked = $self->ranker->rank( \@results, $query );
    $self->cache->set( $query, $ranked );
    return $ranked;
}

1;
