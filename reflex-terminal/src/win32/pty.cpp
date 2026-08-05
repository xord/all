// ConPTY needs windows 10 1809
#define XOT_WIN32_WINNT 0x0A00// for <xot/windows.h>
#define NTDDI_VERSION   0x0A000006// NTDDI_WIN10_RS5
#include <xot/windows.h>

#include "../terminal.h"


#include <stdlib.h>
#include <string.h>
#include <wchar.h>
#include <string>
#include <vector>
#include <map>
#include <reflex/exception.h>


namespace Reflex
{


	struct PTY::Data
	{

		HANDLE input   = NULL;

		HANDLE output  = NULL;

		HPCON console  = NULL;

		HANDLE process = NULL;

	};// PTY::Data


	static COORD
	to_coord (int columns, int rows)
	{
		COORD size = {};
		size.X     = (SHORT) columns;
		size.Y     = (SHORT) rows;
		return size;
	}

	static String
	to_command_line (const StringList& args)
	{
		// CreateProcess takes one command line rather than an argument array,
		// so put back the quoting a shell would have removed

		String line;
		for (const String& arg : args)
		{
			if (!line.empty()) line += ' ';

			if (!arg.empty() && arg.find_first_of(" \t\"") == String::npos)
			{
				line += arg;
				continue;
			}

			line += '"';
			size_t backslashes = 0;
			for (size_t i = 0; i < arg.size(); ++i)
			{
				if (arg[i] == '\\') {++backslashes; continue;}

				// backslashes are literal unless they precede a quote, where
				// each of them needs one of its own to stay literal
				line.append(arg[i] == '"' ? backslashes * 2 + 1 : backslashes, '\\');
				backslashes = 0;
				line += arg[i];
			}
			line.append(backslashes * 2, '\\');// the closing quote counts as one
			line += '"';
		}
		return line;
	}

	static std::wstring
	to_environment_block (const Terminal::EnvMap& envs)
	{
		// a block of NAME=VALUE strings, each terminated by a NUL and the
		// whole ended by an empty one

		std::map<String, String, decltype([](const String& lhs, const String& rhs)
		{
			// windows matches variable names case insensitively, so an inherited
			// Path has to be the same entry as a PATH from the application
			return _stricmp(lhs.c_str(), rhs.c_str()) < 0;
		})> map;

		LPWCH current = GetEnvironmentStringsW();
		if (current)
		{
			for (LPWCH p = current; *p; p += wcslen(p) + 1)
			{
				// a leading '=' marks the per-drive current directories
				// that cmd.exe keeps, which are not variables to inherit
				const wchar_t* eq = wcschr(p + 1, L'=');
				if (!eq) continue;

				map[String(p, eq - p)] = String(eq + 1, wcslen(eq + 1));
			}
			FreeEnvironmentStringsW(current);
		}

		for (const auto& it : Terminal_make_child_envs(envs))
		{
			if (it.second) map[it.first] = *it.second;
			else           map.erase(it.first);
		}

		String block;
		for (const auto& it : map)
		{
			block += it.first;
			block += '=';
			block += it.second;
			block += '\0';
		}
		block += '\0';
		return block.to_wstr();
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
		// login is ignored: windows has no convention for telling a shell
		// to read its login profile

		if (args.empty() || args[0].empty())
			argument_error(__FILE__, __LINE__, "args is empty");
		if (is_open())
			invalid_state_error(__FILE__, __LINE__, "already spawned");

		// the pseudo console owns the far end of each pipe
		HANDLE child_input = NULL, child_output = NULL;
		if (
			!CreatePipe(&child_input, &self->input, NULL, 0) ||
			!CreatePipe(&self->output, &child_output, NULL, 0))
		{
			// the ends the console has not taken over yet are ours to close
			if (child_input)  CloseHandle(child_input);
			if (child_output) CloseHandle(child_output);
			close();
			system_error(__FILE__, __LINE__, "CreatePipe() failed");
		}

		// PIPE_NOWAIT is what keeps write() from stalling the UI thread once
		// the console stops draining. It is documented as legacy, but nothing
		// else makes a CreatePipe() handle non-blocking, and a terminal that
		// can freeze the whole app is worse than one that refuses to start
		DWORD mode = PIPE_NOWAIT;
		if (!SetNamedPipeHandleState(self->input, &mode, NULL, NULL))
		{
			CloseHandle(child_input);
			CloseHandle(child_output);
			close();
			system_error(__FILE__, __LINE__, "failed to make the input pipe non-blocking");
		}

		HRESULT result = CreatePseudoConsole(
			to_coord(columns, rows), child_input, child_output, 0, &self->console);

		// the console duplicated what it needs, so let go of our copies
		CloseHandle(child_input);
		CloseHandle(child_output);

		if (FAILED(result))
		{
			close();
			system_error(__FILE__, __LINE__, "CreatePseudoConsole() failed");
		}

		// asking for the size is expected to fail; a zero means it failed
		// for some other reason and there is nothing to allocate
		size_t attrs_size = 0;
		InitializeProcThreadAttributeList(NULL, 1, 0, &attrs_size);
		if (attrs_size == 0)
		{
			close();
			system_error(__FILE__, __LINE__, "failed to size the process attributes");
		}

		std::vector<char> attrs(attrs_size);

		STARTUPINFOEXW startup  = {};
		startup.StartupInfo.cb  = sizeof(startup);
		startup.lpAttributeList = (LPPROC_THREAD_ATTRIBUTE_LIST) &attrs[0];

		if (
			!InitializeProcThreadAttributeList(startup.lpAttributeList, 1, 0, &attrs_size) ||
			!UpdateProcThreadAttribute(
				startup.lpAttributeList, 0, PROC_THREAD_ATTRIBUTE_PSEUDOCONSOLE,
				self->console, sizeof(self->console), NULL, NULL))
		{
			close();
			system_error(__FILE__, __LINE__, "failed to set up the process attributes");
		}

		std::wstring command = to_command_line(args).to_wstr();
		std::wstring block   = to_environment_block(envs);

		PROCESS_INFORMATION process = {};
		BOOL ok                     = CreateProcessW(
			NULL, &command[0], NULL, NULL, FALSE,
			EXTENDED_STARTUPINFO_PRESENT | CREATE_UNICODE_ENVIRONMENT, &block[0], NULL,
			&startup.StartupInfo, &process);

		DeleteProcThreadAttributeList(startup.lpAttributeList);

		if (!ok)
		{
			close();
			system_error(__FILE__, __LINE__, "CreateProcess() failed");
		}

		CloseHandle(process.hThread);
		self->process = process.hProcess;
	}

