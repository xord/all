// -*- c++ -*-
#pragma once
#ifndef __REFLEX_TERMINAL_SRC_TERMINAL_H__
#define __REFLEX_TERMINAL_SRC_TERMINAL_H__


#include <stddef.h>
#include <xot/pimpl.h>
#include <xot/noncopyable.h>
#include <reflex/defs.h>
#include <reflex/terminal.h>


namespace Reflex
{


	class PTY : public Xot::NonCopyable
	{

		public:

			PTY ();

			~PTY ();

			void spawn (
				const StringList& args, const Terminal::EnvMap& envs,
				int columns, int rows, int cell_width, int cell_height,
				bool login = false);

			size_t read (char* buffer, size_t size);

			bool wait_readable (int timeout_msec) const;

			void write (const char* bytes, size_t size);

			void set_size (
				int columns, int rows, int cell_width, int cell_height);

			void close ();

			bool is_open () const;

			bool is_child_alive () const;

			operator bool () const;

			bool operator ! () const;

			struct Data;

			Xot::PImpl<Data> self;

	};// PTY


	Terminal::EnvMap Terminal_make_child_envs (const Terminal::EnvMap& envs);

	const std::vector<uint>& Terminal_get_cell_offsets (const Terminal& terminal);


}// Reflex


#endif//EOH
