#include "../painter.h"


#include <math.h>
#include <assert.h>
#include <memory>
#include <vector>
#include <algorithm>
#include <functional>
#include "rays/exception.h"
#include "../glm.h"
#include "../coord.h"
#include "../bitmap.h"
#include "../image.h"
#include "../font.h"
#include "opengl.h"
#include "texture.h"
#include "frame_buffer.h"
#include "shader.h"
#include "shader_program.h"


namespace Rays
{


	struct Vector4 : Coord4
	{

		Vector4 (const Coord3& p) {Coord4::operator=(p);}

	};// Vector4


	struct OpenGLState
	{

		GLint viewport[4];

		GLclampf color_clear[4];

		GLboolean depth_test;
		GLint depth_func;

		GLboolean scissor_test;
		GLint scissor_box[4];

		GLboolean blend;
		GLint blend_equation_rgb, blend_equation_alpha;
		GLint blend_src_rgb, blend_src_alpha, blend_dst_rgb, blend_dst_alpha;

		GLint framebuffer_binding;

		void push ()
		{
			glGetIntegerv(GL_VIEWPORT, viewport);

			glGetFloatv(GL_COLOR_CLEAR_VALUE, color_clear);

			glGetBooleanv(GL_DEPTH_TEST, &depth_test);
			glGetIntegerv(GL_DEPTH_FUNC, &depth_func);

			glGetBooleanv(GL_SCISSOR_TEST, &scissor_test);
			glGetIntegerv(GL_SCISSOR_BOX, scissor_box);

			glGetBooleanv(GL_BLEND, &blend);
			glGetIntegerv(GL_BLEND_EQUATION_RGB,   &blend_equation_rgb);
			glGetIntegerv(GL_BLEND_EQUATION_ALPHA, &blend_equation_alpha);
			glGetIntegerv(GL_BLEND_SRC_RGB,   &blend_src_rgb);
			glGetIntegerv(GL_BLEND_SRC_ALPHA, &blend_src_alpha);
			glGetIntegerv(GL_BLEND_DST_RGB,   &blend_dst_rgb);
			glGetIntegerv(GL_BLEND_DST_ALPHA, &blend_dst_alpha);

			glGetIntegerv(GL_FRAMEBUFFER_BINDING, &framebuffer_binding);
		}

		void pop ()
		{
			glViewport(viewport[0], viewport[1], viewport[2], viewport[3]);

			glClearColor(
				color_clear[0], color_clear[1], color_clear[2], color_clear[3]);

			enable(GL_DEPTH_TEST, depth_test);
			glDepthFunc(depth_func);

			enable(GL_SCISSOR_TEST, scissor_test);
			glScissor(scissor_box[0], scissor_box[1], scissor_box[2], scissor_box[3]);

			enable(GL_BLEND, blend);
			glBlendEquationSeparate(blend_equation_rgb, blend_equation_alpha);
			glBlendFuncSeparate(
				blend_src_rgb, blend_dst_rgb, blend_src_alpha, blend_dst_alpha);

			glBindFramebuffer(GL_FRAMEBUFFER, framebuffer_binding);
		}

		private:

			void enable(GLenum type, GLboolean value)
			{
				if (value)
					glEnable(type);
				else
					glDisable(type);
			}

	};// OpenGLState


	class DefaultIndices
	{

		public:

			void resize (size_t size)
			{
				indices.reserve(size);
				while (indices.size() < size)
					indices.emplace_back(indices.size());
			}

			void clear ()
			{
				decltype(indices)().swap(indices);
			}

			const uint* get () const
			{
				return &indices[0];
			}

		private:

			std::vector<uint> indices;

	};// DefaultIndices


	struct Batcher
	{

		int count = 0;

		Shader shader;

		Texture texture;

		std::vector<Vector4> points;

		std::vector<uint>    indices;

		std::vector<Color>   colors;

		std::vector<Vector4> texcoords;

		std::vector<Coord3>  texcoord_mins;

		std::vector<Coord3>  texcoord_maxes;

		void clear ()
		{
			count   = 0;
			shader  = Shader();
			texture = Texture();
			points        .clear();
			indices       .clear();
			colors        .clear();
			texcoords     .clear();
			texcoord_mins .clear();
			texcoord_maxes.clear();
		}

	};// Batcher


	struct PainterData : Painter::Data
	{

		FrameBuffer frame_buffer;

		OpenGLState opengl_state;

