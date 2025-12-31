import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:space_shooter_game/components/asteroid.dart';
import 'package:flutter/material.dart';
import 'package:space_shooter_game/components/pickup.dart';
import 'package:space_shooter_game/components/player.dart';
import 'package:space_shooter_game/components/shoot_button.dart';

class MyGame extends FlameGame with HasKeyboardHandlerComponents, HasCollisionDetection {
  late Player player;
  late JoystickComponent joystick;
  late SpawnComponent _asteriodSpawner;
  late SpawnComponent _pickupSpawner;
  final Random _random = Random();
  late ShootButton _shootButton;
  int _score = 0;
  late TextComponent _scoreDisplay;

  @override
  FutureOr<void> onLoad() async {
    await Flame.device.fullScreen();
    await Flame.device.setPortrait();
    startGame();
    return super.onLoad();
  }

  void startGame() async {
    await _createJoysrick();
    await _createPlayer();
    _createShootButton();
    _createAsteriodSpawner();
    _createPickupSpawner();
    _createScoreDisplay();
  }

  Future<void> _createPlayer() async {
    player = Player()
      ..anchor = Anchor.center
      ..position = Vector2(size.x / 2, size.y * 0.8);
    add(player);
  }

  Future<void> _createJoysrick() async {
    joystick = JoystickComponent(
      knob: SpriteComponent(sprite: await loadSprite('joystick_knob.png'), size: Vector2.all(50)),
      background: SpriteComponent(sprite: await loadSprite('joystick_background.png'), size: Vector2.all(100)),
      anchor: Anchor.bottomLeft,
      position: Vector2(20, size.y - 20),
      priority: 10,
    );
    add(joystick);
  }

  void _createShootButton() {
    _shootButton = ShootButton()
      ..anchor = Anchor.bottomRight
      ..position = Vector2(size.x - 20, size.y - 20)
      ..priority = 10;
    add(_shootButton);
  }

  void _createAsteriodSpawner() {
    _asteriodSpawner = SpawnComponent.periodRange(
      factory: (index) => Asteroid(position: _generateSpawnPosition()),
      minPeriod: 0.7,
      maxPeriod: 1.2,
      selfPositioning: true,
    );

    add(_asteriodSpawner);
  }

  void _createPickupSpawner() {
    _pickupSpawner = SpawnComponent.periodRange(
      factory: (index) => Pickup(position: _generateSpawnPosition(), pickupType: PickupType.values[PickupType.values.length]),
      minPeriod: 0.7,
      maxPeriod: 1.2,
      selfPositioning: true,
    );

    add(_pickupSpawner);
  }

  Vector2 _generateSpawnPosition() {
    return Vector2(10 + _random.nextDouble() * (size.x - 10 * 2), -100);
  }

  void _createScoreDisplay() {
    _score = 0;
    _scoreDisplay = TextComponent(
      text: '0',
      anchor: Anchor.topCenter,
      position: Vector2(size.x / 2, 20),
      priority: 10,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 48,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 2)],
        ),
      ),
    );
    add(_scoreDisplay);
  }

  void incrementScore(int amount) {
    _score += amount;
    _scoreDisplay.text = _score.toString();
    final ScaleEffect popEffect = ScaleEffect.to(
      Vector2.all(1.2),
      EffectController(duration: 0.05, alternate: true, curve: Curves.easeInOut),
    );

    _scoreDisplay.add(popEffect);
  }
}
