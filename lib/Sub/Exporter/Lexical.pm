use strict;
use warnings;
package Sub::Exporter::Lexical;

use namespace::clean ();
use B::Hooks::EndOfScope ();

sub lexical_installer { 
  sub { 
    my ($arg, $to_export) = @_; 

    my $into = $arg->{into};

    my @names =
      map { $to_export->[ $_ ] }
      grep { not($_ % 2) and ! ref $to_export->[$_] } (0 .. $#$to_export);

    Sub::Exporter::default_installer($arg, $to_export); 
    B::Hooks::EndOfScope::on_scope_end {
      namespace::clean->clean_subroutines($arg->{into}, @names);
    };
  }; 
} 

1;
