package HTTP::Spy::WebServer::HTTPDaemon;
use Pony::Object qw/HTTP::Daemon/;

  sub init : Public
    {
      my $this = shift;
      my $obj = HTTP::Daemon->new(@_);
      
      #*{HTTP::Daemon::product_tokens} = \&product_tokens;
      
      return $obj;
    }
  
  sub product_tokens {}

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
