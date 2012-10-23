
# Class: HTTP::Spy
# | Singleton.
# | It's an application class.
# Uses:
#   Pony::Object

package HTTP::Spy;
use Pony::Object -singleton;

  protected _host => '127.0.0.1'; # Default conf, host and port.
  protected _port => '3128';
  protected _conf => undef;
  
  
  # Function: init
  #   Init object.
  # Parameters:
  #   params - hash of spy params.
  
  sub init : Public
    {
      my $this = shift;
      
      # Get params if exists.
      if ( @_ )
      {
        my $params = shift;
        $this->_host = $params->{host};
        $this->_port = $params->{port};
        $this->_conf = $params->{conf};
      }
    }
  
  
  # Function: input
  #   Runs on each http request (as WebServer).
  # Parameters:
  #   env - HTTP env.
  
  sub input : Public
    {
      my $this = shift;
      say dump \@_;
    }
  
  
  # Function: output
  #   Runs on each http request (as UserAgent).
  
  sub output : Public
    {
      my $this = shift;
      
    }
  
  # Function: getHost
  #   Host getter.
  # Return: host - host property
  
  sub getHost : Public
    {
      my $this = shift;
      return $this->_host;
    }
  
  
  # Function: getPort
  #   Port getter.
  # Return: port - port property
  
  sub getPort : Public
    {
      my $this = shift;
      return $this->_port;
    }
  
1;

__END__

=head1 NAME

HTTP::Spy - Spy the web!

=head1 OVERVIEW

HTTP::Spy is a HTTP proxy server with following abilities:
observing and replacement packets on fly, audit and filtration.

=head1 STRUCTURE

                                +---------+                   +----------+
     +------+   +-----------+   | Log,    |   +-----------+   | External |
     | User |<->| WebServer |<->| Modify, |<->| UserAgent |<->| HTTP     |
     +------+   +-----------+   | Filter  |   +-----------+   | resource |
                                +---------+                   +----------+
                                     ^
                                     |
                                     v
                               +-----------+
                               | WebServer |
                               +-----------+
                                     ^
                                     |
                                     v
                             +---------------+
                             | Administrator |
                             | or hacker     |
                             | or webmaster  |
                             +---------------+

=head1 COMMANDS

Following commands will helps you run and manage Spy server:

=head2 start
  
  Use ./bin/start.pl to run spy-proxy server.
  Params:
    --conf - path to configure file (default ./conf/application.yaml);
    --host - proxy host ip (default 127.0.0.1);
    --port - proxy access port (default 3128);
    --help - to see this message.
  For example:
    ./bin/start.pl --conf=/home/user/spy-conf.yaml --host=8.8.8.8 --port=8081

=head1 BROWSERS

How to use it with browsers.

=over

=item Chrome / Chromium

  chromium-browser --proxy-server=localhost:3128

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut