#include "shader.h"


#include <assert.h>
#include <regex>
#include "rays/exception.h"
#include "opengl.h"
#include "image.h"
#include "shader_program.h"
#include "shader_source.h"


namespace Rays
{


	#define A_POSITION        (names.attribute_position_names[0])
	#define A_TEXCOORD        (names.attribute_texcoord_names[0])
	#define A_COLOR           (names.attribute_color_names[0])
	#define V_POSITION        (names.varying_position_name)
	#define V_TEXCOORD        (names.varying_texcoord_name)
	#define V_COLOR           (names.varying_color_name)
	#define U_POSITION_MATRIX (names.uniform_position_matrix_names[0])
	#define U_TEXCOORD_MATRIX (names.uniform_texcoord_matrix_names[0])
	#define U_TEXCOORD_MIN    (names.uniform_texcoord_min_names[0])
	#define U_TEXCOORD_MAX    (names.uniform_texcoord_max_names[0])
	#define U_TEXCOORD_OFFSET (names.uniform_texcoord_offset_names[0])
	#define U_TEXTURE         (names.uniform_texture_names[0])


	static ShaderEnv DEFAULT_ENV;


	struct Shader::Data
	{

		std::unique_ptr<ShaderProgram> program;

		std::unique_ptr<ShaderEnv> env;

		Data (
			const char* fragment_shader_source,
			const char*   vertex_shader_source,
			ShaderEnv* env_)
		{
			if (!fragment_shader_source) return;

			if (env_)
				this->env.reset(new ShaderEnv(*env_));

			program.reset(new ShaderProgram(
				make_vertex_shader_source(vertex_shader_source),
				make_fragment_shader_source(fragment_shader_source),
				env_ ? ShaderEnv_get_flags(*env_) : 0));
		}

		ShaderSource make_vertex_shader_source (const char* source)
		{
			if (source)
				return ShaderSource(GL_VERTEX_SHADER, source);
			else
			{
				return ShaderEnv_get_default_vertex_shader_source(
					env ? env.get() : &DEFAULT_ENV);
			}
		}

		ShaderSource make_fragment_shader_source (const char* source)
		{
			#ifdef IOS
				static const String SHARED_HEADER = "precision highp float;\n";
				static const std::regex PRECISION(R"(^\s*precision\s+\w+p\s+float\s*;)");

				if (!std::regex_search(source, PRECISION))
					return ShaderSource(GL_FRAGMENT_SHADER, SHARED_HEADER + source);
				else
					return ShaderSource(GL_FRAGMENT_SHADER, source);
			#else
				return ShaderSource(GL_FRAGMENT_SHADER, source);
			#endif
		}

	};// Shader::Data


	static Shader
	make_default_shader_for_shape ()
	{
		const ShaderBuiltinVariableNames& names =
			ShaderEnv_get_builtin_variable_names(DEFAULT_ENV);
		return Shader(
			"varying vec4 " + V_COLOR + ";\n"
			"void main ()\n"
			"{\n"
			"  gl_FragColor = " + V_COLOR + ";\n"
			"}\n");
	}

	static Shader
	make_default_shader_for_texture ()
	{
		const ShaderBuiltinVariableNames& names =
			ShaderEnv_get_builtin_variable_names(DEFAULT_ENV);
		return Shader(
			"varying vec4 "      + V_TEXCOORD + ";\n"
			"varying vec4 "      + V_COLOR + ";\n"
			"uniform vec3 "      + U_TEXCOORD_MIN + ";\n"
			"uniform vec3 "      + U_TEXCOORD_MAX + ";\n"
			"uniform sampler2D " + U_TEXTURE + ";\n"
			"void main ()\n"
			"{\n"
			"  vec2 min__      = " + U_TEXCOORD_MIN + ".xy;\n"
			"  vec2 len__      = " + U_TEXCOORD_MAX + ".xy - min__;\n"
			"  vec2 texcoord__ = mod(" + V_TEXCOORD + ".xy - min__, len__) + min__;\n"
			"  vec4 color__    = texture2D(" + U_TEXTURE + ", texcoord__);\n"
			"  gl_FragColor    = " + V_COLOR + " * color__;\n"
			"}\n");
	}

