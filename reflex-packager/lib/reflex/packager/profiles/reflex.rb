require 'reflex/extension'
require 'reflex/packager/profile'


module Reflex


  module Packager


    # The profile to package an app of Reflex with.
    #
    REFLEX = Profile.new(
      extension:    Reflex::Extension,
      config_files: %w[reflex.yml reflex.yaml],
      templates:    {'main.rb': <<~MAIN, 'reflex.yml': <<~CONFIG})
        require 'reflex'

        view = Reflex::View.new
        def view.on_draw(e)
          e.painter.font nil, 48
          e.painter.text 'hello, world!', 100, 100
        end

        win = Reflex::Window.new
        win.title = '{{name}}'
        win.frame = [100, 100, 400, 300]
        win.add view
        win.show

        Reflex.start
      MAIN
        name: {{name}}
        version: 1.0.0
        #bundle_id: org.xord.reflex.example.{{name_id}}
        #icon: icon.png
      CONFIG


  end# Packager


end# Reflex
