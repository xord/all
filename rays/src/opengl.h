// -*- c++ -*-
#pragma once
#ifndef __RAYS_SRC_OPENGL_H__
#define __RAYS_SRC_OPENGL_H__


#if defined(OSX)
	#include <OpenGL/gl.h>
	#include <OpenGL/glext.h>
#elif defined(IOS)
	#include <OpenGLES/ES3/gl.h>
	#include <OpenGLES/ES3/glext.h>
#elif defined(WIN32)
	#include <GL/gl.h>
	#include <GL/glext.h>
#endif

#include "rays/context.h"


namespace Rays
{


	void OpenGL_init ();

	void OpenGL_fin ();

	void OpenGL_set_context (Context context);

	Context OpenGL_get_context ();

	bool OpenGL_has_error ();

	void OpenGL_check_error (const char* file, int line);

	void OpenGL_check_error (const char* file, int line, const char* format, ...);


}// Rays


#endif//EOH
