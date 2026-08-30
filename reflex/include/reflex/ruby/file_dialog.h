// -*- c++ -*-
#pragma once
#ifndef __REFLEX_RUBY_FILE_DIALOG_H__
#define __REFLEX_RUBY_FILE_DIALOG_H__


#include <rucy/class.h>
#include <rucy/extension.h>
#include <reflex/file_dialog.h>
#include <reflex/ruby/event.h>


RUCY_DECLARE_WRAPPER_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::FileDialog)


namespace Reflex
{


	REFLEX_EXPORT Rucy::Class file_dialog_class ();
	// class Reflex::FileDialog


	template <typename T>
	class RubyFileDialog : public Rucy::ClassWrapper<T>
	{

		typedef Rucy::ClassWrapper<T> Super;

		public:

			virtual void on_file (FileEvent* e)
			{
				if (this->is_overridable())
				{
					RUCY_SYM(call_file_block);
					this->value.call(call_file_block, Rucy::value(e));

					if (!e->is_blocked())
					{
						RUCY_SYM(on_file);
						this->value.call(on_file, Rucy::value(e));
					}
				}
				else
					Super::on_file(e);
			}

			virtual void on_cancel (Event* e)
			{
				if (this->is_overridable())
				{
					RUCY_SYM(call_cancel_block);
					this->value.call(call_cancel_block);

					RUCY_SYM(on_cancel);
					this->value.call(on_cancel, Rucy::value(e));
				}
				else
					Super::on_cancel(e);
			}

	};// RubyFileDialog


}// Reflex


namespace Rucy
{


	template <> inline Class
	get_ruby_class<Reflex::FileDialog> ()
	{
		return Reflex::file_dialog_class();
	}

	inline Value
	value (Reflex::FileDialog::Ref& ref, Value klass = Reflex::file_dialog_class())
	{
		return value(ref.get(), klass);
	}


}// Rucy


#endif//EOH
