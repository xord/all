// -*- c++ -*-
#pragma once
#ifndef __REFLEX_MENU_H__
#define __REFLEX_MENU_H__


#include <vector>
#include <xot/ref.h>
#include <xot/pimpl.h>
#include <reflex/defs.h>
#include <reflex/selector.h>


namespace Reflex
{


	class Event;
	class View;


	class Menu : public Xot::RefCountable<>, public HasSelector
	{

		public:

			typedef Xot::Ref<Menu> Ref;

			typedef std::vector<Ref> ChildList;

			typedef ChildList::      iterator       iterator;

			typedef ChildList::const_iterator const_iterator;

			Menu (const char* label = NULL);

			virtual ~Menu ();

			virtual void popup (coord x, coord y);

			virtual void popup (const Point& position);

			virtual void popup (View* view, coord x, coord y);

			virtual void popup (View* view, const Point& position);

			virtual void       add_child (Menu* child, int index = -1);

			virtual void    remove_child (Menu* child);

			virtual void     clear_children ();

			virtual ChildList find_children (
				const Selector& selector, bool recursive = true) const;

			virtual void    set_label (const char* label);

			virtual const char* label () const;

			virtual void    enable (bool state);

			virtual bool is_enabled () const;

			virtual void    check (bool);

			virtual bool is_checked () const;

			virtual void    set_shortcut (const char* key, uint modifiers = MOD_NONE);

			virtual const char* shortcut_key () const;

			virtual uint        shortcut_modifiers () const;

			virtual void     set_image (const Image& image);

			virtual const Image& image () const;

			virtual bool is_separator () const;

			virtual       Menu* parent ();

			virtual const Menu* parent () const;

			virtual size_t size () const;

			virtual bool empty () const;

			virtual       iterator begin ();

			virtual const_iterator begin () const;

			virtual       iterator end ();

			virtual const_iterator end () const;

			virtual void on_show (Event* e);

			virtual void on_hide (Event* e);

			virtual void on_open_submenu  (Event* e);

			virtual void on_close_submenu (Event* e);

			virtual void on_click (Event* e);

			struct Data;

			Xot::PImpl<Data> self;

		protected:

			virtual SelectorPtr* get_selector_ptr ();

	};// Menu


}// Reflex


#endif//EOH
