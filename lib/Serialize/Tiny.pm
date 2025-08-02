unit module Serialize::Tiny;

role ForceInclude {}
role ForceExclude {}

multi sub trait_mod:<is>(Attribute:D $a, :$included_in_serialization!) {
  die "An attribute cannot be both included and excluded" if $a ~~ ForceExclude;
  $a does ForceInclude;
}

multi sub trait_mod:<is>(Attribute:D $a, :$excluded_in_serialization!) {
  die "An attribute cannot be both included and excluded" if $a ~~ ForceExclude;
  $a does ForceExclude;
}

sub serialize-array(Mu:D @obj, :$class-key) {
  @obj.map({ serialize($_, :$class-key) })
}

sub serialize-hash(Mu:D %obj, :$class-key) {
  hash do for %obj.kv -> $k, $v {
    $k => serialize($v)
  }
}

multi sub serialize(Mu:U, *%) is export {
  Nil
}
# TODO serialize-hash
# TODO do this via multi dispatch??
multi sub serialize(Mu:D \obj, :$class-key) is export {
  return obj if obj ~~ Str | Int | Bool;
  return serialize-hash(obj, :$class-key) if obj ~~ Associative;
  return serialize-array(obj, :$class-key) if obj ~~ Positional;
  my @attribute = obj.^attributes.grep({(.has_accessor && $_ !~~ ForceExclude) || $_ ~~ ForceInclude});
  my %attr = @attribute.map({
    .name.substr(2) => serialize(.get_value(obj), :$class-key)
  }).hash;
  %attr ,= add-class-key($class-key, obj.^name) if defined $class-key;
  %attr
}

sub add-class-key($class-key, Str $class-name) {
  do given $class-key {
    when Str { $class-key => $class-name }
    when Callable { $class-key($class-name) }
    default { Empty }
  }
}