		DefaultIndices default_indices;

		std::vector<GLint> locations;

		std::vector<GLuint> buffers;

		std::vector<GLuint> triangle_fan_indices_buffer;

		Batcher batcher;

		GLuint create_and_bind_buffer (GLenum target, const void* data, GLsizeiptr size)
		{
			GLuint id = 0;
			glGenBuffers(1, &id);
			OpenGL_check_error(__FILE__, __LINE__);

			buffers.push_back(id);

			glBindBuffer(target, id);
			OpenGL_check_error(__FILE__, __LINE__);

			glBufferData(target, size, data, GL_STREAM_DRAW);
			OpenGL_check_error(__FILE__, __LINE__);

			return id;
		}

		void cleanup ()
		{
			for (auto loc : locations)
			{
				glDisableVertexAttribArray(loc);
				OpenGL_check_error(__FILE__, __LINE__);
			}

			if (!buffers.empty())
			{
				glDeleteBuffers((GLsizei) buffers.size(), &buffers[0]);
				OpenGL_check_error(__FILE__, __LINE__);
			}

			locations.clear();
			buffers.clear();
		}

	};// PainterData


	static PainterData*
	get_data (Painter* painter)
	{
		return (PainterData*) painter->self.get();
	}

	void
	Painter_update_clip (Painter* painter)
	{
		PainterData* self = get_data(painter);
		const Bounds& clip = self->state.clip;
		if (clip)
		{
			coord y = self->frame_buffer ? clip.y : self->viewport.h - (clip.y + clip.h);
			glEnable(GL_SCISSOR_TEST);
			glScissor(
				self->pixel_density * clip.x,
				self->pixel_density * y,
				self->pixel_density * clip.width,
				self->pixel_density * clip.height);
		}
		else
			glDisable(GL_SCISSOR_TEST);

		OpenGL_check_error(__FILE__, __LINE__);
	}

	static void
	apply_uniform (
		const ShaderProgram& program, const char* name,
		std::function<void(GLint)> apply_fun)
	{
		GLint loc = glGetUniformLocation(program.id(), name);
		if (loc < 0) return;

		apply_fun(loc);
		OpenGL_check_error(__FILE__, __LINE__);
	}

	static void
	apply_uniforms (
		const ShaderProgram& program, const ShaderBuiltinVariableNames& names,
		const Matrix& position_matrix, const Matrix& texcoord_matrix,
		const Texture* texture)
	{
		for (const auto& name : names.uniform_position_matrix_names)
		{
			apply_uniform(program, name, [&](GLint loc) {
				glUniformMatrix4fv(loc, 1, GL_FALSE, position_matrix.array);
			});
		}
		for (const auto& name : names.uniform_texcoord_matrix_names)
		{
			apply_uniform(program, name, [&](GLint loc) {
				glUniformMatrix4fv(loc, 1, GL_FALSE, texcoord_matrix.array);
			});
		}

		if (texture && *texture)
		{
			Point pixel_size(
				1 / texture->reserved_width(),
				1 / texture->reserved_height());
			for (const auto& name : names.uniform_texcoord_pixel_names)
			{
				apply_uniform(
					program, name, [&](GLint loc) {glUniform3fv(loc, 1, pixel_size.array);});
			}
			for (const auto& name : names.uniform_texture_names)
			{
				apply_uniform(program, name, [&](GLint loc) {
					glActiveTexture(GL_TEXTURE0);
					OpenGL_check_error(__FILE__, __LINE__);

					glBindTexture(GL_TEXTURE_2D, Texture_get_id(*texture));
					OpenGL_check_error(__FILE__, __LINE__);

					glUniform1i(loc, 0);
				});
			}
		}
	}

	template <typename COORD>
	static GLenum get_gl_type ();

	template <>
	GLenum
	get_gl_type<float> ()
	{
		return GL_FLOAT;
	}

	static void
	apply_attribute (
		const ShaderProgram& program, const char* name,
		std::function<void(GLint)> apply_fun)
	{
		GLint loc = glGetAttribLocation(program.id(), name);
		if (loc < 0) return;

		apply_fun(loc);
		OpenGL_check_error(__FILE__, __LINE__);
	}