	size_t
	PTY::read (char* buffer, size_t size)
	{
		if (!is_open()) return 0;

		// pipes block on read, so take only what has already arrived
		DWORD available = 0;
		if (!PeekNamedPipe(self->output, NULL, 0, NULL, &available, NULL))
		{
			close();// the pipe is gone with the pseudo console that wrote to it
			return 0;
		}

		// an exited child is deliberately not taken as the end of the output:
		// the pseudo console pumps it on a thread of its own, so bytes
		// written just before the exit may still be on their way. Reading
		// stops when the pipe itself ends, above
		if (available == 0) return 0;

		if (available > size) available = (DWORD) size;

		DWORD read = 0;
		if (!ReadFile(self->output, buffer, available, &read, NULL))
		{
			close();
			return 0;
		}
		return read;
	}

	bool
	PTY::wait_readable (int timeout_msec) const
	{
		if (!is_open()) return false;

		// there is nothing to wait on for a pipe, so poll it. Sleep(1) would
		// really sleep a whole frame at the default timer resolution, so
		// yield the rest of the time slice and keep the time ourselves
		LARGE_INTEGER frequency = {}, start = {}, now = {};
		QueryPerformanceFrequency(&frequency);
		QueryPerformanceCounter(&start);

		while (true)
		{
			DWORD available = 0;
			if (!PeekNamedPipe(self->output, NULL, 0, NULL, &available, NULL))
				return false;

			if (available > 0) return true;

			QueryPerformanceCounter(&now);
			LONGLONG elapsed = (now.QuadPart - start.QuadPart) * 1000;
			if (elapsed >= (LONGLONG) timeout_msec * frequency.QuadPart)
				return false;

			SwitchToThread();
		}
	}

	void
	PTY::write (const char* bytes, size_t size)
	{
		if (!is_open() || !bytes || size == 0) return;

		enum {DRAIN_TIMEOUT = 100};// msec

		size_t offset      = 0;
		ULONGLONG deadline = GetTickCount64() + DRAIN_TIMEOUT;
		while (offset < size)
		{
			DWORD written = 0;
			if (!WriteFile(self->input, bytes + offset, (DWORD) (size - offset), &written, NULL))
			{
				// a full PIPE_NOWAIT pipe reports failure here, with a code that
				// also means the pipe is closing, so there is nothing to tell the
				// two apart by. Fall through to the wait below and leave noticing
				// a dead pipe to read(), which PeekNamedPipe() answers plainly.
				// This is where errno lets the posix side close() right away
				written = 0;
			}

			if (written > 0)
			{
				offset  += written;
				deadline = GetTickCount64() + DRAIN_TIMEOUT;// the timeout is per stall
				continue;
			}

			if (GetTickCount64() >= deadline)
				break;// give up to avoid blocking the UI thread forever

			// the pipe is full; wait for the console to drain it. Sleeping
			// rather than yielding as wait_readable() does: the default timer
			// resolution is nothing next to this timeout, and spinning would
			// burn the UI thread for as long as the wait lasts
			Sleep(1);
		}
	}

	void
	PTY::set_size (int columns, int rows, int cell_width, int cell_height)
	{
		if (!is_open()) return;

		// the cell size has nowhere to go: a pseudo console is sized in cells only
		ResizePseudoConsole(self->console, to_coord(columns, rows));
	}

	void
	PTY::close ()
	{
		if (self->console)
		{
			// out of the order Data declares them: the pseudo console flushes what
			// it still holds on the way out, so closing the pipe it writes to
			// first would leave it stuck
			ClosePseudoConsole(self->console);
			self->console = NULL;
		}

		if (self->input)   {CloseHandle(self->input);   self->input   = NULL;}
		if (self->output)  {CloseHandle(self->output);  self->output  = NULL;}
		if (self->process) {CloseHandle(self->process); self->process = NULL;}
	}

	bool
	PTY::is_open () const
	{
		return self->output != NULL;
	}

	bool
	PTY::is_child_alive () const
	{
		if (!self->process) return false;

		return WaitForSingleObject(self->process, 0) == WAIT_TIMEOUT;
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
