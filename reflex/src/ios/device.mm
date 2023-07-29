// -*- objc -*-
#include "reflex/device.h"


#import <UIKit/UIKit.h>


namespace Reflex
{


	namespace global
	{

		static UIImpactFeedbackGenerator* feedback_generator = nil;

	}// global


	static UIImpactFeedbackGenerator*
	get_feedback_generator ()
	{
		if (global::feedback_generator == nil)
		{
			global::feedback_generator =
				[[UIImpactFeedbackGenerator alloc]
					initWithStyle: UIImpactFeedbackStyleLight];
		}
		return global::feedback_generator;
	}

	void
	viberate ()
	{
		//[get_feedback_generator() prepare];
		[get_feedback_generator() impactOccurred];
	}


}// Reflex
