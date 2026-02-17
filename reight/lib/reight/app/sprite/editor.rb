class Reight::SpriteEditor

  extend  Forwardable
  extend  Reight::Hookable
  extend  Reight::HasState
  include Reight::ModelController

  C = Reight::CONTEXT__

  def initialize(project)
    @project, @settings = project, project.settings
  end

  state :sprite do |new, old|
    group_history do
      self.anim = new&.at 0
      append_history [:set_sprite, new, old]
    end
  end

  state :anim do |new, old|
    group_history do
      self.anim_image = new&.at 0
      append_history [:set_anim, new, old]
    end
  end

  state :anim_image do |new, old|
    group_history do
      deselect if selection(nil)
      append_history [:set_anim_image, new, old]
    end
  end

  state :sprite_size
  state :tool
  state :color

  attr_reader :sprite, :anim, :anim_image, :sprite_size, :tool, :color

  hook :selection_changed

  def_delegators :@project, :sprites

  def_delegators :@settings,
    :sprites_width,
    :sprites_height,
    :sprites_page_width,
    :sprites_page_height

  def tools()
    @tools ||= [
      Reight::SpriteEditor::Select       .new(self),
      Reight::SpriteEditor::Brush        .new(self),
      Reight::SpriteEditor::Fill         .new(self),
      Reight::SpriteEditor::Line         .new(self),
      Reight::SpriteEditor::StrokeRect   .new(self),
      Reight::SpriteEditor::  FillRect   .new(self),
      Reight::SpriteEditor::StrokeEllipse.new(self),
      Reight::SpriteEditor::  FillEllipse.new(self)
    ]
  end

  def colors()
    @colors ||= @project.settings.palette_colors.map {C.color _1}
      .map {[C.red(_1), C.blue(_1), C.green(_1), C.alpha(_1)].map(&:to_i)}
  end

  def select(x, y, w, h)
    x2, y2 = x + w, y + h
    x, x2  = x2, x if x > x2
    y, y2  = y2, y if y > y2
    x, y   = x.floor, y.floor
    w, h   = (x2 - x).ceil, (y2 - y).ceil
    return deselect if w == 0 || h == 0
    old, @selection = @selection, [x, y, w, h]
    append_history [:select, @selection, old]
    selection_changed! @selection
  end

  def deselect()
    old, @selection = @selection, nil
    append_history [:select, @selection, old]
    selection_changed! @selection
  end

  def selection(ifempty = [0, 0, @anim_image&.w || 0, @anim_image&.h || 0])
    @selection || ifempty
  end

  def begin_editing(bounds: nil, &block)
    @image_before_editing = @anim_image.dup
    block.call @anim_image if block
  ensure
    end_editing bounds if block
  end

  def end_editing(bounds = nil)
    return unless @image_before_editing
    before, @image_before_editing = @image_before_editing, nil
    x, y, w, h                    = get_edited_bounds__ before, bounds
    return if w == 0 || h == 0
    before = copy_image__ before,      x, y, w, h
    after  = copy_image__ @anim_image, x, y, w, h, dup: true
    append_history [:snapshot, after, before, x, y] if before && after
    @anim.modified!
  end

  def begin_drawing(bounds: nil, &block)
    begin_editing
    @anim_image.begin_draw
    block.call @anim_image if block
    @anim_image
  ensure
    end_drawing bounds if block
  end

  def end_drawing(bounds = nil)
    @anim_image.end_draw
  ensure
    end_editing bounds
  end

  def add_sprite(x, y, w, h)
    sp = Reight::SpriteAsset.new @project.get_next_id, w, h, x, y
    group_history do
      sprites.put sp
      append_history [:add_sprite, sp]
      self.sprite = sp
      add_anim
    end
  end

  def remove_sprite()
    return unless @sprite
    sprite, index = @sprite, sprites.find_index(@sprite)
    group_history do
      sprites.remove sprite
      append_history [:remove_sprite, sprite]
      self.sprite = sprites[index] || sprites[-1]
    end
  end

  def set_sprite_name(name)
    old, @sprite.name = @sprite.name, name
    append_history [:set_sprite_name, name, old]
  end

  def add_anim(index = nil)
    sp    = @sprite || return
    index = sp.find_index(@anim)&.then {_1 + 1} || sp.size unless index
    anim  = Reight::SpriteAnimation.new @project.get_next_id, sp.w, sp.h
    group_history do
      @sprite.insert index, anim
      append_history [:add_anim, index, anim]
      self.anim = anim
      add_anim_image 0
    end
  end

  def remove_anim()
    return unless @anim
    anim, index = @anim, @sprite.find_index(@anim)
    group_history do
      @sprite.remove anim
      append_history [:remove_anim, index, anim]
      self.anim = @sprite[index] || @sprite[-1]
    end
  end

  def set_anim_name(name)
    old, @anim.name = @anim.name, name
    append_history [:set_anim_name, name, old]
  end

  def add_anim_image(index = nil)
    index = @anim.find_index(@anim_image)&.then {_1 + 1} || @anim.size unless index
    prev_image, insert_pos =
      if index >= @anim.size
        [@anim[-1], @anim.size]
      else
        [@anim_image, index]
      end
    group_history do
      (insert_pos..index).each do |pos|
        image = prev_image&.dup || @anim.create_image
        @anim.insert pos, image
        append_history [:add_anim_image, pos, image]
      end
      self.anim_image = @anim[index]
    end
  end

  def remove_anim_image()
    return unless @anim_image
    image, index = @anim_image, @anim.find_index(@anim_image)
    group_history do
      @anim.remove image
      append_history [:remove_anim_image, index, image]
      self.anim_image = @anim[index] || @anim[-1]
    end
  end

  def cut()
    copy&.tap do |image, x, y|
      w, h = image.w, image.h
      begin_drawing bounds: [x, y, w, h] do |g|
        g.fill(*colors.first)
        g.no_stroke
        g.blend_mode REPLACE
        g.rect x, y, w, h
      end
    end
  end

  def copy()
    return nil unless @anim_image
    sel   = selection
    image = copy_image__(@anim_image, *sel, dup: true) || (return nil)
    x, y, = sel
    @copy = [image, x, y]
  end

  def paste()
    return unless @anim_image
    image, x, y = @copy || return
    w, h        = image.w, image.h
    group_history do
      deselect if selection(nil)
      begin_editing do |img|
        img.begin_draw do |g|
          g.blend image, 0, 0, w, h, x, y, w, h, REPLACE
        end
      end
      select x, y, w, h
    end
  end

  def can_cut?   = true
  def can_copy?  = true
  def can_paste? = @copy

  def undo()
    history__.undo do |action|
      case action
      in [   :add_sprite,     sprite]       then sprites.remove sprite
      in [:remove_sprite,     sprite]       then sprites.put    sprite
      in [   :add_anim,       index, _]     then @sprite.remove_at index
      in [:remove_anim,       index, anim]  then @sprite.insert    index, anim
      in [   :add_anim_image, index, _]     then @anim  .remove_at index
      in [:remove_anim_image, index, image] then @anim  .insert    index, image
      in [:set_sprite,      _, old]         then self.sprite     = old
      in [:set_sprite_name, _, old]         then @sprite.name    = old
      in [:set_anim,        _, old]         then self.anim       = old
      in [:set_anim_name,   _, old]         then @anim.name      = old
      in [:set_anim_image,  _, old]         then self.anim_image = old
      in [:snapshot,        _, old, x, y]   then restore_anim_image__ old, x, y
      in [  :select,        _, old]         then old ? select(*old) : deselect
      end
    end
  end

  def redo()
    history__.redo do |action|
      case action
      in [   :add_sprite,     sprite]       then sprites.put    sprite
      in [:remove_sprite,     sprite]       then sprites.remove sprite
      in [   :add_anim,       index, anim]  then @sprite.insert    index, anim
      in [:remove_anim,       index, _]     then @sprite.remove_at index
      in [   :add_anim_image, index, image] then @anim  .insert    index, image
      in [:remove_anim_image, index, _]     then @anim  .remove_at index
      in [:set_sprite,      new, _]         then self.sprite     = new
      in [:set_sprite_name, new, _]         then @sprite.name    = new
      in [:set_anim,        new, _]         then self.anim       = new
      in [:set_anim_name,   new, _]         then @anim.name      = new
      in [:set_anim_image,  new, _]         then self.anim_image = new
      in [:snapshot,        new, _, x, y]   then restore_anim_image__ new, x, y
      in [  :select,        new, _]         then new ? select(*new) : deselect
      end
    end
  end

  def can_undo?() = history__.can_undo?
  def can_redo?() = history__.can_redo?

  def canvas_pressed( x, y, button) = @tool&.canvas_pressed  x, y, button

  def canvas_released(x, y, button) = @tool&.canvas_released x, y, button

  def canvas_moved(   x, y)         = @tool&.canvas_moved    x, y

  def canvas_dragged( x, y, button) = @tool&.canvas_dragged  x, y, button

  def canvas_clicked( x, y, button) = @tool&.canvas_clicked  x, y, button

  private

  def get_edited_bounds__(image, bounds)
    return [0, 0, image.w, image.h] unless bounds
    x, y, w, h = bounds
    x, w       = x + w, -w if w < 0
    y, h       = y + h, -h if h < 0
    w, h       = (x + w).ceil - x.floor, (y + h).ceil - y.floor
    x, y       = x.floor, y.floor
    b1         = Rays::Bounds.new x, y, w, h
    b2         = Rays::Bounds.new 0, 0, image.w, image.h
    (b1 & b2).to_a 2
  end

  def copy_image__(image, x, y, w, h, dup: false)
    return nil if w == 0 || h == 0
    if x == 0 && y == 0 && w == image.w && h == image.h
      dup ? image.dup : image
    else
      C.create_graphics(w, h).tap do |img|
        img.begin_draw {img.blend image, x, y, w, h, 0, 0, w, h, :replace}
      end
    end
  end

  def restore_anim_image__(img, x, y)
    @anim_image&.begin_draw do |g|
      g.blend img, 0, 0, img.w, img.h, x, y, img.w, img.h, :replace
    end
  end

end# SpriteEditor
