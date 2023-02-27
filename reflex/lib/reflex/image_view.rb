# -*- coding: utf-8 -*-


require 'reflex/view'


module Reflex


  class ImageView

    has_model

    def image=(image)
      self.data = image
    end

    def on_data_update(e)
      set_image self.data
    end

  end# ImageView


end# Reflex
