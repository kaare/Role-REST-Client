use Test::More;
use MooseX::Declare;
use HTTP::Response;
use HTTP::Headers;

{
	package RESTExample;

	use Moose;
	with 'Role::REST::Client';

	sub bar {
		my ($self) = @_;
		return $self->post('foo/bar/baz', {foo => 'bar'});
        }
}

my $ua_class = class {
  use JSON;
  use Test::More;
  sub request {
    my $opts = pop;
    ok(!ref($opts->{'content'}), 'content key must be a scalar value due content-type');
    is($opts->{'content'}, 'foo=bar', 'no serialization should happen');
    my $json = encode_json({ error => 'Resource not found' });
    my $headers = HTTP::Headers->new('Content-Type' => 'application/json');
    return HTTP::Response->new(404, 'Not Found', $headers, $json);
  }
};
my $ua = $ua_class->name->new(timeout => 5);
my %testdata = (
	server => 'http://localhost:3000',
	type => 'application/x-www-form-urlencoded',
	user_agent => $ua,
);
ok(my $obj = RESTExample->new(%testdata), 'New object');
isa_ok($obj, 'RESTExample');

for my $item (qw/post get put delete _call httpheaders/) {
    ok($obj->can($item), "Role method $item exists");
}

ok(my $res = $obj->bar, 'got a response object');
isa_ok($res, 'Role::REST::Client::Response');
isa_ok($res->response, 'HTTP::Response');
is($res->data->{'error'}, 'Resource not found', 'deserialization works');

done_testing;