	template <typename CoordN>
	static void
	apply_attribute (
		PainterData* self,
		const ShaderProgram& program, const auto& names,
		const CoordN* values, size_t nvalues)
	{
		GLuint buffer = 0;
		for (const auto& name : names)
		{
			#ifndef IOS
				if (buffer == 0)
				{
					buffer = self->create_and_bind_buffer(
						GL_ARRAY_BUFFER, values, sizeof(CoordN) * nvalues);
					values = 0;
				}
			#endif

			apply_attribute(program, name, [&](GLint loc)
			{
				glEnableVertexAttribArray(loc);
				OpenGL_check_error(
					__FILE__, __LINE__, "loc: %d %s\n", loc, name.c_str());

				glVertexAttribPointer(
					loc, CoordN::SIZE, get_gl_type<coord>(), GL_FALSE, 0, values);

				self->locations.push_back(loc);
			});
		}

		glBindBuffer(GL_ARRAY_BUFFER, 0);
		OpenGL_check_error(__FILE__, __LINE__);
	}

	template <typename CoordN>
	static void
	apply_attributes (
		PainterData* self,
		const ShaderProgram& program, const ShaderBuiltinVariableNames& names,
		const CoordN* points, size_t npoints,
		const Color* color, const Color* colors,
		const CoordN* texcoords,
		const Coord3* texcoord_min,  const Coord3* texcoord_max,
		const Coord3* texcoord_mins, const Coord3* texcoord_maxes)
	{
		assert(npoints > 0);
		assert(!!color != !!colors);

		apply_attribute(
			self, program, names.attribute_position_names,
			points, npoints);

		if (colors)
		{
			apply_attribute(
				self, program, names.attribute_color_names,
				colors, npoints);
		}
		else if (color)
		{
#if defined(GL_VERSION_2_1) && !defined(GL_VERSION_3_0)
			// to fix that GL 2.1 with glVertexAttrib4fv() draws nothing
			// with specific glsl 'attribute' name.
			std::vector<Color> colors_(npoints, *color);
			apply_attribute(
				self, program, names.attribute_color_names,
				(const Coord4*) &colors_[0], npoints);
#else
			for (const auto& name : names.attribute_color_names)
			{
				apply_attribute(
					program, name, [&](GLint loc) {glVertexAttrib4fv(loc, color->array);});
			}
#endif
		}

		apply_attribute(
			self, program, names.attribute_texcoord_names,
			texcoords ? texcoords : points, npoints);

		if (texcoord_mins)
		{
			apply_attribute(
				self, program, names.attribute_texcoord_min_names,
				texcoord_mins, npoints);
		}
		else if (texcoord_min)
		{
			for (const auto& name : names.attribute_texcoord_min_names)
			{
				apply_attribute(
					program, name, [&](GLint loc) {glVertexAttrib3fv(loc, texcoord_min->array);});
			}
		}

		if (texcoord_maxes)
		{
			apply_attribute(
				self, program, names.attribute_texcoord_max_names,
				texcoord_maxes, npoints);
		}
		else if (texcoord_max)
		{
			for (const auto& name : names.attribute_texcoord_max_names)
			{
				apply_attribute(
					program, name, [&](GLint loc) {glVertexAttrib3fv(loc, texcoord_max->array);});
			}
		}
	}

	static void
	draw_indices (
		PainterData* self, PrimitiveMode mode,
		const uint* indices, size_t nindices, size_t npoints)
	{
		if (!indices || nindices <= 0)
		{
			self->default_indices.resize(npoints);
			indices  = self->default_indices.get();
			nindices = npoints;
		}

		#ifdef IOS
			glDrawElements((GLenum) mode, (GLsizei) nindices, GL_UNSIGNED_INT, indices);
			OpenGL_check_error(__FILE__, __LINE__);
		#else
			self->create_and_bind_buffer(
				GL_ELEMENT_ARRAY_BUFFER, indices, sizeof(uint) * nindices);

			glDrawElements((GLenum) mode, (GLsizei) nindices, GL_UNSIGNED_INT, 0);
			OpenGL_check_error(__FILE__, __LINE__);

			glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
			OpenGL_check_error(__FILE__, __LINE__);
		#endif
	}

	static void
	setup_texcoord_variables (
		Matrix* matrix, Point* min, Point* max,
		const State& state, const TextureInfo& texinfo)
	{
		if (!texinfo.texture) return;

		coord tw = texinfo.texture.reserved_width();
		coord th = texinfo.texture.reserved_height();

		bool normal = state.texcoord_mode == TEXCOORD_NORMAL;
		matrix->scale(
			(normal ? texinfo.texture.width()  : 1.0) / tw,
			(normal ? texinfo.texture.height() : 1.0) / th);

		min->reset(texinfo.min.x / tw, texinfo.min.y / th);
		max->reset(texinfo.max.x / tw, texinfo.max.y / th);
	}

