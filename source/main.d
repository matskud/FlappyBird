import std.stdio;
import raylib;
import std.conv : to;
import std.random;
import std.algorithm : remove;

immutable HEIGHT = 600;
immutable WIDTH = 600;

immutable PILLAR_SPAWN_INTERVAL = 3;
immutable PILLAR_SPEED = 100;
immutable PILLAR_WIDTH = 80;

immutable PILLAR_GAP_MAX = 300;
immutable PILLAR_GAP_MIN = 250;

immutable PILLAR_OFFSET_MAX = 100;
immutable PILLAR_OFFSET_MIN = -100;

immutable GRAVITY = 300;
immutable BIRD_RADIUS = 30;
immutable FLAP_STRENGTH = 200;
immutable HITBOX_REDUCTION = 8;

float pillarSpawnDateAccumulator = 0;

Pillar[] pillars;
Bird bird;
bool running = false;

class Sprite
{
	auto position = Vector2(0, 0);

	void draw()
	{
	}

}

class Pillar : Sprite
{
	int pxVisibleFromTop = 0;
	int pxVisibleFromBottom = 0;

	this()
	{
		const int gapSize = uniform(PILLAR_GAP_MIN, PILLAR_GAP_MAX);
		const int pillarScreenSize = HEIGHT - gapSize;

		const int pillarOffset = uniform(PILLAR_OFFSET_MIN, PILLAR_OFFSET_MAX);

		pxVisibleFromBottom = pillarScreenSize / 2 + pillarOffset;
		pxVisibleFromTop = pillarScreenSize / 2 - pillarOffset;
	}

	override void draw()
	{
		const int px = to!int(position.x);
		const int py = to!int(position.y);

		// top
		DrawRectangle(px, py - HEIGHT + pxVisibleFromTop, PILLAR_WIDTH, HEIGHT, Colors.GREEN);

		// bottom
		DrawRectangle(px, py + HEIGHT - pxVisibleFromBottom, PILLAR_WIDTH, HEIGHT, Colors.GREEN);
	}
}

class Bird : Sprite
{
	float velocity = 0;

	this()
	{
		position.x = WIDTH / 2 - BIRD_RADIUS / 2;
		position.y = HEIGHT / 2 - BIRD_RADIUS / 2;
	}

	void tick(float dt)
	{
		velocity += GRAVITY * dt;
		position.y += velocity * dt;
	}

	void flap()
	{
		velocity = -FLAP_STRENGTH;
	}

	private bool isOutOfScreen()
	{
		if ((position.y > HEIGHT - BIRD_RADIUS + HITBOX_REDUCTION) || (
				position.y < 0 + BIRD_RADIUS - HITBOX_REDUCTION))
		{
			return true;
		}

		return false;
	}

	private bool isCollidingWithAPillar()
	{
		const float hitboxRadius = BIRD_RADIUS - HITBOX_REDUCTION;

		foreach (pillar; pillars)
		{
			float leftBoundary = pillar.position.x;
			if (position.x + hitboxRadius < leftBoundary)
				continue;

			float rightBoundary = pillar.position.x + PILLAR_WIDTH;
			if (position.x - hitboxRadius > rightBoundary)
				continue;

			if (position.y - hitboxRadius < pillar.pxVisibleFromTop)
				return true;

			if (position.y + hitboxRadius  > HEIGHT - pillar.pxVisibleFromBottom)
				return true;
		}

		return false;
	}

	bool shouldDie()
	{
		if ((isOutOfScreen()) | (isCollidingWithAPillar()))
		{
			return true;
		}

		return false;
	}

	override void draw()
	{
		DrawCircleV(position, BIRD_RADIUS, Colors.RED);
	}
}

void tick(float dt)
{
	pillarSpawnDateAccumulator += dt;

	// move pillars
	foreach (pillar; pillars)
	{
		pillar.position.x -= dt * PILLAR_SPEED;
	}

	// spawn new pillars
	if (pillarSpawnDateAccumulator >= PILLAR_SPAWN_INTERVAL)
	{
		pillarSpawnDateAccumulator -= PILLAR_SPAWN_INTERVAL;

		auto pillar = new Pillar();
		pillar.position.x = WIDTH - pillarSpawnDateAccumulator * PILLAR_SPEED;
		pillars ~= pillar;
	}

	pillars = pillars.remove!(pillar => pillar.position.x < 0 - PILLAR_WIDTH);

	if (IsKeyPressed(KeyboardKey.KEY_SPACE))
	{
		bird.flap();
	}

	bird.tick(dt);

	if (bird.shouldDie())
	{
		running = false;
	}
}

void render()
{
	ClearBackground(Colors.SKYBLUE);

	foreach (pillar; pillars)
	{
		pillar.draw();
	}

	bird.draw();
}

int main()
{
	InitWindow(WIDTH, HEIGHT, "Flappybird");

	SetTargetFPS(60);

	bird = new Bird();

	running = true;

	while (running && !WindowShouldClose())
	{
		tick(GetFrameTime());

		BeginDrawing();

		render();

		EndDrawing();
	}

	CloseWindow();

	return 0;
}
