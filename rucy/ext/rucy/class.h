// -*- c++ -*-
#pragma once
#ifndef __CLASS_H__
#define __CLASS_H__


#include <xot/ref.h>
#include <xot/string.h>
#include "rucy/extension.h"
#include "tester.h"


class Base : public Xot::RefCountable<>
{

	public:

		Base ()
		{
			log("Base()");
		}

		virtual ~Base ()
		{
			log("~Base()");
		}

		virtual const char* name () const
		{
			return "Base::name";
		}

		virtual const char* name_overridable () const
		{
			return "Base::name_overridable";
		}

};// Base


class Sub : public Base
{

	public:

		Sub ()
		{
			log("Sub()");
		}

		virtual ~Sub ()
		{
			log("~Sub()");
		}

		virtual const char* name () const
		{
			return "Sub::name";
		}

		virtual const char* name_overridable () const
		{
			return "Sub::name_overridable";
		}

};// Sub


class SimpleObj : public Xot::RefCountable<>
{

	public:

		void init (const char* name_)
		{
			name = name_;
			log("SimpleObj(" + name + ")");
		}

		~SimpleObj ()
		{
			log("~SimpleObj(" + name + ")");
		}

	private:

		Xot::String name;

};// SimpleObj


#endif//EOH
