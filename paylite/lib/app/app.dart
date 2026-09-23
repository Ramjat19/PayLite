import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';
import 'package:paylite/core/widgets/app_lifecycle_observer.dart';
import 'package:paylite/core/widgets/biometric_lock_screen.dart';
import 'package:paylite/core/security/app_lock.dart';

class PayLiteApp extends ConsumerWidget {
  const PayLiteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final isLocked = ref.watch(appLockProvider);

    return AppLifecycleObserver(
      child: MaterialApp.router(
        title: 'PayLite',
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFF1A73E8),
          useMaterial3: true,
        ),
        routerConfig: router,
        builder: (context, child) {
          return Stack(
            children: [
              child ?? const SizedBox.shrink(),
              if (isLocked) const Positioned.fill(child: BiometricLockScreen()),
            ],
          );
        },
      ),
    );
  }
}   