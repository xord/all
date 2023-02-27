# -*- coding: utf-8 -*-


%w[xot rays reflex]
  .map  {|s| File.expand_path "../../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'thread'
require 'reflex'


class Channel

  def initialize ()
    @c2s, @s2c = Queue.new, Queue.new
  end

  def send (obj, async = false)
    @c2s.push obj
    async ? obj : @s2c.pop
  end

  def receive ()
    @s2c.pop
  end

  def process ()
    reply eval @c2s.pop(true)
  rescue ThreadError
  rescue => e
    reply e.backtrace
  end

  def reply (obj)
    @s2c.push obj
  end

end# Channel


class PrimaryWindow < Reflex::Window

  attr_reader :channel

  def initialize ()
    super
    set :title,  "Reflex/REPL"
    set :frame, 100, 100, 320, 240

    @channel = Channel.new

    Thread.new do
      loop do
        print '> '
        puts @channel.send(gets).inspect
      end
    end
  end

  def on_update (dt)
    super
    @channel.process
  end

end# PrimaryWindow


Reflex.start do
  $window = PrimaryWindow.new.show
end
