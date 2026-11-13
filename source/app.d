module app;

import raylib;
import random = std.random;
import std.algorithm : remove;
static import engine;
import std.functional : toDelegate;

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
enum BIRD_RADIUS = 40;
enum FLAP_STRENGTH = 200;
enum HITBOX_REDUCTION = 8;

float pillarSpawnDateAccumulator = 0;

Pillar[] pillars;
Bird bird;

Texture2D pillarTexture;
Texture2D birdTexture;

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
		const int gapSize = random.uniform(PILLAR_GAP_MIN, PILLAR_GAP_MAX);
		const int pillarScreenSize = HEIGHT - gapSize;

		const int pillarOffset = random.uniform(PILLAR_OFFSET_MIN, PILLAR_OFFSET_MAX);

		pxVisibleFromBottom = pillarScreenSize / 2 + pillarOffset;
		pxVisibleFromTop = pillarScreenSize / 2 - pillarOffset;
	}

	override void draw()
	{
		const float texW = pillarTexture.width;
		const float texH = pillarTexture.height;
		const float scale = PILLAR_SIZE.y / texH;

		const float bottomY = position.y + HEIGHT - pxVisibleFromBottom;
		DrawTexturePro(
			pillarTexture,
			Rectangle(0, 0, texW, pxVisibleFromBottom / scale),
			Rectangle(position.x, bottomY, PILLAR_SIZE.x, pxVisibleFromBottom),
			Vector2(0, 0), 0, Colors.WHITE
		);

		DrawTexturePro(
			pillarTexture,
			Rectangle(0, 0, texW, -(pxVisibleFromTop / scale)),
			Rectangle(position.x, position.y, PILLAR_SIZE.x, pxVisibleFromTop),
			Vector2(0, 0), 0, Colors.WHITE
		);
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

	void tick(float dt, float gravity)
	{
		velocity += gravity * dt;
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
		const float size = BIRD_RADIUS * 2;
		DrawTexturePro(
			birdTexture,
			Rectangle(0, 0, birdTexture.width, birdTexture.height),
			Rectangle(position.x, position.y, size, size),
			Vector2(size / 2, size / 2),
			0, Colors.WHITE
		);
	}
}

void tick(float dt)
{
	pillarSpawnDateAccumulator += dt;

	float speedMultiplier = 1 + engine.secondsSinceStarted * 0.05;
	float pillarSpeed = speedMultiplier * PILLAR_SPEED;
	float pillarSpawnInterval = PILLAR_SPAWN_INTERVAL / (speedMultiplier * 0.8);
	float gravity = GRAVITY + GRAVITY * speedMultiplier * 0.05;

	// move pillars
	foreach (pillar; pillars)
	{
		pillar.position.x -= dt * pillarSpeed;
	}

	// spawn new pillars
	if (pillarSpawnDateAccumulator >= pillarSpawnInterval)
	{
		pillarSpawnDateAccumulator -= pillarSpawnInterval;

		auto pillar = new Pillar();
		pillar.position.x = WIDTH - pillarSpawnDateAccumulator * pillarSpeed;
		pillars ~= pillar;
	}

	pillars = pillars.remove!(pillar => pillar.position.x < 0 - PILLAR_SIZE.x);

	if (IsKeyPressed(KeyboardKey.KEY_SPACE))
	{
		bird.flap();
	}

	bird.tick(dt, gravity);

	if (bird.shouldDie(pillars))
	{
		engine.kill();
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

int start()
{
	engine.init("FlappyBird", WIDTH, HEIGHT);

	birdTexture = engine.loadTexture!"art/bird.png"();
	pillarTexture = engine.loadTexture!"art/pillar.png"();

	bird = new Bird();

	engine.start(toDelegate(&tick), toDelegate(&render));

	return 0;
}
