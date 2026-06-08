module Reight


  # @private
  class Window < RubySketch::Window

    def initialize(...)
      super

      c = context
      c.setup {
        @project = r8.project
        w, h = Reight::App::SCREEN_WIDTH, Reight::App::SCREEN_HEIGHT
        c.create_canvas w, h, pixelDensity: c.class::AUTO
        c.window_resize(*[w, h].map {_1 * 3})
        c.text_font @project.font
        self.app = apps.first
      }
      c.draw           {app.draw}
      c.key_pressed    {app.key_pressed}
      c.key_released   {app.key_released}
      c.key_typed      {app.key_typed}
      c.mouse_pressed  {app.mouse_pressed}
      c.mouse_released {app.mouse_released}
      c.mouse_moved    {app.mouse_moved}
      c.mouse_dragged  {app.mouse_dragged}
      c.mouse_clicked  {app.mouse_clicked}
      c.double_clicked {app.double_clicked}
      c.mouse_wheel    {app.mouse_wheel}
      c.touch_started  {app.touch_started}
      c.touch_ended    {app.touch_ended}
      c.touch_moved    {app.touch_moved}
      c.note_pressed   {app.note_pressed}
      c.note_released  {app.note_released}
      c.control_change {app.control_change}
      c.window_moved   {apps.each {_1.window_moved}}
      c.window_resized {apps.each {_1.window_resized}}
    end

    attr_reader :project, :app

    def app=(app)
      @app&.deactivated
      @app = app
      @app.activated

      context.set_title [
        self.class.name.split('::').first,
        Reight::Extension.version,
        '|',
        app.label
      ].join ' '
    end

    def apps()
      @apps ||= [].tap {|a|
        r, w, p, e = Reight, self, project, r8.edit?
        a << r::Runner.new(w, p)
        a << r::App.new(w, p, r::ScriptEditor, r::ScriptEditorInterface) if e
        a << r::App.new(w, p, r::SpriteEditor, r::SpriteEditorInterface) if e
        a << r::App.new(w, p, r::   MapEditor, r::   MapEditorInterface) if e
        a << r::App.new(w, p, r:: SoundEditor, r:: SoundEditorInterface) if e
      }
    end

    def flash(...) = app.flash(...)

  end# Window


end# Reight