	static Shader
	make_shader_for_text ()
	{
		const ShaderBuiltinVariableNames& names =
			ShaderEnv_get_builtin_variable_names(DEFAULT_ENV);
		return Shader(
			"varying vec4 "      + V_TEXCOORD + ";\n"
			"varying vec4 "      + V_COLOR + ";\n"
			"uniform sampler2D " + U_TEXTURE + ";\n"
			"void main ()\n"
			"{\n"
			"  vec4 col__   = texture2D(" + U_TEXTURE + ", " + V_TEXCOORD + ".xy);\n"
			#if defined(OSX) || defined(IOS)
			// restore premultiplied rgb values
			"  vec3 rgb__   = col__.a != 0.0 ? col__.rgb / col__.a : col__.rgb;\n"
			"  gl_FragColor = " + V_COLOR + " * vec4(rgb__, col__.a);\n"
			#else
			"  gl_FragColor = " + V_COLOR + " * col__;\n"
			#endif
			"}\n");
	}

	const ShaderProgram*
	Shader_get_program (const Shader& shader)
	{
		return shader.self->program ? shader.self->program.get() : NULL;
	}

	const ShaderBuiltinVariableNames&
	Shader_get_builtin_variable_names (const Shader& shader)
	{
		return ShaderEnv_get_builtin_variable_names(
			shader.self->env ? *shader.self->env : DEFAULT_ENV);
	}

	const Shader&
	Shader_get_default_shader_for_shape ()
	{
		static const Shader SHADER = make_default_shader_for_shape();
		return SHADER;
	}

	const Shader&
	Shader_get_default_shader_for_texture ()
	{
		static const Shader SHADER = make_default_shader_for_texture();
		return SHADER;
	}

	const Shader&
	Shader_get_shader_for_text ()
	{
		static const Shader SHADER = make_shader_for_text();
		return SHADER;
	}


	Shader::Shader (
		const char* fragment_shader_source,
		const char*   vertex_shader_source)
	:	self(new Data(fragment_shader_source, vertex_shader_source, NULL))
	{
	}

	Shader::Shader (
		const char* fragment_shader_source,
		const char*   vertex_shader_source,
		ShaderEnv env)
	:	self(new Data(fragment_shader_source, vertex_shader_source, &env))
	{
	}

	Shader::~Shader ()
	{
	}

	void
	Shader::set_uniform (const char* name, int arg1)
	{
		if (!self->program)
			invalid_state_error(__FILE__, __LINE__);

		self->program->set_uniform(name, arg1);
	}

	void
	Shader::set_uniform (const char* name, int arg1, int arg2)
	{
		if (!self->program)
			invalid_state_error(__FILE__, __LINE__);

		self->program->set_uniform(name, arg1, arg2);
	}

	void
	Shader::set_uniform (const char* name, int arg1, int arg2, int arg3)
	{
		if (!self->program)
			invalid_state_error(__FILE__, __LINE__);

		self->program->set_uniform(name, arg1, arg2, arg3);
	}

	void
	Shader::set_uniform (const char* name, int arg1, int arg2, int arg3, int arg4)
	{
		if (!self->program)
			invalid_state_error(__FILE__, __LINE__);

		self->program->set_uniform(name, arg1, arg2, arg3, arg4);
	}

	void
	Shader::set_uniform (const char* name, const int* args, size_t size)
	{
		if (!self->program)
			invalid_state_error(__FILE__, __LINE__);

		self->program->set_uniform(name, args, size);
	}

	void
	Shader::set_uniform (const char* name, float arg1)
	{
		if (!self->program)
			invalid_state_error(__FILE__, __LINE__);

		self->program->set_uniform(name, arg1);
	}

	void
	Shader::set_uniform (const char* name, float arg1, float arg2)
	{
		if (!self->program)
			invalid_state_error(__FILE__, __LINE__);

		self->program->set_uniform(name, arg1, arg2);
	}

	void
	Shader::set_uniform (const char* name, float arg1, float arg2, float arg3)
	{
		if (!self->program)
			invalid_state_error(__FILE__, __LINE__);

		self->program->set_uniform(name, arg1, arg2, arg3);
	}

