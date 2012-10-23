
# Class: HTTP::Spy::WebServer
#   WebServer wrapper.
# Uses:
#   Pony::Object
#   HTTP::Daemon;

package HTTP::Spy::WebServer;
use Pony::Object;
  
  use HTTP::Daemon;
  use HTTP::Status;
  
  protected _driver => undef;
  
  
  # Function: init
  #   Constructor
  # Parameters:
  #   host - listening host
  #   port - listening port
  
  sub init : Public
    {
      my $this = shift;
      my $host = shift;
      my $port = shift;
      
      $this->_driver = HTTP::Daemon->new(LocalAddr => $host, LocalPort => $port)
        or die "Cannot initialize proxy server: $!";
    }
  
  
  # Function: loop
  #   Runs on each http request.
  # Parameters:
  #   action - anonymous function - do it!
  
  sub loop : Public
    {
      my $this = shift;
      my $action = shift;
      
      while ( 1 )
      {
        eval
        {
          while ( my $c = $this->_driver->accept )
          {
            while ( my $r = $c->get_request )
            {
              $c->send_response( $action->($r) );
            }
            
            $c->close;
            #undef($c);
          }
          
          sleep 1;
        }
      }
    }
  
1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
