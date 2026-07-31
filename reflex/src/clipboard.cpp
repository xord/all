#include "reflex/clipboard.h"


#include <map>
#include "reflex/exception.h"


namespace Reflex
{


	static const char* TEXT_TYPE = "text/plain";


	struct Clipboard::Data
	{

		std::map<String, String> types;

	};// Clipboard::Data


	Clipboard::Clipboard (const char* text)
	{
		if (text) set_text(text);
	}

	Clipboard::~Clipboard ()
	{
	}

	void
	Clipboard::set_text (const char* text)
	{
		if (!text)
			argument_error(__FILE__, __LINE__);

		self->types[TEXT_TYPE] = text;
	}

	const char*
	Clipboard::text () const
	{
		auto it = self->types.find(TEXT_TYPE);
		if (it == self->types.end())
			return NULL;

		return it->second.c_str();
	}

	void
	Clipboard::set_image (const Image& image)
	{
		not_implemented_error(__FILE__, __LINE__);
	}

	const Image*
	Clipboard::image () const
	{
		return NULL;
	}

	void
	Clipboard::clear ()
	{
		self->types.clear();
	}

	Clipboard::operator bool () const
	{
		return true;
	}

	bool
	Clipboard::operator ! () const
	{
		return !operator bool();
	}


}// Reflex
