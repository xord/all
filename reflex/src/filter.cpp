#include "reflex/filter.h"


#include "reflex/exception.h"
#include "reflex/debug.h"


namespace Reflex
{


	struct Filter::Data
	{

		Shader shader;

	};// Filter::Data


	Filter::Filter ()
	{
	}

	Filter::Filter (const Shader& shader)
	{
		self->shader = shader;
	}

	Filter::~Filter ()
	{
	}

	void
	Filter::apply (Painter* painter, const Image& image) const
	{
		if (!self->shader)
			return;

		if (!painter || !image)
			argument_error(__FILE__, __LINE__);

		painter->set_shader(self->shader);
		painter->image(image);
	}

	void
	Filter::set_shader (const Shader& shader)
	{
		self->shader = shader;
	}

	Shader&
	Filter::shader ()
	{
		return self->shader;
	}

	const Shader&
	Filter::shader () const
	{
		return const_cast<Filter*>(this)->shader();
	}

	Filter::operator bool () const
	{
		return self->shader;
	}

	bool
	Filter::operator ! () const
	{
		return !operator bool();
	}


}// Reflex
