// -*- c++ -*-
#pragma once
#ifndef __XOT_REF_H__
#define __XOT_REF_H__


#ifdef check // by OSX's AssertMacros.h
#undef check
#endif

#include <limits.h>
#include <assert.h>
#include <typeinfo>
#include <type_traits>
#include <xot/defs.h>
#include <xot/exception.h>
#include <xot/noncopyable.h>
#include <xot/debug.h>


//#define XOT_REF_DEBUG 1


namespace Xot
{


	class EmptyClass {};


	template <typename SuperClass = EmptyClass>
	class RefCountable : public SuperClass, public NonCopyable
	{

		public:

			virtual void retain (intptr_t data = 0) const
			{
				refc_update_count(true);

				#ifdef XOT_REF_DEBUG
					doutln(
						"%s: %d -> %d",
						typeid(this).name(), refc_count - 1, refc_count);
				#endif
			}

			virtual void release (intptr_t data = 0) const
			{
				assert(refc_count >= 0);

				bool del = refc_count == 0 || refc_update_count(false) == 0;

				#ifdef XOT_REF_DEBUG
					doutln(
						"%s: %d -> %d, delete:%s",
						typeid(this).name(), refc_count + 1, refc_count,
						del ? "yes" : "no");
				#endif

				if (del) delete this;
			}

			virtual void* rucy_wrapper_value () const
			{
				return NULL;
			}

			virtual bool rucy_disable_override () const
			{
				return false;
			}

		protected:

			RefCountable ()
			{
			}

			virtual ~RefCountable ()
			{
			}

		private:

			mutable int refc_count = 0;

			int refc_update_count (bool increment) const
			{
				int c = refc_count + (increment ? +1 : -1);
				if (c < 0)
					invalid_state_error(__FILE__, __LINE__, "refc_count underflow");
				if (c > INT_MAX)
					xot_error(__FILE__, __LINE__, "refc_count overflow.");

				return refc_count = c;
			}

	};// RefCountable


	template <typename T, typename = void>
	class Ref
	{

		typedef Ref<T> This;

		typedef       T       Value;

		typedef const T  ConstValue;

		typedef       T&      Reference;

		typedef const T& ConstReference;

		typedef       T*      Pointer;

		typedef const T* ConstPointer;

		public:

			Ref (Pointer ptr = NULL)
			:	ptr(ptr)
			{
				if (ptr) ptr->retain();
			}

			Ref (const This& obj)
			:	ptr(obj.ptr)
			{
				if (ptr) ptr->retain();
			}

			This& operator = (Pointer ptr)
			{
				reset(ptr);
				return *this;
			}

			This& operator = (const This& obj)
			{
				if (&obj == this) return *this;
				reset(obj.ptr);
				return *this;
			}

			~Ref ()
			{
				if (ptr) ptr->release();
			}

			void reset (Pointer ptr = NULL)
			{
				if (this->ptr == ptr) return;
				if (this->ptr) this->ptr->release();
				this->ptr = ptr;
				if (this->ptr) this->ptr->retain();
			}

			     Pointer get ()       {return ptr;}

			ConstPointer get () const {return ptr;}

			     Pointer operator -> ()       {return get();}

			ConstPointer operator -> () const {return get();}

			     Reference operator * ()       {return *get();}

			ConstReference operator * () const {return *get();}

			operator      Pointer ()       {return get();}

			operator ConstPointer () const {return get();}

			bool operator == (Pointer ptr) const {return this->ptr == ptr;}

			bool operator != (Pointer ptr) const {return !operator==(ptr);}

			bool operator == (ConstPointer ptr) const {return this->ptr == ptr;}

			bool operator != (ConstPointer ptr) const {return !operator==(ptr);}

			bool operator == (const This& obj) const {return ptr == obj.ptr;}

			bool operator != (const This& obj) const {return !operator==(obj);}

			template <typename X>
			bool operator == (const Ref<X>& obj) const {return ptr == obj.get();}

			template <typename X>
			bool operator != (const Ref<X>& obj) const {return !operator==(obj);}

			bool operator <  (const This& obj) const {return ptr < obj.ptr;}

			operator bool () const {return ptr != NULL;}

			bool operator ! () const {return !operator bool();}

		private:

			Pointer ptr;

	};// Ref


	template <typename T>
	class Ref<T, typename std::enable_if<std::is_const<T>::value>::type>
	{

		typedef Ref<T> This;

		typedef typename std::remove_const<T>::type Value;

		typedef                            T   ConstValue;

		typedef       Value&      Reference;

		typedef const Value& ConstReference;

		typedef       Value*      Pointer;

		typedef const Value* ConstPointer;

		public:

			Ref (ConstPointer ptr = NULL)
			:	ptr(ptr)
			{
				if (ptr) ptr->retain();
			}

			Ref (const This& obj)
			:	ptr(obj.ptr)
			{
				if (ptr) ptr->retain();
			}

			This& operator = (ConstPointer ptr)
			{
				reset(ptr);
				return *this;
			}

			This& operator = (const This& obj)
			{
				if (&obj == this) return *this;
				reset(obj.ptr);
				return *this;
			}

			~Ref ()
			{
				if (ptr) ptr->release();
			}

			void reset (ConstPointer ptr = NULL)
			{
				if (this->ptr == ptr) return;
				if (this->ptr) this->ptr->release();
				this->ptr = ptr;
				if (this->ptr) this->ptr->retain();
			}

			ConstPointer get () const {return ptr;}

			ConstPointer operator -> () const {return get();}

			ConstReference operator * () const {return *get();}

			operator ConstPointer () const {return get();}

			bool operator == (ConstPointer ptr) const {return this->ptr == ptr;}

			bool operator != (ConstPointer ptr) const {return !operator==(ptr);}

			bool operator == (const This& obj) const {return ptr == obj.ptr;}

			bool operator != (const This& obj) const {return !operator==(obj);}

			template <typename X>
			bool operator == (const Ref<X>& obj) const {return ptr == obj.get();}

			template <typename X>
			bool operator != (const Ref<X>& obj) const {return !operator==(obj);}

			bool operator <  (const This& obj) const {return ptr < obj.ptr;}

			operator bool () const {return ptr != NULL;}

			bool operator ! () const {return !operator bool();}

		private:

			ConstPointer ptr;

	};// Ref


}// Xot


#endif//EOH
