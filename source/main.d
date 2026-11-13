module main;

import core.runtime;
import core.sys.windows.windows;
static import app;

extern (Windows)
int WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
	try
	{
		Runtime.initialize();
		app.start();
		Runtime.terminate();
		return 0;
	}
	catch (Throwable e)
	{
		return 1;
	}
}
