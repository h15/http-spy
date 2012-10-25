
# Class: HTTP::Spy::Admin
#   HTTP::Spy admin panel.
# Uses:
#   Pony::Object

package HTTP::Spy::Admin;
use Pony::Object;

  use threads;
  use threads::shared;
  use JSON;
  
  protected headers => ['HTTP/1.1 200 OK', 'Content-Type: text/html'];
  protected params => {};
  
  our @LOG : shared;
  
  # Function: init
  #   Constructor.
  
  sub init : Public
    {
      my $this = shift;
    }
  
  sub show : Public
    {
      my $this = shift;
      my $req  = shift;
      my $content = '';
      
      $this->params = $this->getGet($req);
      
      # Return files.
      local $/;
      given ( $req->path )
      {
        when ('/')
        {
          unless ( keys %{ $this->params } )
          {
            return { type => 'file', path => HTTP::Spy->new->getRoot() . '/www/index.html' };
          }
        }
        when ('/jquery.min.js')
        {
          return { type => 'file', path => HTTP::Spy->new->getRoot() . '/www/jquery.min.js' };
        }
      }
      
      # If some action
      given ( $this->params->{act} )
      {
        default
        {
          $content = to_json({log => \@HTTP::Spy::Admin::LOG});
          @HTTP::Spy::Admin::LOG = (); # Flush
        }
      }
      
      return [join("\r\n", @{ $this->headers }) . "\r\n", $content];
    }
  
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

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
