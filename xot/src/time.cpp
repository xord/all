#include "xot/time.h"


#include <chrono>
#include <thread>


namespace Ch = std::chrono;


namespace Xot
{


	double
	time ()
	{
		auto now = Ch::system_clock::now().time_since_epoch();
		return Ch::duration_cast<Ch::milliseconds>(now).count() / 1000.0;
	}

	void
	sleep (double seconds)
	{
		if (seconds <= 0) return;

		long long millisecs = seconds * 1000;
		std::this_thread::sleep_for(Ch::milliseconds(millisecs));
	}


}// Xot
