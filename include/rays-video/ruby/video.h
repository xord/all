// -*- c++ -*-
#pragma once
#ifndef __RAYS_VIDEO_RUBY_VIDEO_H__
#define __RAYS_VIDEO_RUBY_VIDEO_H__


#include <rucy/class.h>
#include <rucy/extension.h>
#include <rays/video.h>


#if defined(WIN32) && defined(GCC) && defined(RAYS_VIDEO)
	#define RAYS_VIDEO_EXPORT __declspec(dllexport)
#else
	#define RAYS_VIDEO_EXPORT
#endif


RUCY_DECLARE_VALUE_FROM_TO(RAYS_VIDEO_EXPORT, Rays::Video)


namespace Rays
{


	RAYS_VIDEO_EXPORT Rucy::Class video_class ();
	// class Rays::Video


}// Rays


namespace Rucy
{


	template <> inline Class
	get_ruby_class<Rays::Video> ()
	{
		return Rays::video_class();
	}


}// Rucy


#endif//EOH
