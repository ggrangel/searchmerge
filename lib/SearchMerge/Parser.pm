package SearchMerge::Parser;
use Modern::Perl;
use Moo;
use JSON::XS     qw( decode_json );
use Try::Tiny    qw( catch try );
use Data::Dumper ();

sub parse_source {
    my ( $self, $source_name, $response ) = @_;

    return [] unless $response && $response->is_success;

    my $method = "parse_" . lc($source_name);
    if ( $self->can($method) ) {
        return $self->$method($response);
    }

    warn "No parser for source: $source_name";
    return [];
}

sub parse_wikipedia {
    my ( $self, $response ) = @_;

    try {
        my $data = decode_json( $response->body );

        # Wikipedia returns: [query, [titles], [descriptions], [urls]]
        my ( $query, $titles, $descriptions, $urls ) = @$data;

        my @results;

        # $# => last index from the array reference
        for my $i ( 0 .. $#$titles ) {
            push @results,
              {
                title   => $titles->[$i],
                snippet => $descriptions->[$i] || '',
                url     => $urls->[$i],
                source  => 'Wikipedia',
                score   => 0,
              };
        }
        return \@results;
    }
    catch {
        warn "Failed to parse Wikipedia response: $_";
        return [];
    };
}

sub parse_openlibrary {
    my ( $self, $response ) = @_;

    try {
        my $data = decode_json( $response->body );
        my @results;

        for my $doc ( @{ $data->{docs} || [] } ) {
            push @results,
              {
                title   => $doc->{title} || 'Untitled',
                snippet => join(
                    ", ",
                    grep { defined } (
                        $doc->{author_name}
                        ? "by " . join( ", ", @{ $doc->{author_name} } )
                        : undef,
                        $doc->{first_publish_year}
                        ? "($doc->{first_publish_year})"
                        : undef
                    )
                ),
                url      => "https://openlibrary.org" . ( $doc->{key} || '' ),
                source   => 'OpenLibrary',
                score    => 0,
                metadata => {
                    year    => $doc->{first_publish_year},
                    authors => $doc->{author_name},
                }
              };
        }
        return \@results;
    }
    catch {
        warn "Failed to parse OpenLibrary response: $_";
        return [];
    };
}

# sub parse_reddit {
#     my ( $self, $response ) = @_;
#
#     try {
#         my $data = decode_json( $response->body );
#         my @results;
#
#         for my $child ( @{ $data->{data}{children} || [] } ) {
#             my $post = $child->{data};
#             push @results,
#               {
#                 title    => $post->{title},
#                 snippet  => substr( $post->{selftext} || '', 0, 200 ),
#                 url      => "https://reddit.com" . $post->{permalink},
#                 source   => 'Reddit',
#                 score    => 0,
#                 metadata => {
#                     upvotes   => $post->{score},
#                     comments  => $post->{num_comments},
#                     subreddit => $post->{subreddit},
#                 }
#               };
#         }
#         return \@results;
#     }
#     catch {
#         warn "Failed to parse Reddit response: $_";
#         return [];
#     };
# }

1;

