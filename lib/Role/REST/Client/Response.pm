package Role::REST::Client::Response;

use 5.010;
use Moose;

has 'code' => (
    isa => 'Int',
    is  => 'ro',
);
has 'response' => (
    isa => 'HashRef | ArrayRef',
    is  => 'ro',
);
has 'error' => (
    isa => 'Str',
    is  => 'ro',
);
has 'data' => (
    isa => 'HashRef',
    is  => 'ro',
);

__PACKAGE__->meta->make_immutable;

1;
__END__
=head1 NAME

Role::REST::Client::Response - Response class for REST

=head1 METHODS

=head2 code

Returns the http status code of the request

=head2 response

Returns the raw HTTP::Tiny response. Use this if you need more information than status and content.

=head2 error

Returns the returned reason from HTTP::Tiny where the status is 500 or higher. 

=head2 data

Returns the deserialized data. Returns an empty hashref if the response was unsuccessful

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
