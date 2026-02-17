require 'forwardable'
require 'json'
require 'rubysketch/all'


module Reight
  Processing.alias_snake_case_methods__ Processing
  Processing.alias_snake_case_methods__ RubySketch

  WINDOW__              = Processing.setup__ RubySketch::Window, RubySketch::Context
  CONTEXT__             = WINDOW__.context
  $processing_context__ = CONTEXT__

  refine Object do
    klass = RubySketch::Context
    (Processing.funcs__(klass) - Processing.events__(klass)).each do |func|
      define_method func do |*args, **kwargs, &block|
        $processing_context__.__send__ func, *args, **kwargs, &block
      end
    end
  end
end# Reight


require 'reight/extension'
require 'reight/helpers'
require 'reight/editable'
require 'reight/history'
require 'reight/button'
require 'reight/text'
require 'reight/asset_table'

require 'reight/reight'
require 'reight/context'
require 'reight/sprite'
require 'reight/project'
require 'reight/settings'
require 'reight/asset'
require 'reight/asset_list'
require 'reight/sprite_asset'
require 'reight/sprite_animation'
require 'reight/map_asset'
require 'reight/map_layer'
require 'reight/map_chunk'
require 'reight/map_tile'
require 'reight/sound'

require 'reight/app'
require 'reight/app/navigator'
require 'reight/app/runner'
require 'reight/app/sprite'
require 'reight/app/map'
require 'reight/app/sound'
