#include "rays/ruby/rays.h"


#include <assert.h>
#include <vector>
#include "defs.h"


RUCY_DEFINE_CONVERT_TO(Rays::CapType)
RUCY_DEFINE_CONVERT_TO(Rays::JoinType)
RUCY_DEFINE_CONVERT_TO(Rays::BlendMode)


template <typename T>
struct EnumType
{
	const char* name;
	const char* short_name;
	T value;
};

static std::vector<EnumType<Rays::CapType>> CAP_TYPES({
	{"CAP_BUTT",   "BUTT",   Rays::CAP_BUTT},
	{"CAP_ROUND",  "ROUND",  Rays::CAP_ROUND},
	{"CAP_SQUARE", "SQUARE", Rays::CAP_SQUARE},
});

static std::vector<EnumType<Rays::JoinType>> JOIN_TYPES({
	{"JOIN_MITER",  "MITER",  Rays::JOIN_MITER},
	{"JOIN_ROUND",  "ROUND",  Rays::JOIN_ROUND},
	{"JOIN_SQUARE", "SQUARE", Rays::JOIN_SQUARE},
});

static std::vector<EnumType<Rays::BlendMode>> BLEND_MODES({
	{"BLEND_NORMAL",    "NORMAL",    Rays::BLEND_NORMAL},
	{"BLEND_ADD",       "ADD",       Rays::BLEND_ADD},
	{"BLEND_SUBTRACT",  "SUBTRACT",  Rays::BLEND_SUBTRACT},
	{"BLEND_LIGHTEST",  "LIGHTEST",  Rays::BLEND_LIGHTEST},
	{"BLEND_DARKEST",   "DARKEST",   Rays::BLEND_DARKEST},
	{"BLEND_EXCLUSION", "EXCLUSION", Rays::BLEND_EXCLUSION},
	{"BLEND_MULTIPLY",  "MULTIPLY",  Rays::BLEND_MULTIPLY},
	{"BLEND_SCREEN",    "SCREEN",    Rays::BLEND_SCREEN},
	{"BLEND_REPLACE",   "REPLACE",   Rays::BLEND_REPLACE},
});


static
RUCY_DEF0(init)
{
	Rays::init();
	return self;
}
RUCY_END

static
RUCY_DEF0(fin)
{
	Rays::fin();
	return self;
}
RUCY_END


static Module mRays;

void
Init_rays ()
{
	mRays = define_module("Rays");

	mRays.define_singleton_method("init!", init);
	mRays.define_singleton_method("fin!", fin);

	for (auto it = CAP_TYPES.begin(); it != CAP_TYPES.end(); ++it)
		mRays.define_const(it->name, it->value);

	for (auto it = JOIN_TYPES.begin(); it != JOIN_TYPES.end(); ++it)
		mRays.define_const(it->name, it->value);

	for (auto it = BLEND_MODES.begin(); it != BLEND_MODES.end(); ++it)
		mRays.define_const(it->name, it->value);
}


namespace Rucy
{


	template <> Rays::CapType
	value_to<Rays::CapType> (int argc, const Value* argv, bool convert)
	{
		assert(argc > 0 && argv);

		if (convert)
		{
			if (argv->is_s() || argv->is_sym())
			{
				const char* str = argv->c_str();
				for (auto it = CAP_TYPES.begin(); it != CAP_TYPES.end(); ++it)
				{
					if (
						strcasecmp(str, it->name)       == 0 ||
						strcasecmp(str, it->short_name) == 0)
					{
						return it->value;
					}
				}
				argument_error(__FILE__, __LINE__, "invalid cap type -- %s", str);
			}
		}

		int type = value_to<int>(*argv, convert);
		if (type < 0 || Rays::CAP_MAX <= type)
			argument_error(__FILE__, __LINE__, "invalid cap type -- %d", type);

		return (Rays::CapType) type;
	}


	template <> Rays::JoinType
	value_to<Rays::JoinType> (int argc, const Value* argv, bool convert)
	{
		assert(argc > 0 && argv);

		if (convert)
		{
			if (argv->is_s() || argv->is_sym())
			{
				const char* str = argv->c_str();
				for (auto it = JOIN_TYPES.begin(); it != JOIN_TYPES.end(); ++it)
				{
					if (
						strcasecmp(str, it->name)       == 0 ||
						strcasecmp(str, it->short_name) == 0)
					{
						return it->value;
					}
				}
				argument_error(__FILE__, __LINE__, "invalid join type -- %s", str);
			}
		}

		int type = value_to<int>(*argv, convert);
		if (type < 0 || Rays::JOIN_MAX <= type)
			argument_error(__FILE__, __LINE__, "invalid join type -- %d", type);

		return (Rays::JoinType) type;
	}


	template <> Rays::BlendMode
	value_to<Rays::BlendMode> (int argc, const Value* argv, bool convert)
	{
		assert(argc > 0 && argv);

		if (convert)
		{
			if (argv->is_s() || argv->is_sym())
			{
				const char* str = argv->c_str();
				for (auto it = BLEND_MODES.begin(); it != BLEND_MODES.end(); ++it)
				{
					if (
						strcasecmp(str, it->name)       == 0 ||
						strcasecmp(str, it->short_name) == 0)
					{
						return it->value;
					}
				}
				argument_error(__FILE__, __LINE__, "invalid blend mode -- %s", str);
			}
		}

		int mode = value_to<int>(*argv, convert);
		if (mode < 0 || Rays::BLEND_MAX <= mode)
			argument_error(__FILE__, __LINE__, "invalid blend mode -- %d", mode);

		return (Rays::BlendMode) mode;
	}


}// Rucy


namespace Rays
{


	Module
	rays_module ()
	{
		return mRays;
	}


}// Rays
