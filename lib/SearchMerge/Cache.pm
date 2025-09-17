package SearchMerge::Cache;
use Modern::Perl;
use Moo;
use CHI;
use Digest::SHA qw(sha256_hex);

has chi => (
  is => 'lazy',
  default => sub {
    CHI -> new(
      driver => 'Memory',
      global => 1,
    )
  }
);

sub get {
  my ($self, $query) = @_;
  my $key = $self->_make_key($query);
  return $self->chi->get($key);
}

sub set {
  my ($self, $query, $results) = @_;
  my $key = $self->_make_key($query);
  $self->chi->set($key, $results, '5 minutes');
}

sub _make_key {
  my ($self, $query) = @_;
  return 'searchmerge:' . sha256_hex(lc($query));
}

1;
