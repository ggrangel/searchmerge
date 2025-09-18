#!/usr/bin/env perl
use Modern::Perl;
use FindBin ();
use lib "$FindBin::RealBin/../lib";
use Getopt::Long qw( GetOptions );
use Pod::Usage   qw( pod2usage );
use JSON::XS     qw( encode_json );
use SearchMerge::Aggregator;

# Command line options
my $help     = 0;
my $json     = 0;
my $limit    = 10;
my $no_cache = 0;
my $verbose  = 0;

GetOptions(
    'help|h'     => \$help,
    'json|j'     => \$json,
    'limit|l=i'  => \$limit,
    'no-cache|n' => \$no_cache,
    'verbose|v+' => \$verbose,
) or pod2usage(2);

pod2usage(1) if $help;
pod2usage("No query provided.") unless @ARGV;

my $query = join( ' ', @ARGV );

my $aggregator = SearchMerge::Aggregator->new( verbose => $verbose );
my $results    = $aggregator->aggregate($query);

splice( @$results, $limit ) if @$results > $limit;

if ($json) {
    print encode_json(
        {
            query   => $query,
            count   => scalar(@$results),
            results => $results,
        }
    );
    exit;
}

say "\nSearch Results for: '$query'";
print "=" x 50 . "\n";

if ( !@$results ) {
    say "No results found.";
    exit;
}

for my $i ( 0 .. $#$results ) {
    my $r = $results->[$i];
    printf( "\n%d. [%s] %s\n",  $i + 1, $r->{source}, $r->{title} );
    printf( "   Score: %.2f\n", $r->{score} );
    printf( "   URL: %s\n",     $r->{url} );
    printf( "   %s\n",          $r->{snippet} ) if $r->{snippet};
}

print "\n" . "=" x 50 . "\n";
printf( "Found %d results\n", scalar(@$results) );

__END__

=head1 NAME

searchmerge-cli - Command line interface for SearchMerge

=head1 SYNOPSIS

searchmerge-cli [options] <query>

 Options:
   -h, --help       Show this help message
   -j, --json       Output as JSON
   -l, --limit=N    Limit results (default: 10)
   -n, --no-cache   Skip cache
   -v, --verbose    Show debug output

=head1 EXAMPLES

    # Simple search
    searchmerge-cli perl programming

    # JSON output
    searchmerge-cli --json perl

    # Limit to 5 results
    searchmerge-cli --limit 5 perl

    # Verbose mode (see what's happening)
    searchmerge-cli -v perl web development

=head1 DESCRIPTION

SearchMerge CLI aggregates search results from multiple sources.

=cut
