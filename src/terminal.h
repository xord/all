// -*- c++ -*-
#pragma once
#ifndef __REFLEX_TERMINAL_SRC_TERMINAL_H__
#define __REFLEX_TERMINAL_SRC_TERMINAL_H__


#include <stddef.h>
#include <xot/noncopyable.h>
#include <reflex/defs.h>
#include <reflex/terminal.h>


namespace Reflex
{


	// A pseudo terminal with a child process attached to the slave side.
	class PTY : public Xot::NonCopyable
	{

		public:

			PTY ();

			~PTY ();

			// args[0] is the command; each platform marshals args into
			// its own form (argv array on POSIX, command line on Windows).
			// envs is applied on top of the defaults set for the child.
			// login follows the terminal convention of prefixing argv[0]
			// with '-' so that shells read their login profiles
			void spawn (
				const StringList& args, const Terminal::EnvMap& envs,
				int columns, int rows, int cell_width, int cell_height,
				bool login = false);

			// nonblocking; returns 0 if nothing is available
			size_t read (char* buffer, size_t size);

			// waits until read() would return data, up to timeout
			bool wait_readable (int timeout_msec) const;

			void write (const char* bytes, size_t size);

			void set_size (
				int columns, int rows, int cell_width, int cell_height);

			void close ();

			bool is_open () const;

			bool is_child_alive () const;

			operator bool () const;

			bool operator ! () const;

		private:

			int fd  = -1;

			int pid = -1;

	};// PTY


}// Reflex


#endif//EOH
