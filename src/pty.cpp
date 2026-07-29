#if defined(OSX) || defined(LINUX)


#include "terminal.h"


#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <stdlib.h>
#include <unistd.h>
#ifdef OSX
	#include <util.h>
#else
	#include <pty.h>
#endif
#include <sys/ioctl.h>
#include <sys/wait.h>
#include <vector>
#include <xot/exception.h>


namespace Reflex
{


	static struct winsize
	to_winsize (int columns, int rows, int cell_width, int cell_height)
	{
		struct winsize size = {};
		size.ws_col         = (unsigned short) columns;
		size.ws_row         = (unsigned short) rows;
		size.ws_xpixel      = (unsigned short) (columns * cell_width);
		size.ws_ypixel      = (unsigned short) (rows    * cell_height);
		return size;
	}


	PTY::PTY ()
	{
	}

	PTY::~PTY ()
	{
		close();
	}

	void
	PTY::spawn (
		const StringList& args, const Terminal::EnvMap& envs,
		int columns, int rows, int cell_width, int cell_height,
		bool login)
	{
		if (args.empty() || args[0].empty())
			Xot::argument_error(__FILE__, __LINE__, "args is empty");
		if (is_open())
			Xot::invalid_state_error(__FILE__, __LINE__, "already spawned");

		String argv0 = args[0];
		if (login)
		{
			// shells read their login profiles when argv[0] starts with
			// a '-', so pass the base name prefixed with it (/bin/zsh
			// becomes -zsh); the path itself still goes to execvp()
			size_t pos = argv0.rfind('/');
			argv0      = "-" + (pos == String::npos ? argv0 : argv0.substr(pos + 1));
		}

		std::vector<const char*> argv;
		argv.emplace_back(argv0.c_str());
		for (size_t i = 1; i < args.size(); ++i)
			argv.emplace_back(args[i].c_str());
		argv.push_back(NULL);

		struct winsize size = to_winsize(columns, rows, cell_width, cell_height);

		int master  = -1;
		pid_t child = forkpty(&master, NULL, NULL, &size);
		if (child < 0)
			Xot::system_error(__FILE__, __LINE__, "forkpty() failed");

		if (child == 0)
		{
			// child process: exec the command
			setenv("TERM",         "xterm-256color",  1);
			setenv("COLORTERM",    "truecolor",       1);
			setenv("TERM_PROGRAM", "reflex-terminal", 1);
			unsetenv("LINES");
			unsetenv("COLUMNS");

			// drop what would contradict the terminal we just claimed to
			// be: a version for someone else's TERM_PROGRAM, and terminfo
			// pointing at another app. Session markers left by a terminal
			// or multiplexer we happen to run inside are its own business,
			// so the application removes those it cares about (env => nil)
			unsetenv("TERM_PROGRAM_VERSION");
			unsetenv("TERMINFO");

			// applied last so that the application wins over the
			// defaults above, but never over the cleanup
			for (const auto& it : envs)
			{
				if (it.second)
					setenv(it.first.c_str(), it.second->c_str(), 1);
				else
					unsetenv(it.first.c_str());
			}

			// exec the real path; argv[0] may be the login shell name
			execvp(args[0].c_str(), (char* const*) &argv[0]);
			_exit(127);// exec failed
		}

		int flags = fcntl(master, F_GETFL, 0);
		if (flags < 0 || fcntl(master, F_SETFL, flags | O_NONBLOCK) < 0)
		{
			::close(master);
			kill(child, SIGKILL);
			waitpid(child, NULL, 0);
			Xot::system_error(__FILE__, __LINE__, "failed to set O_NONBLOCK");
		}

		fd  = master;
		pid = child;
	}

	size_t
	PTY::read (char* buffer, size_t size)
	{
		if (!is_open()) return 0;

		ssize_t n = ::read(fd, buffer, size);
		if (n > 0) return (size_t) n;

		if (n == 0 || (errno != EAGAIN && errno != EINTR))
			close();// EOF or EIO: the child has exited
		return 0;
	}

	bool
	PTY::wait_readable (int timeout_msec) const
	{
		if (!is_open()) return false;

		fd_set fds;
		FD_ZERO(&fds);
		FD_SET(fd, &fds);
		struct timeval timeout = {0, timeout_msec * 1000};
		return select(fd + 1, &fds, NULL, NULL, &timeout) > 0;
	}

	void
	PTY::write (const char* bytes, size_t size)
	{
		if (!is_open() || !bytes || size == 0) return;

		size_t offset = 0;
		while (offset < size)
		{
			ssize_t n = ::write(fd, bytes + offset, size - offset);
			if (n > 0)
				offset += (size_t) n;
			else if (errno == EINTR)
				continue;
			else if (errno == EAGAIN)
			{
				// the pty buffer is full; wait briefly for the child to drain it
				fd_set fds;
				FD_ZERO(&fds);
				FD_SET(fd, &fds);
				struct timeval timeout = {0, 100 * 1000};// 100ms
				if (select(fd + 1, NULL, &fds, NULL, &timeout) <= 0)
					break;// give up to avoid blocking the UI thread forever
			}
			else
			{
				close();
				break;
			}
		}
	}

	void
	PTY::set_size (int columns, int rows, int cell_width, int cell_height)
	{
		if (!is_open()) return;

		struct winsize size = to_winsize(columns, rows, cell_width, cell_height);
		ioctl(fd, TIOCSWINSZ, &size);// sends SIGWINCH to the child
	}

	void
	PTY::close ()
	{
		if (fd >= 0)
		{
			::close(fd);
			fd = -1;
		}
		if (pid >= 0)
		{
			waitpid(pid, NULL, WNOHANG);// reap if already exited
			pid = -1;
		}
	}

	bool
	PTY::is_open () const
	{
		return fd >= 0;
	}

	bool
	PTY::is_child_alive () const
	{
		if (pid < 0) return false;

		return waitpid(pid, NULL, WNOHANG) == 0;
	}

	PTY::operator bool () const
	{
		return is_open();
	}

	bool
	PTY::operator ! () const
	{
		return !operator bool();
	}


}// Reflex


#endif// OSX || LINUX
