#include "xot/util.h"


#include <stdlib.h>


namespace Xot
{


	int
	bit2byte (int bits)
	{
		if ((bits % 8) != 0) return -1;
		return bits / 8;
	}

	int
	byte2bit (int bytes)
	{
		return bytes * 8;
	}


	static bool seeded = false;

	void
	seed (uint value)
	{
		srand(value);
		seeded = true;
	}

	double
	random (double max_)
	{
		return random(0, max_);
	}

	double
	random (double min_, double max_)
	{
		if (!seeded) seed();

		double n = (double) rand() / (double) RAND_MAX;
		if (max_ != 1) n *= max_;
		if (min_ != 0) n += min_;
		return n;
	}


}// Xot
