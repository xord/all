#include "reflex/ruby/window.h"


#include <rays/ruby/bounds.h>
#include <rays/ruby/painter.h>
#include "reflex/ruby/screen.h"
#include "reflex/ruby/view.h"
#include "defs.h"


RUCY_DEFINE_WRAPPER_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::Window)

#define THIS      to<Reflex::Window*>(self)

#define CHECK     RUCY_CHECK_OBJECT(Reflex::Window, self)

#define CALL(fun) RUCY_CALL_SUPER(THIS, fun)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	return value(new Reflex::RubyWindow<Reflex::Window>, klass);
}
RUCY_END

static
RUCY_DEF0(show)
{
	CHECK;
	THIS->show();
	return self;
}
RUCY_END

static
RUCY_DEF0(hide)
{
	CHECK;
	THIS->hide();
	return self;
}
RUCY_END

static
RUCY_DEF0(hidden)
{
	CHECK;
	return value(THIS->hidden());
}
RUCY_END

static
RUCY_DEF0(close)
{
	CHECK;
	THIS->close();
	return self;
}
RUCY_END

static
RUCY_DEF0(redraw)
{
	CHECK;
	THIS->redraw();
	return self;
}
RUCY_END

static
RUCY_DEF1(from_screen, point)
{
	CHECK;
	return value(THIS->from_screen(to<Rays::Point>(point)));
}
RUCY_END

static
RUCY_DEF1(to_screen, point)
{
	CHECK;
	return value(THIS->to_screen(to<Rays::Point>(point)));
}
RUCY_END

static
RUCY_DEF1(set_title, title)
{
	CHECK;
	THIS->set_title(title.c_str());
	return title;
}
RUCY_END

static
RUCY_DEF0(get_title)
{
	CHECK;
	return value(THIS->title());
}
RUCY_END

static
RUCY_DEFN(set_frame)
{
	CHECK;
	THIS->set_frame(to<Rays::Bounds>(argc, argv));
	return value(THIS->frame());
}
RUCY_END

static
RUCY_DEF0(get_frame)
{
	CHECK;
	return value(THIS->frame());
}
RUCY_END

static
RUCY_DEF1(set_closable, state)
{
	CHECK;

	if (state)
		THIS->   add_flag(Reflex::Window::FLAG_CLOSABLE);
	else
		THIS->remove_flag(Reflex::Window::FLAG_CLOSABLE);

	return state;
}
RUCY_END

static
RUCY_DEF0(is_closable)
{
	CHECK;
	return value(THIS->has_flag(Reflex::Window::FLAG_CLOSABLE));
}
RUCY_END

static
RUCY_DEF1(set_minimizable, state)
{
	CHECK;

	if (state)
		THIS->   add_flag(Reflex::Window::FLAG_MINIMIZABLE);
	else
		THIS->remove_flag(Reflex::Window::FLAG_MINIMIZABLE);

	return state;
}
RUCY_END

static
RUCY_DEF0(is_minimizable)
{
	CHECK;
	return value(THIS->has_flag(Reflex::Window::FLAG_MINIMIZABLE));
}
RUCY_END

static
RUCY_DEF1(set_resizable, state)
{
	CHECK;

	if (state)
		THIS->   add_flag(Reflex::Window::FLAG_RESIZABLE);
	else
		THIS->remove_flag(Reflex::Window::FLAG_RESIZABLE);

	return state;
}
RUCY_END

static
RUCY_DEF0(is_resizable)
{
	CHECK;
	return value(THIS->has_flag(Reflex::Window::FLAG_RESIZABLE));
}
RUCY_END

static
RUCY_DEF1(set_fullscreen, state)
{
	CHECK;

	if (state)
		THIS->   add_flag(Reflex::Window::FLAG_FULLSCREEN);
	else
		THIS->remove_flag(Reflex::Window::FLAG_FULLSCREEN);

	return state;
}
RUCY_END

static
RUCY_DEF0(is_fullscreen)
{
	CHECK;
	return value(THIS->has_flag(Reflex::Window::FLAG_FULLSCREEN));
}
RUCY_END

