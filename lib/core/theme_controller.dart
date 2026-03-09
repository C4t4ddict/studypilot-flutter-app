import 'package:flutter/material.dart';

final themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);

void toggleThemeMode() {
  final cur = themeModeNotifier.value;
  if (cur == ThemeMode.dark) {
    themeModeNotifier.value = ThemeMode.light;
  } else {
    themeModeNotifier.value = ThemeMode.dark;
  }
}
