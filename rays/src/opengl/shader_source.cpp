#include "shader_source.h"


#include <regex>
#include "rays/exception.h"
#include "rays/debug.h"


namespace Rays
{


	struct ShaderSource::Data
	{

		GLuint id = 0;

		GLenum type = 0;

		String source;

		Data ()
		{
		}

		~Data ()
		{
			clear();
		}

		void compile (GLenum type_, const char* source_)
		{
			if (!is_valid_type(type_))
				argument_error(__FILE__, __LINE__);
			if (!source_)
				argument_error(__FILE__, __LINE__);
			if (!*source_)
				argument_error(__FILE__, __LINE__);

			if (is_valid())
				invalid_state_error(__FILE__, __LINE__);

			String buffer;
			const char* src = add_headers(type_, source_, &buffer);

			id = glCreateShader(type_);
			glShaderSource(id, 1, &src, NULL);
			glCompileShader(id);

			GLint status = GL_FALSE;
			glGetShaderiv(id, GL_COMPILE_STATUS, &status);
			if (status == GL_FALSE)
				shader_error(__FILE__, __LINE__, get_compile_log().c_str());

			type   = type_;
			source = source_;
		}

		const char* add_headers (GLenum type, const char* source, String* buffer)
		{
#ifdef IOS
			if (type == GL_FRAGMENT_SHADER)
			{
				static const std::regex PRECISION(R"(^\s*precision\s+\w+p\s+float\s*;)");
				if (!std::regex_search(source, PRECISION))
				{
					static const String PRECISION_HEADER = "precision highp float;\n";
					*buffer = PRECISION_HEADER + source;
					source  = buffer->c_str();
				}
			}
#endif

#ifndef IOS
			static const std::regex VERSION(R"(^\s*#\s*version\s+\d+)");
			if (!std::regex_search(source, VERSION))
			{
				static const String VERSION_HEADER = "#version 120\n";
				*buffer = VERSION_HEADER + source;
				source  = buffer->c_str();
			}
#endif

			return source;
		}

		String get_compile_log () const
		{
			GLsizei len = 0;
			glGetShaderiv(id, GL_INFO_LOG_LENGTH, &len);
			if (len <= 0) return "";

			std::unique_ptr<char[]> buffer(new char[len]);
			int written = 0;
			glGetShaderInfoLog(id, len, &written, &buffer[0]);
			return buffer.get();
		}

		void clear ()
		{
			if (id > 0) glDeleteShader(id);

			id   = 0;
			type = 0;
			source.clear();
		}

		bool is_valid () const
		{
			return is_valid_type(type) && id > 0;
		}

		static bool is_valid_type (GLenum type)
		{
			return type == GL_VERTEX_SHADER || type == GL_FRAGMENT_SHADER;
		}

	};// ShaderSource::Data


	ShaderSource::ShaderSource ()
	{
	}

	ShaderSource::ShaderSource (GLenum type, const char* source)
	{
		self->compile(type, source);
	}

	ShaderSource::~ShaderSource ()
	{
	}

	const char*
	ShaderSource::source () const
	{
		return self->is_valid() ? self->source.c_str() : NULL;
	}

	GLenum
	ShaderSource::type () const
	{
		return self->type;
	}

	GLuint
	ShaderSource::id () const
	{
		return self->id;
	}

	ShaderSource::operator bool () const
	{
		return self->is_valid();
	}

	bool
	ShaderSource::operator ! () const
	{
		return !operator bool();
	}

	bool
	operator == (const ShaderSource& lhs, const ShaderSource& rhs)
	{
		return (!lhs && !rhs) || lhs.self->id == rhs.self->id;
	}

	bool
	operator != (const ShaderSource& lhs, const ShaderSource& rhs)
	{
		return !operator==(lhs, rhs);
	}


}// Rays
