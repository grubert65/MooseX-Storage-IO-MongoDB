use strict;
use warnings;
use Test::More;
use MongoDB;
use TryCatch;

#First, configure your Moose class via a call to Storage:

BEGIN {

  my $client   = MongoDB::MongoClient->new();
  foreach ( qw( TestCollection TestCollection2 ) ) {
      try {
        my $collection = $client->ns( "TESTDB.".$_ );
        $collection->drop() if ( $collection->count() );
    } catch ( $err ) {
        diag "Error dropping a collection: $err";
    }
  }

  package MyDoc;
  use Moose;
  use MooseX::Storage;

  with Storage(
      'format' => 'JSON', 
      io => [ 'MongoDB' => {
          key_attr   => 'doc_id',   # which attribute should keep the unique id
          database   => 'TESTDB',
          collection => 'TestCollection',
  }]);

  has 'doc_id'  => (is => 'ro', isa => 'Str', required => 1);
  has 'title'   => (is => 'rw', isa => 'Str');
  has 'body'    => (is => 'rw', isa => 'Str');
  has 'tags'    => (is => 'rw', isa => 'ArrayRef');
  has 'authors' => (is => 'rw', isa => 'HashRef');

  1;

  package MyDoc2;
  use Moose;
  use MooseX::Storage;

  with Storage(
      'format' => 'JSON', 
      io => [ 'MongoDB' => {
          key_attr   => 'doc_id',   # which attribute should keep the unique id
          database   => 'TESTDB',
          collection => 'TestCollection2',
          connect_timeout_ms => 30000
  }]);

  has 'doc_id'  => (is => 'ro', isa => 'Str', required => 1);
  has 'title'   => (is => 'rw', isa => 'Str');
  has 'body'    => (is => 'rw', isa => 'Str');
  has 'tags'    => (is => 'rw', isa => 'ArrayRef');
  has 'authors' => (is => 'rw', isa => 'HashRef');

  1;

}

#Now you can store/load your class to the cache you defined in cache_args:

BEGIN {
    use_ok( 'MooseX::Storage::IO::MongoDB' ) || print "Bail out!\n";
    use_ok( 'MyDoc' );
}

diag( "Testing MooseX::Storage::IO::MongoDB $MooseX::Storage::IO::MongoDB::VERSION, Perl $], $^X" );

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

  # Save it to cache (will be stored using key "mydoc-foo12")
  # if no key attribute 
is( MyDoc->exists('foo12'), undef, "ok, object doesn't exist yet...");
ok( my $doc_id = $doc->store(), 'store' );
ok( MyDoc->exists('foo12'), "ok, object now exists...");

# Load the saved data into a new instance
my $doc2 = MyDoc->load('foo12');

# This should say 'Bob Smith'
is ( $doc2->authors->{bsmith}{name}, 'Bob Smith', 'got right data back' );

$doc2->authors->{bsmith}{name} = 'Bob Smith Junior';

ok( $doc2->store(), 'storing again...');
my $doc3 = MyDoc->load('foo12');

# This should say now 'Bob Smith Junior'
is ( $doc3->authors->{bsmith}{name}, 'Bob Smith Junior', 'got right data back' );
# this only to check that actually the same
# collection object is used...
ok( my $doc4 = MyDoc2->new(
      doc_id   => 'foo-bar',
      title    => 'Foo Bar',
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
  ), 'creating a MyDoc2 doc...');
ok( $doc4->store(), 'storing...' );

ok( my $doc5 = MyDoc2->new(
      doc_id   => 'foo-bar-baz',
      title    => 'Foo Bar Baz',
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
  ), 'creating another MyDoc2 doc...');
ok( $doc5->store(), 'and storing it...' );

done_testing;
