package SearchMerge::Web;
use Modern::Perl;
use Mojo::Base 'Mojolicious';    # Makes our class inherint from Mojolicious
use Data::Dumper qw( Dumper );
use SearchMerge::Aggregator;

sub startup {
    my ($self) = @_;

    $self->helper(
        aggregator => sub {
            state $aggregator = SearchMerge::Aggregator->new;
            return $aggregator;
        }
    );

    my $r = $self->routes;

    $r->get('/')->to(

        # cb is short for callback
        cb => sub {
            my ($c) = @_;    # c is the controller
            $c->render(
                json => {
                    message        => 'SearchMerge API is running!',
                    has_aggregator => defined $c->aggregator ? 'yes' : 'no'
                }
            );
        }
    );

    $r->get('/search')->to(
        cb => sub {
            my ($c) = @_;
            my $query = $c->param('q');
            if ( !$query ) {
                return $c->render(
                    status => 400,
                    json   => { error => 'Query parameter q is required' }
                );
            }

            say "Web: calling aggregator with query: $query";

            my $results = $c->aggregator->aggregate($query);
            say "Web: aggregator returned: " . Dumper($results);
            say "Web: result count: " . scalar(@$results);

            return $c->render(
                json => {
                    query   => $query,
                    count   => scalar(@$results),
                    results => $results
                }
            );
        }
    );
}

1;
