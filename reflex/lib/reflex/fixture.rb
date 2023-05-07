require 'xot/setter'
require 'xot/universal_accessor'


module Reflex


  class Fixture

    include Xot::Setter

    universal_accessor :density, :friction, :restitution, :sensor

  end# Fixture


end# Reflex
