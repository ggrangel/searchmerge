package SearchMerge::Ranker;
use Modern::Perl;
use Moo;

sub rank {
    my ( $self, $results, $query ) = @_;

    my @ranked = map {
        {
            %$_, score => $self->calculate_score( $_, $query )
        }
    } @$results;

    @ranked = sort { $b->{score} <=> $a->{score} } @ranked;

    return \@ranked;
}

sub calculate_score {
    my ( $self, $result, $query ) = @_;

    # Simple scoring: check if query words appear in title
    my $score = 0;
    my $title = lc( $result->{title} || '' );

    for my $word ( split /\s+/, lc($query) ) {
        $score++ if index( $title, $word ) >= 0;
    }

    # Boost by source
    my %boost = (
        Wikipedia   => 2,
        OpenLibrary => 5,
        Reddit      => 0.5,
    );

    $score *= ( $boost{ $result->{source} } || 1 );

    return $score;
}

1;
