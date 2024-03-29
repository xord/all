// -*- c++ -*-
#pragma once
#ifndef __RAYS_RUBY_RAYS_H__
#define __RAYS_RUBY_RAYS_H__


#include <rucy/module.h>
#include <rucy/extension.h>
#include <rays/rays.h>


RUCY_DECLARE_CONVERT_TO(Rays::CapType)

RUCY_DECLARE_CONVERT_TO(Rays::JoinType)

RUCY_DECLARE_CONVERT_TO(Rays::BlendMode)

RUCY_DECLARE_CONVERT_TO(Rays::TexCoordMode)

RUCY_DECLARE_CONVERT_TO(Rays::TexCoordWrap)


namespace Rays
{


	Rucy::Module rays_module ();
	// module Rays


}// Rays


#endif//EOH
