#include "tester.h"


#include <vector>
#include "defs.h"


using namespace Rucy;


static std::vector<Xot::String> logs;


void
log (const char* str)
{
	logs.push_back(str);
}


/*
	return all logs.
*/
RUCY_DEF0(all_logs)
{
	std::vector<Value> a;
	for (size_t i = 0; i < logs.size(); ++i) a.push_back(logs[i].c_str());
	return array(&a[0], a.size());
}
RUCY_END

/*
	clcear all logs.
*/
RUCY_DEF0(clear_logs)
{
	logs.clear();
}
RUCY_END


void Init_value ();
void Init_exception ();
void Init_function ();
void Init_struct ();
void Init_class ();


extern "C" void
Init_tester ()
{
	RUCY_TRY

	init();

	Module mRucy   =       define_module("Rucy");
	Module mTester = mRucy.define_module("Tester");

	mTester.define_module_function("all_logs", all_logs);
	mTester.define_module_function("clear_logs", clear_logs);

	Init_value();
	Init_exception();
	Init_function();
	Init_struct ();
	Init_class ();

	RUCY_CATCH
}
