#include "reflex/ruby/menu.h"


#include <ranges>
#include <rays/ruby/image.h>
#include "reflex/exception.h"
#include "reflex/ruby/selector.h"
#include "reflex/ruby/view.h"
#include "defs.h"
#include "selector.h"


RUCY_DEFINE_WRAPPER_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::Menu)

#define THIS      to<Reflex::Menu*>(self)

#define CHECK     RUCY_CHECK_OBJ(Reflex::Menu, self)

#define CALL(fun) RUCY_CALL_SUPER(THIS, fun)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	return value(new Reflex::RubyMenu<Reflex::Menu>, klass);
}
RUCY_END

static
RUCY_DEFN(popup)
{
	CHECK;
	check_arg_count(__FILE__, __LINE__, "Menu#popup", argc, 2, 3);

	Reflex::View* view = NULL;
	if (argv[0].is_a(Reflex::view_class()))
	{
		view = to<Reflex::View*>(argv[0]);
		argc--;
		argv++;
	}
	THIS->popup(view, to<Rays::Point>(argc, argv));
	return self;
}
RUCY_END

static
RUCY_DEF2(add_child, child, index)
{
	CHECK;
	THIS->add_child(to<Reflex::Menu*>(child), index.is_nil() ? -1 : to<int>(index));
	return child;
}
RUCY_END

static
RUCY_DEF1(remove_child, child)
{
	CHECK;
	THIS->remove_child(to<Reflex::Menu*>(child));
	return child;
}
RUCY_END

static
RUCY_DEF0(clear_children)
{
	CHECK;
	THIS->clear_children();
	return self;
}
RUCY_END

static
RUCY_DEFN(find_children)
{
	CHECK;
	check_arg_count(__FILE__, __LINE__, "Menu#find_children", argc, 1, 2);

	bool recursive = (argc >= 2) ? to<bool>(argv[1]) : true;

	auto children =
		THIS->find_children(to<Reflex::Selector>(argv[0]), recursive) |
		std::views::transform([](auto& ref) {return value(ref);});
	return array(children.begin(), children.end());
}
RUCY_END

static
RUCY_DEF1(set_label, label)
{
	CHECK;
	THIS->set_label(label ? to<const char*>(label) : NULL);
}
RUCY_END

static
RUCY_DEF0(get_label)
{
	CHECK;
	return value(THIS->label());
}
RUCY_END

static
RUCY_DEF1(set_image, image)
{
	CHECK;
	THIS->set_image(image ? to<Rays::Image&>(image) : Rays::Image());
	return image;
}
RUCY_END

static
RUCY_DEF0(get_image)
{
	CHECK;
	const Rays::Image& image = THIS->image();
	return image ? value(image) : nil();
}
RUCY_END

static
RUCY_DEF1(enable, state)
{
	CHECK;
	THIS->enable(to<bool>(state));
}
RUCY_END

static
RUCY_DEF0(is_enabled)
{
	CHECK;
	return value(THIS->is_enabled());
}
RUCY_END

static
RUCY_DEF1(check, state)
{
	CHECK;
	THIS->check(to<bool>(state));
}
RUCY_END

static
RUCY_DEF0(is_checked)
{
	CHECK;
	return value(THIS->is_checked());
}
RUCY_END


static
RUCY_DEF1(set_shortcut_key, key)
{
	CHECK;
	THIS->set_shortcut(
		key ? to<const char*>(key) : NULL,
		THIS->shortcut_modifiers());
}
RUCY_END

static
RUCY_DEF0(get_shortcut_key)
{
	CHECK;
	return value(THIS->shortcut_key());
}
RUCY_END

static
RUCY_DEF1(set_shortcut_modifiers, modifiers)
{
	CHECK;
	THIS->set_shortcut(THIS->shortcut_key(), to<uint>(modifiers));
}
RUCY_END

static
RUCY_DEF0(get_shortcut_modifiers)
{
	CHECK;
	return value(THIS->shortcut_modifiers());
}
RUCY_END

static
RUCY_DEF0(is_separator)
{
	CHECK;
	return value(THIS->is_separator());
}
RUCY_END

static
RUCY_DEF0(get_parent)
{
	CHECK;
	return value(THIS->parent());
}
RUCY_END

static
RUCY_DEF0(get_size)
{
	CHECK;
	return value((int) THIS->size());
}
RUCY_END

static
RUCY_DEF0(is_empty)
{
	CHECK;
	return value(THIS->empty());
}
RUCY_END

static
RUCY_DEF0(each)
{
	CHECK;

	std::vector<Reflex::Menu::Ref> children(THIS->begin(), THIS->end());

	Value ret;
	for (auto& child : children)
		ret = rb_yield(value(child.get()));
	return ret;
}
RUCY_END

static
RUCY_DEF1(on_show, event)
{
	CHECK;
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
RUCY_DEF1(on_open_submenu, event)
{
	CHECK;
	CALL(on_open_submenu(to<Reflex::Event*>(event)));
}
RUCY_END

static
RUCY_DEF1(on_close_submenu, event)
{
	CHECK;
	CALL(on_close_submenu(to<Reflex::Event*>(event)));
}
RUCY_END

static
RUCY_DEF1(on_click, event)
{
	CHECK;
	CALL(on_click(to<Reflex::Event*>(event)));
}
RUCY_END


static Class cMenu;

void
Init_reflex_menu ()
{
	Module mReflex = define_module("Reflex");

	cMenu = mReflex.define_class("Menu");
	cMenu.define_alloc_func(alloc);
	cMenu.define_method("popup", popup);
	cMenu.define_method(   "add_child!",     add_child);
	cMenu.define_method("remove_child",   remove_child);
	cMenu.define_method( "clear_children", clear_children);
	cMenu.define_method(  "find_children",  find_children);
	cMenu.define_method("label=", set_label);
	cMenu.define_method("label",  get_label);
	cMenu.define_method("image=", set_image);
	cMenu.define_method("image",  get_image);
	cMenu.define_method("enable!",     enable);
	cMenu.define_method("enabled?", is_enabled);
	cMenu.define_method("check!",      check);
	cMenu.define_method("checked?", is_checked);
	cMenu.define_method("shortcut_key=",       set_shortcut_key);
	cMenu.define_method("shortcut_key",        get_shortcut_key);
	cMenu.define_method("shortcut_modifiers=", set_shortcut_modifiers);
	cMenu.define_method("shortcut_modifiers",  get_shortcut_modifiers);
	cMenu.define_method("separator?", is_separator);
	cMenu.define_method("parent", get_parent);
	cMenu.define_method("size",  get_size);
	cMenu.define_method("empty?", is_empty);
	cMenu.define_method("each!", each);
	cMenu.define_method("on_show",        on_show);
	cMenu.define_method("on_hide",        on_hide);
	cMenu.define_method("on_open_submenu",  on_open_submenu);
	cMenu.define_method("on_close_submenu", on_close_submenu);
	cMenu.define_method("on_click",       on_click);

	define_wrapper_equality_methods<Reflex::Menu>(cMenu);
	define_selector_methods<Reflex::Menu>(cMenu);
}


namespace Reflex
{


	Class
	menu_class ()
	{
		return cMenu;
	}


}// Reflex
