use strict;
use warnings;
use Test::More;

eval 'use JSON';
if ($@) {
	plan skip_all => 'Install JSON to run this test';
} else {
	plan tests => 8
};

use_ok( 'Role::REST::Client::Serializer' );
use_ok( 'Role::REST::Client::Response' );

# test JSON hashes / arrays
my $jtype = 'application/json';
my $json_array = '["foo","bar"]';
my $array_data = [qw/foo bar/];

ok (my $serializer = Role::REST::Client::Serializer->new(type => $jtype), "New $jtype type serializer");
is($serializer->content_type, $jtype, 'Content Type');
ok(my $sdata = $serializer->serialize($array_data), 'Serialize');
is($sdata, $json_array, 'Serialize data');
is_deeply($serializer->deserialize($sdata), $array_data, 'Deserialize');

ok(Role::REST::Client::Response->new(
    code => 200,
    response => {},
    data => $array_data,
), 'response accepted an arrayref');

