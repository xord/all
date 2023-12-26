#include "rays/util.h"
#include "rays/ruby/point.h"
#include "defs.h"


static
RUCY_DEFN(perlin)
{
	check_arg_count(__FILE__, __LINE__, "Rays.perlin", argc, 1, 2, 3, 4);

	coord noise = 0;
	if (argc == 4)
	{
		noise = Rays::perlin(
			to<coord>(argv[0]),
			to<coord>(argv[1]),
			to<coord>(argv[2]),
			to<coord>(argv[3]));
	}
	else
		noise = Rays::perlin(to<Rays::Point>(argc, argv));

	return value(noise);
}
RUCY_END

static
RUCY_DEFN(simplex)
{
	check_arg_count(__FILE__, __LINE__, "Rays.simplex", argc, 1, 2, 3, 4);

	coord noise = 0;
	if (argc == 4)
	{
		noise = Rays::simplex(
			to<coord>(argv[0]),
			to<coord>(argv[1]),
			to<coord>(argv[2]),
			to<coord>(argv[3]));
	}
	else
		noise = Rays::simplex(to<Rays::Point>(argc, argv));

	return value(noise);
}
RUCY_END


void
Init_rays_util ()
{
	Module mRays = define_module("Rays");
	mRays.define_singleton_method("perlin", perlin);
	mRays.define_singleton_method("simplex", simplex);
}
