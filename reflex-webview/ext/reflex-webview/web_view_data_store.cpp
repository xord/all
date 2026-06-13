#include "reflex-webview/ruby/web_view.h"


#include "defs.h"


RUCY_DEFINE_VALUE_FROM_TO(REFLEX_WEBVIEW_EXPORT, Reflex::WebView::DataStore)

#define THIS  to<Reflex::WebView::DataStore*>(self)

#define CHECK RUCY_CHECK_OBJ(Reflex::WebView::DataStore, self)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	return new_type<Reflex::WebView::DataStore>(klass);
}
RUCY_END

// DataStore.new -> an ephemeral (incognito) store.
static
RUCY_DEF0(initialize)
{
	CHECK;
	*THIS = Reflex::WebView::DataStore::create_ephemeral();
	return rb_call_super(0, NULL);
}
RUCY_END

static
RUCY_DEF1(initialize_copy, obj)
{
	CHECK;
	*THIS = to<Reflex::WebView::DataStore&>(obj);
	return self;
}
RUCY_END

// DataStore.default -> the shared default persistent store.
static
RUCY_DEF0(get_default)
{
	return value(Reflex::WebView::DataStore::create_default());
}
RUCY_END

// DataStore.load(name) -> a named persistent profile (macOS 14+).
static
RUCY_DEF1(load, name)
{
	return value(Reflex::WebView::DataStore::create_named(name.c_str()));
}
RUCY_END

static
RUCY_DEF0(is_persistent)
{
	CHECK;
	return value(THIS->persistent());
}
RUCY_END

static
RUCY_DEF0(get_name)
{
	CHECK;
	Xot::String n = THIS->name();
	return n.empty() ? nil() : value(n.c_str());
}
RUCY_END

static
RUCY_DEF0(clear)
{
	CHECK;
	THIS->clear();
	return self;
}
RUCY_END


static Class cDataStore;

void
Init_reflex_web_view_data_store ()
{
	Class cWebView = Reflex::web_view_class();

	cDataStore = cWebView.define_class("DataStore");
	cDataStore.define_alloc_func(alloc);
	cDataStore.define_private_method("initialize",      initialize);
	cDataStore.define_private_method("initialize_copy", initialize_copy);
	cDataStore.define_singleton_method("default", get_default);
	cDataStore.define_singleton_method("load",    load);
	cDataStore.define_method("persistent?", is_persistent);
	cDataStore.define_method("name",        get_name);
	cDataStore.define_method("clear",       clear);
}


namespace Reflex
{


	Class
	web_view_data_store_class ()
	{
		return cDataStore;
	}


}// Reflex
