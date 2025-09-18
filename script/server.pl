#!/usr/bin/env perl
use Modern::Perl;
use FindBin ();
use lib "$FindBin::RealBin/../lib";    # Add lib/ to Perl's path

use Mojolicious::Commands;
Mojolicious::Commands->start_app('SearchMerge::Web');

