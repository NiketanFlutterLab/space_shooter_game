import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:space_shooter_game/components/asteroid.dart';
import 'package:space_shooter_game/components/explosion.dart';

import 'package:space_shooter_game/components/laser.dart';
import 'package:space_shooter_game/my_game.dart';
import 'package:flutter/services.dart';

class Player extends SpriteAnimationComponent with HasGameReference<MyGame>, KeyboardHandler, CollisionCallbacks {
  bool _isShooting = false;
  final double _fireCooldown = 0.2;
  double _elapsedFireTime = 0.0;
  final Vector2 _keyboardMovement = Vector2.zero();
  bool _isDestroyed = false;
  final Random _random = Random();
  late Timer _explosionTimer;

  Player() {
    _explosionTimer = Timer(0.1, onTick: _createRandomExplosion, repeat: true, autoStart: false);
  }
  @override
  FutureOr<void> onLoad() async {
    animation = await _loadAnimation();
    size *= 0.3;
    add(RectangleHitbox.relative(Vector2(0.6, 0.9), parentSize: size, anchor: Anchor.center));
    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_isDestroyed) {
      _explosionTimer.update(dt);
      return;
    }
    final Vector2 movement = game.joystick.relativeDelta + _keyboardMovement;
    position += movement.normalized() * 200 * dt;
    _handleScreenBounds();
    _elapsedFireTime += dt;
    if (_isShooting && _elapsedFireTime >= _fireCooldown) {
      _fireLaser();
      _elapsedFireTime = 0.0;
    }
  }

  Future<SpriteAnimation> _loadAnimation() async {
    return SpriteAnimation.spriteList(
      [await game.loadSprite('player_blue_on0.png'), await game.loadSprite('player_blue_on1.png')],
      stepTime: 0.1,
      loop: true,
    );
  }

  void _handleScreenBounds() {
    final double screenWidth = game.size.x;
    final double screenHeight = game.size.y;
    position.y = clampDouble(position.y, size.y / 2, screenHeight - size.y / 2);

    if (position.x < 0) {
      position.x = screenWidth;
    } else if (position.x > screenWidth) {
      position.x = 0;
    }
  }

  void startShooting() {
    _isShooting = true;
  }

  void stopShooting() {
    _isShooting = false;
  }

  void _fireLaser() {
    game.add(Laser(position: position.clone() + Vector2(0, -size.y / 2)));
  }

  void _handleDestruction() async {
    animation = SpriteAnimation.spriteList([await game.loadSprite('player_blue_off.png')], stepTime: double.infinity);

    add(ColorEffect(const Color.fromRGBO(255, 255, 255, 1.0), EffectController(duration: 0.0)));

    add(OpacityEffect.fadeOut(EffectController(duration: 3.0), onComplete: () => _explosionTimer.stop()));

    add(MoveEffect.by(Vector2(0, 200), EffectController(duration: 3.0)));
    add(RemoveEffect(delay: 4.0));
    _isDestroyed = true;
    _explosionTimer.start();
  }

  void _createRandomExplosion() {
    final Vector2 explosionPosition = Vector2(
      position.x - size.x / 2 + _random.nextDouble() * size.x,
      position.y - size.y / 2 + _random.nextDouble() * size.y,
    );

    final ExplosionType explosionType = _random.nextBool() ? ExplosionType.smoke : ExplosionType.fire;

    final Explosion explosion = Explosion(position: explosionPosition, explosionType: explosionType, explosionSize: size.x * 0.7);
    game.add(explosion);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (_isDestroyed) return;
    if (other is Asteroid) {
      _handleDestruction();
    }
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    _keyboardMovement.x = 0;
    _keyboardMovement.x += keysPressed.contains(LogicalKeyboardKey.arrowLeft) ? -1 : 0;
    _keyboardMovement.x += keysPressed.contains(LogicalKeyboardKey.arrowRight) ? 1 : 0;
    _keyboardMovement.x = 0;
    _keyboardMovement.x += keysPressed.contains(LogicalKeyboardKey.keyA) ? -1 : 0;
    _keyboardMovement.x += keysPressed.contains(LogicalKeyboardKey.keyB) ? 1 : 0;
    _keyboardMovement.y = 0;
    _keyboardMovement.y += keysPressed.contains(LogicalKeyboardKey.arrowUp) ? -1 : 0;
    _keyboardMovement.y += keysPressed.contains(LogicalKeyboardKey.arrowDown) ? 1 : 0;
    _keyboardMovement.y = 0;
    _keyboardMovement.y += keysPressed.contains(LogicalKeyboardKey.keyW) ? -1 : 0;
    _keyboardMovement.y += keysPressed.contains(LogicalKeyboardKey.keyS) ? 1 : 0;
    return true;
  }
}