	static void
	draw (
		PainterData* self, PrimitiveMode mode,
		const Color* color,
		const Coord3* points,  size_t npoints,
		const uint*   indices, size_t nindices,
		const Color*  colors,
		const Coord3* texcoords, const TextureInfo* texinfo,
		const Shader& shader, const Matrix& position_matrix)
	{
		const ShaderProgram* program = Shader_get_program(shader);
		if (!program || !*program) return;

		ShaderProgram_activate(*program);

		Matrix texcoord_matrix(1);
		Point texcoord_min(0, 0), texcoord_max(1, 1);
		if (texinfo)
		{
			setup_texcoord_variables(
				&texcoord_matrix, &texcoord_min, &texcoord_max, self->state, *texinfo);
		}

		const auto& names = Shader_get_builtin_variable_names(shader);
		apply_uniforms(
			*program, names, position_matrix, texcoord_matrix,
			texinfo ? &texinfo->texture : NULL);
		apply_attributes(
			self, *program, names, points, npoints, color, colors,
			texcoords, &texcoord_min, &texcoord_max, NULL, NULL);
		draw_indices(self, mode, indices, nindices, npoints);
		self->cleanup();

		ShaderProgram_deactivate();
	}

	static void
	draw_batch (PainterData* self)
	{
		Batcher& batcher = self->batcher;
		if (batcher.points.empty()) return;

		const ShaderProgram* program = Shader_get_program(batcher.shader);
		if (!program || !*program)
			return batcher.clear();

		ShaderProgram_activate(*program);

		const auto& names = Shader_get_builtin_variable_names(batcher.shader);
		Matrix identity(1);
		apply_uniforms(
			*program, names, identity, identity, batcher.texture ? &batcher.texture : NULL);
		apply_attributes(
			self, *program, names, &batcher.points[0], batcher.points.size(),
			NULL, &batcher.colors[0],
			&batcher.texcoords[0],
			NULL, NULL, &batcher.texcoord_mins[0], &batcher.texcoord_maxes[0]);
		draw_indices(
			self, MODE_TRIANGLES,
			&batcher.indices[0], batcher.indices.size(), batcher.points.size());
		self->cleanup();

		ShaderProgram_deactivate();
		batcher.clear();
	}

	static inline Vector4
	apply_matrix (const Matrix& matrix, const Coord3& point)
	{
		return to_rays<Vector4>(to_glm(matrix) * Vec4(point.x, point.y, point.z, 1));
	}

	static void
	batch (
		Painter* painter, PrimitiveMode mode, const Color* color,
		const Coord3* points,  size_t npoints,
		const uint*   indices, size_t nindices,
		const Color*  colors,
		const Coord3* texcoords, const TextureInfo* texinfo,
		const Shader& shader)
	{
		PainterData* self = get_data(painter);
		Batcher& batcher  = self->batcher;

		Texture texture = texinfo ? texinfo->texture : Texture();
		if (
			batcher.points.empty()    ||
			batcher.shader  != shader ||
			batcher.texture != texture)
		{
			Painter_flush(painter);
			batcher.shader  = shader;
			batcher.texture = texture;
		}

		if (++batcher.count <= 5)
		{
			return draw(
				self, mode, color, points, npoints, indices, nindices, colors,
				texcoords, texinfo, shader, self->position_matrix);
		}

		size_t points0 = batcher.points.size();

		for (size_t i = 0; i < npoints; ++i)
			batcher.points.push_back(apply_matrix(self->position_matrix, points[i]));

		if (indices && nindices > 0)
		{
			for (size_t i = 0; i < nindices; ++i)
				batcher.indices.push_back((uint) (points0 + indices[i]));
		}
		else
		{
			for (size_t i = 0; i < npoints; ++i)
				batcher.indices.push_back((uint) (points0 + i));
		}

		if (colors)
			batcher.colors.insert(batcher.colors.end(), colors, colors + npoints);
		else if (color)
			batcher.colors.insert(batcher.colors.end(), npoints, *color);

		if (texture)
		{
			Matrix matrix(1);
			Point min(0, 0), max(1, 1);
			setup_texcoord_variables(&matrix, &min, &max, self->state, *texinfo);

			const Coord3* src = texcoords ? texcoords : points;
			for (size_t i = 0; i < npoints; ++i)
				batcher.texcoords.push_back(apply_matrix(matrix, src[i]));

			batcher.texcoord_mins .insert(batcher.texcoord_mins.end(),  npoints, min);
			batcher.texcoord_maxes.insert(batcher.texcoord_maxes.end(), npoints, max);
		}
		else
		{
			const Coord3* src = texcoords ? texcoords : points;
			batcher.texcoords     .insert(batcher.texcoords.end(),      src, src + npoints);
			batcher.texcoord_mins .insert(batcher.texcoord_mins.end(),  npoints, Point(0, 0));
			batcher.texcoord_maxes.insert(batcher.texcoord_maxes.end(), npoints, Point(1, 1));
		}
	}

