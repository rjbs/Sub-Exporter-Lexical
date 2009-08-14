use strict;
use warnings;
package Sub::Exporter::Lexical;

use namespace::clean ();
use B::Hooks::EndOfScope;

sub lexical_installer { 
  sub { 
    my ($arg, $to_export) = @_; 

    my $into = $arg->{into};

    my @names;
    for (my $i = 0; $i < @$to_export; $i += 2) {
      my ($as, $code) = @$to_export[ $i, $i+1 ];
      next if ref $as;
      push @names, $as;
    }
 
    Sub::Exporter::default_installer($arg, $to_export); 
    on_scope_end {
      namespace::clean->clean_subroutines($arg->{into}, @names);
    };
  }; 
} 

1;
