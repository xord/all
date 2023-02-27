// -*- c++ -*-
#pragma once
#ifndef __XOT_PIMPL_H__
#define __XOT_PIMPL_H__


#include <memory>


namespace Xot
{


	template <typename T>
	class PImpl : public std::unique_ptr<T>
	{

		typedef std::unique_ptr<T> Super;

		typedef PImpl<T> This;

		public:

			PImpl () : Super(new T) {}

			PImpl (T* p) : Super(p) {}

			PImpl (const This& obj)
			:	Super(obj ? new T(*obj) : NULL)
			{
			}

			This& operator = (const This& obj)
			{
				if (&obj == this) return *this;

				this->reset(obj ? new T(*obj) : NULL);
				return *this;
			}

	};// PImpl


	template <typename T>
	class PSharedImpl : public std::shared_ptr<T>
	{

		typedef std::shared_ptr<T> Super;

		typedef PSharedImpl<T> This;

		public:

			PSharedImpl () : Super(new T) {}

			PSharedImpl (T* p) : Super(p) {}

	};// PSharedImpl


}// Xot


#endif//EOH
