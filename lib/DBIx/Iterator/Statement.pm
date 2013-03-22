#!perl

use strict;
use warnings;

package DBIx::Iterator::Statement;

# ABSTRACT: Query your database using iterators and save memory

use Carp qw(confess);

=method new($query, $db)

Creates a database statement object that can be used to bind parameters and
execute the query.

=cut

sub new {
    my ($class, $query, $db) = @_;
    confess("Please specify a database query") unless defined $query;
    confess("Please specify a database iterator factory") unless defined $db;
    my $sth = $db->dbh->prepare($query);
    return bless {
        'sth'   => $sth,
        'db'    => $db,
    }, $class;
}

=method db

Returns the database object specified in the constructor.

=cut

sub db {
    my ($self) = @_;
    return $self->{'db'};
}

=method sth

Returns the DBI statement handle associated with the prepared statement.

=cut

sub sth {
    my ($self) = @_;
    return $self->{'sth'};
}

=method bind_param(@args)

Specifies bind parameters for the query as defined in L<DBI/bind_param>.

=cut

## no critic (Subroutines::RequireArgUnpacking)
sub bind_param {
    my $self = shift;
    return $self->sth->bind_param(@_);
}
## use critic

=method execute(@placeholder_values)

Executes the prepared query with the optional placeholder values.  Returns a
code reference you can execute until it is exhausted.  If called in list
context, it will also return a reference to the statement object itself.
The iterator returns exactly what L<DBI/fetchrow_hashref> returns.  When the
iterator is exhausted it will return undef.

=cut

## no critic (Subroutines::RequireArgUnpacking)
sub execute {
    my $self = shift;
    $self->sth->execute(@_);
## use critic
    return sub {
        my $row = $self->sth->fetchrow_hashref();
        return $row, $self if wantarray;
        return $row;
    };
}

1;
