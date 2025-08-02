# TODO get a nicer filename...
use Test;
use lib './lib';
use Serialize::Tiny;

plan 17;

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

  my A @a =
		A.new(:x(1,2,3), :4y),
		A.new(:x(10, 100, 1000), :10000y),
		A.new(:x(0, 0, 0), :0y)
	;
  my B $b .= new(:@a);
  my %h = serialize($b, class-key => 'type');
  is %h<a>.elems, 3, 'It extracted all the elements';
  is all(|%h<a>)<type>, 'A', 'They have the correct class type';
  is %h<a>.map(*<x>[1]), (2, 100, 0), 'The values have been extracted correctly';
}

subtest "class-key", {
  my class A {
		has Int @.x;
		has $.y;
	}
	my class B {
	}
	my class C {
	  has A $.a;
		has B $.b;
	}

	my A $a .= new(:x(1, 2, 3), :y("hey"));
	my B $b .= new;
	my C $c .= new(:$a, :$b);
  my %h = serialize($c, :class-key({ type => $_ }));
	is %h<type>, 'C', "Allows to override key name";
	is %h<b><type>, 'B', "Even when nested";
	is %h<a>.keys.sort, <type x y>, "Even with other attributes";
}

subtest "serialize hash", {
  my class A {
    has $.x;
  }
  my class B {
    has A %.v;
  }
  my B $b .= new(v => {
    a1 => A.new(:1x),
    a2 => A.new(:2x),
    a3 => A.new(:3x),
  });
  my %h = serialize($b);
  is %h.keys, <v>, 'It has a single h key';
  is %h<v>.keys.sort, <a1 a2 a3>, 'It has all the hash keys';
  is %h<v><a1>.keys, <x>;
  is %h<v><a1><x>, 1;
  is %h<v><a2>.keys, <x>;
  is %h<v><a2><x>, 2;
  is %h<v><a3>.keys, <x>;
  is %h<v><a3><x>, 3;
}

subtest "excluded_from_serialization", {
  my class A {
    has $.x is excluded_from_serialization;
  };
  my $a = A.new(x => 1);
  my %h = serialize($a);
  is %h.keys, (), "No keys";
};

subtest "included_in_serialization", {
  my class A {
    has Int $!x is included_in_serialization;
  };
  my $a = A.new(x => 1);
  my %h = serialize($a);
  is %h.keys, <x>, "Force-included key is present";
  is %h<x>, 1, "Key has correct value";
}

subtest "class-key function", {
  my class A::B::C {
  };
  my sub f($s) { type => $s.split("::")[*-1] }
  my %h = serialize(A::B::C.new, :class-key(&f));
  is %h.keys, <type>;
  is %h<type>, "C", "class-key was called";
}
