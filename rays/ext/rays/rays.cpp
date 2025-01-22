#include "rays/ruby/rays.h"


#include <assert.h>
#include <vector>
#include "defs.h"


RUCY_DEFINE_CONVERT_TO(RAYS_EXPORT, Rays::CapType)
RUCY_DEFINE_CONVERT_TO(RAYS_EXPORT, Rays::JoinType)
RUCY_DEFINE_CONVERT_TO(RAYS_EXPORT, Rays::BlendMode)
RUCY_DEFINE_CONVERT_TO(RAYS_EXPORT, Rays::TexCoordMode)
RUCY_DEFINE_CONVERT_TO(RAYS_EXPORT, Rays::TexCoordWrap)


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

static std::vector<EnumType<Rays::TexCoordMode>> TEXCOORD_MODES({
	{"TEXCOORD_IMAGE",  "IMAGE",  Rays::TEXCOORD_IMAGE},
	{"TEXCOORD_NORMAL", "NORMAL", Rays::TEXCOORD_NORMAL},
});

static std::vector<EnumType<Rays::TexCoordWrap>> TEXCOORD_WRAPS({
	{"TEXCOORD_CLAMP",  "CLAMP",  Rays::TEXCOORD_CLAMP},
	{"TEXCOORD_REPEAT", "REPEAT", Rays::TEXCOORD_REPEAT},
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

static
RUCY_DEF0(renderer_info)
{
	return value(Rays::get_renderer_info());
}
RUCY_END


static Module mRays;

void
Init_rays ()
{
	mRays = define_module("Rays");

	mRays.define_singleton_method("init!", init);
	mRays.define_singleton_method("fin!", fin);
	mRays.define_singleton_method("renderer_info", renderer_info);

	for (auto it = CAP_TYPES.begin(); it != CAP_TYPES.end(); ++it)
		mRays.define_const(it->name, it->value);

	for (auto it = JOIN_TYPES.begin(); it != JOIN_TYPES.end(); ++it)
		mRays.define_const(it->name, it->value);

	for (auto it = BLEND_MODES.begin(); it != BLEND_MODES.end(); ++it)
		mRays.define_const(it->name, it->value);

	for (auto it = TEXCOORD_MODES.begin(); it != TEXCOORD_MODES.end(); ++it)
		mRays.define_const(it->name, it->value);

	for (auto it = TEXCOORD_WRAPS.begin(); it != TEXCOORD_WRAPS.end(); ++it)
		mRays.define_const(it->name, it->value);
}


namespace Rucy
{


	template <> RAYS_EXPORT Rays::CapType
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
		if (type < 0)
			argument_error(__FILE__, __LINE__, "invalid cap type -- %d", type);
		if (type >= Rays::CAP_MAX)
			argument_error(__FILE__, __LINE__, "invalid cap type -- %d", type);

		return (Rays::CapType) type;
	}


	template <> RAYS_EXPORT Rays::JoinType
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
		if (type < 0)
			argument_error(__FILE__, __LINE__, "invalid join type -- %d", type);
		if (type >= Rays::JOIN_MAX)
			argument_error(__FILE__, __LINE__, "invalid join type -- %d", type);

		return (Rays::JoinType) type;
	}


	template <> RAYS_EXPORT Rays::BlendMode
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
		if (mode < 0)
			argument_error(__FILE__, __LINE__, "invalid blend mode -- %d", mode);
		if (mode >= Rays::BLEND_MAX)
			argument_error(__FILE__, __LINE__, "invalid blend mode -- %d", mode);

		return (Rays::BlendMode) mode;
	}


	template <> RAYS_EXPORT Rays::TexCoordMode
	value_to<Rays::TexCoordMode> (int argc, const Value* argv, bool convert)
	{
		assert(argc > 0 && argv);

		if (convert)
		{
			if (argv->is_s() || argv->is_sym())
			{
				const char* str = argv->c_str();
				for (auto it = TEXCOORD_MODES.begin(); it != TEXCOORD_MODES.end(); ++it)
				{
					if (
						strcasecmp(str, it->name)       == 0 ||
						strcasecmp(str, it->short_name) == 0)
					{
						return it->value;
					}
				}
				argument_error(__FILE__, __LINE__, "invalid texcoord mode -- %s", str);
			}
		}

		int mode = value_to<int>(*argv, convert);
		if (mode < 0)
			argument_error(__FILE__, __LINE__, "invalid texcoord mode -- %d", mode);
		if (mode >= Rays::TEXCOORD_MODE_MAX)
			argument_error(__FILE__, __LINE__, "invalid texcoord mode -- %d", mode);

		return (Rays::TexCoordMode) mode;
	}


	template <> RAYS_EXPORT Rays::TexCoordWrap
	value_to<Rays::TexCoordWrap> (int argc, const Value* argv, bool convert)
	{
		assert(argc > 0 && argv);

		if (convert)
		{
			if (argv->is_s() || argv->is_sym())
			{
				const char* str = argv->c_str();
				for (auto it = TEXCOORD_WRAPS.begin(); it != TEXCOORD_WRAPS.end(); ++it)
				{
					if (
						strcasecmp(str, it->name)       == 0 ||
						strcasecmp(str, it->short_name) == 0)
					{
						return it->value;
					}
				}
				argument_error(__FILE__, __LINE__, "invalid texcoord wrap -- %s", str);
			}
		}

		int wrap = value_to<int>(*argv, convert);
		if (wrap < 0)
			argument_error(__FILE__, __LINE__, "invalid texcoord wrap -- %d", wrap);
		if (wrap >= Rays::TEXCOORD_WRAP_MAX)
			argument_error(__FILE__, __LINE__, "invalid texcoord wrap -- %d", wrap);

		return (Rays::TexCoordWrap) wrap;
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