	void
	Painter_flush (Painter* painter)
	{
		draw_batch(get_data(painter));
	}

	static const TextureInfo*
	setup_texinfo (
		PainterData* self, const TextureInfo* texinfo,
		std::unique_ptr<TextureInfo>* ptr)
	{
		assert(ptr);

		if (texinfo) return texinfo;

		const Texture* tex =
			self->state.texture ? &Image_get_texture(self->state.texture) : NULL;
		if (!tex) return NULL;

		ptr->reset(new TextureInfo(*tex, 0, 0, tex->width(), tex->height()));
		return ptr->get();
	}

	static const Shader*
	setup_shader (PainterData* self, const Shader* shader, bool for_texture)
	{
		if (self->state.shader) return &self->state.shader;
		if (shader)             return shader;
		return for_texture
			?	&Shader_get_default_shader_for_texture(self->state.texcoord_wrap)
			:	&Shader_get_default_shader_for_shape();
	}

	static bool
	setup_triangle_fan_indices (auto* indices, size_t npoints)
	{
		if (npoints < 3) return false;

		indices->reserve((npoints - 2) * 3);
		for (size_t i = 1; i + 1 < npoints; ++i)
		{
			indices->push_back(0);
			indices->push_back((uint) i);
			indices->push_back((uint) (i + 1));
		}
		return true;
	}

	void
	Painter_draw (
		Painter* painter, PrimitiveMode mode, const Color* color,
		const Coord3* points,  size_t npoints,
		const uint*   indices, size_t nindices,
		const Color*  colors,
		const Coord3* texcoords,
		const TextureInfo* texinfo,
		const Shader* shader)
	{
		if (!points)
			argument_error(__FILE__, __LINE__);
		if (npoints <= 0)
			argument_error(__FILE__, __LINE__);

		PainterData* self = get_data(painter);

		if (!self->is_painting())
			invalid_state_error(__FILE__, __LINE__, "'painting' should be true.");

		std::unique_ptr<TextureInfo> ptexinfo;
		texinfo = setup_texinfo(self, texinfo, &ptexinfo);
		shader  = setup_shader(self, shader, texinfo);

		bool batchable =
			painter->has_flag(Painter::FLAG_BATCHING) &&
			!Painter::debug() &&
			!self->state.shader;
		if (batchable && mode == MODE_TRIANGLES)
		{
			batch(
				painter, mode, color, points, npoints, indices, nindices,
				colors, texcoords, texinfo, *shader);
		}
		else if (batchable && mode == MODE_TRIANGLE_FAN && (!indices || nindices == 0))
		{
			auto& fan_indices = self->triangle_fan_indices_buffer;
			fan_indices.clear();
			if (!setup_triangle_fan_indices(&fan_indices, npoints))
				return;
			batch(
				painter, MODE_TRIANGLES, color, points, npoints, &fan_indices[0], fan_indices.size(),
				colors, texcoords, texinfo, *shader);
		}
		else
		{
			Painter_flush(painter);
			draw(
				self, mode, color, points, npoints, indices, nindices,
				colors, texcoords, texinfo, *shader, self->position_matrix);
		}
	}

