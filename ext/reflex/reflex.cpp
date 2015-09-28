#include <rucy.h>
#include "reflex/reflex.h"
#include "reflex/ruby/view.h"
#include "reflex/ruby/timer.h"
#include "defs.h"


using namespace Rucy;


namespace Reflex
{
	typedef View*  (*CreateRootViewFun) ();
	typedef Timer* (*CreateTimerFun)    ();
	void set_create_root_view_fun (CreateRootViewFun);
	void set_create_timer_fun     (CreateTimerFun);
}

static Reflex::View*
create_root_view ()
{
	return new Reflex::RubyView<Reflex::View>;
}

static Reflex::Timer*
create_timer ()
{
	return new Reflex::RubyTimer<Reflex::Timer>;
}


static
RUCY_DEF0(init)
{
	Reflex::init();
	Reflex::set_create_root_view_fun(create_root_view);
	Reflex::set_create_timer_fun(create_timer);

	return self;
}
RUCY_END

static
RUCY_DEF0(fin)
{
	Reflex::fin();
	return self;
}
RUCY_END


static Module mReflex;

void
Init_reflex ()
{
	mReflex = define_module("Reflex");
	mReflex.define_singleton_method("init!", init);
	mReflex.define_singleton_method("fin!", fin);
}


namespace Reflex
{


	Module
	reflex_module ()
	{
		return mReflex;
	}


}// Reflex
