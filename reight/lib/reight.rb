require 'reight/all'


module Reight

  WINDOW__              = Processing.setup__ Reight::Window, RubySketch::Context
  $processing_context__ = WINDOW__.context

end# Reight


begin
  w = Reight::WINDOW__

  Reight.import_context_constants__ w.context.class

  w.__send__ :begin_draw
  at_exit do
    w.__send__ :end_draw
    Processing::App.new {w.show}.start if w.context.hasUserBlocks__ && !$!
  end
end