	static inline void
	debug_draw_text_line (
		Painter* painter, const Font& font,
		coord x, coord y, coord str_width, coord str_height)
	{
#if 0
		painter->self->text_image.save("/tmp/font.png");

		painter->push_state();
		{
			coord asc, desc, lead;
			font.get_height(&asc, &desc, &lead);
			//printf("%f %f %f %f \n", str_height, asc, desc, lead);

			painter->set_stroke(0.5, 0.5, 1);
			painter->no_fill();
			painter->rect(x - 1, y - 1, str_width + 2, str_height + 2);

			coord yy = y;
			painter->set_stroke(1, 0.5, 0.5, 0.4);
			painter->rect(x, yy, str_width, asc);//str_height);

			yy += asc;
			painter->set_stroke(1, 1, 0.5, 0.4);
			painter->rect(x, yy, str_width, desc);

			yy += desc;
			painter->set_stroke(1, 0.5, 1, 0.4);
			painter->rect(x, yy, str_width, lead);
		}
		painter->pop_state();
#endif
	}

	void
	Painter_draw_text_line (
		Painter* painter, const Font& font,
		const char* line, coord x, coord y,
		coord width, coord height)
	{
		assert(painter && font && line && *line != '\0');

		Painter::Data* self = painter->self.get();

		float density          = self->pixel_density;
		const RawFont& rawfont = Font_get_raw(font, density);
		coord str_w            = rawfont.get_width(line);
		coord str_h            = rawfont.get_height();
		int tex_w              = ceil(str_w);
		int tex_h              = ceil(str_h);
		const Texture& texture = Image_get_texture(self->text_image);
		if (
			texture.width()  < tex_w ||
			texture.height() < tex_h ||
			self->text_image.pixel_density() != density)
		{
			int bmp_w = std::max(texture.width(),  tex_w);
			int bmp_h = std::max(texture.height(), tex_h);
			self->text_image = Image(Bitmap(bmp_w, bmp_h), density);
		}

		if (!self->text_image)
			invalid_state_error(__FILE__, __LINE__);

		assert(self->text_image.pixel_density() == density);

		Bitmap_draw_string(
			&self->text_image.bitmap(), rawfont, line, 0, 0, font.smooth());

		str_w /= density;
		str_h /= density;
		if (width  == 0) width  = str_w;
		if (height == 0) height = str_h;

		Painter_draw_image(
			painter, self->text_image,
			0, 0, str_w, str_h,
			x, y, str_w, str_h,
			&Shader_get_shader_for_text());

		debug_draw_text_line(painter, font, x, y, str_w / density, str_h / density);
	}


	Painter::Painter ()
	:	self(new PainterData())
	{
	}

	void
	Painter::bind (const Image& image)
	{
		if (!image)
			argument_error(__FILE__, __LINE__, "invalid image.");

		if (self->is_painting())
			invalid_state_error(__FILE__, __LINE__, "painting flag should be false.");

		FrameBuffer fb(Image_get_texture(image));
		if (!fb)
			rays_error(__FILE__, __LINE__, "invalid frame buffer.");

		unbind();

		get_data(this)->frame_buffer = fb;
		canvas(0, 0, image.width(), image.height(), image.pixel_density());
	}

	void
	Painter::unbind ()
	{
		if (self->is_painting())
			invalid_state_error(__FILE__, __LINE__, "painting flag should be true.");

		get_data(this)->frame_buffer = FrameBuffer();
	}

	void
	Painter::begin ()
	{
		PainterData* self = get_data(this);

		if (self->is_painting())
			invalid_state_error(__FILE__, __LINE__, "painting flag should be false.");

		self->opengl_state.push();

		//glEnable(GL_CULL_FACE);

		glEnable(GL_DEPTH_TEST);
		glDepthFunc(GL_LEQUAL);
		OpenGL_check_error(__FILE__, __LINE__);

		glEnable(GL_BLEND);
		set_blend_mode(self->state.blend_mode);

		FrameBuffer& fb = self->frame_buffer;
		if (fb)
		{
			FrameBuffer_bind(fb.id());

			Texture& tex = fb.texture();
			if (tex) tex.set_modified();
		}

		const Bounds& vp = self->viewport;
		float density    = self->pixel_density;
		glViewport(
			(int) (vp.x      * density), (int) (vp.y      * density),
			(int) (vp.width  * density), (int) (vp.height * density));
		OpenGL_check_error(__FILE__, __LINE__);

		coord x1 = vp.x, x2 = vp.x + vp.width;
		coord y1 = vp.y, y2 = vp.y + vp.height;
		coord z1 = vp.z, z2 = vp.z + vp.depth;
		if (z1 == 0 && z2 == 0) {z1 = -1000; z2 = 1000;}
		if (!fb) std::swap(y1, y2);

		self->position_matrix.reset(1);
		self->position_matrix *= to_rays(glm::ortho(x1, x2, y1, y2));

		// map z to 0.0-1.0
		self->position_matrix.scale(1, 1, 1.0 / (z2 - z1));
		self->position_matrix.translate(0, 0, -z2);

		//self->position_matrix.translate(0.375f, 0.375f);

		Painter_update_clip(this);

		Xot::add_flag(&self->flags, Painter::Data::PAINTING);

		glClear(GL_DEPTH_BUFFER_BIT);
	}

