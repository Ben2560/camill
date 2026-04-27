import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/biometric_service.dart';

class BiometricLockOverlay extends StatefulWidget {
  const BiometricLockOverlay({super.key, required this.onUnlocked});

  final VoidCallback onUnlocked;

  @override
  State<BiometricLockOverlay> createState() => _BiometricLockOverlayState();
}

class _BiometricLockOverlayState extends State<BiometricLockOverlay> {
  final _service = BiometricService();
  bool _authenticating = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
  }

  Future<void> _authenticate() async {
    if (_authenticating) return;
    setState(() {
      _authenticating = true;
      _failed = false;
    });
    final success = await _service.authenticate();
    if (!mounted) return;
    if (success) {
      widget.onUnlocked();
    } else {
      setState(() {
        _authenticating = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF2D5A27);
    const accent = Color(0xFF6AA864);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'camill',
                style: GoogleFonts.outfit(
                  fontSize: 56,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -2.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '家計を、もっとシンプルに',
                style: GoogleFonts.zenMaruGothic(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 64),
              _authenticating
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Column(
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 52,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                        const SizedBox(height: 24),
                        if (_failed)
                          Text(
                            '認証に失敗しました',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 14,
                            ),
                          ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _authenticate,
                          icon: const Icon(Icons.fingerprint, size: 22),
                          label: const Text(
                            '生体認証でロック解除',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
