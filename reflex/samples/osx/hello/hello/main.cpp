#include <xot.h>
#include <rays.h>
#include <reflex.h>

using namespace Xot;
using namespace Rays;
using namespace Reflex;


class Win : public Window
{

	typedef Window Super;

	public:

		void on_update (UpdateEvent* e)
		{
			redraw();
		}

		void on_draw (DrawEvent* e)
		{
			e->painter->text(stringf("%f", e->fps), 10, 10);
		}

};// Window


class App : public Application
{

	public:

		void on_start (Event* e)
		{
			Window* win = new Win();
			win->set_title(app()->name());
			win->set_frame(100, 100, 500, 500);
			win->show();

			win->root()->set_gravity(0, 9.8 * win->root()->meter2pixel());
			win->root()->set_debug(true);

			Image image(32, 32);
			Painter painter = image.painter();
			painter.begin();
			painter.no_stroke();
			painter.set_fill(1, 1, 1);
			painter.rect(0, 0, image.width(), image.height());
			painter.set_fill(1, 0, 0);
			painter.ellipse(0, 0, image.width(), image.height());
			painter.end();

			for (int y = 0; y < 3; ++y)
			for (int x = 0; x < 10; ++x)
			{
				ImageView* view = new ImageView();
				view->set_image(image);
				view->set_frame(
					x * (image.width()  + 10),
					y * (image.height() + 10),
					image.width(),
					image.height());

				win->root()->add_child(view);

				view->body()->set_dynamic(true);
				view->body()->set_density(1);
			}

			View* ground = new View();
			ground->set_frame(10, 400, 300, 10);
			win->root()->add_child(ground);
			ground->body()->set_static(true);
		}

};// App


int main(int argc, const char** argv)
{
	Rays::init();
	Reflex::init();

	Application* app = new App();
	app->set_name("Hello Xcode!");
	app->start();

	Reflex::fin();
	Rays::fin();

	return 0;
}
