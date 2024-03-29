require 'rubysketch/all'


module RubySketch
  w = (ENV['WIDTH']  || 500).to_i
  h = (ENV['HEIGHT'] || 500).to_i
  WINDOW  = Processing::Window.new(w, h) {start}
  CONTEXT = RubySketch::Context.new WINDOW

  refine Object do
    (CONTEXT.methods - Object.instance_methods).each do |method|
      define_method method do |*args, **kwargs, &block|
        CONTEXT.__send__ method, *args, **kwargs, &block
      end
    end
  end
end# RubySketch


begin
  w, c = RubySketch::WINDOW, RubySketch::CONTEXT

  c.class.constants.each do |const|
    self.class.const_set const, c.class.const_get(const)
  end

  w.__send__ :begin_draw
  at_exit do
    w.__send__ :end_draw
    Processing::App.new {w.show}.start if c.hasUserBlocks__ && !$!
  end
end
