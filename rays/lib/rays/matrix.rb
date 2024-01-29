require 'rays/ext'


module Rays


  class Matrix

    include Comparable
    include Enumerable

    def transpose()
      dup.transpose!
    end

    def translate(*args)
      dup.translate!(*args)
    end

    def scale(*args)
      dup.scale!(*args)
    end

    def rotate(*args)
      dup.rotate!(*args)
    end

    def each(&block)
      to_a.each(&block)
    end

    alias inspect_org inspect

    def inspect()
      inspect_org.gsub(/\.?0+([^\.\d]|$)/) {$1}
    end

  end# Matrix


end# Rays
