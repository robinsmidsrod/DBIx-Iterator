use strict;
use warnings;
package DBIx::Iterator;

# ABSTRACT: Query your database using iterators and save memory

use Carp qw(confess);
use DBIx::Iterator::Statement;

=method new($dbh)

Creates a new iterator factory connected to the specified database handle.

=cut

sub new {
    my ($class, $dbh) = @_;
    confess("Please specify a database handle") unless defined $dbh;
    return bless {
        'dbh' => $dbh,
    }, $class;
}

=method dbh

Returns the database handle provided to new().

=cut

sub dbh {
    my ($self) = @_;
    return $self->{'dbh'};
}

=method prepare($query)

Asks the database engine to parse the query and return a statement object
that can be used to execute the query with optional parameters.

=cut

sub prepare {
    my ($self, $query) = @_;
    confess("Please specify a database query") unless defined $query;
    return DBIx::Iterator::Statement->new($query, $self);
}

=method query($query, @placeholder_values)

Executes the query with the optional placeholder values.  Returns a code
reference you can execute until it is exhausted.  If called in list context,
it will also return a reference to the statement object itself.  The
iterator returns exactly what L<DBI/fetchrow_hashref> returns.  When the
iterator is exhausted it will return undef.

=cut

sub query {
    my ($self, $query, @placeholder_values) = @_;
    confess("Please specify a query") unless defined $query;
    return $self->prepare($query)->execute(@placeholder_values);
}

1;

=head1 SYNOPSIS

    # Create an iterator for a simple DBI query
    my $db = DBIx::Iterator->new( DBI->connect('...') );
    my $it = $db->query("SELECT id, name FROM person");
    while ( my $row = $it->() ) {
        say $row->{'id'} . ": " . $row->{'name'};
        # Do something with $row...
    }

    # We have a basic class here that knows nothing about iterators
    package Person;
    use Moose;

    has 'id'   => ( is => 'ro', isa => 'Int' );
    has 'name' => ( is => 'ro', isa => 'Str' );

    sub label {
        my ($self) = @_;
        return $self->id . ": " . $self->name;
    }

    # Then we have a role that knows how to create instances
    # from iterators
    package FromIterator;
    use Moose::Role;

    sub new_from_iterator {
        my ($self, $it) = @_;
        return sub {
            my $row = $it->();
            return unless defined $row;
            return $self->new($row);
        }
    }

    # Then we apply the role to the Person class and use
    # our plain database iterator that produces hashes to
    # now create Person instances instead.

    package main;
    use Moose::util qw(apply_all_roles);
    my $p = apply_all_roles('Person', 'FromIterator');
    my $it = $p->new_from_iterator(
        $db->query("SELECT * FROM person")
    );
    while ( my $person = $it->() ) {
        say $person->label;
        # Do something with $person...
    }


=head1 DESCRIPTION

Iterators are a nice way to perform operations on large datasets without
having to keep all of the data you're working on in memory at the same time.
Most people have experience with iterators already from working with
filehandles.  They are basically iterators hidden behind a somewhat odd
syntax.  This module gives you the same way of executing database queries.

The trivial example at the start of the synopsis is not very different from
using L<DBI/fetchrow_hashref> directly to retrieve your database rows.  But
when we look at the second example we can start to see how it allows much
cleaner separation of concerns without having to modify the core class
(Person) to support iterators or database interaction at all.

For more information about iterators and how they can work for you, have a
look at chapter 4 in the book Higher-Order Perl mentioned below.  It is free
to download and highly recommended.


=head1 SEE ALSO

=for :list
* L<Higher-Order Perl by Mark Jason Dominus, page 163-173|http://hop.perl.plover.com/>
* L<Iterator>


=head1 SEMANTIC VERSIONING

This module uses semantic versioning concepts from L<http://semver.org/>.

=cut
