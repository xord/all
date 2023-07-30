// -*- objc -*-
#include "reflex/device.h"


#import <UIKit/UIKit.h>


namespace Reflex
{


	static UIImpactFeedbackGenerator* g_feedback_generator = nil;

	static UIImpactFeedbackGenerator*
	get_feedback_generator ()
	{
		if (g_feedback_generator == nil)
		{
			g_feedback_generator =
				[[UIImpactFeedbackGenerator alloc]
					initWithStyle: UIImpactFeedbackStyleLight];
		}
		return g_feedback_generator;
	}

	void
	viberate ()
	{
		//[get_feedback_generator() prepare];
		[get_feedback_generator() impactOccurred];
	}


}// Reflex
