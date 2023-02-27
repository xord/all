// -*- c++ -*-
#pragma once
#ifndef __REFLEX_SRC_SELECTOR_H__
#define __REFLEX_SRC_SELECTOR_H__


#include <memory>
#include <reflex/selector.h>


namespace Reflex
{


	class SelectorPtr : public std::unique_ptr<Selector>
	{

		public:

			void    set_name (const char* name);

			const char* name () const;

			void                 add_tag (const char* tag);

			void              remove_tag (const char* tag);

			void               clear_tags ();

			bool                 has_tag (const char* tag) const;

			Selector::      iterator tag_begin ();

			Selector::const_iterator tag_begin () const;

			Selector::      iterator tag_end ();

			Selector::const_iterator tag_end () const;

			void            set_selector (const Selector& selector);

			      Selector& selector ();

			const Selector& selector () const;

	};// SelectorPtr


}// Reflex


#endif//EOH
