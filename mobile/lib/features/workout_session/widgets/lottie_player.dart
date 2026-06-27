import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LottiePlayer extends StatelessWidget {
  final String assetPath;

  const LottiePlayer({required this.assetPath, super.key});

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      'assets/lottie/$assetPath',
      width: 280,
      height: 280,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const Icon(
        Icons.fitness_center,
        size: 120,
        color: Color(0xFF6C63FF),
      ),
    );
  }
}
