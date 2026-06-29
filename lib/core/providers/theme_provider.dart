import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../shared/theme/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDark = true;

  bool get isDark => _isDark;

  Future<void> init() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final file = File(p.join(appDir.path, 'LagosStore', 'theme_pref.txt'));
      if (await file.exists()) {
        final content = await file.readAsString();
        _isDark = content.trim() != 'light';
      }
    } catch (_) {
      // Default to dark mode on error
      _isDark = true;
    }
    AppColors.setDark(_isDark);
  }

  Future<void> toggleTheme() async {
    _isDark = !_isDark;
    AppColors.setDark(_isDark);
    notifyListeners();

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dir = Directory(p.join(appDir.path, 'LagosStore'));
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      final file = File(p.join(dir.path, 'theme_pref.txt'));
      await file.writeAsString(_isDark ? 'dark' : 'light');
    } catch (_) {
      // Ignore errors when saving preference
    }
  }
}
