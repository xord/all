// -*- c++ -*-
#pragma once
#ifndef __REFLEX_EXT_SELECTOR_H__
#define __REFLEX_EXT_SELECTOR_H__


#include "reflex/ruby/selector.h"


template <typename T>
static
RUCY_DEF1(set_name, name)
{
	RUCY_CHECK_OBJ(T, self);
	Reflex::HasSelector* this_ = Rucy::to<T*>(self);

	this_->set_name(name.is_nil() ? NULL : name.c_str());
}
RUCY_END

template <typename T>
static
RUCY_DEF0(get_name)
{
	RUCY_CHECK_OBJ(T, self);
	const Reflex::HasSelector* this_ = Rucy::to<const T*>(self);

	return this_->name() ? Rucy::value(this_->name()) : Rucy::nil();
}
RUCY_END

template <typename T>
static
RUCY_DEF1(add_tag, tag)
{
	RUCY_CHECK_OBJ(T, self);
	Reflex::HasSelector* this_ = Rucy::to<T*>(self);

	this_->add_tag(tag.c_str());
}
RUCY_END

template <typename T>
static
RUCY_DEF1(remove_tag, tag)
{
	RUCY_CHECK_OBJ(T, self);
	Reflex::HasSelector* this_ = Rucy::to<T*>(self);

	this_->remove_tag(tag.c_str());
}
RUCY_END

template <typename T>
static
RUCY_DEF0(clear_tags)
{
	RUCY_CHECK_OBJ(T, self);
	Reflex::HasSelector* this_ = Rucy::to<T*>(self);

	this_->clear_tags();
}
RUCY_END

template <typename T>
static
RUCY_DEF1(has_tag, tag)
{
	RUCY_CHECK_OBJ(T, self);
	const Reflex::HasSelector* this_ = Rucy::to<const T*>(self);

	return Rucy::value(this_->has_tag(tag.c_str()));
}
RUCY_END

template <typename T>
static
RUCY_DEF0(each_tag)
{
	RUCY_CHECK_OBJ(T, self);
	const Reflex::HasSelector* this_ = Rucy::to<const T*>(self);

	Rucy::Value ret;
	Reflex::Selector::const_iterator end = this_->tag_end();
	for (Reflex::Selector::const_iterator it = this_->tag_begin(); it != end; ++it)
		ret = rb_yield(Rucy::value(*it));
	return ret;
}
RUCY_END

template <typename T>
static
RUCY_DEF1(set_selector, selector)
{
	RUCY_CHECK_OBJ(T, self);
	Reflex::HasSelector* this_ = Rucy::to<T*>(self);

	this_->set_selector(Rucy::to<Reflex::Selector>(selector));
}
RUCY_END

template <typename T>
static
RUCY_DEF0(get_selector)
{
	RUCY_CHECK_OBJ(T, self);
	const Reflex::HasSelector* this_ = Rucy::to<const T*>(self);

	return Rucy::value(this_->selector());
}
RUCY_END


template <typename T>
static void
define_selector_methods (Rucy::Class klass)
{
	klass.define_method("name=", set_name<T>);
	klass.define_method("name",  get_name<T>);
	klass.define_method("add_tag",    add_tag<T>);
	klass.define_method("remove_tag", remove_tag<T>);
	klass.define_method("clear_tags", clear_tags<T>);
	klass.define_method("tag?",       has_tag<T>);
	klass.define_method("each_tag",   each_tag<T>);
	klass.define_method("selector=", set_selector<T>);
	klass.define_method("selector",  get_selector<T>);
}


#endif//EOH
