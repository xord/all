# -*- coding: utf-8 -*-


require 'xot/setter'
require 'xot/universal_accessor'


module Reflex


  class Fixture

    include Xot::Setter

    universal_accessor :density, :friction, :restitution,
      :sensor, :category, :collision

  end# Fixture


end# Reflex
