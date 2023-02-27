// -*- c++ -*-
#pragma once
#ifndef __RAYS_SRC_IMAGE_H__
#define __RAYS_SRC_IMAGE_H__


#include <rays/image.h>


namespace Rays
{


	class Texture;


	      Texture& Image_get_texture (      Image& image);

	const Texture& Image_get_texture (const Image& image);


}// Rays


#endif//EOH
