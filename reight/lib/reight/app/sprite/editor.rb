class Reight::SpriteEditor

  extend Forwardable

  include Reight::Hookable

  C = Reight::CONTEXT__

  def_delegators :@project, :sprites

  def_delegators :@settings,
    :sprites_width,
    :sprites_height,
    :sprites_page_width,
    :sprites_page_height

  def initialize(project)
    hook :sprite_changed
    hook :anim_changed
    hook :anim_image_changed
    hook :sprite_size_changed
    hook :tool_changed
    hook :color_changed
    hook :selection_changed

    @project, @settings = project, project.settings
  end

  attr_reader :sprite, :anim, :anim_image, :sprite_size, :tool, :color

  def sprite=(sprite)
    return if sprite == @sprite
    old, @sprite = @sprite, sprite
    group_history do
      self.anim = @sprite&.at 0
      history__.append [:sprite, old, @sprite]
      sprite_changed! @sprite
    end
  end

  def anim=(anim)
    return if anim == @anim
    old, @anim = @anim, anim
    group_history do
      self.anim_image = @anim&.at 0
      history__.append [:anim, old, @anim]
      anim_changed! @anim
    end
  end

  def anim_image=(image)
    return if image == @anim_image
    old, @anim_image = @anim_image, image
    group_history do
      deselect if selection(nil)
      history__.append [:anim_image, old, @anim_image]
      anim_image_changed! @anim_image
    end
  end

  def sprite_size=(size)
    return if size == @sprite_size
    @sprite_size = size
    sprite_size_changed! @sprite_size
  end

  def tool=(tool)
    return if tool == @tool
    @tool = tool
    tool_changed! @tool
  end

  def color=(color)
    return if color == @color
    @color = color
    color_changed! @color
  end

  def tools()
    @tools ||= [
      Reight::SpriteEditor::Select       .new(self),
      Reight::SpriteEditor::Brush        .new(self),
      Reight::SpriteEditor::Fill         .new(self),
      Reight::SpriteEditor::Line         .new(self),
      Reight::SpriteEditor::StrokeRect   .new(self),
      Reight::SpriteEditor::  FillRect   .new(self),
      Reight::SpriteEditor::StrokeEllipse.new(self),
      Reight::SpriteEditor::  FillEllipse.new(self),
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
    history__.append [:select, old, @selection]
    selection_changed! @selection
  end

  def deselect()
    old, @selection = @selection, nil
    history__.append [:select, old, @selection]
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
    history__.append [:snapshot, before, after, x, y] if before && after
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
    sp = Reight::SpriteAsset.new(@project.get_next_id, w, h, x, y).tap {|asset|
      asset.push Reight::SpriteAnimation.new(@project.get_next_id, w, h).tap {|anim|
        anim.push anim.create_image
      }
    }
    group_history do
      @project.sprites.add sp
      history__.append [:add_sprite, sp]
      self.sprite = sp
    end
  end

  def add_anim_image(index = @anim.find_index(@anim_image) + 1)
    prev_image, insert_pos =
      if index >= @anim.size
        [@anim[-1], @anim.size]
      else
        [@anim_image, index]
      end
    group_history do
      (insert_pos..index).each do |pos|
        image = prev_image.dup
        @anim.insert pos, image
        history__.append [:add_anim_image, pos, image]
      end
      self.anim_image = @anim[index]
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
      in [:add_sprite, sprite]          then @project.sprites.remove sprite
      in [:add_anim_image, index, _]    then @anim.remove_at index
      in [:sprite,     before, _]       then self.sprite     = before
      in [:anim,       before, _]       then self.anim       = before
      in [:anim_image, before, _]       then self.anim_image = before
      in [:snapshot,   before, _, x, y] then restore_anim_image__ before, x, y
      in [  :select,   before, _]       then before ? select(*before) : deselect
      end
    end
  end

  def redo()
    history__.redo do |action|
      case action
      in [:add_sprite, sprite]            then @project.sprites.add sprite
      in [:add_anim_image, index, sprite] then @anim.insert index, sprite
      in [:sprite,     _, after]          then self.sprite     = after
      in [:anim,       _, after]          then self.anim       = after
      in [:anim_image, _, after]          then self.anim_image = after
      in [:snapshot,   _, after, x, y]    then restore_anim_image__ after, x, y
      in [  :select,   _, after]          then after ? select(*after) : deselect
      end
    end
  end

  def can_undo?() = history__.can_undo?
  def can_redo?() = history__.can_redo?

  def group_history(&block)   = history__.group(&block)

  def disable_history(&block) = history__.disable(&block)

  def canvas_pressed( x, y, button) = @tool&.canvas_pressed  x, y, button

  def canvas_released(x, y, button) = @tool&.canvas_released x, y, button

  def canvas_moved(   x, y)         = @tool&.canvas_moved    x, y

  def canvas_dragged( x, y, button) = @tool&.canvas_dragged  x, y, button

  def canvas_clicked( x, y, button) = @tool&.canvas_clicked  x, y, button

  private

  def history__() = @history ||= Reight::History.new

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
