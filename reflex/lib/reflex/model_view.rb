require 'reflex/model_owner'


module Reflex


  module ModelView

    include ModelOwner

    def on_data_update(e)
      resize_to_fit
      redraw
    end

  end# ModelView


end# Reflex
