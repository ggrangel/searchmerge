package SearchMerge::RateLimiter::TokenBucket;
use Moo;
use Time::HiRes ();

with 'SearchMerge::Role::RateLimiter';

has 'tokens'      => ( is => 'rw', default => 2 );    # start with 2 tokens
has 'max_tokens'  => ( is => 'ro', default => 2 );    # cap at 2
has 'refill_rate' => ( is => 'ro', default => 1 );    # 1 token per second
has 'last_refill' => ( is => 'rw', default => sub { time() } );

sub wait_if_needed {
    my ( $self, $source ) = @_;
    $self->_refill_tokens;

    while ( $self->tokens < 1 ) {
        sleep(0.1);
        $self->_refill_tokens;
    }

    $self->tokens( $self->tokens - 1 );
}

sub _refill_tokens {
    my $self    = shift;
    my $now     = time();
    my $elapsed = $now - $self->last_refill;

    my $new_tokens = $self->tokens + ( $elapsed * $self->refill_rate );
    $self->tokens(
        $new_tokens > $self->max_tokens ? $self->max_tokens : $new_tokens );
    $self->last_refill($now);
}

1;
