import raylib;
import std.random;
import std.algorithm : remove;

enum HEIGHT = 600;
enum WIDTH = 600;

enum PILLAR_SPAWN_INTERVAL = 3;
enum PILLAR_SPEED = 100;
immutable PILLAR_SIZE = Vector2(80, HEIGHT);

enum PILLAR_GAP_MAX = 300;
enum PILLAR_GAP_MIN = 250;

enum PILLAR_OFFSET_MAX = 100;
enum PILLAR_OFFSET_MIN = -100;

enum GRAVITY = 300;
enum BIRD_RADIUS = 30;
enum FLAP_STRENGTH = 200;
enum HITBOX_REDUCTION = 8;

float pillarSpawnDateAccumulator = 0;

Pillar[] pillars;
Bird bird;
bool running = false;

abstract class Sprite
{
	auto position = Vector2(0, 0);

	abstract void draw()
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
		// top
		DrawRectangleV(Vector2(position.x, position.y - HEIGHT + pxVisibleFromTop), PILLAR_SIZE, Colors.GREEN);

		// bottom
		DrawRectangleV(Vector2(position.x, position.y + HEIGHT - pxVisibleFromBottom), PILLAR_SIZE, Colors.GREEN);
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

	bool isOutOfScreen()
	{
		if ((position.y > HEIGHT - BIRD_RADIUS + HITBOX_REDUCTION) || (
				position.y < 0 + BIRD_RADIUS - HITBOX_REDUCTION))
		{
			return true;
		}

		return false;
	}

	bool isCollidingWithAPillar(const Pillar[] pillars) const
	{
		const hitboxRadius = BIRD_RADIUS - HITBOX_REDUCTION;
		foreach (pillar; pillars)
		{
			auto top = Rectangle(pillar.position.x, 0, PILLAR_SIZE.x, pillar.pxVisibleFromTop);
			auto bottom = Rectangle(pillar.position.x, HEIGHT - pillar.pxVisibleFromBottom,
				PILLAR_SIZE.x, pillar.pxVisibleFromBottom);

			if (CheckCollisionCircleRec(position, hitboxRadius, top) ||
				CheckCollisionCircleRec(position, hitboxRadius, bottom))
				return true;
		}
		return false;
	}

	bool shouldDie(const Pillar[] pillars)
	{
		if ((isOutOfScreen()) | (isCollidingWithAPillar(pillars)))
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

	pillars = pillars.remove!(pillar => pillar.position.x < 0 - PILLAR_SIZE.x);

	if (IsKeyPressed(KeyboardKey.KEY_SPACE))
	{
		bird.flap();
	}

	bird.tick(dt);

	if (bird.shouldDie(pillars))
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
