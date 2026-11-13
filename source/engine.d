import raylib;
import std.algorithm : min;
import std.path : extension;

private bool running = false;

/*
	Initialises the window and enables vsync.
*/
void init(const char* name, const int width, const int height)
{
	SetConfigFlags(ConfigFlags.FLAG_VSYNC_HINT);
	InitWindow(width, height, name);
}

/*
	Starts the main loop.
	Handles vsync not working.
*/
void start(void function(float) tick, void function() render)
{
	running = true;

	int hz = GetMonitorRefreshRate(GetCurrentMonitor());
	if (hz <= 0)
		hz = 60;

	const int warmupFrames = 10;
	const int sampleFrames = 60;
	int frameCount = 0;
	double sampleTime = 0;
	bool checked = false;

	while (!WindowShouldClose() && running)
	{
		if (IsWindowFocused())
		{
			const float dt = min(GetFrameTime(), 0.05); // clamp to avoid giant frame jumps
			tick(dt);
		}

		BeginDrawing();

		render();

		EndDrawing();

		if (!checked)
		{
			frameCount++;
			if (frameCount > warmupFrames)
				sampleTime += GetFrameTime();

			if (frameCount == warmupFrames + sampleFrames)
			{
				double avg = sampleTime / sampleFrames;
				double expected = 1.0 / hz;

				if (avg < expected * 0.6)
					SetTargetFPS(hz);

				checked = true;
			}
		}
	}

	CloseWindow();
}

/*
	Loads a texture from its path with bilinear filtering.
	The images are embedded into the executable.
*/
Texture2D loadTexture(string path)()
{
    static immutable ubyte[] textureData = cast(immutable ubyte[]) import(path);
    enum fileType = path.extension ~ "\0"; // null-terminated for the C API

    Image image = LoadImageFromMemory(fileType.ptr, textureData.ptr, cast(int) textureData.length);
    Texture2D texture = LoadTextureFromImage(image);
    UnloadImage(image);
    SetTextureFilter(texture, TextureFilter.TEXTURE_FILTER_BILINEAR);
    return texture;
}

/*
	Kills the main loop.
*/
void kill()
{
	running = false;
}
