package SearchMerge::RateLimiter;
#
# Implements a simple fixed-interval rate limiter that enforces
# a minimum time gap between consecutive requests to each source.
# 
# Algorithm: Minimum Interval Spacing
# - No burst capacity
# - Blocking (waits if too soon)
# - Per-source tracking
#
# Example: 100 req/sec = 0.01s minimum between requests
#
use Modern::Perl;
use Moo;
use Time::HiRes qw(time sleep);

has limits => (
  is => 'ro',
  default => sub {{
      Wikipedia => {max => 200, per => 1}, # 200 requests per second
      OpenLibrary => {max => 100, per => 1}, # 100 requests per second
    }}
  );
1;

has last_request => (
  is => 'rw',
  default => sub { {} },
);


sub wait_if_needed {
  my ($self, $source_name) = @_;

  my $limit = $self->limits->{$source_name};
  return 0 unless $limit; # no limit

  # Minimum time between requests
  my $min_interval = $limit->{per} / $limit->{max};

  my $last = $self->last_request->{$source_name} // 0;
  my $elapsed = time() - $last;

  if ($elapsed < $min_interval) {
    my $wait_time = $min_interval - $elapsed;
    say sprintf("Rate limiting %s: waiting %.3f seconds", $source_name, $wait_time);
    sleep($wait_time);
  }

  $self->last_request->{$source_name} = time()
}

1;
