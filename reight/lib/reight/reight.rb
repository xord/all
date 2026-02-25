def r8() = $r8__


class Reight::R8

  C = Reight::CONTEXT__

  def initialize(path, edit: false)
    raise if $r8__
    $r8__ = self

    @path, @edit = path, edit
    self.current = apps.first
  end

  attr_reader :current

  def edit? = @edit

  def project()
    @project ||= Reight::Project.new @path
  end

  def apps()
    @apps ||= [].tap {|a|
      a << Reight::Runner.new(project)
      a << Reight::App.new(project, Reight::SpriteEditor, Reight::SpriteEditorInterface) if edit?
      a << Reight::App.new(project, Reight::   MapEditor, Reight::   MapEditorInterface) if edit?
      a << Reight::App.new(project, Reight:: SoundEditor, Reight:: SoundEditorInterface) if edit?
    }
  end

  def flash(...) = current.flash(...)

  def icons()
    @icons ||= C.load_image(File.expand_path('../../res/icons.png', __dir__)).tap do |img|
      transp = C.color '#FF77A8'
      img.load_pixels
      img.pixels.map! {|c| c == transp ? C.color(0, 0, 0, 0) : c}
      img.update_pixels
    end
  end

  def icon(xi, yi, size)
    return nil unless xi && yi && size
    (@icon ||= {})[[xi, yi, size]] ||= C.create_graphics(size, size).tap do |g|
      g.beginDraw do
        g.copy icons, xi * size, yi * size, size, size, 0, 0, size, size
      end
    end
    # TODO: ||= r8.icons.sub_image xi * size, yi * size, size, size
  end

  def current=(app)
    @current&.deactivated
    @current = app
    @current.activated

    C.set_title [
      self.class.name.split('::').first,
      Reight::Extension.version,
      '|',
      current.label
    ].join ' '
  end

  def start_auto_save()
    project.modified observe_all: true do
      C.set_timeout 0.3, id: :project_auto_save do
        project.save_all
      end
    end
  end

  def setup()
    w, h = Reight::App::SCREEN_WIDTH, Reight::App::SCREEN_HEIGHT
    C.create_canvas w, h, pixelDensity: AUTO
    C.window_resize(*[w, h].map {_1 * 3})
    C.text_font r8.project.font, r8.project.settings.font_size

    start_auto_save
  end

  def draw()           = current.draw
  def key_pressed()    = current.key_pressed
  def key_released()   = current.key_released
  def key_typed()      = current.key_typed
  def mouse_pressed()  = current.mouse_pressed
  def mouse_released() = current.mouse_released
  def mouse_moved()    = current.mouse_moved
  def mouse_dragged()  = current.mouse_dragged
  def mouse_clicked()  = current.mouse_clicked
  def double_clicked() = current.double_clicked
  def mouse_wheel()    = current.mouse_wheel
  def touch_started()  = current.touch_started
  def touch_ended()    = current.touch_ended
  def touch_moved()    = current.touch_moved
  def note_pressed()   = current.note_pressed
  def note_released()  = current.note_released
  def control_change() = current.control_change
  def window_moved()   = apps.each {_1.window_moved}
  def window_resized() = apps.each {_1.window_resized}

end# R8