static const uint ORIENTATION_MASK =
	Reflex::Window::FLAG_PORTRAIT | Reflex::Window::FLAG_LANDSCAPE;

static
RUCY_DEF1(set_orientations, orientations)
{
	using namespace Reflex;

	CHECK;

	uint flags = to<uint>(orientations);
	THIS->set_flag(
		(      flags   &  ORIENTATION_MASK) |
		(THIS->flags() & ~ORIENTATION_MASK));
}
RUCY_END

static
RUCY_DEF0(get_orientations)
{
	using namespace Reflex;

	CHECK;
	return value(THIS->flags() & ORIENTATION_MASK);
}
RUCY_END

static
RUCY_DEF0(get_screen)
{
	CHECK;
	return value(THIS->screen());
}
RUCY_END

static
RUCY_DEF0(get_root)
{
	CHECK;
	return value(THIS->root());
}
RUCY_END

static
RUCY_DEF0(get_focus)
{
	CHECK;
	return value(THIS->focus());
}
RUCY_END

static
RUCY_DEF0(get_painter)
{
	CHECK;
	return value(THIS->painter());
}
RUCY_END

static
RUCY_DEF1(on_activate, event)
{
	CHECK;
	CALL(on_activate(to<Reflex::Event*>(event)));
}
RUCY_END

static
RUCY_DEF1(on_deactivate, event)
{
	CHECK;
	CALL(on_deactivate(to<Reflex::Event*>(event)));
}
RUCY_END

static
RUCY_DEF1(on_show, event)
{
	CHECK;

	RUCY_SYM(call_show_block);
	self.call(call_show_block);

	CALL(on_show(to<Reflex::Event*>(event)));
}
RUCY_END

static
RUCY_DEF1(on_hide, event)
{
	CHECK;
	CALL(on_hide(to<Reflex::Event*>(event)));
}
RUCY_END

static
RUCY_DEF1(on_close, event)
{
	CHECK;
	CALL(on_close(to<Reflex::Event*>(event)));
}
RUCY_END

static
RUCY_DEF1(on_update, event)
{
	CHECK;
	CALL(on_update(to<Reflex::UpdateEvent*>(event)));
}
RUCY_END

static
RUCY_DEF1(on_draw, event)
{
	CHECK;
	CALL(on_draw(to<Reflex::DrawEvent*>(event)));
}
RUCY_END

static
RUCY_DEF1(on_move, event)
{
	CHECK;
	CALL(on_move(to<Reflex::FrameEvent*>(event)));
}
RUCY_END

static
RUCY_DEF1(on_resize, event)
{
	CHECK;
	CALL(on_resize(to<Reflex::FrameEvent*>(event)));
}
RUCY_END

static
RUCY_DEF1(on_key, event)
{
	CHECK;
	CALL(on_key(to<Reflex::KeyEvent*>(event)));
}
RUCY_END

static
RUCY_DEF1(on_key_down, event)
{
	CHECK;
	CALL(on_key_down(to<Reflex::KeyEvent*>(event)));
}
RUCY_END

static
RUCY_DEF1(on_key_up, event)
{
	CHECK;
	CALL(on_key_up(to<Reflex::KeyEvent*>(event)));
}
RUCY_END

static
RUCY_DEF1(on_pointer, event)
{
	CHECK;
	CALL(on_pointer(to<Reflex::PointerEvent*>(event)));
}
RUCY_END

static
RUCY_DEF1(on_pointer_down, event)
{
	CHECK;
	CALL(on_pointer_down(to<Reflex::PointerEvent*>(event)));
}
RUCY_END

static
RUCY_DEF1(on_pointer_up, event)
{
	CHECK;
	CALL(on_pointer_up(to<Reflex::PointerEvent*>(event)));
}
RUCY_END

static
RUCY_DEF1(on_pointer_move, event)
{
	CHECK;
	CALL(on_pointer_move(to<Reflex::PointerEvent*>(event)));
}
RUCY_END

