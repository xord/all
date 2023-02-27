#include "shader_program.h"


#include <assert.h>
#include <vector>
#include <memory>
#include <algorithm>
#include "rays/shader.h"
#include "rays/exception.h"
#include "shader_source.h"
#include "texture.h"
#include "painter.h"


namespace Rays
{


	static GLint
	get_texture_unit_max ()
	{
		static GLint value = -1;
		if (value < 0)
		{
			glGetIntegerv(GL_MAX_TEXTURE_IMAGE_UNITS, &value);
			OpenGL_check_error(__FILE__, __LINE__);
		}
		return value;
	}


	class UniformValue
	{

		public:

			virtual ~UniformValue () {}

			virtual bool apply (size_t index, GLint location) const = 0;

	};// UniformValue


	template <typename T, int DIMENSION>
	class UniformValueT : public UniformValue
	{

		public:

			UniformValueT (T arg1)
			{
				assert(DIMENSION == 1);
				array[0] = arg1;
			}

			UniformValueT (T arg1, T arg2)
			{
				assert(DIMENSION == 2);
				array[0] = arg1;
				array[1] = arg2;
			}

			UniformValueT (T arg1, T arg2, T arg3)
			{
				assert(DIMENSION == 3);
				array[0] = arg1;
				array[1] = arg2;
				array[2] = arg3;
			}

			UniformValueT (T arg1, T arg2, T arg3, T arg4)
			{
				assert(DIMENSION == 4);
				array[0] = arg1;
				array[1] = arg2;
				array[2] = arg3;
				array[3] = arg4;
			}

			UniformValueT (const T* args, size_t size)
			{
				assert(size == DIMENSION);
				for (size_t i = 0; i < size; ++i)
					array[i] = args[i];
			}

			bool apply (size_t index, GLint location) const
			{
				apply_value(location);
				return !OpenGL_has_error();
			}

			void apply_value (GLint location) const;

		private:

			T array[DIMENSION];

	};// UniformValueT


	template <> void UniformValueT<int, 1>::apply_value (GLint location) const
	{
		glUniform1iv(location, 1, array);
	}

	template <> void UniformValueT<int, 2>::apply_value (GLint location) const
	{
		glUniform2iv(location, 1, array);
	}

	template <> void UniformValueT<int, 3>::apply_value (GLint location) const
	{
		glUniform3iv(location, 1, array);
	}

	template <> void UniformValueT<int, 4>::apply_value (GLint location) const
	{
		glUniform4iv(location, 1, array);
	}

	template <> void UniformValueT<float, 1>::apply_value (GLint location) const
	{
		glUniform1fv(location, 1, array);
	}

	template <> void UniformValueT<float, 2>::apply_value (GLint location) const
	{
		glUniform2fv(location, 1, array);
	}

	template <> void UniformValueT<float, 3>::apply_value (GLint location) const
	{
		glUniform3fv(location, 1, array);
	}

	template <> void UniformValueT<float, 4>::apply_value (GLint location) const
	{
		glUniform4fv(location, 1, array);
	}


	class UniformTexture : public UniformValue
	{

		public:

			UniformTexture (const Texture& texture)
			:	texture(texture)
			{
			}

			bool apply (size_t index, GLint location) const
			{
				if (!texture)
					shader_error(__FILE__, __LINE__, "invalid texture");

				GLint unit = (GLint) (index + 1);// GL_TEXTURE0 is used by apply_builtin_uniforms()
				GLint max  = get_texture_unit_max();
				if (unit >= max)
					shader_error(__FILE__, __LINE__, "texture unit must be less than %d", max);

				glActiveTexture(GL_TEXTURE0 + unit);
				glBindTexture(GL_TEXTURE_2D, texture.id());
				glUniform1i(location, unit);
				return !OpenGL_has_error();
			}

		private:

			Texture texture;

	};// UniformTexture


	struct Uniform
	{

		struct Data
		{

			String name;

			std::unique_ptr<const UniformValue> value;

			bool applied = false;

		};// Data

		Xot::PSharedImpl<Data> self;

		Uniform (const char* name, const UniformValue* value)
		{
			if (!name || name[0] == '\0')
				argument_error(__FILE__, __LINE__);

			reset(value);

			self->name = name;
		}

		void reset (const UniformValue* value)
		{
			if (!value)
				argument_error(__FILE__, __LINE__);

			self->value.reset(value);
			self->applied = false;
		}

