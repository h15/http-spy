
# Class: HTTP::Spy::UserAgent
#   UserAgent wrapper.
# Uses:
#   Pony::Object
#   LWP::UserAgent
#   HTTP::Request

package HTTP::Spy::UserAgent;
use Pony::Object;
  
  use LWP::UserAgent;
  use HTTP::Request;
  
  protected _timeout   => 100;
  protected _keepAlive => 1;
  protected _envProxy  => 0;
  protected _parseHead => 1;
  protected _driver    => undef;
  
  
  # Function: init
  #   Constructor.
  # Parameters:
  #   params - hash UserAgent params
  
  sub init : Public
    {
      my $this = shift;
      my $params = shift;
      
      while ( my($key, $val) = each %$params )
      {
        # Little Pony-hack.
        # Will init _timeout and other properties.
        $this->{'_'.$key} = $val;
      }
      
      # Init UserAgent driver.
      $this->_driver = LWP::UserAgent->new(
        env_proxy  => $this->_envProxy,
        keep_alive => $this->_keepAlive,
        parse_head => $this->_parseHead,
        timeout    => $this->_timeout,
      )
      or die "Cannot initialize proxy agent: $!";
    }
  
  
  # Function: send
  #   Send HTTP request.
  # Parameters:
  #   req - HTTP::Spy::Request - user request
  
  sub send : Public
    {
      my $this = shift;
      my $req = shift;
      
      my $ua = new LWP::UserAgent;
      my $r = HTTP::Request->new( $req->method, $req->uri );
      
      # Set headers.
      while ( my($k, $v) = each %{ $req->headers } )
      {
        $r->header($k => $v);
      }
      
      # Set request's body.
      $r->content($req->content);
      
      my $resp = $ua->request($r) or die $!;
      
      return $resp;
    }

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
