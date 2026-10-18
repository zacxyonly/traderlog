import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/app_settings.dart';
import '../providers/trade_provider.dart';
import '../utils/app_strings.dart';

class SecurityLockScreen extends StatefulWidget {
  const SecurityLockScreen({super.key});

  @override
  State<SecurityLockScreen> createState() => _SecurityLockScreenState();
}

class _SecurityLockScreenState extends State<SecurityLockScreen> {
  String _enteredPin = '';
  bool _hasError = false;
  final LocalAuthentication _auth = LocalAuthentication();
  bool _isCheckingBio = false;

  int _failedAttempts = 0;
  int _lockoutSecondsLeft = 0;
  Timer? _lockoutTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBiometricOnLaunch();
    });
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkBiometricOnLaunch() async {
    final settings = context.read<TradeProvider>().settings;
    if (settings.isBiometricEnabled && _lockoutSecondsLeft <= 0) {
      await _authenticateBiometric();
    }
  }

  Future<void> _authenticateBiometric() async {
    if (_isCheckingBio || _lockoutSecondsLeft > 0) return;
    _isCheckingBio = true;

    try {
      final canBio = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      if (!canBio || !isDeviceSupported) {
        _isCheckingBio = false;
        return;
      }

      if (!mounted) return;
      final lang = context.read<TradeProvider>().settings.languageCode;
      final localizedReason = lang == 'id'
          ? 'Pindai sidik jari atau wajah untuk membuka TraderLog'
          : 'Scan fingerprint or face to unlock TraderLog';

      final authenticated = await _auth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated && mounted) {
        _failedAttempts = 0;
        _lockoutTimer?.cancel();
        context.read<TradeProvider>().unlockApp();
      }
    } catch (_) {
      // Biometric cancelled or unavailable
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingBio = false;
        });
      }
    }
  }

  void _onKeyPress(String val) {
    if (_lockoutSecondsLeft > 0) return;
    if (_enteredPin.length >= 4) return;

    setState(() {
      _hasError = false;
      _enteredPin += val;
    });

    if (_enteredPin.length == 4) {
      _verifyPin();
    }
  }

  void _onBackspace() {
    if (_lockoutSecondsLeft > 0) return;
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _hasError = false;
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  void _verifyPin() {
    if (_lockoutSecondsLeft > 0) return;
    final expected = context.read<TradeProvider>().settings.pinCode;
    if (AppSettings.verifyPin(_enteredPin, expected)) {
      if (expected != null && expected.length != 64) {
        context.read<TradeProvider>().setPinCode(_enteredPin);
      }
      _failedAttempts = 0;
      _lockoutTimer?.cancel();
      HapticFeedback.lightImpact();
      context.read<TradeProvider>().unlockApp();
    } else {
      HapticFeedback.heavyImpact();
      _failedAttempts++;
      setState(() {
        _hasError = true;
      });

      if (_failedAttempts >= 5) {
        _startLockout();
      }

      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) {
          setState(() {
            _enteredPin = '';
            _hasError = false;
          });
        }
      });
    }
  }

  void _startLockout() {
    _lockoutTimer?.cancel();
    setState(() {
      _lockoutSecondsLeft = 30;
      _enteredPin = '';
    });
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_lockoutSecondsLeft <= 1) {
        timer.cancel();
        setState(() {
          _lockoutSecondsLeft = 0;
          _failedAttempts = 0;
        });
      } else {
        setState(() {
          _lockoutSecondsLeft--;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<TradeProvider>().settings.languageCode;
    final isBiometricOn = context.watch<TradeProvider>().settings.isBiometricEnabled;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A111C),
        body: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              // App Icon / Logo
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5),
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  size: 34,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'TraderLog',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              if (_lockoutSecondsLeft > 0)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.lose.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.lose.withOpacity(0.4)),
                  ),
                  child: Text(
                    lang == 'id'
                        ? 'Terlalu banyak percobaan salah.\nCoba lagi dalam $_lockoutSecondsLeft detik.'
                        : 'Too many incorrect attempts.\nTry again in $_lockoutSecondsLeft seconds.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.loseText,
                    ),
                  ),
                )
              else
                Text(
                  AppStrings.tr('enter_pin_to_unlock', lang),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.darkMuted,
                  ),
                ),
              const SizedBox(height: 24),

              // PIN Indicator Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final isFilled = i < _enteredPin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _hasError
                          ? AppColors.lose
                          : (isFilled ? AppColors.primary : Colors.transparent),
                      border: Border.all(
                        color: _hasError
                            ? AppColors.lose
                            : (isFilled ? AppColors.primary : Colors.white30),
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),
              const Spacer(flex: 3),

              // Keypad (1 - 9, Biometric, 0, Backspace)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    _buildKeypadRow(['1', '2', '3']),
                    const SizedBox(height: 16),
                    _buildKeypadRow(['4', '5', '6']),
                    const SizedBox(height: 16),
                    _buildKeypadRow(['7', '8', '9']),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Biometric Button
                        if (isBiometricOn)
                          _buildSpecialKey(
                            icon: Icons.fingerprint_rounded,
                            onTap: _authenticateBiometric,
                          )
                        else
                          const SizedBox(width: 64, height: 64),
                        // 0 Key
                        _buildNumberKey('0'),
                        // Backspace Key
                        _buildSpecialKey(
                          icon: Icons.backspace_outlined,
                          onTap: _onBackspace,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: keys.map((k) => _buildNumberKey(k)).toList(),
    );
  }

  Widget _buildNumberKey(String val) {
    final isLocked = _lockoutSecondsLeft > 0;
    return InkWell(
      onTap: isLocked
          ? null
          : () {
              HapticFeedback.selectionClick();
              _onKeyPress(val);
            },
      borderRadius: BorderRadius.circular(32),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isLocked ? 0.35 : 1.0,
        child: Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF131D2D),
            border: Border.all(color: const Color(0xFF1F2E45)),
          ),
          alignment: Alignment.center,
          child: Text(
            val,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialKey({required IconData icon, required VoidCallback onTap}) {
    final isLocked = _lockoutSecondsLeft > 0;
    return InkWell(
      onTap: isLocked
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap();
            },
      borderRadius: BorderRadius.circular(32),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isLocked ? 0.35 : 1.0,
        child: Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF131D2D).withOpacity(0.5),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: AppColors.primary, size: 26),
        ),
      ),
    );
  }
}