		void apply (
			size_t index, const ShaderProgram& program,
			bool ignore_no_uniform_location_error) const
		{
			if (!program || self->applied) return;
			self->applied = true;

			const char* name = self->name;
			GLint location = glGetUniformLocation(program.id(), name);
			if (location < 0 && !ignore_no_uniform_location_error)
				shader_error(__FILE__, __LINE__, "uniform location '%s' not found", name);

			if (!self->value->apply(index, location))
				shader_error(__FILE__, __LINE__, "failed to apply uniform variable '%s'", name);
		}

		bool operator == (const Uniform& rhs) const
		{
			return self.get() == rhs.self.get();
		}

		bool operator != (const Uniform& rhs) const
		{
			return !operator==(rhs);
		}

	};// Uniform


	typedef std::vector<Uniform> UniformList;


	struct ShaderProgram::Data
	{

		GLuint id  = 0;

		uint flags = 0;

		ShaderSource vertex, fragment;

		UniformList uniform_values, uniform_textures;

		mutable bool linked = false, applied = false;

		Data ()
		{
			id = glCreateProgram();
			if (id <= 0)
				opengl_error(__FILE__, __LINE__, "failed to create program.");
		}

		~Data ()
		{
			if (id > 0) glDeleteProgram(id);

			uniform_values.clear();
			uniform_textures.clear();
		}

		void set_uniform_value (const char* name, const UniformValue* value)
		{
			set_uniform(&uniform_values, name, value);
		}

		void set_uniform_texture (const char* name, const UniformValue* value)
		{
			if (uniform_textures.size() >= (size_t) get_texture_unit_max())
				shader_error(__FILE__, __LINE__, "too many texture units.");

			set_uniform(&uniform_textures, name, value);
		}

		void set_uniform (
			UniformList* uniforms, const char* name, const UniformValue* value)
		{
			assert(uniforms);

			auto it = std::find_if(
				uniforms->begin(), uniforms->end(), [&](const Uniform& uniform) {
					return uniform.self->name == name;
				});

			if (it != uniforms->end())
				it->reset(value);
			else
				uniforms->push_back(Uniform(name, value));

			applied = false;
		}

		bool is_valid () const
		{
			return id > 0 && vertex && fragment;
		}

		void link () const
		{
			if (linked) return;
			linked = true;

			attach_shader(vertex);
			attach_shader(fragment);

			glLinkProgram(id);
			OpenGL_check_error(__FILE__, __LINE__);

			detach_shader(vertex);
			detach_shader(fragment);

			GLint status = GL_FALSE;
			glGetProgramiv(id, GL_LINK_STATUS, &status);
			if (status == GL_FALSE)
				shader_error(__FILE__, __LINE__, get_link_log().c_str());

			glValidateProgram(id);

			GLint validate = GL_FALSE;
			glGetProgramiv(id, GL_VALIDATE_STATUS, &validate);
			if (validate == GL_FALSE)
				OpenGL_check_error(__FILE__, __LINE__, "shader program validation failed");
		}

		void attach_shader (const ShaderSource& source) const
		{
			glAttachShader(id, source.id());
			OpenGL_check_error(__FILE__, __LINE__);
		}

		void detach_shader (const ShaderSource& source) const
		{
			glDetachShader(id, source.id());
			OpenGL_check_error(__FILE__, __LINE__);
		}

		String get_link_log () const
		{
			int len = 0;
			glGetProgramiv(id, GL_INFO_LOG_LENGTH, &len);
			if (len <= 0) return "";

			std::unique_ptr<char[]> buffer(new char[len]);
			int written = 0;
			glGetProgramInfoLog(id, len, &written, &buffer[0]);
			return &buffer[0];
		}

		void apply_uniforms (const ShaderProgram& program) const
		{
			if (applied) return;
			applied = true;

			bool ignore_no_loc = flags & ShaderEnv::IGNORE_NO_UNIFORM_LOCATION_ERROR;

			for (size_t i = 0; i < uniform_values.size(); ++i)
				uniform_values[i].apply(i, program, ignore_no_loc);

			for (size_t i = 0; i < uniform_textures.size(); ++i)
				uniform_textures[i].apply(i, program, ignore_no_loc);
		}

	};// ShaderProgram::Data


	void
	ShaderProgram_activate (const ShaderProgram& program)
	{
		ShaderProgram::Data* self = program.self.get();

		if (!self->is_valid()) return;

		self->link();

		glUseProgram(program.id());
		OpenGL_check_error(__FILE__, __LINE__);

		self->apply_uniforms(program);
	}

