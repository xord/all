# -*- coding: utf-8 -*-


require 'beeps'
require 'rays'
require 'reflex'


module Reflexion


  include Beeps, Rays, Reflex


  DEFAULTS = {
    title: 'Reflexion',
    frame: [100, 100, 512, 512]
  }


  def call_event(event, *args, &block)
    $event = event
    Xot::BlockUtil.instance_eval_or_block_call *args, &block if block
    $event = nil
  end


  class App < Application

    def on_motion(e)
      super
      call_event e, e, &$motion
    end

  end# App


  class MainWindow < Window

    attr_reader :event

    def initialize(*args, &block)
      super
      $window = self
      call_event nil, self, &$setup
    end

    def on_update(e)
      super
      redraw
      call_event e, e, &$update
    end

    def on_draw(e)
      super
      call_event e, e.painter, &$draw
    end

    def on_key(e)
      super
      call_event e, e, &$key
    end

    def on_pointer(e)
      super
      call_event e, e, &$pointer
    end

  end# MainWindow


  module_function

  def window()
    $window ||= MainWindow.new DEFAULTS
  end

  def event()
    $event
  end

  def setup(&block)
    $setup = block
  end

  def update(&block)
    $update = block
  end

  def draw(&block)
    $draw = block
  end

  def key(&block)
    $key = block
  end

  def pointer(&block)
    $pointer = block
  end

  def motion(&block)
    $motion = block
  end

  def start()
    App.new {window.show}.start
  end

  def quit()
    window.close
  end


end# Reflexion


at_exit do
  Reflexion.start unless $!
end
