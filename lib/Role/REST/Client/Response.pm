package Role::REST::Client::Response;

use Moose;

has 'code' => (
	isa => 'Int',
	is  => 'ro',
);
has 'response' => (
	isa => 'HTTP::Response',
	is  => 'ro',
);
has 'error' => (
	isa => 'Str',
	is  => 'ro',
	predicate => 'failed',
);
has 'data_callback' => (
	init_arg => 'data',
	traits  => ['Code'],
	isa => 'CodeRef', is  => 'ro',
	default => sub { sub { {} } },
	handles => { data => 'execute' },
);

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Role::REST::Client::Response - Response class for REST

=head1 SYNOPSIS

    my $res = Role::REST::Client::Response->new(
        code          => '200',
        response      => HTTP::Response->new(...),
        error         => 0,
        data_callback => sub { sub { ... } },
    );

=head1 ATTRIBUTES

=head2 code

HTTP status code of the request

=head2 response

L<HTTP::Response> object. Use this if you need more information than status and content.

=head2 error

The returned reason from L<HTTP::Tiny> where the status is 500 or higher. More detail may be provided 
by calling C<< $res->response->content >>.

=head2 failed

True if the request didn't succeed.

=head2 data

The deserialized data. Returns an empty hashref if the response was unsuccessful.

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
