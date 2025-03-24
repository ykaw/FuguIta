#!/usr/bin/perl

# pattern of identifiers
#
$idexp='[A-Za-z_]+[0-9A-Za-z_]*';

# initial scope
#
$func = 'GLOBAL';

while (<>) {
  chomp;

  # strip unnecessary parts
  #
  s/'.*?'/ /g;     # single-quoted strings
  s/#.*//;         # comments
  s/^\s+$//;       # only white spaces
  next unless $_;  # skip blank lines

  printf("%4d:%16s:%s\n", $., $func, $_);

  # function declaration
  if (scalar(@w=(/^(${idexp})\s*\(\)\s*{/o)) ||
      scalar(@w=(/^\s*function\s+(${idexp})\s*{/o))) {
    $func=shift @w;
    print "FUN: ${func}()\n";

  # end of function
  } elsif (/^}/) {
    # end of function
    print "END: ${func}()\n";
    $func = 'GLOBAL';
  } else {

    # local variables
    if (/^\s*local\s+${idexp}/) {
      # local variables
      s/;.*//;
      s/\$\(.+?\)/ /g;
      @names=(/(${idexp})=\S+|(${idexp})/go);
      foreach $name (@names) {
        if ($name && $name ne 'local') {
          print "LOC:$name\n";
          $localvar{$func}{$name}++;
        }
      }

    # global variables
    } elsif (@names=(/(${idexp})=|\${?(${idexp})}?/go)) {
      # global variables
      foreach $name (@names) {
        if ($name && !defined $localvar{$func}{$name}) {
          print "GLO:$name\n";
          $var{$name}{$func}++;
        }
      }
    }
  }
}

# listing functions with global variables
#
print "*global vars:\n";
$i=1;
foreach $name (sort keys %var) {
  print "*    $name\n";
  foreach $func (sort keys %{$var{$name}}) {
    if (0 <= $localvar{$func}{$name}) {
      print "*        $func\n";
    }
  }
}

print "\n";

# listing local variables with functions
#
print "+local vars:\n";
foreach $func (sort keys %localvar) {
  if (%{$localvar{$func}}) {
    print "+    $func\n";
    foreach $name (sort keys %{$localvar{$func}}) {
      print "+        $name\n";
    }
  }
}
