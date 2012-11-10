
# Class: HTTP::Spy::Admin
#   HTTP::Spy admin panel.
# Uses:
#   Pony::Object

package HTTP::Spy::Admin;
use Pony::Object;

  use threads;
  use threads::shared;
  use JSON;
  use Storable qw/freeze thaw/;
  use URI::Escape;
  use Digest::MD5;
  use HTTP::Spy::Packet;
  
  protected headers => ['HTTP/1.1 200 OK', 'Content-Type: text/html'];
  protected params => {};
  
  our @LOG : shared;
  our %InspectConfig : shared = (
    'method-GET' => 0,
    'method-POST' => 0,
    'method-PUT' => 0,
    'method-HEAD' => 0,
    'method-DELETE' => 0,
    'direction-toServer' => 0,
    'direction-fromServer' => 0,
    'extensions-except' => '',
    'host' => '',
  );
  # For none-regular structures.
  our %requests : shared;
  our %inspected : shared;
  
  # Function: init
  #   Constructor.
  
  sub init : Public
    {
      my $this = shift;
    }
  
  
  # Function: show
  #   Show Admin web-interface.
  # Parameters:
  #   req - HTTP::Spy::Request
  # Returns:
  #   hash|array ref - some presentations of http response
  
  sub show : Public
    {
      my $this = shift;
      my $req  = shift;
      my $content = '';
      
      $this->params = { %{ $this->getGet ($req) },
                        %{ $this->getPost($req) } };
      
      # Return files.
      local $/;
      given ( $req->path )
      {
        when ( '/' )
        {
          unless (keys %{$this->params})
          {
            return { type => 'file', path => HTTP::Spy->new->getRoot() . '/www/index.html' };
          }
        }
        when ( '/jquery.min.js' )
        {
          return { type => 'file', path => HTTP::Spy->new->getRoot() . '/www/jquery.min.js' };
        }
        when ( '/inspect' )
        {
          # Flush config.
          %HTTP::Spy::Admin::InspectConfig = (
            'method-GET' => 0,
            'method-POST' => 0,
            'method-PUT' => 0,
            'method-HEAD' => 0,
            'method-DELETE' => 0,
            'direction-toServer' => 0,
            'direction-fromServer' => 0,
            'extensions-except' => '',
            'host' => '',
          );
          
          # Set config.
          while ( my($k, $v) = each %{ $this->params } )
          {
            $v = 1 if $v eq 'on';
            $HTTP::Spy::Admin::InspectConfig{$k} = $v;
            $content = to_json {error => 0};
          }
          
          HTTP::Spy->new->log("New inspect config is setting up.");
        }
        when ( '/log' )
        {
          my @waiting; # <- Packets will be here.
          
          {
            lock ( %requests );
            
            # Get all does not processed requests.
            while ( my($k, $v) = each %requests )
            {
              next if $v->{processed} != 0;
              $requests{$k}{processed} = 1;
              push @waiting, { %$v };
            }
          }
          
          # Get all logs.
          $content = to_json({log => \@HTTP::Spy::Admin::LOG, packets => \@waiting});
          @HTTP::Spy::Admin::LOG = (); # Flush
        }
        
        when ( '/change' )
        {
          my $id = $this->params->{packetId};
          $inspected{$id} = &share({});
          
          while ( my($k, $v) = each %{ $this->params } )
          {
            $v =~ s/\+/ /g;
            $inspected{$id}{$k} = uri_unescape($v);
          }
          
          $content = to_json {error => 0};
          
          HTTP::Spy->new->log("Packet $id changed.");
        }
      }
      
      return [join("\r\n", @{ $this->headers }), $content];
    }
  
  
  # Function: getGet
  #   Get GET params from request.
  # Parameters:
  #   req - HTTP::Spy::Request
  # Returns:
  #   params - hashref to GET params
  
  sub getGet : Protected
    {
      my $this = shift;
      my $req  = shift;
      
      my @parts = split('\?', $req->uri);
      shift @parts;
      my %params;
      
      for my $pair ( split '&', join('?', @parts) )
      {
        next if $pair eq '';
        my ($k, $v) = split '=', $pair;
        %params = (%params, $k => $v);
      }
      
      return \%params;
    }
  
  
  # Function: getPost
  #   Get POST params from request.
  # Parameters:
  #   req - HTTP::Spy::Request
  # Returns:
  #   params - hashref to POST params
  
  sub getPost : Protected
    {
      my $this = shift;
      my $req  = shift;
      my %params;
      
      for my $pair ( split '&', $req->content )
      {
        next if $pair eq '';
        my ($k, $v) = split '=', $pair;
        %params = (%params, $k => $v);
      }
      
      return \%params;
    }
  
  
  # Function: inspect
  #   Inspect packet.
  # Parameters:
  #   packet - HTTP request|response
  # Returns:
  #   packet - modified packet
  
  sub inspect : Public
    {
      my $this = shift;
      my $packet = shift;
      
      # If does not match
      return $packet unless $this->match($packet);
      
      $packet = new HTTP::Spy::Packet( $packet );
      my $key = Digest::MD5::md5_hex(rand);
      $packet->packetId = $key;
      $requests{$key} = &shared_clone( $packet->toHash() );
      
      while ( sleep(1) )
      {
        next unless exists $inspected{$key}; # Wait
        
        # Update headers.
        for my $k ( keys %{$inspected{$key}} )
        {
          my $v = $inspected{$key}{$k};
          $packet->header->{$k} = "$v" if exists $packet->header->{$k};
        }
        
        # Update body if needed.
        $packet->body = $inspected{$key}{content} if $inspected{$key}{content};
        
        HTTP::Spy->new->log("Packet $key sent.");
        
        return ( $packet->isResponse ? $packet->toResponse() : $packet->toSpyRequest() );
      }
    }
  
  
  # Function: match
  #   Does param matchs inspect-config?
  # Parameters:
  #   packet
  # Returns:
  #   1 | 0 - true or false
  
  sub match : Protected
    {
      my $this = shift;
      my $packet = shift;
      
      if ( $packet->isa('HTTP::Spy::Request') )
      {
        my ( $method, $ext ) = ( $packet->method, $packet->extension );
        
        return 0 if !exists $InspectConfig{"method-$method"} || $InspectConfig{"method-$method"} == 0;
        return 0 if $InspectConfig{'direction-toServer'} == 0;
        return 0 if $InspectConfig{'host'} ne '' && $InspectConfig{'host'} ne $packet->host;
        
        for my $e ( split /(?:%7C|\|)/, $InspectConfig{'extensions-except'} )
        {
          return 0 if $ext eq $e;
        }
        
        return 1;
      }
      elsif ( $packet->isa('HTTP::Response') )
      {
        my $req = HTTP::Spy::Packet->new->fromResponse( $packet )->toSpyRequest();
        my ( $method, $ext ) = ( $req->method, $req->extension );
        
        return 0 if !exists $InspectConfig{"method-$method"} || $InspectConfig{"method-$method"} == 0;
        return 0 if $InspectConfig{'direction-fromServer'} == 0;
        return 0 if $InspectConfig{'host'} ne '' && $InspectConfig{'host'} ne $req->host;
        
        for my $e ( split /(?:%7C|\|)/, $InspectConfig{'extensions-except'} )
        {
          return 0 if $ext eq $e;
        }
        
        return 1;
      }
    }

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
