import 'package:flutter_riverpod/flutter_riverpod.dart';

final appLockProvider = NotifierProvider<AppLockNotifier, bool>(
  AppLockNotifier.new,
);

class AppLockNotifier extends Notifier<bool> {
  @override
  bool build() => false; // false = unlocked

  void lock() => state = true;
  void unlock() => state = false;
}   