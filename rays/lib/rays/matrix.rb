# -*- coding: utf-8 -*-


require 'rays/ext'


module Rays


  class Matrix

    include Comparable
    include Enumerable

    def each(&block)
      to_a.each(&block)
    end

    alias inspect_org inspect

    def inspect()
      inspect_org.gsub(/\.?0+([^\.\d]|$)/) {$1}
    end

  end# Matrix


end# Rays
