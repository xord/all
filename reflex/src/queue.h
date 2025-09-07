// -*- c++ -*-
#pragma once
#ifndef __REFLEX_SRC_QUEUE_H__
#define __REFLEX_SRC_QUEUE_H__


#include <queue>
#include <mutex>
#include <condition_variable>


namespace Reflex
{


	template <typename T>
	class Queue
	{

		public:

			void push (const T& value)
			{
				{
					std::lock_guard<std::mutex> lock(mutex);
					queue.push(value);
				}
				condvar.notify_one();
			}

			T pop ()
			{
				std::unique_lock<std::mutex> lock(mutex);
				condvar.wait(lock, [this] {return !queue.empty();});

				T value = queue.front();
				queue.pop();
				return value;
			}

			bool try_pop (T* value)
			{
				std::lock_guard<std::mutex> lock(mutex);
				if (queue.empty()) return false;

				*value = queue.front();
				queue.pop();
				return true;
			}

			bool empty () const
			{
				std::lock_guard<std::mutex> lock(mutex);
				return queue.empty();
			}

		private:

			std::queue<T> queue;

			mutable std::mutex mutex;

			std::condition_variable condvar;

	};// Queue


}// Reflex


#endif//EOH
