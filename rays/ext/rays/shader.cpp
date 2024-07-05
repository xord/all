#include "rays/ruby/shader.h"


#include <assert.h>
#include "rays/ruby/image.h"
#include "defs.h"


RUCY_DEFINE_VALUE_OR_ARRAY_FROM_TO(RAYS_EXPORT, Rays::Shader)

#define THIS  to<Rays::Shader*>(self)

#define CHECK RUCY_CHECK_OBJECT(Rays::Shader, self)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	return new_type<Rays::Shader>(klass);
}
RUCY_END

static const char*
to_name (const Value& names, size_t index)
{
	if (!names || !names.is_array() || index >= names.size())
		return NULL;

	const auto& name = names[index];
	if (!name) return NULL;

	return name.c_str();
}

static Rays::ShaderEnv::NameList
to_name_list (const Value& names, size_t index)
{
	if (!names || !names.is_array() || index >= names.size())
		return {};

	const auto& name_or_array = names[index];
	if (name_or_array.is_array())
	{
		Rays::ShaderEnv::NameList list;
		for (size_t i = 0; i < name_or_array.size(); ++i)
			list.emplace_back(name_or_array[i].c_str());
		return list;
	}
	else if (name_or_array.is_s() || name_or_array.is_sym())
		return {Xot::String(name_or_array.c_str())};
	else
		return {};
}

static std::shared_ptr<Rays::ShaderEnv>
make_env (const Value& names, const Value& ignore_no_uniform_location_error)
{
	bool has_names = names && names.is_array() && !names.empty();
	if (!has_names && !ignore_no_uniform_location_error)
		return NULL;

	uint flags = 0;
	if (ignore_no_uniform_location_error)
		flags |= Rays::ShaderEnv::IGNORE_NO_UNIFORM_LOCATION_ERROR;

	return std::make_shared<Rays::ShaderEnv>(
		to_name_list(names, 0),
		to_name_list(names, 1),
		to_name_list(names, 2),
		to_name(     names, 3),
		to_name(     names, 4),
		to_name(     names, 5),
		to_name_list(names, 6),
		to_name_list(names, 7),
		to_name_list(names, 8),
		to_name_list(names, 9),
		to_name_list(names, 10),
		to_name_list(names, 11),
		flags);
}

static
RUCY_DEF4(setup,
	fragment_shader_source, vertex_shader_source,
	builtin_variable_names, ignore_no_uniform_location_error)
{
	RUCY_CHECK_OBJ(Rays::Shader, self);

	if (fragment_shader_source.is_nil())
		argument_error(__FILE__, __LINE__);

	const char* fs = fragment_shader_source.c_str();
	const char* vs = vertex_shader_source ? vertex_shader_source.c_str() : NULL;

	auto env = make_env(builtin_variable_names, ignore_no_uniform_location_error);
	if (env)
		*THIS = Rays::Shader(fs, vs, *env);
	else
		*THIS = Rays::Shader(fs, vs);
}
RUCY_END

static
RUCY_DEFN(set_uniform)
{
	CHECK;
	check_arg_count(__FILE__, __LINE__, "Painter#set_uniform", argc, 2, 3, 4, 5);

	const char* name = argv[0].c_str();
	if (argv[1].is_array())
	{
		argc = argv[1].size();
		argv = argv[1].as_array();
	}
	else
	{
		argc -= 1;
		argv += 1;
	}

	#define Ai(n) (argv[n].as_i())
	#define Af(n) ((float) argv[n].as_f())

	if (argv[0].is_i())
	{
		switch (argc)
		{
			case 1: THIS->set_uniform(name, Ai(0)); break;
			case 2: THIS->set_uniform(name, Ai(0), Ai(1)); break;
			case 3: THIS->set_uniform(name, Ai(0), Ai(1), Ai(2)); break;
			case 4: THIS->set_uniform(name, Ai(0), Ai(1), Ai(2), Ai(3)); break;
		}
	}
	else if (argv[0].is_f())
	{
		switch (argc)
		{
			case 1: THIS->set_uniform(name, Af(0)); break;
			case 2: THIS->set_uniform(name, Af(0), Af(1)); break;
			case 3: THIS->set_uniform(name, Af(0), Af(1), Af(2)); break;
			case 4: THIS->set_uniform(name, Af(0), Af(1), Af(2), Af(3)); break;
		}
	}
	else if (argv[0].is_kind_of(Rays::image_class()))
		THIS->set_uniform(name, to<Rays::Image&>(argv[0]));
	else
		argument_error(__FILE__, __LINE__);

	#undef Ai
	#undef Af

	return self;
}
RUCY_END

static
RUCY_DEF0(get_vertex_shader_source)
{
	CHECK;

	const char* source = THIS->vertex_shader_source();
	return source ? value(source) : nil();
}
RUCY_END

static
RUCY_DEF0(get_fragment_shader_source)
{
	CHECK;

	const char* source = THIS->fragment_shader_source();
	return source ? value(source) : nil();
}
RUCY_END


static Class cShader;

void
Init_rays_shader ()
{
	Module mRays = define_module("Rays");

	cShader = mRays.define_class("Shader");
	cShader.define_alloc_func(alloc);
	cShader.define_private_method("setup", setup);
	cShader.define_private_method("set_uniform", set_uniform);
	cShader.define_method(  "vertex_shader_source",   get_vertex_shader_source);
	cShader.define_method("fragment_shader_source", get_fragment_shader_source);
}


namespace Rucy
{


	template <> RAYS_EXPORT Rays::Shader
	value_to<Rays::Shader> (int argc, const Value* argv, bool convert)
	{
		if (argc == 1 && argv->is_array())
		{
			argc = argv->size();
			argv = argv->as_array();
		}

		assert(argc > 0 && argv);

		if (convert)
		{
			if (argv->is_s())
				return Rays::Shader(argv[0].c_str());
		}

		if (argc != 1)
			argument_error(__FILE__, __LINE__);

		return value_to<Rays::Shader&>(*argv, convert);
	}


}// Rucy


namespace Rays
{


	Class
	shader_class ()
	{
		return cShader;
	}


}// Rays
