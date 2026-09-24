import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paylite/core/security/biometric_services.dart';
import 'package:paylite/core/security/app_lock.dart';
import 'package:paylite/features/auth/state/session_provider.dart';

class BiometricLockScreen extends ConsumerStatefulWidget {
  const BiometricLockScreen({super.key});

  @override
  ConsumerState<BiometricLockScreen> createState() =>
      _BiometricLockScreenState();
}

class _BiometricLockScreenState extends ConsumerState<BiometricLockScreen> {
  final _bio = BiometricService();
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _unlock();
  }

  Future<void> _unlock() async {
    setState(() => _checking = true);
    final supported = await _bio.isDeviceSupported();
    if (!supported) {
      // No biometrics on device → unlock directly
      ref.read(appLockProvider.notifier).unlock();
      return;
    }
    final success = await _bio.authenticate(
      reason: 'Unlock PayLite',
      localizedReason: 'Confirm your identity to continue',
    );
    if (success) {
      ref.read(appLockProvider.notifier).unlock();
    } else {
      // Stay locked, user can retry or log out
      if (mounted) setState(() => _checking = false);
    }
  }

  void _logout() {
    ref.read(sessionProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: Colors.grey[600]),
              const SizedBox(height: 16),
              const Text('PayLite is Locked',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(
                _checking
                    ? 'Verifying…'
                    : 'Use fingerprint or device PIN to unlock',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _unlock,
                child: _checking
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Unlock'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _logout,
                child: const Text('Log out instead'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}   