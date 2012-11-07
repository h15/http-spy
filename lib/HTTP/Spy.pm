
# Class: HTTP::Spy
# | Singleton.
# | It's an application class.
# Uses:
#   Pony::Object
#   HTTP::Spy::Admin
#   HTTP::Spy::Request
#   HTTP::Spy::UserAgent
#   Log::Log4perl

package HTTP::Spy;
use Pony::Object -singleton;
  
  use HTTP::Spy::Admin;
  use HTTP::Spy::Request;
  use HTTP::Spy::UserAgent;
  use HTTP::Spy::Packet;
  
  use Log::Log4perl;

  protected _host => '127.0.0.1'; # Default conf, host and port.
  protected _port => '3128';
  protected _conf => undef;
  protected _root => '';
  protected _adm  => undef;
  
  
  # Function: init
  #   Init object.
  # Parameters:
  #   params - hash of spy params.
  
  sub init : Public
    {
      my $this = shift;
      my $params = shift;
      
      # Get params if exists.
      while ( my($k, $v) = each %$params )
      {
        $this->{"_$k"} = $v;
      }
      
      # Init admin object.
      $this->_adm = new HTTP::Spy::Admin;
      
      my $rootPath = $this->getRoot();
      
      # Init logger.
      my $logConf = qq{
        log4perl.rootLogger              = DEBUG, LOG1
        log4perl.appender.LOG1           = Log::Log4perl::Appender::File
        log4perl.appender.LOG1.filename  = $rootPath/tmp/log.txt
        log4perl.appender.LOG1.mode      = append
        log4perl.appender.LOG1.layout    = Log::Log4perl::Layout::PatternLayout
        log4perl.appender.LOG1.layout.ConversionPattern = \%d \%p \%m \%n
      };
      
      Log::Log4perl->init( \$logConf );
      my $logger = Log::Log4perl->get_logger('HTTP::Spy');
      
      say "HTTP::Spy started!";
      $logger->fatal("HTTP::Spy started!");
    }
  
  
  # Function: input
  #   Runs on each http request (as WebServer).
  # Parameters:
  #   env - HTTP env.
  
  sub input : Public
    {
      my $this = shift;
      my $env = shift;
      
      # Get URI without scheme and host.
      # For example:
      # 'http://ya.ru/favicon.ico?a=1' -> 'favicon?a=1'
      my $path = $env->uri->path;
      
      # Get extension from URI.
      # For example:
      # 'http://ya.ru/favicon.ico?a=1' -> 'ico'
      my ( $ext ) = ( $path =~ /\.([\w\d]+)(?:\?|$)/ );
      $ext ||= ''; # Empty string if no extension.
      
      my $params =
      {
        headers   => $env->headers,
        method    => $env->method,
        ua        => $env->headers->{'user-agent'},
        host      => $env->headers->{'host'},
        proto     => $env->protocol,
        path      => $path,
        extension => lc $ext,
        uri       => $env->uri->as_string(),
        content   => $env->content,
      };
      
      my $req = new HTTP::Spy::Request($params);
      
      #############################
      #
      #   ADMIN INTERFACE
      #
      return $this->_adm->show($req) if $env->headers->{'host'} eq 'http.spy';
      ##############################
      
      $this->log($req);
      
      # Inspection & substitution (request).
      # Can delays thread.
      $req = $this->_adm->inspect($req);
      
      # Do request.
      my $ua   = new HTTP::Spy::UserAgent;
      my $resp = $ua->send($req);
      
      # Inspection & substitution (response).
      # Can delays thread.
      $resp = $this->_adm->inspect($resp);
      
      return $resp;
    }
  
  
  # Function: getHost
  #   Host getter.
  # Return: host - host property
  
  sub getHost : Public
    {
      my $this = shift;
      return $this->_host;
    }
  
  
  # Function: getRoot
  #   Root getter.
  # Return: string - root directory
  
  sub getRoot : Public
    {
      my $this = shift;
      return $this->_root;
    }
  
  
  # Function: getPort
  #   Port getter.
  # Return: port - port property
  
  sub getPort : Public
    {
      my $this = shift;
      return $this->_port;
    }
  
  
  # Function: log
  #   Log requests.
  # Parameters:
  #   req - HTTP::Spy::Request
  
  sub log : Public
    {
      my $this = shift;
      my $message = shift;
      my $logger = Log::Log4perl->get_logger('HTTP::Spy');
      
      if ( $message->isa('HTTP::Spy::Request') )
      {
        my $req = $message;
        my $message = sprintf "[%s] %s via %s (%s)",
                        scalar localtime, $req->host, $req->method, $req->uri;
        
        $logger->info($message);
        #say $message;
        
        push @HTTP::Spy::Admin::LOG, $message;
      }
      else
      {
        $logger->info($message);
        #say $message;
        push @HTTP::Spy::Admin::LOG, $message;
      }
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
