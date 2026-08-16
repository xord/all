#include "reflex-terminal/ruby/renderer.h"


#include <rays/ruby/bounds.h>
#include <rays/ruby/font.h>
#include <rays/ruby/painter.h>
#include <reflex-terminal/ruby/terminal.h>
#include "defs.h"


RUCY_DEFINE_VALUE_FROM_TO(REFLEX_TERMINAL_EXPORT, ReflexTerminal::Renderer)

#define THIS  to<ReflexTerminal::Renderer*>(self)

#define CHECK RUCY_CHECK_OBJ(ReflexTerminal::Renderer, self)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	return new_type<ReflexTerminal::Renderer>(klass);
}
RUCY_END

static
RUCY_DEF1(set_font, font)
{
	CHECK;
	THIS->set_font(to<Rays::Font&>(font));
	return font;
}
RUCY_END

static
RUCY_DEF0(get_font)
{
	CHECK;
	return value(THIS->font());
}
RUCY_END

static
RUCY_DEF0(get_cell_width)
{
	CHECK;
	return value(THIS->cell_width());
}
RUCY_END

static
RUCY_DEF0(get_cell_height)
{
	CHECK;
	return value(THIS->cell_height());
}
RUCY_END

static
RUCY_DEF1(bake_glyphs, terminal)
{
	CHECK;
	THIS->bake_glyphs(to<Reflex::Terminal&>(terminal));
	return self;
}
RUCY_END

static
RUCY_DEF0(get_glyph_count)
{
	CHECK;
	return value(THIS->glyph_count());
}
RUCY_END

static
RUCY_DEF1(set_blink_visible, visible)
{
	CHECK;
	THIS->set_blink_visible(to<bool>(visible));
}
RUCY_END

static
RUCY_DEF0(is_blink_visible)
{
	CHECK;
	return value(THIS->blink_visible());
}
RUCY_END

static
RUCY_DEF1(set_background_alpha, alpha)
{
	CHECK;
	THIS->set_background_alpha(to<float>(alpha));
}
RUCY_END

static
RUCY_DEF0(get_background_alpha)
{
	CHECK;
	return value(THIS->background_alpha());
}
RUCY_END

static
RUCY_DEF3(draw, painter, terminal, bounds)
{
	CHECK;
	THIS->draw(
		to<Rays::Painter*>(painter),
		to<Reflex::Terminal&>(terminal),
		to<Rays::Bounds>(bounds));
	return self;
}
RUCY_END


static Class cRenderer;

void
Init_reflex_terminal_renderer ()
{
	Module mReflexTerminal = define_module("ReflexTerminal");

	cRenderer = mReflexTerminal.define_class("Renderer");
	cRenderer.define_alloc_func(alloc);
	cRenderer.define_method("font=", set_font);
	cRenderer.define_method("font",  get_font);
	cRenderer.define_method("cell_width",  get_cell_width);
	cRenderer.define_method("cell_height", get_cell_height);
	cRenderer.define_method("bake_glyphs",     bake_glyphs);
	cRenderer.define_method(     "glyph_count", get_glyph_count);
	cRenderer.define_method("blink_visible=", set_blink_visible);
	cRenderer.define_method("blink_visible?",  is_blink_visible);
	cRenderer.define_method("background_alpha=", set_background_alpha);
	cRenderer.define_method("background_alpha",  get_background_alpha);
	cRenderer.define_method("draw", draw);
}


namespace ReflexTerminal
{


	Class
	renderer_class ()
	{
		return cRenderer;
	}


}// ReflexTerminal
