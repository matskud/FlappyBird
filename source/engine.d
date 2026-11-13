import raylib;
import std.algorithm : min;

private bool running = false;

void init(const char* name, const int width, const int height, const int targetFPS = 60)
{
	InitWindow(width, height, name);
	SetTargetFPS(targetFPS);
}

void start(void function(float) tick, void function() render)
{
	running = true;

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
	}

	CloseWindow();
}

Texture2D loadTexture(const char* path)
{
	auto texture = LoadTexture(path);
	SetTextureFilter(texture, TextureFilter.TEXTURE_FILTER_BILINEAR);
	return texture;
}

void kill()
{
	running = false;
}
