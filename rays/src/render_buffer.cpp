#include "render_buffer.h"


#include "rays/exception.h"


namespace Rays
{


	struct RenderBuffer::Data
	{

		int id, width, height;

		Data ()
		:	id(-1), width(0), height(0)
		{
		}

		~Data ()
		{
			clear();
		}

		void create (int width_, int height_)
		{
			if (width_  <= 0)
				argument_error(__FILE__, __LINE__);
			if (height_ <= 0)
				argument_error(__FILE__, __LINE__);

			if (is_valid())
			{
				if (width  != width_)
				{
					argument_error(__FILE__, __LINE__,
						"RenderBuffer is already created and "
						"width parameters is not same as current width.");
				}
				if (height != height_)
				{
					argument_error(__FILE__, __LINE__,
						"RenderBuffer is already created and "
						"height parameters is not same as current height.");
				}
				return;
			}

			GLuint id_ = 0;
			glGenRenderbuffers(1, &id_);
			OpenGL_check_error(__FILE__, __LINE__);

			id = id_;
			glBindRenderbuffer(GL_RENDERBUFFER, id_);
			OpenGL_check_error(__FILE__, __LINE__);

			glRenderbufferStorage(
				GL_RENDERBUFFER,
				#ifdef IOS
					GL_DEPTH_COMPONENT16,
				#else
					GL_DEPTH_COMPONENT24,
				#endif
				width_,
				height_);
			OpenGL_check_error(__FILE__, __LINE__);

			glBindRenderbuffer(GL_RENDERBUFFER, 0);
			OpenGL_check_error(__FILE__, __LINE__);

			width  = width_;
			height = height_;
		}

		void clear ()
		{
			if (id >= 0)
			{
				GLuint id_ = id;
				glDeleteRenderbuffers(1, &id_);
			}

			id = -1;
		}

		bool is_valid () const
		{
			return id >= 0;
		}

	};// RenderBuffer::Data


	RenderBuffer::RenderBuffer ()
	{
	}

	RenderBuffer::RenderBuffer (int width, int height)
	{
		self->create(width, height);
	}

	RenderBuffer::~RenderBuffer ()
	{
	}

	GLuint
	RenderBuffer::id () const
	{
		return self->id;
	}

	int
	RenderBuffer::width () const
	{
		return self->width;
	}

	int
	RenderBuffer::height () const
	{
		return self->height;
	}

	RenderBuffer::operator bool () const
	{
		return self && self->is_valid();
	}

	bool
	RenderBuffer::operator ! () const
	{
		return !operator bool();
	}


}// Rays
