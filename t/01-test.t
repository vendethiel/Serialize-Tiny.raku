# TODO get a nicer filename...
use Test;
use Serialize::Tiny;

plan 7;

{
  my class A {
    has $.a;
    has $.b;
    has $!c;
  };
  
  my A $a .= new(:1a, :b('o rly'));
  my %h = serialize($a);
  
  is %h.keys.sort, <a b>, 'It will filter out the keys without accessors';
  is %h<a>, 1, 'It extracted the 1st value correctly';
  is %h<b>, 'o rly', 'It extracted the 2nd value correctly';
}

{
  my class A {
    has $.x;
    has $.y;
  }
  my class B {
    has $.a;
  }

  my A $a .= new(:1x, :2y);
  my B $b .= new(:$a);

  my %h = serialize($b);

  is %h.keys.sort, <a>, 'It has the correct keys';
  is %h<a>.keys.sort, <x y>, 'It has the correct keys... even nested';
  is %h<a><x>, 1, 'It extracted all the subkeys';
}

{
  my class A {
    has $.x;
    has $.y;
  }

  my A $a .= new(:1x, :2y);
  my %h = serialize($a, class-key => 'type');
  is %h<type>, 'A', 'It shows class type';
}

{
  my class A {
    has $.x;
    has $.y;
  }
  my class B {
    has $.a;
  }

  my A $a .= new(:1x, :2y);
  my B $b .= new(:$a);
  my %h = serialize($b, class-key => 'type');
  is %h<type>, 'B', 'Top-level type is correct';
  is %h<a><type>, 'A', 'Nested type is present';
}

{
  my class A {
    has Int @.x;
    has $.y;
  }
  my class B {
    has A @.a;
  }

  my @a = A.new(:x(1,2,3), :4y), A.new(:x(10, 100, 1000), :10000y), A.new(:x(0, 0, 0), :0y);
  my $b = B.new(:@a);
  my %h = serialize($b, class-key => 'type');
  is %h<a>.elems, 3, 'It extracted all the elements';
  is all(|%h<a>)<type>, 'A', 'They have the correct class type';
  is %h<a>.map(*<x>[1]), (2, 100, 0), 'The values have been extracted correctly';
}