	void
	Shader::set_uniform (
		const char* name, float arg1, float arg2, float arg3, float arg4)
	{
		if (!self->program)
			invalid_state_error(__FILE__, __LINE__);

		self->program->set_uniform(name, arg1, arg2, arg3, arg4);
	}

	void
	Shader::set_uniform (const char* name, const float* args, size_t size)
	{
		if (!self->program)
			invalid_state_error(__FILE__, __LINE__);

		self->program->set_uniform(name, args, size);
	}

	void
	Shader::set_uniform (const char* name, const Coord2& vec2)
	{
		if (!self->program)
			invalid_state_error(__FILE__, __LINE__);

		self->program->set_uniform(name, vec2);
	}

	void
	Shader::set_uniform (const char* name, const Coord3& vec3)
	{
		if (!self->program)
			invalid_state_error(__FILE__, __LINE__);

		self->program->set_uniform(name, vec3);
	}

	void
	Shader::set_uniform (const char* name, const Coord4& vec4)
	{
		if (!self->program)
			invalid_state_error(__FILE__, __LINE__);

		self->program->set_uniform(name, vec4);
	}

	void
	Shader::set_uniform (const char* name, const Image& texture)
	{
		if (!self->program)
			invalid_state_error(__FILE__, __LINE__);

		self->program->set_uniform(name, Image_get_texture(texture));
	}

	const char*
	Shader::vertex_shader_source () const
	{
		return self->program
			? self->program->vertex_shader_source().source()
			: NULL;
	}

	const char*
	Shader::fragment_shader_source () const
	{
		return self->program
			? self->program->fragment_shader_source().source()
			: NULL;
	}

	Shader::operator bool () const
	{
		return self->program && *self->program;
	}

	bool
	Shader::operator ! () const
	{
		return !operator bool();
	}

	bool
	operator == (const Shader& lhs, const Shader& rhs)
	{
		return (!lhs && !rhs) || lhs.self->program == rhs.self->program;
	}

	bool
	operator != (const Shader& lhs, const Shader& rhs)
	{
		return !operator==(lhs, rhs);
	}


	struct ShaderEnv::Data
	{

		ShaderBuiltinVariableNames names;

		uint flags;

		ShaderSource default_vertex_shader_source;

		Data (const ShaderBuiltinVariableNames& names, uint flags)
		:	names(names), flags(flags)
		{
		}

		String make_default_vertex_shader_source_code ()
		{
			return
				"attribute vec3 " + A_POSITION + ";\n"
				"attribute vec3 " + A_TEXCOORD + ";\n"
				"attribute vec4 " + A_COLOR + ";\n"
				"varying vec4 "   + V_POSITION + ";\n"
				"varying vec4 "   + V_TEXCOORD + ";\n"
				"varying vec4 "   + V_COLOR + ";\n"
				"uniform mat4 "   + U_POSITION_MATRIX + ";\n"
				"uniform mat4 "   + U_TEXCOORD_MATRIX + ";\n"
				"void main ()\n"
				"{\n"
				"  vec4 pos__          = vec4(" + A_POSITION + ", 1.0);\n"
				"  vec4 texcoord__     = vec4(" + A_TEXCOORD + ", 1.0);\n"
				"  " + V_POSITION +  " = pos__;\n"
				"  " + V_TEXCOORD +  " = " + U_TEXCOORD_MATRIX + " * texcoord__;\n"
				"  " + V_COLOR    +  " = " + A_COLOR + ";\n"
				"  gl_Position         = " + U_POSITION_MATRIX + " * pos__;\n"
				"}\n";
		}

	};// ShaderEnv::Data


	const ShaderBuiltinVariableNames&
	ShaderEnv_get_builtin_variable_names (const ShaderEnv& env)
	{
		return env.self->names;
	}

	uint
	ShaderEnv_get_flags (const ShaderEnv& env)
	{
		return env.self->flags;
	}

	const ShaderSource&
	ShaderEnv_get_default_vertex_shader_source (ShaderEnv* env)
	{
		if (!env)
			argument_error(__FILE__, __LINE__);

		ShaderEnv::Data* self = env->self.get();

		if (!self->default_vertex_shader_source)
		{
			self->default_vertex_shader_source = ShaderSource(
				GL_VERTEX_SHADER, self->make_default_vertex_shader_source_code());
		}
		return self->default_vertex_shader_source;
	}


