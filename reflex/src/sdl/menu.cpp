#include "../menu.h"


namespace Reflex
{


	Menu::Data*
	Menu_create_data ()
	{
		return new Menu::Data();
	}

	void
	Menu_update (Menu* menu)
	{
	}

	void
	Menu_popup (Menu* menu, View* view, coord x, coord y)
	{
	}

	void
	Menu_child_added (Menu* parent, Menu* child, int index)
	{
	}

	void
	Menu_child_removed (Menu* parent, Menu* child)
	{
	}


}// Reflex
