#include "reflex/ruby/file_dialog.h"


#include "reflex/ruby/window.h"
#include "defs.h"


RUCY_DEFINE_WRAPPER_VALUE_FROM_TO(REFLEX_EXPORT, Reflex::FileDialog)

#define THIS      to<Reflex::FileDialog*>(self)

#define CHECK     RUCY_CHECK_OBJECT(Reflex::FileDialog, self)

#define CALL(fun) RUCY_CALL_SUPER(THIS, fun)


static
RUCY_DEF_ALLOC(alloc, klass)
{
	return value(new Reflex::RubyFileDialog<Reflex::FileDialog>, klass);
}
RUCY_END

static
RUCY_DEF1(open_file, dir)
{
	CHECK;
	THIS->open_file(dir.is_nil() ? NULL : dir.c_str());
	return self;
}
RUCY_END

static
RUCY_DEF1(open_files, dir)
{
	CHECK;
	THIS->open_files(dir.is_nil() ? NULL : dir.c_str());
	return self;
}
RUCY_END

static
RUCY_DEF1(open_directory, dir)
{
	CHECK;
	THIS->open_directory(dir.is_nil() ? NULL : dir.c_str());
	return self;
}
RUCY_END

static
RUCY_DEF2(save_file, dir, name)
{
	CHECK;
	THIS->save_file(
		dir.is_nil()  ? NULL : dir.c_str(),
		name.is_nil() ? NULL : name.c_str());
	return self;
}
RUCY_END

static
RUCY_DEF1(set_owner, owner)
{
	CHECK;
	THIS->set_owner(owner.is_nil() ? NULL : to<Reflex::Window*>(owner));
	return owner;
}
RUCY_END

static
RUCY_DEF0(get_owner)
{
	CHECK;
	return value(THIS->owner());
}
RUCY_END

static
RUCY_DEF1(set_title, title)
{
	CHECK;
	THIS->set_title(title.c_str());
	return title;
}
RUCY_END

static
RUCY_DEF0(get_title)
{
	CHECK;
	return value(THIS->title());
}
RUCY_END

static
RUCY_DEF1(set_extensions, extensions)
{
	CHECK;

	Reflex::StringList list;
	if (extensions.is_nil())
		;// emplace nothing
	else if (extensions.is_s() || extensions.is_sym())
		list.emplace_back(extensions.c_str());
	else if (extensions.is_array())
	{
		size_t size = extensions.size();
		for (size_t i = 0; i < size; ++i)
		{
			if (!extensions[i].is_s() && !extensions[i].is_sym())
				argument_error(__FILE__, __LINE__);

			list.emplace_back(extensions[i].c_str());
		}
	}
	else
		argument_error(__FILE__, __LINE__);

	THIS->set_extensions(list);
	return extensions;
}
RUCY_END

static
RUCY_DEF0(get_extensions)
{
	CHECK;

	std::vector<Value> values;
	for (const auto& extension : THIS->extensions())
		values.emplace_back(extension.c_str());

	return array(values.data(), values.size());
}
RUCY_END

static
RUCY_DEF1(on_file, event)
{
	CHECK;

	CALL(on_file(to<Reflex::FileEvent*>(event)));
}
RUCY_END

static
RUCY_DEF1(on_cancel, event)
{
	CHECK;

	CALL(on_cancel(to<Reflex::Event*>(event)));
}
RUCY_END


static Class cFileDialog;

void
Init_reflex_file_dialog ()
{
	Module mReflex = define_module("Reflex");

	cFileDialog = mReflex.define_class("FileDialog");
	cFileDialog.define_alloc_func(alloc);
	cFileDialog.define_method("open_file!",      open_file);
	cFileDialog.define_method("open_files!",     open_files);
	cFileDialog.define_method("open_directory!", open_directory);
	cFileDialog.define_method("save_file!",      save_file);
	cFileDialog.define_method("owner=", set_owner);
	cFileDialog.define_method("owner",  get_owner);
	cFileDialog.define_method("title=", set_title);
	cFileDialog.define_method("title",  get_title);
	cFileDialog.define_method("extensions=", set_extensions);
	cFileDialog.define_method("extensions",  get_extensions);
	cFileDialog.define_method("on_file",   on_file);
	cFileDialog.define_method("on_cancel", on_cancel);
}


namespace Reflex
{


	Class
	file_dialog_class ()
	{
		return cFileDialog;
	}


}// Reflex
