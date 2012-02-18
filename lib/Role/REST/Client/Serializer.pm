package Role::REST::Client::Serializer;
use 5.010;
use Try::Tiny;
use Moose;
use Moose::Util::TypeConstraints;

use Data::Serializer;

has 'type' => (
    isa => enum ([qw{application/json application/xml application/yaml application/x-www-form-urlencoded}]),
    is  => 'rw',
	default => 'application/json',
);
no Moose::Util::TypeConstraints;
has 'serializer' => (
	isa => 'Data::Serializer',
	is => 'ro',
	default => \&_set_serializer,
	lazy => 1,
);

no Moose;

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

	return Data::Serializer->new(
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
		$result = $self->serializer->raw_serialize($data)
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
		$result = $self->serializer->raw_deserialize($data);
	} catch {
		warn "Couldn't deserialize data with " . $self->type;
	};

	return $result;
}

1;
