package SearchMerge::Role::RateLimiter;
use Moo::Role;

requires 'wait_if_needed';

1;
