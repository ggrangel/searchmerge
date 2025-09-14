package SearchMerge::Aggregator;
use Moo;                # Lightweight object system
use Mojo::UserAgent;    # For making HTTP requests
use Mojo::Promise;      # For handling asynchronous operations
use Data::Dumper qw( Dumper );          # For debugging output

# Attribute to hold the user agent instance
has ua => (
  is => 'lazy', # Lazily built attribute
  default => sub { Mojo::UserAgent->new }, # Default value is a new Mojo::UserAgent
);

sub aggregate {
  my ($self, $query) = @_; # Accept a list of URLs to fetch

  my @sources = (
    {
      name => 'Wikipedia',
      url  => 'https://en.wikipedia.org/w/api.php?action=opensearch&limit=2&format=json&search=' . $query,
    },
    {
      name => 'Reddit',
      url  => 'https://www.reddit.com/search.json?limit=2q=' . $query,
    }
  );

  my @promises;
  for my $source (@sources) {
    my $promise = $self->ua->get_p($source->{url});
    push @promises, $promise;
  }

  my @results;
  # Use a closure to capture the results from the promise
  my $results_promise = Mojo::Promise->all(@promises)->then(
    sub {
      my @transactions = @_;
      # --- DEBUG LINE HERE ---
      print Dumper(\@transactions);
      # -----------------------

      # Now process the transactions inside the closure
      for my $tx (@transactions) {
        if ($tx->is_success) {
          push @results, { data => 'parsed data', source => $tx->req->url->to_string };
        } else {
          warn "Failed to fetch from ", $tx->req->url, ": ", $tx->error->{message};
        }
      }
    }
  );

  # This will block until the promise chain is complete
  $results_promise->wait;

  return @results; # Return the aggregated results
}

1;
