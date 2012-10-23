
# Class: HTTP::Spy::Request
#   User HTTP Request.
# Uses:
#   Pony::Object

package HTTP::Spy::Request;
use Pony::Object;
  
  # Accept type, encoding, lang, etc...
  public accept => {};
  # HTTP method. For example "POST", "GET".
  public method => '';
  # UserAgent.
  public ua => '';
  # Remote (User) address.
  public remote => '';
  # Host for request.
  public host => '';
  # Protocol.
  public proto => '';
  # Requested path.
  public path => '';
  # Requested file extension.
  public extension => '';
  # Requested URI.
  public uri => '';
  
  
  # Function: init
  #   Constructor.
  # Parameters:
  #   params - hash of params (see properties)
  
  sub init : Public
    {
      my $this = shift;
      my $params = shift;
      
      while ( my($key, $val) = each %$params )
      {
        $this->$key = $val;
      }
    }

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
