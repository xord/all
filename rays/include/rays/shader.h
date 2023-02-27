// -*- c++ -*-
#pragma once
#ifndef __RAYS_SHADER_H__
#define __RAYS_SHADER_H__


#include <vector>
#include <xot/pimpl.h>
#include <rays/defs.h>
#include <rays/coord.h>


namespace Rays
{


	class Image;
	class ShaderEnv;


	class Shader
	{

		typedef Shader This;

		public:

			Shader (
				const char* fragment_shader_source = NULL,
				const char*   vertex_shader_source = NULL);

			Shader (
				const char* fragment_shader_source,
				const char*   vertex_shader_source,
				ShaderEnv env);

			~Shader ();

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

			void set_uniform (const char* name, const Image& texture);

			const char*   vertex_shader_source () const;

			const char* fragment_shader_source () const;

			operator bool () const;

			bool operator ! () const;

			friend bool operator == (const This& lhs, const This& rhs);

			friend bool operator != (const This& lhs, const This& rhs);

			struct Data;

			Xot::PSharedImpl<Data> self;

	};// Shader


	class ShaderEnv
	{

		public:

			typedef std::vector<String> NameList;

			enum Flags
			{
				IGNORE_NO_UNIFORM_LOCATION_ERROR = 0x1 << 0,
			};

			ShaderEnv (
				const NameList& attribute_position_names      = {},
				const NameList& attribute_texcoord_names      = {},
				const NameList& attribute_color_names         = {},
				const char*     varying_position_name         = NULL,
				const char*     varying_texcoord_name         = NULL,
				const char*     varying_color_name            = NULL,
				const NameList& uniform_position_matrix_names = {},
				const NameList& uniform_texcoord_matrix_names = {},
				const NameList& uniform_texcoord_min_names    = {},
				const NameList& uniform_texcoord_max_names    = {},
				const NameList& uniform_texcoord_offset_names = {},
				const NameList& uniform_texture_names         = {},
				uint flags                                    = 0);

			struct Data;

			Xot::PSharedImpl<Data> self;

	};// ShaderEnv


}// Rays


#endif//EOH
