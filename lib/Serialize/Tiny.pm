unit module Serialize::Tiny;

multi sub serialize(Mu:U, *%) is export {
  Nil
}
sub serialize-array(Mu:D @obj, Str :$class-key) {
  @obj.map({ serialize($_, :$class-key) })
}
# TODO serialize-hash
# TODO do this via multi dispatch??
multi sub serialize(Mu:D \obj, Str :$class-key) is export {
  return obj if obj ~~ any(Str, Int, Bool);
  return serialize-array(obj, :$class-key) if obj ~~ Array; # TODO Positional?
  my \type = obj.WHAT;
  my @attribute = type.^attributes.grep(*.has_accessor);
  my %attr = @attribute.map({
    .name.substr(2) => serialize(.get_value(obj), :$class-key)
  }).hash;
  %attr{$class-key} = obj.^name if defined $class-key; # TODO try to fall back on attr type if Nil?
  %attr
}
