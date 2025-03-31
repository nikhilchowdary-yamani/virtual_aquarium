import 'dart:math';
import 'package:flutter/material.dart';

class Fish {
  Offset position;
  Offset direction;
  Color color;
  double speed;
  double size;
  bool isGrowing;

  Fish({
    required this.color, 
    required this.speed,
    Offset? position,
    double size = 20.0,
  }) : 
    position = position ?? Offset(Random().nextDouble() * 280, Random().nextDouble() * 280),
    direction = Offset(
      Random().nextDouble() * 2 - 1, 
      Random().nextDouble() * 2 - 1
    ),
    size = size,
    isGrowing = true;

  void move(Size containerSize) {
    // Update position based on direction and speed
    position = Offset(
      position.dx + direction.dx * speed,
      position.dy + direction.dy * speed,
    );

    // Bounce off walls
    if (position.dx <= 0 || position.dx >= containerSize.width - size) {
      direction = Offset(-direction.dx, direction.dy);
    }
    if (position.dy <= 0 || position.dy >= containerSize.height - size) {
      direction = Offset(direction.dx, -direction.dy);
    }

    // Ensure fish stays within bounds
    position = Offset(
      position.dx.clamp(0, containerSize.width - size),
      position.dy.clamp(0, containerSize.height - size),
    );
  }

  void changeDirection() {
    direction = Offset(
      Random().nextDouble() * 2 - 1, 
      Random().nextDouble() * 2 - 1
    );
  }

  void updateSize() {
    if (isGrowing) {
      size += 0.5;
      if (size >= 30) {
        isGrowing = false;
      }
    } else {
      size -= 0.5;
      if (size <= 20) {
        isGrowing = false;
      }
    }
  }
}