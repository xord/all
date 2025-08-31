#include "rays/camera.h"


#include "rays/exception.h"


namespace Rays
{


	struct Camera::Data
	{
	};// Camera::Data


	std::vector<String>
	get_camera_device_names ()
	{
		not_implemented_error(__FILE__, __LINE__);
	}


	Camera::Camera (
		const char* device_name,
		int min_width, int min_height, bool resize, bool crop)
	{
		not_implemented_error(__FILE__, __LINE__);
	}

	Camera::~Camera ()
	{
		not_implemented_error(__FILE__, __LINE__);
	}

	bool
	Camera::start ()
	{
		not_implemented_error(__FILE__, __LINE__);
	}

	void
	Camera::stop ()
	{
		not_implemented_error(__FILE__, __LINE__);
	}

	bool
	Camera::is_active () const
	{
		not_implemented_error(__FILE__, __LINE__);
	}

	void
	Camera::set_min_width (int width)
	{
		not_implemented_error(__FILE__, __LINE__);
	}

	int
	Camera::min_width () const
	{
		not_implemented_error(__FILE__, __LINE__);
	}

	void
	Camera::set_min_height (int height)
	{
		not_implemented_error(__FILE__, __LINE__);
	}

	int
	Camera::min_height () const
	{
		not_implemented_error(__FILE__, __LINE__);
	}

	void
	Camera::set_resize (bool resize)
	{
		not_implemented_error(__FILE__, __LINE__);
	}

	bool
	Camera::is_resize () const
	{
		not_implemented_error(__FILE__, __LINE__);
	}

	void
	Camera::set_crop (bool crop)
	{
		not_implemented_error(__FILE__, __LINE__);
	}

	bool
	Camera::is_crop () const
	{
		not_implemented_error(__FILE__, __LINE__);
	}

	const Image*
	Camera::image () const
	{
		not_implemented_error(__FILE__, __LINE__);
	}

	Camera::operator bool () const
	{
		return false;
	}

	bool
	Camera::operator ! () const
	{
		return !operator bool();
	}


}// Rays
