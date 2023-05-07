%w[xot rays reflex]
  .map  {|s| File.expand_path "../../#{s}/lib", __dir__}
  .each {|s| $:.unshift s if !$:.include?(s) && File.directory?(s)}

require 'reflex'
include Reflex


module Reflex
  class View
    def view (color: [rand, rand, rand], &block)
      add View.new background: color, &block
    end

    alias text view
    alias image view
    alias button view
  end
end

win = Window.new title: 'Layout Sample', frame: [100, 100, 500, 400] do
  flow :right, :down
  100.times do |i|
    root.view do
      style {
        width  100
        height 200
        left top '50%' if i == 5
      }
    end
  end
  root.view do
    style {
      left top right bottom '45%'
    }
  end
=begin
  lock_screen = View.new do
    view :header do
      view :left do
        text :dots
        text :carrior
        image :antenna
      end
      image :notifycation_pulltab
      view :right do
        iamge :blutooth
        text :battery_percent
        image :battery
      end
    end

    view :passcode do
      view :main do
      end
      view :footer do
        button :emergency
        button :cancel
      end
    end

    view :slider do
      view :clock
      view :slide
    end
  end
  add lock_screen

  style :all do
    padding 10
  end

  style :header do
    margin 20, 10

    #background gray|graya|rgb|rgba|hsv|hsva,image,bounds,repeat
    #background_color gray|graya|rgb|rgba|hsv|hsva
    #background_image image,bounds,repeat

    #frame x,y,w,h
    #x px|%
    #y px|%
    #width px|%
    #height px|%
    #left px|%
    #top px|%
    #right px|%
    #bottom px|%
  end
=end
end


Reflex.start do
  win.show
end
