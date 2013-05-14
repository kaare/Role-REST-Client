package Role::REST::Client::Serializer;

use Try::Tiny;
use Moo;
use MooX::Types::MooseLike::Base qw/:all/;
use Data::Serializer::Raw;

has 'type' => (
	isa => Enum[qw{application/json application/xml application/yaml application/x-www-form-urlencoded}],
	is  => 'rw',
	default => sub { 'application/json' },
);

has 'serializer' => (
	isa => InstanceOf['Data::Serializer::Raw'],
	is => 'ro',
	default => \&_set_serializer,
	lazy => 1,
);

our %modules = (
	'application/json' => {
		module => 'JSON',
	},
	'application/xml' => {
		module => 'XML::Simple',
	},
	'application/yaml' => {
		module => 'YAML',
	},
	'application/x-www-form-urlencoded' => {
		module => 'FORM',
	},
);

sub _set_serializer {
	my $self = shift;
	return unless $modules{$self->type};

	my $module = $modules{$self->type}{module};
	return $module if $module eq 'FORM';

	return Data::Serializer::Raw->new(
		serializer => $module,
	);
}

sub content_type {
	my ($self) = @_;
	return $self->type;
}

sub serialize {
	my ($self, $data) = @_;
	return unless $self->serializer;

	my $result;
	try {
		$result = $self->serializer->serialize($data)
	} catch {
		warn "Couldn't serialize data with " . $self->type;
	};

	return $result;
}

sub deserialize {
	my ($self, $data) = @_;
	return unless $self->serializer;

	my $result;
	try {
		$result = $self->serializer->deserialize($data);
	} catch {
		warn "Couldn't deserialize data with " . $self->type;
	};

	return $result;
}

1;
