import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/trade_provider.dart';
import '../utils/app_strings.dart';

class SecurityLockScreen extends StatefulWidget {
  const SecurityLockScreen({super.key});

  @override
  State<SecurityLockScreen> createState() => _SecurityLockScreenState();
}

class _SecurityLockScreenState extends State<SecurityLockScreen> {
  final LocalAuthentication _auth = LocalAuthentication();
  String _enteredPin = '';
  bool _hasError = false;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBiometric();
    });
  }

  Future<void> _checkBiometric() async {
    final provider = context.read<TradeProvider>();
    if (!provider.settings.isBiometricEnabled) return;

    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      if ((canCheck || isDeviceSupported) && mounted) {
        _authenticateBiometric();
      }
    } catch (_) {}
  }

  Future<void> _authenticateBiometric() async {
    if (_isAuthenticating) return;
    setState(() => _isAuthenticating = true);

    final lang = context.read<TradeProvider>().settings.languageCode;
    try {
      final didAuthenticate = await _auth.authenticate(
        localizedReason: AppStrings.tr('biometric_prompt', lang),
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );

      if (didAuthenticate && mounted) {
        context.read<TradeProvider>().unlockApp();
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isAuthenticating = false);
      }
    }
  }

  void _onKeyPress(String val) {
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
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _hasError = false;
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  void _verifyPin() {
    if (context.read<TradeProvider>().verifyPin(_enteredPin)) {
      HapticFeedback.lightImpact();
      context.read<TradeProvider>().unlockApp();
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _hasError = true;
      });
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
              Text(
                AppStrings.tr('enter_pin_to_unlock', lang),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.darkMuted,
                ),
              ),
              const SizedBox(height: 28),

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
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        _onKeyPress(val);
      },
      borderRadius: BorderRadius.circular(32),
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
    );
  }

  Widget _buildSpecialKey({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(32),
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
    );
  }
}
