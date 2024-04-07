// -*- c++ -*-
#pragma once
#ifndef __RAYS_RUBY_RAYS_H__
#define __RAYS_RUBY_RAYS_H__


#include <rucy/module.h>
#include <rucy/extension.h>
#include <rays/rays.h>


RUCY_DECLARE_CONVERT_TO(RAYS_EXPORT, Rays::CapType)

RUCY_DECLARE_CONVERT_TO(RAYS_EXPORT, Rays::JoinType)

RUCY_DECLARE_CONVERT_TO(RAYS_EXPORT, Rays::BlendMode)

RUCY_DECLARE_CONVERT_TO(RAYS_EXPORT, Rays::TexCoordMode)

RUCY_DECLARE_CONVERT_TO(RAYS_EXPORT, Rays::TexCoordWrap)


namespace Rays
{


	RAYS_EXPORT Rucy::Module rays_module ();
	// module Rays


}// Rays


#endif//EOH
