// -*- c++ -*-
#pragma once
#ifndef __XOT_DEBUG_H__
#define __XOT_DEBUG_H__


#if 1//def _DEBUG
#define XOT_USE_DOUT
#endif


namespace Xot
{


#ifdef XOT_USE_DOUT

	void dout (const char* format, ...);

	void doutln (const char* format, ...);

#else

	inline void dout(...) {}

	inline void doutln(...) {}

#endif


}// Xot


#endif//EOH