static
RUCY_DEF1(on_pointer_cancel, event)
{
	CHECK;
	CALL(on_pointer_cancel(to<Reflex::PointerEvent*>(event)));
}
RUCY_END

static
RUCY_DEF1(on_wheel, event)
{
	CHECK;
	CALL(on_wheel(to<Reflex::WheelEvent*>(event)));
}
RUCY_END

static
RUCY_DEF1(on_note, event)
{
	CHECK;
	CALL(on_note(to<Reflex::NoteEvent*>(event)));
}
RUCY_END

static
RUCY_DEF1(on_note_on, event)
{
	CHECK;
	CALL(on_note_on(to<Reflex::NoteEvent*>(event)));
}
RUCY_END

static
RUCY_DEF1(on_note_off, event)
{
	CHECK;
	CALL(on_note_off(to<Reflex::NoteEvent*>(event)));
}
RUCY_END


static Class cWindow;

void
Init_reflex_window ()
{
	Module mReflex = define_module("Reflex");

	cWindow = mReflex.define_class("Window");
	cWindow.define_alloc_func(alloc);
	cWindow.define_method("show", show);
	cWindow.define_method("hide", hide);
	cWindow.define_method("close", close);
	cWindow.define_method("redraw", redraw);
	cWindow.define_method("from_screen", from_screen);
	cWindow.define_method(  "to_screen",   to_screen);
	cWindow.define_method("title=", set_title);
	cWindow.define_method("title", get_title);
	cWindow.define_method("frame=", set_frame);
	cWindow.define_method("frame",  get_frame);
	cWindow.define_method("closable=",    set_closable);
	cWindow.define_method("closable?",     is_closable);
	cWindow.define_method("minimizable=", set_minimizable);
	cWindow.define_method("minimizable?",  is_minimizable);
	cWindow.define_method("resizable=",   set_resizable);
	cWindow.define_method("resizable?",    is_resizable);
	cWindow.define_method("fullscreen=",  set_fullscreen);
	cWindow.define_method("fullscreen?",   is_fullscreen);
	cWindow.define_method("orientations=", set_orientations);
	cWindow.define_method("orientations",  get_orientations);
	cWindow.define_method("hidden", hidden);
	cWindow.define_method("screen",  get_screen);
	cWindow.define_method("root",    get_root);
	cWindow.define_method("focus",   get_focus);
	cWindow.define_method("painter", get_painter);
	cWindow.define_method("on_activate",   on_activate);
	cWindow.define_method("on_deactivate", on_deactivate);
	cWindow.define_method("on_show",  on_show);
	cWindow.define_method("on_hide",  on_hide);
	cWindow.define_method("on_close", on_close);
	cWindow.define_method("on_update", on_update);
	cWindow.define_method("on_draw",   on_draw);
	cWindow.define_method("on_move",   on_move);
	cWindow.define_method("on_resize", on_resize);
	cWindow.define_method("on_key",      on_key);
	cWindow.define_method("on_key_down", on_key_down);
	cWindow.define_method("on_key_up",   on_key_up);
	cWindow.define_method("on_pointer",      on_pointer);
	cWindow.define_method("on_pointer_down",   on_pointer_down);
	cWindow.define_method("on_pointer_up",     on_pointer_up);
	cWindow.define_method("on_pointer_move",   on_pointer_move);
	cWindow.define_method("on_pointer_cancel", on_pointer_cancel);
	cWindow.define_method("on_wheel", on_wheel);
	cWindow.define_method("on_note",     on_note);
	cWindow.define_method("on_note_on",  on_note_on);
	cWindow.define_method("on_note_off", on_note_off);

	cWindow.define_const("ORIENTATION_PORTRAIT",  Reflex::Window::FLAG_PORTRAIT);
	cWindow.define_const("ORIENTATION_LANDSCAPE", Reflex::Window::FLAG_LANDSCAPE);
}


namespace Reflex
{


	Class
	window_class ()
	{
		return cWindow;
	}


}// Reflex
