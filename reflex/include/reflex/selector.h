// -*- c++ -*-
#pragma once
#ifndef __REFLEX_SELECTOR_H__
#define __REFLEX_SELECTOR_H__


#include <set>
#include <xot/pimpl.h>
#include <reflex/defs.h>


namespace Reflex
{


	class SelectorPtr;


	class Selector
	{

		typedef Selector This;

		public:

			typedef std::set<String> TagSet;

			typedef TagSet::      iterator       iterator;

			typedef TagSet::const_iterator const_iterator;

			Selector (const char* name = NULL);

			This copy () const;

			bool contains (const This& selector) const;

			void    set_name (const char* name);

			const char* name () const;

			void    add_tag (const char* tag);

			void remove_tag (const char* tag);

			void  clear_tags ();

			bool    has_tag (const char* tag) const;

			      iterator begin ();

			const_iterator begin () const;

			      iterator end ();

			const_iterator end () const;

			bool empty () const;

			friend bool operator == (const This& lhs, const This& rhs);

			friend bool operator != (const This& lhs, const This& rhs);

			friend bool operator < (const This& lhs, const This& rhs);

			struct Data;

			Xot::PSharedImpl<Data> self;

	};// Selector


	class HasSelector
	{

		public:

			typedef Selector::      iterator       tag_iterator;

			typedef Selector::const_iterator const_tag_iterator;

			virtual ~HasSelector ();

			virtual void    set_name (const char* name);

			virtual const char* name () const;

			virtual void           add_tag (const char* tag);

			virtual void        remove_tag (const char* tag);

			virtual void         clear_tags ();

			virtual bool           has_tag (const char* tag) const;

			virtual       tag_iterator tag_begin ();

			virtual const_tag_iterator tag_begin () const;

			virtual       tag_iterator tag_end ();

			virtual const_tag_iterator tag_end () const;

			virtual void        set_selector (const Selector& selector);

			virtual       Selector& selector ();

			virtual const Selector& selector () const;

		protected:

			virtual       SelectorPtr* get_selector_ptr () = 0;

			virtual const SelectorPtr* get_selector_ptr () const;

	};// HasSelector


}// Reflex


#endif//EOH
