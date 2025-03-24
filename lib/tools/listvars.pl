#!/usr/bin/perl

$idexp='[A-Za-z_]+[0-9A-Za-z_]*';

$func = 'GLOBAL';
while (<>) {
  chomp;

  s/'.*?'/ /g;
  s/'"[^'"]*$//;
  s/#.*//;
  s/^\s+$//;
  next unless $_;

  printf("%4d:%16s:%s\n", $., $func, $_);

  if (@w=(/^(${idexp})\s+\(\)\s*{/o)) {
    $func=shift @w;
    print "FUN: ${func}()\n";
  } elsif (/^}/) {
    print "END: ${func}()\n";
    $func = 'GLOBAL';
  } else {
    if (/^\s*local\s+${idexp}/) {
      s/;.*//;
      s/\$\(.+?\)/ /g;
      @names=(/(${idexp})=\S+|(${idexp})/go);
      foreach $name (@names) {
        if ($name && $name ne 'local') {
          print "LOC:$name\n";
          $localvar{$func}{$name}++;
        }
      }
    } elsif (@names=(/(${idexp})=|\${?(${idexp})}?/go)) {
      foreach $name (@names) {
        if ($name && !defined $localvar{$func}{$name}) {
          print "GLO:$name\n";
          $var{$name}{$func}++;
        }
      }
    }
  }
}

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
print "+local vars:\n";
foreach $func (sort keys %localvar) {
  if (%{$localvar{$func}}) {
    print "+    $func\n";
    foreach $name (sort keys %{$localvar{$func}}) {
      print "+        $name\n";
    }
  }
}
