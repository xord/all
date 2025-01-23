require 'processing/all'


module Processing
  w = (ENV['WIDTH']  || 500).to_i
  h = (ENV['HEIGHT'] || 500).to_i
  WINDOW__  = Processing::Window.new(w, h) {start}
  CONTEXT__ = Processing::Context.new WINDOW__
  BINDING__ = binding
  EVENTS__  = %i[
    setup draw
    keyPressed keyReleased keyTyped
    mousePressed mouseReleased mouseMoved mouseDragged
    mouseClicked doubleClicked mouseWheel
    touchStarted touchEnded touchMoved
    windowMoved windowResized motion
  ]

  refine Object do
    (CONTEXT__.methods - Object.instance_methods - EVENTS__)
      .reject {_1 =~ /__$/} # methods for internal use
      .each do |method|
        define_method method do |*args, **kwargs, &block|
          CONTEXT__.__send__ method, *args, **kwargs, &block
        end
      end

    EVENTS__.each do |name|
      define_method(name) {|&b| CONTEXT__.__send__(name, &b) if b}
      define_method :__define_processing_event_caller__ do |name|
        CONTEXT__.__send__(name) {BINDING__.eval name.to_s} if
          EVENTS__.include?(name)
      end
    end

    def Object.method_added(name)
      __define_processing_event_caller__ name if
        respond_to?(:__define_processing_event_caller__)
    end
  end
end# Processing


begin
  w, c = Processing::WINDOW__, Processing::CONTEXT__

  c.class.constants.reject {_1 =~ /__$/}.each do |const|
    self.class.const_set const, c.class.const_get(const)
  end

  w.__send__ :begin_draw
  at_exit do
    w.__send__ :end_draw
    Processing::App.new {w.show}.start if c.hasUserBlocks__ && !$!
  end
end
