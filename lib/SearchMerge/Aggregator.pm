package SearchMerge::Aggregator;
use Modern::Perl;
use Moo;
use Mojo::UserAgent;
use Mojo::Promise;
use Data::Dumper ();
use SearchMerge::Cache;
use SearchMerge::Parser;
use SearchMerge::Ranker;
use SearchMerge::Role::RateLimiter;
use SearchMerge::RateLimiter::MinimumInterval;
use Types::Standard qw( ConsumerOf );

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
    is      => 'ro',
    isa     => ConsumerOf ['SearchMerge::Role::RateLimiter'],
    default => sub {
        return SearchMerge::RateLimiter::MinimumInterval->new;
    },
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
    {
        name => 'Reddit',
        url  => 'https://www.reddit.com/search.json?limit=2&q='
    },
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

    my @results;
    for my $source (@sources_requests) {
        say "Fetching from ", $source->{name}, " at ", $source->{full_url};

        $self->rate_limiter->wait_if_needed( $source->{name} );

        my $tx = $self->ua->get( $source->{full_url} );

        if ( $tx->res && $tx->res->is_success ) {
            say "Query to ", $tx->req->url, " succeeded";
            my $parsed =
              $self->parser->parse_source( $source->{name}, $tx->res );
            push @results, @$parsed;
        }
        else {
            say "Query to ", $tx->req->url, " failed";
            if ( $tx->error ) {
                say "Error: ", $tx->error->{message};
            }
        }
    }

    my $ranked = $self->ranker->rank( \@results, $query );
    $self->cache->set( $query, $ranked );
    return $ranked;
}

1;
