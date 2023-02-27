// -*- c++ -*-
#pragma once
#ifndef __REFLEX_FILTER_H__
#define __REFLEX_FILTER_H__


#include <xot/ref.h>
#include <xot/pimpl.h>
#include <rays/image.h>
#include <rays/shader.h>
#include <rays/painter.h>
#include <reflex/defs.h>


namespace Reflex
{


	class Filter : public Xot::RefCountable<>
	{

		typedef Filter This;

		public:

			typedef Xot::Ref<This> Ref;

			Filter ();

			Filter (const Shader& shader);

			virtual ~Filter ();

			virtual void apply (Painter* painter, const Image& image) const;

			virtual void      set_shader (const Shader& shader);

			virtual       Shader& shader ();

			virtual const Shader& shader () const;

			virtual operator bool () const;

			virtual bool operator ! () const;

			struct Data;

			Xot::PImpl<Data> self;

	};// Filter


}// Reflex


#endif//EOH
