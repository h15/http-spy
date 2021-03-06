#!/usr/bin/perl

# Usage:
my $usage =<<USEAGE;
Use ./bin/start.pl to run spy-proxy server.
Params:
  --conf - path to configure file (default ./conf/application.yaml);
  --host - proxy host ip (default 127.0.0.1);
  --port - proxy access port (default 3128);
  --help - to see this message.
For example:
  ./bin/start.pl --conf=/home/user/spy-conf.yaml --host=8.8.8.8 --port=8081
USEAGE
;

# Make code strict & modern.
use strict;
use warnings;
use feature ':5.10';

use File::Basename 'dirname';
use File::Spec;
use Term::ANSIColor;

# Get application's location.
use constant APP_PATH =>
  join '/', File::Spec->splitdir(dirname(__FILE__)), '..';

use lib APP_PATH . '/lib';

use HTTP::Spy;
use HTTP::Spy::WebServer;
  
  # Turn off STDERR.
  close STDERR;
  
  # Default params.
  # Will use if user does not redefine them.
  my $params =
  {
    conf => APP_PATH . '/conf/application.yaml',
    host => '127.0.0.1',
    port => 3128,
    root => APP_PATH,
  };
  
  # Parse input params.
  #
  for my $param ( @ARGV )
  {
    given ( $param )
    {
      when ( /^--conf=/ )
      {
        my ( $key, @path ) = split '=', $param;
        my $path = join '', @path;
        
        $params->{conf} = $path;
      }
      
      when ( /^--host=/ )
      {
        my $key;
        ( $key, $params->{host} ) = split '=', $param;
      }
      
      when ( /^--port=/ )
      {
        my $key;
        ( $key, $params->{port} ) = split '=', $param;
      }
      
      when ( /^(--help|\?|-h|\/\?|\/h)/ )
      {
        say $usage;
        _exit(0);
      }
      
      default
      {
        say qq{Incorrect params! Error on "$param"\n};
        say $usage;
        _exit(1);
      }
    }
  }

  # Init Spy.
  #
  my $spy = new HTTP::Spy($params);
  
  eval
  {
    # RUNNING WebServer...
    HTTP::Spy::WebServer
      ->new( $spy->getHost(), $spy->getPort() )
        ->loop( sub{ $spy->input(@_) } );
  };
  
  # Good looking error print.
  if ( $@ )
  {
    print color 'bold red';
    print "\n[FAIL]";
    print color 'reset';
    print " $@\n";
    
    _exit(1); # Some error happend.
  }
  else
  {
    print color 'bold green';
    print "\n[DONE]";
    print color 'reset';
    print " Server stopped.\n";
    
    _exit(0); # Some error did not happend.
  }

sub _exit
  {
    my $code = shift;
    sleep(5);
    exit($code);
  }

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
