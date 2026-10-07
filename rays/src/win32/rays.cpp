#include "rays/rays.h"


#include "rays/exception.h"
#include "../renderer.h"


namespace Rays
{


	typedef void (*PreInitFun) ();


	namespace global
	{

		static bool initialized        = false;

		static PreInitFun pre_init_fun = NULL;

	}// global


	void
	Rays_set_pre_init_fun (PreInitFun fun)
	{
		global::pre_init_fun = fun;

		if (fun && global::initialized)
			fun();
	}

	void
	init ()
	{
		if (global::initialized)
			rays_error(__FILE__, __LINE__, "already initialized.");

		global::initialized = true;

		if (global::pre_init_fun)
			global::pre_init_fun();

		Renderer_init();
	}

	void
	fin ()
	{
		if (!global::initialized)
			rays_error(__FILE__, __LINE__, "not initialized.");

		Renderer_fin();

		global::initialized = false;
	}


}// Rays
