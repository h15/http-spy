package HTTP::Spy::Packet;
use Pony::Object;

  use HTTP::Spy::Request;
  use HTTP::Headers;
  use HTTP::Response;
  use HTTP::Request;
  use URI;
  
  public processed => 0;
  public packetId => '';
  public type => '';
  
  # Only in responses.
  public code   => '';
  public message=> '';
  
  # Only in requests.
  public uri    => '';
  public method => '';
  
  public header => {};
  public body   => '';
  
  # For HTTP::Spy::Request capability.
  public ua     => '';
  public host   => '';
  
  
  # Function: init
  #   Constructor
  # Parameters:
  #   r - HTTP request or response [optional]
  # Returns:
  #   HTTP::Spy::Packet
  
  sub init : Public
    {
      my $this = shift;
      
      if ( @_ )
      {
        my $r = shift;
        
        if ( $r->isa('HTTP::Spy::Request') )
        {
          $this->fromRequest($r);
        }
        elsif ( $r->isa('HTTP::Response') )
        {
          $this->fromResponse($r);
        }
        else
        {
          die "Wrong param's type";
        }
      }
      
      return $this;
    }
  
  
  # Function: fromRequest
  #   Init packet from HTTP::Spy::Request
  # Parameters:
  #   req - HTTP::Spy::Request
  
  sub fromRequest : Public
    {
      my $this = shift;
      my $req  = shift;
      
      # HTTP::Headers -> Hash.
      my $headers = {};
      
      for my $l ( split /(?:\r\n|\n)/, $req->{headers}->as_string() )
      {
        next if $l eq ''; # skip empty string.
        my ($k, @v) = split /: /, $l;
        $k = join ( '-', map { ucfirst } split('-', $k) ); # make canonical header's name.
        $headers->{$k} = join(': ', @v); # If header's value contained ': '.
      }
      
      # Init packet.
      $this->type   = 'request';
      $this->method = $req->method;
      $this->uri    = $req->uri;
      $this->header = $headers;
      $this->body   = $req->content;
      
      $this->ua     = $req->{headers}->{'user-agent'};
      $this->host   = $req->{headers}->{'host'};
      
      return $this;
    }
  
  
  # Function: fromResponse
  #   Init packet from HTTP::Response
  # Parameters:
  #   resp - HTTP::Response
  
  sub fromResponse : Public
    {
      my $this = shift;
      my $resp = shift;
      
      # HTTP::Headers -> Hash.
      my $headers = {};
      
      for my $l ( split /(?:\r\n|\n)/, $resp->headers->as_string() )
      {
        next if $l eq ''; # skip empty string.
        my ($k, @v) = split /: /, $l;
        $k = join ( '-', map { ucfirst } split('-', $k) ); # make canonical header's name.
        $headers->{$k} = join(': ', @v); # If header's value contained ': '.
      }
      
      # Init packet.
      $this->type   = 'response';
      $this->code   = $resp->code;
      $this->message= $resp->message;
      $this->header = $headers;
      $this->body   = $resp->content;
      # Some info we can get from request.
      $this->uri    = $resp->request->{_uri}->as_string();
      $this->method = $resp->request->{_method};
      
      $this->ua     = $resp->request->{_headers}->{'user-agent'};
      $this->host   = $resp->request->{_headers}->{'host'};
      
      return $this;
    }
  
  
  # Function: toRequest
  #   
  sub toRequest : Public
    {
      my $this = shift;
      my $headers = new HTTP::Headers( $this->header );
      return HTTP::Request->new( $this->method, $this->uri, $headers, $this->body );
    }
  
  sub toSpyRequest : Public
    {
      my $this = shift;
      
      # Get URI without scheme and host.
      # For example:
      # 'http://ya.ru/favicon.ico?a=1' -> 'favicon?a=1'
      my $path = URI->new($this->uri)->path;
      
      # Get extension from URI.
      # For example:
      # 'http://ya.ru/favicon.ico?a=1' -> 'ico'
      my ( $ext ) = ( $path =~ /\.([\w\d]+)(?:\?|$)/ );
      $ext ||= ''; # Empty string if no extension.
      
      my $params =
      {
        headers   => $this->header,
        method    => $this->method,
        ua        => $this->ua,
        host      => $this->host,
        proto     => 'HTTP 1/1',
        path      => $path,
        extension => lc $ext,
        uri       => $this->uri,
        content   => $this->body,
      };
      
      return HTTP::Spy::Request->new($params);
    }
  
  sub toResponse : Public
    {
      my $this = shift;
      my $headers = new HTTP::Headers( $this->header );
      return HTTP::Response->new( $this->code, $this->message, $headers, $this->body );
    }
  
  
  # Function: isResponse
  #   Does packet is response?
  # Returns:
  #   1|0
  
  sub isResponse : Public
    {
      my $this = shift;
      return ( $this->type eq 'response' ? 1 : 0 );
    }
  
  
  # Function: isRequest
  #   Does packet is request?
  # Returns:
  #   1|0
  
  sub isRequest : Public
    {
      my $this = shift;
      return ( $this->type eq 'request' ? 1 : 0 );
    }

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
