import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'fish.dart';
import 'db_helper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Virtual Aquarium',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AquariumPage(),
    );
  }
}

class AquariumPage extends StatefulWidget {
  const AquariumPage({Key? key}) : super(key: key);

  @override
  _AquariumPageState createState() => _AquariumPageState();
}

class _AquariumPageState extends State<AquariumPage> with TickerProviderStateMixin {
  List<Fish> fishList = [];
  late AnimationController _controller;
  late Timer _timer;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  Color selectedColor = Colors.blue;
  double selectedSpeed = 2.0;
  bool collisionEnabled = true;
  
  final Size aquariumSize = const Size(300, 300);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
    
    // Load settings from database
    _loadSettings();
    
    // Start animation timer
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      _updateFishPositions();
    });
  }

  Future<void> _loadSettings() async {
    final settings = await _dbHelper.loadSettings();
    if (settings != null) {
      setState(() {
        selectedSpeed = settings['speed'];
        selectedColor = Color(settings['color']);
        collisionEnabled = settings['collisionEnabled'] == 1;
        
        // Add fish based on saved count
        int fishCount = settings['fishCount'];
        fishList.clear();
        for (int i = 0; i < fishCount; i++) {
          _addFish();
        }
      });
    }
  }

  void _updateFishPositions() {
    if (!mounted) return;
    
    setState(() {
      // Move each fish
      for (var fish in fishList) {
        fish.move(aquariumSize);
        if (fish.isGrowing) {
          fish.updateSize();
        }
      }
      
      // Check for collisions if enabled
      if (collisionEnabled) {
        for (int i = 0; i < fishList.length; i++) {
          for (int j = i + 1; j < fishList.length; j++) {
            _checkForCollision(fishList[i], fishList[j]);
          }
        }
      }
    });
  }

  void _checkForCollision(Fish fish1, Fish fish2) {
    if ((fish1.position.dx - fish2.position.dx).abs() < fish1.size &&
        (fish1.position.dy - fish2.position.dy).abs() < fish1.size) {
      // Collision detected, change direction and color
      fish1.changeDirection();
      fish2.changeDirection();
      
      // Random color change on collision
      setState(() {
        fish1.color = Color.fromARGB(
          255,
          Random().nextInt(256),
          Random().nextInt(256),
          Random().nextInt(256),
        );
      });
    }
  }

  void _addFish() {
    if (fishList.length < 10) {
      setState(() {
        Fish newFish = Fish(
          color: selectedColor,
          speed: selectedSpeed,
        );
        newFish.isGrowing = true; // Start the growing animation
        fishList.add(newFish);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum of 10 fish reached!')),
      );
    }
  }

  Future<void> _saveSettings() async {
    await _dbHelper.saveSettings(
      fishList.length,
      selectedSpeed,
      selectedColor.value,
      collisionEnabled,
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved!')),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Virtual Aquarium'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Aquarium container
            Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: Colors.lightBlue.shade100,
                border: Border.all(color: Colors.blue, width: 2),
              ),
              child: Stack(
                children: [
                  for (var fish in fishList)
                    Positioned(
                      left: fish.position.dx,
                      top: fish.position.dy,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: fish.size,
                        height: fish.size,
                        decoration: BoxDecoration(
                          color: fish.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _addFish,
                  child: const Text('Add Fish'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: _saveSettings,
                  child: const Text('Save Settings'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            
            // Speed Slider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text('Speed: '),
                  Expanded(
                    child: Slider(
                      value: selectedSpeed,
                      min: 0.5,
                      max: 5.0,
                      divisions: 9,
                      label: selectedSpeed.toStringAsFixed(1),
                      onChanged: (value) {
                        setState(() {
                          selectedSpeed = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            // Color Selection
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text('Color: '),
                  const SizedBox(width: 10),
                  for (var color in [Colors.blue, Colors.red, Colors.green, Colors.yellow, Colors.purple])
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedColor = color;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.all(5),
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: color == selectedColor
                              ? Border.all(color: Colors.black, width: 2)
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Collision Toggle (Graduate-Level Task)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text('Enable Collisions: '),
                  Switch(
                    value: collisionEnabled,
                    onChanged: (value) {
                      setState(() {
                        collisionEnabled = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}