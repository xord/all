// -*- c++ -*-
#pragma once
#ifndef __RAYS_SRC_SHADER_PROGRAM_H__
#define __RAYS_SRC_SHADER_PROGRAM_H__


#include <xot/pimpl.h>
#include "rays/defs.h"
#include "rays/coord.h"
#include "opengl.h"


namespace Rays
{


	class ShaderSource;
	class Texture;


	class ShaderProgram
	{

		typedef ShaderProgram This;

		public:

			ShaderProgram (
				const ShaderSource& vertex,
				const ShaderSource& fragment,
				uint flags);

			~ShaderProgram ();

			void set_uniform (const char* name, int arg1);

			void set_uniform (const char* name, int arg1, int arg2);

			void set_uniform (const char* name, int arg1, int arg2, int arg3);

			void set_uniform (const char* name, int arg1, int arg2, int arg3, int arg4);

			void set_uniform (const char* name, const int* args, size_t size);

			void set_uniform (const char* name, float arg1);

			void set_uniform (const char* name, float arg1, float arg2);

			void set_uniform (const char* name, float arg1, float arg2, float arg3);

			void set_uniform (const char* name, float arg1, float arg2, float arg3, float arg4);

			void set_uniform (const char* name, const float* args, size_t size);

			void set_uniform (const char* name, const Coord2& vec2);

			void set_uniform (const char* name, const Coord3& vec3);

			void set_uniform (const char* name, const Coord4& vec4);

			void set_uniform (const char* name, const Texture& texture);

			GLuint id () const;

			const ShaderSource& vertex_shader_source () const;

			const ShaderSource& fragment_shader_source () const;

			operator bool () const;

			bool operator ! () const;

			friend bool operator == (const This& lhs, const This& rhs);

			friend bool operator != (const This& lhs, const This& rhs);

			struct Data;

			Xot::PSharedImpl<Data> self;

	};// ShaderProgram


	void ShaderProgram_activate (const ShaderProgram& program);

	void ShaderProgram_deactivate ();


}// Rays


#endif//EOH
