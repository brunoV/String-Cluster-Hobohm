package String::Cluster::Hobohm;

# ABSTRACT: Cluster strings using the Hobohm algorithm

use strict;
use warnings;

use Mouse;
use String::Cluster::Hobohm::Types 'Quotient';
use Carp 'croak';
use Text::LevenshteinXS;
use namespace::autoclean;

# accept a list of strings or a closure that returns, stepwise, the
# strings (this prevents loading everything into memory in the case that
# the dataset is too big)

# Return, for now, a structure with the indices
# {
#    index1 => [ index2, index3, index4 ]
#    ...
# }

has similarity => ( is => 'ro', default => 0.62, isa => Quotient );

sub cluster {
    my ($self, $sequences) = @_;
    defined $sequences or croak "Need sequences as argument";

    my @clusters;

    foreach my $sequence (@$sequences) {

        my $cluster_id = $self->_is_similar( $sequence, \@clusters );

        if ( defined $cluster_id ) {
            push @{ $clusters[ $cluster_id ] }, \$sequence;
        }
        else {
            push @clusters, [ \$sequence ]
        }
    }

    return \@clusters;
}

sub _is_similar {
    my ($self, $sequence, $clusters ) = @_;

    foreach my $i (0 .. $#$clusters) {
        my $similarity = $self->_similarity(\$sequence, $clusters->[$i][0]);

        return $i if $similarity >= $self->similarity;
    }

    return;
}

sub _similarity {
    my $self = shift;

    my @seqs = map { $$_ } @_;

    my $distance = Text::LevenshteinXS::distance(@seqs);
    defined $distance or croak "unable to compute distance";

    return 1 - $distance / (length( $seqs[0] ) || 1);
}

__PACKAGE__->meta->make_immutable;

=head1 SYNOPSIS

    use String::Cluster::Hobohm;

    my @strings = qw(foo foa bar);

    my $clusterer = String::Cluster::Hobohm->new( similarity => 0.62 );

    my $groups = $clusterer->cluster( \@strings );

    # [ [ \'foo', \'foa' ], [ \'bar' ] ];

    my @reduced = map { ${ $_->[0] } } @$groups;

    # [ 'foo', 'bar' ];

=head1 DESCRIPTION

String::Cluster::Hobohm implements the Hobohm clustering algorithm
[1], originally devised to reduce redundancy of biological sequence data
sets.

As a clustering algorithm, it takes a set of sequences, and returns them
grouped by similarity. The latter is computed using the Levenshtein
distance, as implemented by the C<Text::LevenshteinXS> module.

=attr similarity

The similarity threshold that defines whether two strings are
sufficiently alike to be part of the same cluster. Should be a number
between 0 and 1. Defaults to 0.62.

=method cluster

    my $grouped = $hobohm->cluster( \@strings );

Takes an array reference with the sequences to cluster as argument, and
returns an array reference of clusters. Each cluster is depicted as a
list of references to the strings that define it.

For example, given the following array of strings, and a similarity of
0.62:

    [ 'foo', 'foa', 'bar' ];

The data structure returned after clustering would be:

    [ [ \'foo', \'foa' ], [ \'bar' ] ];

The reason for using references instead of the actual strings is to avoid
copying potentially large strings and taking up too much memory (remember that
the algorithm was designed with biological sequences in mind).

=head1 REFERENCES

[1] Uwe Hobohm, Michael Scharf, Reinhard Schneider and Chris Sander.
Selection of representative protein data sets. Protein Science (1992),
409-417. Cambridge University Press.

=cut
