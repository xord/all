// -*- objc -*-
#include "reflex/ai.h"


#import <Foundation/Foundation.h>
#include "reflex/exception.h"
#include "reflex/debug.h"
#include "llm.swift.h"


namespace Reflex
{


	struct AI::Data
	{

		id llm = nil;

		~Data ()
		{
			[llm release];
		}

		id get_llm ()
		{
			if (!llm) llm = create_llm();
			return llm;
		}

		static id create_llm (const char* system_prompt = NULL)
		{
			id llm = nil;
			if (@available(macOS 26.0, *))
			{
				if (system_prompt)
				{
					llm = [[LLM alloc] initWithInstructions:
						[NSString stringWithUTF8String: system_prompt]];
				}
				else
					llm = [[LLM alloc] init];
				if (!llm)
					system_error(__FILE__, __LINE__);
			}
			return llm;
		}

	};// AI::Data


	AI::AI (const char* system_prompt)
	{
		if (@available(macOS 26.0, *))
		{
			if (system_prompt)
				self->llm = self->create_llm(system_prompt);
		}
	}

	AI::~AI ()
	{
	}

	String
	AI::generate (const char* prompt)
	{
		if (!prompt)
			argument_error(__FILE__, __LINE__);

		if (@available(macOS 26.0, *))
		{
			NSError* error   = nil;
			NSString* result = [self->get_llm()
				generateSyncWithPrompt: [NSString stringWithUTF8String: prompt]
				error:                  &error];
			if (error)
				reflex_error(__FILE__, __LINE__, error.localizedDescription.UTF8String);
			return result.UTF8String;
		}
		else
			not_implemented_error(__FILE__, __LINE__);
	}

	AI::operator bool () const
	{
		if (@available(macOS 26.0, *))
			return true;
		else
			return false;
	}

	bool
	AI::operator ! () const
	{
		return !operator bool();
	}


}// Reflex
