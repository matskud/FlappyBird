import std.stdio;
import raylib;
import std.conv : to;
import std.random;

immutable HEIGHT = 600;
immutable WIDTH = 600;

immutable PILLAR_SPAWN_INTERVAL = 3;
immutable PILLAR_SPEED = 100;
immutable PILLAR_WIDTH = 80;

immutable PILLAR_GAP_MAX = 300;
immutable PILLAR_GAP_MIN = 250;

immutable PILLAR_OFFSET_MAX = 100;
immutable PILLAR_OFFSET_MIN = -100;

float pillarSpawnDateAccumulator = 0;

Pillar[] pillars;

class Sprite
{
	auto position = Vector2(0, 0);
	auto size = Vector2(0, 0);

	void draw()
	{
	}

}

class Pillar : Sprite
{
	private int pxVisibleFromTop = 0;
	private int pxVisibleFromBottom = 0;

	this()
	{
		size.x = PILLAR_WIDTH;
		size.y = HEIGHT; // same as the screen so we can easily move it on y

		const int gapSize = uniform(PILLAR_GAP_MIN, PILLAR_GAP_MAX);
		const int pillarScreenSize = HEIGHT - gapSize;

		const int pillarOffset = uniform(PILLAR_OFFSET_MIN, PILLAR_OFFSET_MAX);

		pxVisibleFromBottom = pillarScreenSize / 2 + pillarOffset;
		pxVisibleFromTop = pillarScreenSize / 2 - pillarOffset;

		pillars ~= this;
	}

	override void draw()
	{
		const int px = to!int(position.x);
		const int py = to!int(position.y);
		const int sx = to!int(size.x);
		const int sy = to!int(size.y);

		// top
		DrawRectangle(px, py - sy + pxVisibleFromTop, sx, sy, Colors.GREEN);

		// bottom
		DrawRectangle(px, py + HEIGHT - pxVisibleFromBottom, sx, sy, Colors.GREEN);
	}
}

void tick(float deltaTime)
{
	pillarSpawnDateAccumulator += deltaTime;

	// move pillars
	foreach (pillar; pillars)
	{
		pillar.position.x -= deltaTime * PILLAR_SPEED;
	}

	// spawn new pillars
	if (pillarSpawnDateAccumulator >= PILLAR_SPAWN_INTERVAL)
	{
		pillarSpawnDateAccumulator -= PILLAR_SPAWN_INTERVAL;

		auto pillar = new Pillar();
		pillar.position.x = WIDTH - pillarSpawnDateAccumulator * PILLAR_SPEED;
	}
}

void render()
{
	ClearBackground(Colors.SKYBLUE);

	foreach (pillar; pillars)
	{
		pillar.draw();
	}
}

int main()
{
	InitWindow(WIDTH, HEIGHT, "Flappybird");

	SetTargetFPS(60);

	while (!WindowShouldClose())
	{
		tick(GetFrameTime());

		BeginDrawing();

		render();

		EndDrawing();
	}

	CloseWindow();

	return 0;
}
