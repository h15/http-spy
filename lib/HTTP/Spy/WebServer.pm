
# Class: HTTP::Spy::WebServer
#   WebServer wrapper.
# Uses:
#   Pony::Object
#   HTTP::Daemon;

package HTTP::Spy::WebServer;
use Pony::Object;
  
  use HTTP::Spy::WebServer::HTTPDaemon;
  use threads;
  
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
      
      $this->_driver = HTTP::Spy::WebServer::HTTPDaemon
                        ->new->init(LocalAddr => $host, LocalPort => $port)
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
      
      while ( my $c = $this->_driver->accept )
      {
        threads->create(\&service, $c, $action)->detach;
        $c->close;  # close client socket in server
      }
    }
  
  sub service
    {
      my $c = shift;
      my $action = shift;
      $c->daemon->close;
      
      while ( my $r = $c->get_request )
      {
        my $resp = $action->($r);
        
        if ( ref $resp eq 'HASH' )
        {
          $c->send_file_response( $resp->{path} );
        }
        elsif ( ref $resp eq 'ARRAY' )
        {
          $c->send_response( $resp->[0] );
          print $c $resp->[1];
        }
        else
        {
          $c->send_response( $resp );
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
