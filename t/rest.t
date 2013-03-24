use Test::More;
use Test::Deep;
use HTTP::Response;
use HTTP::Headers;
use HTTP::Request;
use utf8;

{
	package RESTExample;

	use Moose;
	with 'Role::REST::Client';

	sub bar {
		my ($self) = @_;
		return $self->post('foo/bar/baz', {foo => 'bar'});
        }

        sub baz {
		my ($self) = @_;
		return $self->post('foo/bar/baz', {foo => 'bar', bar => 'baz' });
        }
}
{
  package UAClass;
  use Moose;
  use JSON;
  use Test::More;
  has 'timeout' => ( is => 'ro', isa => 'Int' );
  sub request {
    my ( $self, $method, $uri, $opts ) = @_;
    ok(!ref($opts->{'content'}), 'content key must be a scalar value due content-type');
    if ( lc $method eq 'post' ) {
      like($opts->{'content'}, qr{foo\=bar}, 'no serialization should happen');
    }
    my $req = HTTP::Request->new($method => $uri);
    my $json = encode_json({ error => 'Resource not found' });
    my $headers = HTTP::Headers->new('Content-Type' => 'application/json');
    my $res = HTTP::Response->new(404, 'Not Found', $headers, $json);
    $res->request($req);
    return $res;
  }
}
my $ua = UAClass->new(timeout => 5);
my $persistent_headers = { 'Accept' => 'application/json' };
my %testdata = (
	server => 'http://localhost:3000',
	type => 'application/x-www-form-urlencoded',
	user_agent => $ua,
        persistent_headers => $persistent_headers,
);
ok(my $obj = RESTExample->new(%testdata), 'New object');
isa_ok($obj, 'RESTExample');

for my $item (qw/post get put delete _call httpheaders/) {
    ok($obj->can($item), "Role method $item exists");
}

is_deeply($obj->httpheaders, $persistent_headers,
  'headers should include persistent ones since first request');
ok(my $res = $obj->bar, 'got a response object');
is_deeply($obj->httpheaders, $persistent_headers,
  'after first request, it contains persistent ones');
isa_ok($res, 'Role::REST::Client::Response');
isa_ok($res->response, 'HTTP::Response');
is($res->data->{'error'}, 'Resource not found', 'deserialization works');

$obj->set_header('X-Foo', 'foo');
is_deeply($obj->httpheaders, {
  %$persistent_headers,
  'X-Foo', 'foo',
});

$obj->reset_headers; # which would be like ->httpheaders($persistent_headers);
is_deeply($obj->httpheaders, $persistent_headers,
  'should have at least persistent_headers');

ok(!exists($obj->persistent_headers->{'X-Foo'}));
ok($res = $obj->bar, 'got a response obj');
ok(!exists($obj->persistent_headers->{'content-length'}));
ok($res = $obj->baz, 'got a response obj');
ok(!exists($obj->persistent_headers->{'content-length'}));

$obj->clear_headers;
is_deeply($obj->httpheaders, {}, 'new fresh httpheaders without persistent ones');

ok($obj = RESTExample->new({ %testdata, httpheaders => { 'X-Foo' => 'foo' } }));
is_deeply($obj->httpheaders, {
  %$persistent_headers,
  'X-Foo', 'foo',
}, 'merge httpheaders with persistent_headers');
ok($res = $obj->bar, 'got a response object');
is_deeply($obj->httpheaders, $persistent_headers,
  'after first request, it contains persistent ones');

ok($res = $obj->get('/getendpoint', { param => 'büz' }));
like($res->response->request->uri, qr{param=b%C3%BCz});

done_testing;
