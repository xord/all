#include "menu.h"


#include <algorithm>
#include <rays/point.h>
#include "reflex/exception.h"


namespace Reflex
{


	Menu::Data::Data ()
	{
	}

	Menu::Data::~Data ()
	{
	}


	Menu::Menu (const char* label)
	:	self(Menu_create_data())
	{
		if (label) set_label(label);
	}

	Menu::~Menu ()
	{
	}

	void
	Menu::popup (coord x, coord y)
	{
		Menu_popup(this, NULL, x, y);
	}

	void
	Menu::popup (const Point& position)
	{
		Menu_popup(this, NULL, position.x, position.y);
	}

	void
	Menu::popup (View* view, coord x, coord y)
	{
		Menu_popup(this, view, x, y);
	}

	void
	Menu::popup (View* view, const Point& position)
	{
		Menu_popup(this, view, position.x, position.y);
	}

	void
	Menu::add_child (Menu* child, int index)
	{
		if (!child)
			argument_error(__FILE__, __LINE__);

		if (child->parent() == this)
			return;

		if (child->parent())
			argument_error(__FILE__, __LINE__);

		ChildList* children = self->children();
		if (index < 0 || (int) children->size() < index)
			index = (int) children->size();

		children->insert(children->begin() + (size_t) index, child);

		child->self->parent.reset(this);

		Menu_child_added(this, child, index);
	}

	void
	Menu::remove_child (Menu* child)
	{
		if (!child || child->parent() != this)
			return;

		auto* children = self->pchildren.get();
		if (!children) return;

		auto it = std::find(children->begin(), children->end(), child);
		if (it == children->end()) return;

		children->erase(it);
		if (children->empty())
			self->pchildren.reset();

		child->self->parent.reset();

		Menu_child_removed(this, child);
	}

	void
	Menu::clear_children ()
	{
		while (self->pchildren && !self->pchildren->empty())
			remove_child(self->pchildren->back().get());
	}

	static void
	find_all_children (
		Menu::ChildList* result, const Menu* menu, const Selector& selector,
		bool recursive)
	{
		auto* children = menu->self->pchildren.get();
		if (!children) return;

		for (auto& child : *children)
		{
			if (!child)
				invalid_state_error(__FILE__, __LINE__);

			if (child->selector().contains(selector))
				result->push_back(child);

			if (recursive)
				find_all_children(result, child.get(), selector, true);
		}
	}

	Menu::ChildList
	Menu::find_children (const Selector& selector, bool recursive) const
	{
		ChildList result;
		find_all_children(&result, this, selector, recursive);
		return result;
	}

	static bool
	is_separator_label (const char* s)
	{
		if (!s || !*s) return false;
		for (const char* p = s; *p; ++p)
			if (*p != '-') return false;
		return true;
	}

	void
	Menu::set_label (const char* label)
	{
		if (!label) label = "";
		if (label == self->label)
			return;

		self->label     = label;
		self->separator = is_separator_label(label);

		Menu_update(this);
	}

	const char*
	Menu::label () const
	{
		return self->label.c_str();
	}

	void
	Menu::enable (bool state)
	{
		if (state == self->enabled)
			return;

		self->enabled = state;
		Menu_update(this);
	}

	bool
	Menu::is_enabled () const
	{
		return self->enabled;
	}

	void
	Menu::check (bool state)
	{
		if (state == self->checked)
			return;

		self->checked = state;
		Menu_update(this);
	}

	bool
	Menu::is_checked () const
	{
		return self->checked;
	}

	void
	Menu::set_shortcut (const char* key, uint modifiers)
	{
		if (!key) key = "";
		if (key == self->key && modifiers == self->modifiers)
			return;

		self->key       = key;
		self->modifiers = modifiers;
		Menu_update(this);
	}

	const char*
	Menu::shortcut_key () const
	{
		return self->key.c_str();
	}

	uint
	Menu::shortcut_modifiers () const
	{
		return self->modifiers;
	}

	void
	Menu::set_image (const Image& image)
	{
		self->image = image;
		Menu_update(this);
	}

	const Image&
	Menu::image () const
	{
		return self->image;
	}

	bool
	Menu::is_separator () const
	{
		return self->separator;
	}

	Menu*
	Menu::parent ()
	{
		return self->parent;
	}

	const Menu*
	Menu::parent () const
	{
		return const_cast<Menu*>(this)->parent();
	}

	size_t
	Menu::size () const
	{
		return self->pchildren ? self->pchildren->size() : 0;
	}

	bool
	Menu::empty () const
	{
		return self->pchildren ? self->pchildren->empty() : true;
	}

	static Menu::ChildList empty_children;

	Menu::iterator
	Menu::begin ()
	{
		if (!self->pchildren) return empty_children.begin();
		return self->pchildren->begin();
	}

	Menu::const_iterator
	Menu::begin () const
	{
		if (!self->pchildren) return empty_children.begin();
		return self->pchildren->begin();
	}

	Menu::iterator
	Menu::end ()
	{
		if (!self->pchildren) return empty_children.end();
		return self->pchildren->end();
	}

	Menu::const_iterator
	Menu::end () const
	{
		if (!self->pchildren) return empty_children.end();
		return self->pchildren->end();
	}

	void
	Menu::on_show (Event* e)
	{
	}

	void
	Menu::on_hide (Event* e)
	{
	}

	void
	Menu::on_open_submenu (Event* e)
	{
	}

	void
	Menu::on_close_submenu (Event* e)
	{
	}

	void
	Menu::on_click (Event* e)
	{
	}

	SelectorPtr*
	Menu::get_selector_ptr ()
	{
		return &self->pselector;
	}


}// Reflex
