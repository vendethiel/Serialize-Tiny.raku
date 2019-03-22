unit module Serialize::Tiny;

multi sub serialize(Mu:U, *%) is export {
  Nil
}
sub serialize-array(Mu:D @obj, :$class-key) {
  @obj.map({ serialize($_, :$class-key) })
}
# TODO serialize-hash
# TODO do this via multi dispatch??
multi sub serialize(Mu:D \obj, :$class-key) is export {
  return obj if obj ~~ Str | Int | Bool;
  return serialize-array(obj, :$class-key) if obj ~~ Array; # TODO Positional?
  my \type = obj.WHAT;
  my @attribute = type.^attributes.grep(*.has_accessor);
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
