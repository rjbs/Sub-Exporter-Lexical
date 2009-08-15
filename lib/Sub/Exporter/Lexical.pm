use strict;
use warnings;
package Sub::Exporter::Lexical;
# ABSTRACT: to export lexically-available subs with Sub::Exporter

use namespace::clean ();
use B::Hooks::EndOfScope ();

use Sub::Exporter -setup => {
  exports => [ qw(lexical_installer) ],
};


=head1 SYNOPSIS

In an exporting library:

  package Some::Toolkit;

  use Sub::Exporter -setup => {
    exports   => [ qw(foo bar baz) ],
  };

  sub foo { ... }
  sub bar { ... }
  sub baz { ... }

In an importing library:

  package Vehicle::Autobot;

  use Sub::Exporter::Lexical lexical_installer => { -as => 'lex' };

  ...;

  {
    use Some:::Toolkit { installer => lex }, qw(foo bar);
    
    foo(1,2,3);
    my $x = bar;

    ...
  };

  # ... and here, foo and bar are no longer available ...

=head1 DESCRIPTION

Sub::Exporter::Lexical provides an alternate installer for
L<Sub::Exporter|Sub::Exporter>.  Installers are documented in Sub::Exporter's
documentation; all you need to know is that by using Sub::Exporter::Lexical's
installer, you can import routines into a lexical scope that will be cleaned up
when that scope ends.

There are two places it makes sense to use the lexical installer: when
configuring Sub::Exporter in your exporting package or when importing from a
package that uses Sub::Exporter.  For the first case, do something like this:

  package Some::Toolkit;
  use Sub::Exporter::Lexical ();
  use Sub::Exporter -setup => {
    exports   => [ ... ],
    installer => Sub::Exporter::Lexical::lexical_installer,
  };

For the second:

  package My::Library;

  use Sub::Exporter::Lexical ();
  use Some::Toolkit
    { installer => Sub::Exporter::Lexical::lexical_installer },
    qw(foo bar baz);

=head1 EXPORTS

Sub::Exporter::ForMethods offers only one routine for export, and it may also
be called by its full package name:

=head2 lexical_installer

This routine returns an installer suitable for use as the C<installer> argument
to Sub::Exporter.  It installs all requested routines as usual, but marks them
to be removed from the target package as soon as the block in which it was
called is complete.

It does not affect the behavior of routines exported into scalar references.

B<More importantly>, it does not affect scopes in which it is invoked at
runtime, rather than compile time.  B<This is important!>  It means that this
works:

  {
    use Some::Toolkit { installer => lexical_installer }, qw(foo);
    foo(1,2,3);
  }

  foo(); # this dies

...but this does not...

  {
    require Some::Toolkit;
    Some::Toolkit->import({ installer => lexical_installer }, qw(foo));
    foo(1,2,3);
  }

  foo(); # this does not die, even though you might expect it to

=cut

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
