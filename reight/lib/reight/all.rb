require 'forwardable'
require 'fileutils'
require 'json'
require 'prism'
require 'rubysketch/all'


module Reight
  Processing.alias_snake_case_methods__ Processing
  Processing.alias_snake_case_methods__ RubySketch

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
require 'reight/label'
require 'reight/overlay'

require 'reight/reight'
require 'reight/context'
require 'reight/window'
require 'reight/controller'
require 'reight/sprite'
require 'reight/map'
require 'reight/sound'

require 'reight/project'
require 'reight/settings'
require 'reight/asset'
require 'reight/asset_list'
require 'reight/asset_table'
require 'reight/script_asset'
require 'reight/text'
require 'reight/sprite_asset'
require 'reight/sprite_animation'
require 'reight/map_asset'
require 'reight/map_layer'
require 'reight/map_chunk'
require 'reight/map_tile'
require 'reight/sound_asset'
require 'reight/sound_note'

require 'reight/app'
require 'reight/app/navigator'
require 'reight/app/runner'
require 'reight/app/script'
require 'reight/app/sprite'
require 'reight/app/map'
require 'reight/app/sound'