	void
	Painter::end ()
	{
		PainterData* self = get_data(this);

		if (!self->is_painting())
			invalid_state_error(__FILE__, __LINE__, "painting flag should be true.");

		if (!self->state_stack.empty())
			invalid_state_error(__FILE__, __LINE__, "state stack is not empty.");

		if (!self->position_matrix_stack.empty())
			invalid_state_error(__FILE__, __LINE__, "position matrix stack is not empty.");

		Painter_flush(this);

		Xot::remove_flag(&self->flags, Painter::Data::PAINTING);
		self->opengl_state.pop();
		self->default_indices.clear();

		glFinish();

		if (self->frame_buffer)
			FrameBuffer_unbind();
	}

	void
	Painter::clear ()
	{
		if (!self->is_painting())
			invalid_state_error(__FILE__, __LINE__, "painting flag should be true.");

		Painter_flush(this);

		const Color& c = self->state.background;
		glClearColor(c.red, c.green, c.blue, c.alpha);
		glClear(GL_COLOR_BUFFER_BIT);
		OpenGL_check_error(__FILE__, __LINE__);
	}

	void
	Painter::set_blend_mode (BlendMode mode)
	{
		if (self->state.blend_mode != mode)
			Painter_flush(this);

		self->state.blend_mode = mode;
		switch (mode)
		{
			case BLEND_NORMAL:
				glBlendEquationSeparate(GL_FUNC_ADD, GL_FUNC_ADD);
				glBlendFuncSeparate(
					GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, GL_ONE, GL_ONE);
				break;

			case BLEND_ADD:
				glBlendEquationSeparate(GL_FUNC_ADD, GL_FUNC_ADD);
				glBlendFuncSeparate(GL_SRC_ALPHA, GL_ONE, GL_ONE, GL_ONE);
				break;

			case BLEND_SUBTRACT:
				glBlendEquationSeparate(GL_FUNC_REVERSE_SUBTRACT, GL_FUNC_ADD);
				glBlendFuncSeparate(GL_SRC_ALPHA, GL_ONE, GL_ONE, GL_ONE);
				break;

			case BLEND_LIGHTEST:
				glBlendEquationSeparate(GL_MAX, GL_FUNC_ADD);
				glBlendFuncSeparate(GL_ONE, GL_ONE, GL_ONE, GL_ONE);
				break;

			case BLEND_DARKEST:
				glBlendEquationSeparate(GL_MIN, GL_FUNC_ADD);
				glBlendFuncSeparate(GL_ONE, GL_ONE, GL_ONE, GL_ONE);
				break;

			case BLEND_EXCLUSION:
				glBlendEquationSeparate(GL_FUNC_ADD, GL_FUNC_ADD);
				glBlendFuncSeparate(
					GL_ONE_MINUS_DST_COLOR, GL_ONE_MINUS_SRC_COLOR, GL_ONE, GL_ONE);
				break;

			case BLEND_MULTIPLY:
				glBlendEquationSeparate(GL_FUNC_ADD, GL_FUNC_ADD);
				glBlendFuncSeparate(GL_ZERO, GL_SRC_COLOR, GL_ONE, GL_ONE);
				break;

			case BLEND_SCREEN:
				glBlendEquationSeparate(GL_FUNC_ADD, GL_FUNC_ADD);
				glBlendFuncSeparate(GL_ONE_MINUS_DST_COLOR, GL_ONE, GL_ONE, GL_ONE);
				break;

			case BLEND_REPLACE:
				glBlendEquationSeparate(GL_FUNC_ADD, GL_FUNC_ADD);
				glBlendFuncSeparate(GL_ONE, GL_ZERO, GL_ONE, GL_ZERO);
				break;

			default:
				argument_error(__FILE__, __LINE__, "unknown blend mode");
				break;
		}
		OpenGL_check_error(__FILE__, __LINE__);
	}


}// Rays