	ShaderEnv::ShaderEnv (
		const NameList& a_position_names,
		const NameList& a_texcoord_names,
		const NameList& a_color_names,
		const char*     v_position_name,
		const char*     v_texcoord_name,
		const char*     v_color_name,
		const NameList& u_position_matrix_names,
		const NameList& u_texcoord_matrix_names,
		const NameList& u_texcoord_min_names,
		const NameList& u_texcoord_max_names,
		const NameList& u_texcoord_offset_names,
		const NameList& u_texture_names,
		uint flags)
	:	self(new Data(
			ShaderBuiltinVariableNames(
				a_position_names, a_texcoord_names, a_color_names,
				v_position_name,  v_texcoord_name,  v_color_name,
				u_position_matrix_names, u_texcoord_matrix_names,
				u_texcoord_min_names, u_texcoord_max_names, u_texcoord_offset_names,
				u_texture_names),
			flags))
	{
	}


	static void
	validate_name (const String& name, const char* for_variable)
	{
		assert(for_variable);

		if (name.empty())
		{
			argument_error(
				__FILE__, __LINE__,
				"invalid variable name '%s' for '%s'", name.c_str(), for_variable);
		}
	}

	static void
	validate_names (
		ShaderEnv::NameList* names,
		const char* for_variable,
		const char* default_name)
	{
		assert(names && for_variable && default_name);

		if (names->empty()) names->emplace_back(default_name);

		for (const auto& name : *names)
			validate_name(name, for_variable);
	}

	ShaderBuiltinVariableNames::ShaderBuiltinVariableNames (
		const ShaderEnv::NameList& a_position,
		const ShaderEnv::NameList& a_texcoord,
		const ShaderEnv::NameList& a_color,
		const char* v_position,
		const char* v_texcoord,
		const char* v_color,
		const ShaderEnv::NameList& u_position_matrix,
		const ShaderEnv::NameList& u_texcoord_matrix,
		const ShaderEnv::NameList& u_texcoord_min,
		const ShaderEnv::NameList& u_texcoord_max,
		const ShaderEnv::NameList& u_texcoord_offset,
		const ShaderEnv::NameList& u_texture)
	:	attribute_position_names(a_position),
		attribute_texcoord_names(a_texcoord),
		attribute_color_names(a_color),
		varying_position_name(v_position ? v_position : "v_Position"),
		varying_texcoord_name(v_texcoord ? v_texcoord : "v_TexCoord"),
		varying_color_name(   v_color    ? v_color    : "v_Color"),
		uniform_position_matrix_names(u_position_matrix),
		uniform_texcoord_matrix_names(u_texcoord_matrix),
		uniform_texcoord_min_names(u_texcoord_min),
		uniform_texcoord_max_names(u_texcoord_max),
		uniform_texcoord_offset_names(u_texcoord_offset),
		uniform_texture_names(u_texture)
	{
		validate_names(&attribute_position_names,      "attribute_position",      "a_Position");
		validate_names(&attribute_texcoord_names,      "attribute_texcoord",      "a_TexCoord");
		validate_names(&attribute_color_names,         "attribute_color",         "a_Color");
		validate_name(varying_position_name,           "varying_position");
		validate_name(varying_texcoord_name,           "varying_texcoord");
		validate_name(varying_color_name,              "varying_color");
		validate_names(&uniform_position_matrix_names, "uniform_position_matrix", "u_PositionMatrix");
		validate_names(&uniform_texcoord_matrix_names, "uniform_texcoord_matrix", "u_TexCoordMatrix");
		validate_names(&uniform_texcoord_min_names,    "uniform_texcoord_min",    "u_TexCoordMin");
		validate_names(&uniform_texcoord_max_names,    "uniform_texcoord_max",    "u_TexCoordMax");
		validate_names(&uniform_texcoord_offset_names, "uniform_texcoord_offset", "u_TexCoordOffset");
		validate_names(&uniform_texture_names,         "uniform_texture",         "u_Texture");
	}


}// Rays
