package MooseX::Storage::IO::MongoDB;

=encoding utf-8

=head1 NAME

MooseX::Storage::IO::MongoDB - Store and retrieve Moose objects to and from a L<MongoDB> collection.

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

First, configure your Moose class via a call to Storage:

  package MyDoc;
  use Moose;
  use MooseX::Storage;

  with Storage(io => [ 'MongoDB' => {
      key_attr=> 'doc_id',              # which attribute should keep the unique id
      host   => 'my-mongodb-host.com',  # defaults to localhost
      port   => $port,                  # defaults to 27017
      collection    => 'my-collection',
  }]);

  has 'doc_id'  => (is => 'ro', isa => 'Str', required => 1);
  has 'title'   => (is => 'rw', isa => 'Str');
  has 'body'    => (is => 'rw', isa => 'Str');
  has 'tags'    => (is => 'rw', isa => 'ArrayRef');
  has 'authors' => (is => 'rw', isa => 'HashRef');

  1;

Now you can store/load your class:

  use MyDoc;

  # Create a new instance of MyDoc
  my $doc = MyDoc->new(
      doc_id   => 'foo12',
      title    => 'Foo',
      body     => 'blah blah',
      tags     => [qw(horse yellow angry)],
      authors  => {
          jdoe => {
              name  => 'John Doe',
              email => 'jdoe@gmail.com',
              roles => [qw(author reader)],
          },
          bsmith => {
              name  => 'Bob Smith',
              email => 'bsmith@yahoo.com',
              roles => [qw(editor reader)],
          },
      },
  );

  # Save it to cache (will be stored using key "foo12")
  # if no key attribute 
  my $doc_id = $doc->store();

  # Load the saved data into a new instance
  my $doc2 = MyDoc->load('foo12');

  # This should say 'Bob Smith'
  print $doc2->authors->{bsmith}{name};

=head1 DESCRIPTION

MooseX::Storage::IO::MongoDB is a Moose role that provides an io layer for L<MooseX::Storage> to store/load your Moose objects to a MongoDB database, as MongoDB documents.

You should understand the basics of L<Moose>, L<MooseX::Storage>, and L<MongoDB> before using this module.

At a bare minimum the consuming class needs to give this role a L<MongoDB> configuration, and a field to use as a unique key.

=head1 PARAMETERS

Following are the parameters you can set when consuming this role that configure it in different ways.

=head2 key_attr

"key_attr" is a required parameter when consuming this role.  It specifies an attribute in your class that will provide the value to use as the MongoDB unique key when storing your object via L<MongDB>.

=head2 host

The MongoDB host, defaults to localhost.

=head2 port

The MongoDB port, defaults to 27017

=head2 collection

The MongoDB collection where the document should be stored.

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=cut

use strict;
use MongoDB;
use MooseX::Role::Parameterized;
use namespace::autoclean;
use Try::Tiny;
use Carp;

#HISTORY
# 0.01 | 04.06.2015 | First version
our $VERSION='0.01';

parameter key_attr => (
    is       => 'rw',
    isa      => 'Str',
);

parameter host => ( 
    isa     => 'Str',
    default => 'localhost',
);

parameter port => ( 
    isa     => 'Int',
    default => 27017,
);

parameter database => (
    isa      => 'Str',
    required => 1,
);

parameter collection => ( 
    isa      => 'Str',
    required => 1,
);

role {
    my $p = shift;

    requires 'pack';
    requires 'unpack';

    method _get_collection => sub { 
        try {
            my $client = MongoDB::MongoClient->new(
                host => $p->host, 
                port => $p->port
            ); 

            my $database = $client->get_database( $p->database )
                or die "Error connecting to database: $@";

            return $database->get_collection( $p->collection );
        } catch {
            croak "Error: $_";
        };
    };

    has 'collection' => (
        is      => 'ro',
        isa     => 'MongoDB::Collection',
        lazy    => 1,
        traits  => [ 'DoNotSerialize' ],
        default => sub { shift->_get_collection() },
    );

#=============================================================

=head2 store

=head3 INPUT

=head3 OUTPUT

    doc id/undef in case of errors

=head3 DESCRIPTION

    Stores data, dies in case of errors.
    In case an object with the same id is already stored
    it is replaced with the new one.
    Returns the MongoDB unique document id.

=cut

#=============================================================
method store => sub {
    my $self = shift;
    my $key_attr = $p->key_attr;
    my $key_val = $self->$key_attr;

    # we need to pass hash refs to MongoDB
    # so we don't freeze/thaw here
    # (don't need to serialize the object as for other
    # drivers, MongoDB does it for us...)
    my $data;
    $data = $self->pack;
    try {
        return $self->collection->update( 
            { $key_attr => $key_val }, 
            $data, 
            { "safe" => 1, "upsert" => 1 } );
    } catch {
        die ("Error inserting doc: $_");
    };
};

#=============================================================

=head2 load

=head3 INPUT

    $key_value : the value of the key attribute

=head3 OUTPUT

The object or undef in case of error.

=head3 DESCRIPTION

Gets the collection object, search for the document with
the passed id value, returns the blessed document.

=cut

#=============================================================
    method load => sub {
        my ( $class, $key_value, %args ) = @_;

        my $collection = $class->_get_collection()
            or die "Error getting the collection: $@";

        my $key_attr = $p->key_attr;
        $key_value // die "undefined value for key attr $key_attr";

        my $data = $collection->find_one( { $key_attr => $key_value } )
            or return undef;

        my $obj;
        $obj = $class->unpack($data, %args);
        return $obj;
    };
};

1;
__END__

=encoding utf-8

=head1 AUTHOR

Marco Masetti, E<lt>grubert65@gmail.comE<gt>

=head1 BUGS

Please report any bugs or feature requests to C<bug-moosex-storage-io-mongodb at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooseX-Storage-IO-MongoDB>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MooseX::Storage::IO::MongoDB

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooseX-Storage-IO-MongoDB>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MooseX-Storage-IO-MongoDB>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MooseX-Storage-IO-MongoDB>

=item * Search CPAN

L<http://search.cpan.org/dist/MooseX-Storage-IO-MongoDB/>

=back

=head1 COPYRIGHT

Copyright 2015 Marco Masetti E<lt>grubert65@gmail.comE<gt>.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1; # End of MooseX::Storage::IO::MongoDB
