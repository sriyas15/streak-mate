import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

// TODO(you): if wiring flutter_dotenv, do it here before runApp:
//   import 'package:flutter_dotenv/flutter_dotenv.dart';
//   await dotenv.load(fileName: ".env");

void main() {
  runApp(const ProviderScope(child: StreakMateApp()));
}