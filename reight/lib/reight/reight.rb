def r8() = $r8__


class Reight::R8

  C = Reight::CONTEXT__

  def initialize(path, edit: false)
    raise if $r8__
    $r8__ = self

    @path, @edit = path, edit
    start_auto_save
  end

  def edit? = @edit

  def project()
    @project ||= Reight::Project.new @path
  end

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

  def start_auto_save()
    project.modified observe_all: true do
      C.set_timeout 0.3, id: :project_auto_save do
        project.save_all
      end
    end
  end

end# R8
