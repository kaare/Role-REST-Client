package Role::REST::Client;

use 5.010;
use Moose::Role;
use Moose::Util::TypeConstraints;
use HTTP::Tiny;
use URI::Escape;
use Try::Tiny;

use Carp qw(confess);
use Role::REST::Client::Serializer;
use Role::REST::Client::Response;

has 'server' => (
    isa => 'Str',
    is  => 'rw',
	lazy    => 1,
	builder => '_build_server',
);
has 'type' => (
    isa => enum ([qw{application/json application/xml application/yaml application/x-www-form-urlencoded}]),
    is  => 'rw',
	default => 'application/json',
);
has clientattrs => (isa => 'HashRef', is => 'ro', default => sub {return {} });

no Moose::Util::TypeConstraints;

sub _build_server {
	my ($self) = @_;
	$self->{server} ||= $self->config->{server} if $self->config->{server};
}

sub _serializer {
	my ($self, $type) = @_;
	$type ||= $self->type;
	$type =~ s/;\s*?charset=.+$//i; #remove stuff like ;charset=utf8
	try {
		$self->{serializer}{$type} ||= Role::REST::Client::Serializer->new(type => $type);
	}
	catch {
		# Deal with real life content types like "text/xml;charset=ISO-8859-1"
		warn "No serializer available for " . $type . " content. Trying default " . $self->type;
		$self->{serializer}{$type} = Role::REST::Client::Serializer->new(type => $self->type);
	};
	return $self->{serializer}{$type};
}

sub _ua {
	my ($self) = @_;
	$self->{ua} ||= HTTP::Tiny->new(%{$self->clientattrs});
	return $self->{ua};
}

sub _call {
	my ($self, $method, $endpoint, $data, $args) = @_;
	my $uri = $self->server.$endpoint;
	# If no data, just call endpoint (or uri if GET w/parameters)
	# If data is a scalar, call endpoint with data as content (POST w/parameters)
	# Otherwise, encode data
	my %options = (
		headers => { 'content-type' => $self->_serializer->content_type },
	);
	$options{content} = ref $data ? $self->_serializer->serialize($data) : $data if defined $data;
	my $res = $self->_ua->request($method, $uri, \%options);
	# Return an error if status 5XX
	return Role::REST::Client::Response->new(
		code => $res->{status},
		response => $res,
		error => $res->{reason},
	) if $res->{status} > 499;

	# Try to find a serializer for the result content
	my $content_type = $args->{deserializer} || $res->{headers}{content_type} || $res->{headers}{'content-type'};
	my $deserializer = $self->_serializer($content_type);
	# Try to deserialize
	my $content;
	$content = $deserializer->deserialize($res->{content}) if $deserializer && $res->{content};
	$content ||= {};
	return Role::REST::Client::Response->new(
		code => $res->{status},
		response => $res,
		data => $content,
	);
}

sub get {
	my ($self, $endpoint, $data, $args) = @_;
	my $uri = $endpoint;
	if (my %data = %{ $data || {} }) {
		$uri .= '?' . join '&', map { uri_escape($_) . '=' . uri_escape($data{$_})} keys %data;
	}
	return $self->_call('GET', $uri, undef, $args);
}

sub post {
	my $self = shift;
	my ($endpoint, $data, $args) = @_;
	if ($self->type =~ /urlencoded/ and my %data = %{ $data }) {
		my $content = join '&', map { uri_escape($_) . '=' . uri_escape($data{$_})} keys %data;
		return $self->_call('POST', $endpoint, $content, $args);
	}
	return $self->_call('POST', @_);
}

sub put {
	my $self = shift;
	return $self->_call('PUT', @_);
}

sub delete {
	my $self = shift;
	return $self->_call('DELETE', @_);
}

sub options {
	my $self = shift;
	return $self->_call('OPTIONS', @_);
}

1;
__END__
# ABSTRACT: REST Client Role
=pod

=head1 NAME

Role::REST::Client - REST Client Role

=head1 SYNOPSIS

    {
        package RESTExample;

        use Moose;
        with 'Role::REST::Client';

        sub bar {
            my ($self) = @_;
            my $res = $self->post('foo/bar/baz', {foo => 'bar'});
            my $code = $res->code;
            my $data = $res->data;
            return $data if $code == 200;
       }

    }

    my $foo = RESTExample->new( 
        server =>      'http://localhost:3000',
        type   =>      'application/json',
        clientattrs => {timeout => 5},
    );

    $foo->bar;

    # controller
    sub foo : Local {
        my ($self, $c) = @_;
        my $res = $c->model('MyData')->post('foo/bar/baz', {foo => 'bar'});
        my $code = $res->code;
        my $data = $res->data;
        ...
    }

=head1 DESCRIPTION

This REST Client role makes REST connectivety easy.

Role::REST::Client will handle encoding and decoding when using the four HTTP verbs.

	GET
	PUT
	POST
	DELETE

Currently Role::REST::Client supports these encodings

	application/json
	application/x-www-form-urlencoded
	application/xml
	application/yaml

x-www-form-urlencoded only works for GET and POST, and only for encoding, not decoding.

=head1 METHODS

=head2 methods

Role::REST::Client implements the standard HTTP 1.1 verbs as methods

	post
	get
	put
	delete

All methods take these parameters

	url - The REST service
	data - The data structure (hashref, arrayref) to send. The data will be encoded
		according to the value of the I<type> attribute.
	args - hashref with arguments to augment the way the call is handled.

args - the optional argument parameter can have these entries

	deserializer - if you KNOW that the content-type of the response is incorrect,
	you can supply the correct content type, like

	my $res = $self->post('foo/bar/baz', {foo => 'bar'}, {deserializer => 'application/yaml'});


All methods return a L<Role::REST::Client::Response> object.

=head1 ATTRIBUTES

=head2 server

Url of the REST server.

e.g. 'http://localhost:3000'

=head2 type

Mime content type,

e.g. application/json

=head2 clientattrs

Attributes to feed HTTP::Tiny

e.g. {timeout => 10}

=head1 AUTHOR

Kaare Rasmussen, <kaare at cpan dot com>

=head1 BUGS 

Please report any bugs or feature requests to bug-role-rest-client at rt.cpan.org, or through the
web interface at http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Role-REST-Client.

=head1 COPYRIGHT & LICENSE 

Copyright 2012 Kaare Rasmussen, all rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as 
Perl itself, either Perl version 5.8.8 or, at your option, any later version of Perl 5 you may 
have available.
