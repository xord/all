// -*- c++ -*-
#pragma once
#ifndef __XOT_NONCOPYABLE_H__
#define __XOT_NONCOPYABLE_H__


namespace Xot
{


	class NonCopyable
	{

		protected:

			NonCopyable () = default;

			~NonCopyable () = default;

			NonCopyable (const NonCopyable&) = delete;

			NonCopyable& operator = (const NonCopyable&) = delete;

	};// NonCopyable


}// Xot


#endif//EOH