	void
	ShaderProgram_deactivate ()
	{
		glUseProgram(0);
		OpenGL_check_error(__FILE__, __LINE__);
	}


	ShaderProgram::ShaderProgram (
		const ShaderSource& vertex, const ShaderSource& fragment, uint flags)
	{
		self->vertex   = vertex;
		self->fragment = fragment;
		self->flags    = flags;
	}

	ShaderProgram::~ShaderProgram ()
	{
	}

	void
	ShaderProgram::set_uniform (const char* name, int arg1)
	{
		self->set_uniform_value(name, new UniformValueT<int, 1>(arg1));
	}

	void
	ShaderProgram::set_uniform (const char* name, int arg1, int arg2)
	{
		self->set_uniform_value(name, new UniformValueT<int, 2>(arg1, arg2));
	}

	void
	ShaderProgram::set_uniform (const char* name, int arg1, int arg2, int arg3)
	{
		self->set_uniform_value(name, new UniformValueT<int, 3>(arg1, arg2, arg3));
	}

	void
	ShaderProgram::set_uniform (
		const char* name, int arg1, int arg2, int arg3, int arg4)
	{
		self->set_uniform_value(
			name, new UniformValueT<int, 4>(arg1, arg2, arg3, arg4));
	}

	template <typename T>
	static UniformValue*
	create_uniform_value (const T* args, size_t size)
	{
		switch (size)
		{
			case 1: return new UniformValueT<T, 1>(args, 1);
			case 2: return new UniformValueT<T, 2>(args, 2);
			case 3: return new UniformValueT<T, 3>(args, 3);
			case 4: return new UniformValueT<T, 4>(args, 4);

			default:
				argument_error(__FILE__, __LINE__, "invalid 'size' value.");
		}

		return NULL;
	}

	void
	ShaderProgram::set_uniform (const char* name, const int* args, size_t size)
	{
		self->set_uniform_value(name, create_uniform_value(args, size));
	}

	void
	ShaderProgram::set_uniform (const char* name, float arg1)
	{
		self->set_uniform_value(name, new UniformValueT<float, 1>(arg1));
	}

	void
	ShaderProgram::set_uniform (const char* name, float arg1, float arg2)
	{
		self->set_uniform_value(name, new UniformValueT<float, 2>(arg1, arg2));
	}

	void
	ShaderProgram::set_uniform (const char* name, float arg1, float arg2, float arg3)
	{
		self->set_uniform_value(
			name, new UniformValueT<float, 3>(arg1, arg2, arg3));
	}

	void
	ShaderProgram::set_uniform (
		const char* name, float arg1, float arg2, float arg3, float arg4)
	{
		self->set_uniform_value(
			name, new UniformValueT<float, 4>(arg1, arg2, arg3, arg4));
	}

	void
	ShaderProgram::set_uniform (const char* name, const float* args, size_t size)
	{
		self->set_uniform_value(name, create_uniform_value(args, size));
	}

	void
	ShaderProgram::set_uniform (const char* name, const Coord2& vec2)
	{
		self->set_uniform_value(name, new UniformValueT<float, 2>(vec2.array, 2));
	}

	void
	ShaderProgram::set_uniform (const char* name, const Coord3& vec3)
	{
		self->set_uniform_value(name, new UniformValueT<float, 3>(vec3.array, 3));
	}

	void
	ShaderProgram::set_uniform (const char* name, const Coord4& vec4)
	{
		self->set_uniform_value(name, new UniformValueT<float, 4>(vec4.array, 4));
	}

	void
	ShaderProgram::set_uniform (const char* name, const Texture& texture)
	{
		self->set_uniform_texture(name, new UniformTexture(texture));
	}

	const ShaderSource&
	ShaderProgram::vertex_shader_source () const
	{
		return self->vertex;
	}

	const ShaderSource&
	ShaderProgram::fragment_shader_source () const
	{
		return self->fragment;
	}

	GLuint
	ShaderProgram::id () const
	{
		return self->id;
	}

	ShaderProgram::operator bool () const
	{
		return self->is_valid();
	}

	bool
	ShaderProgram::operator ! () const
	{
		return !operator bool();
	}

	bool
	operator == (const ShaderProgram& lhs, const ShaderProgram& rhs)
	{
		return (!lhs && !rhs) || lhs.self->id == rhs.self->id;
	}

	bool
	operator != (const ShaderProgram& lhs, const ShaderProgram& rhs)
	{
		return !operator==(lhs, rhs);
	}


}// Rays
