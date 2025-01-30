require 'xot/universal_accessor'
require 'reflex/point'
require 'reflex/bounds'


module Reflex


  module HasFrame

    def move_to(*args)
      self.frame = frame.move_to(*args)
      self
    end

    def move_by(*args)
      self.frame = frame.move_by(*args)
      self
    end

    def resize_to(*args)
      self.frame = frame.resize_to(*args)
      self
    end

    def resize_by(*args)
      self.frame = frame.resize_by(*args)
      self
    end

    def inset_by(*args)
      self.frame = frame.inset_by(*args)
      self
    end

    %w[
      x y z w h d width height depth
      left top back right bottom front
      left_top right_top left_bottom right_bottom
      lt rt lb rb
      position pos size center
    ].each do |name|
      class_eval <<-END
        def #{name}()
          frame.#{name}
        end
        def #{name}=(*args)
          self.frame = frame.tap {|b| b.send :#{name}=, *args}
          #{name}
        end
      END

      universal_accessor name
    end

  end# HasFrame


  module HasTags

    def tag=(*tags)
      clear_tags
      tag(*tags.flatten)
    end

    alias tags= tag=

    def tag(*tags)
      tags.each {|tag| add_tag tag}
    end

    def untag(*tags)
      tags.each {|tag| remove_tag tag}
    end

    def tags()
      to_enum :each_tag
    end

    def clear_tags()
      untag(*tags.to_a)
    end

  end# HasTags


end# Reflex
