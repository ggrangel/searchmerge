package SearchMerge::Aggregator;
use Modern::Perl;
use Moo;
use Mojo::UserAgent;
use Mojo::Promise;
use Data::Dumper ();
use SearchMerge::Parser;

has ua => (
    is      => 'lazy',
    default => sub { Mojo::UserAgent->new },
);

has parser => (
    is      => 'lazy',
    default => sub { SearchMerge::Parser->new },
);

my @sources = (
    {
        name => 'Wikipedia',
        url  =>
'https://en.wikipedia.org/w/api.php?action=opensearch&limit=1&format=json&search='
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

    my @sources_requests = map {
        {
            name     => $_->{name},
            url      => $_->{url},
            full_url => $_->{url} . Mojo::Util::url_escape($query),
        }
    } @sources;

    my @promises = map {
        my $source = $_;
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

    Mojo::Promise->all(@promises)->then(
        sub {
            my @wrapped_results = @_;

            for my $wrapped (@wrapped_results) {
                my $result = $wrapped->[0];
                my $source = $result->{source};
                my $tx     = $result->{tx};

                if ( $tx && $tx->res && $tx->res->is_success ) {
                    say "Query to ", $tx->req->url, " succeeded";
                    my $parsed =
                      $self->parser->parse_source( $source, $tx->res );
                    push @results, @$parsed;
                }
                else {
                    say "Query to ", $tx->req->url, " failed";
                    if ( $tx && $tx->error ) {
                        warn "  Error: ", $tx->error->{message}, "";
                    }
                }
            }
        }
    )->catch(
        sub {
            my $err = shift;
            warn "A promise was rejected: $err";
        }
    )->wait;

    return @results;
}

1;
