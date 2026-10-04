import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/haptic_feedback_util.dart';
import '../../../providers/finance_providers.dart';

enum AuthStep {
  phoneInput,
  otpVerification,
  nameInput,
  welcome,
}

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  AuthStep _currentStep = AuthStep.phoneInput;
  bool _isLoading = false;
  String? _errorMessage;

  // Step 1: Phone
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();

  // Step 2: OTP (4 digits)
  final List<TextEditingController> _otpControllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(4, (_) => FocusNode());
  Timer? _timer;
  int _secondsRemaining = 102; // 01:42
  String? _receivedDevOtp; // Test code shown for instant testing

  // Step 3: Name (Registration only)
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();

  // State info
  String _rawPhoneNumber = '';
  String _userName = '';
  final String _selectedLanguage = 'UZ';

  @override
  void initState() {
    super.initState();
    _phoneFocusNode.addListener(_onFocusOrTextChanged);
    _nameFocusNode.addListener(_onFocusOrTextChanged);
    for (final fn in _otpFocusNodes) {
      fn.addListener(_onFocusOrTextChanged);
    }
    _phoneController.addListener(_onFocusOrTextChanged);
    _nameController.addListener(_onFocusOrTextChanged);
  }

  void _onFocusOrTextChanged() {
    if (mounted) {
      if (_errorMessage != null) {
        _errorMessage = null;
      }
      setState(() {});
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phoneFocusNode.removeListener(_onFocusOrTextChanged);
    _nameFocusNode.removeListener(_onFocusOrTextChanged);
    for (final fn in _otpFocusNodes) {
      fn.removeListener(_onFocusOrTextChanged);
      fn.dispose();
    }
    _phoneController.removeListener(_onFocusOrTextChanged);
    _nameController.removeListener(_onFocusOrTextChanged);
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = 102; // 01:42 as in design mockup
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  String _formatTimer(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String get _maskedPhone {
    final digits = _rawPhoneNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 9) {
      final last2 = digits.substring(digits.length - 2);
      return '+998 ** *** ** $last2';
    }
    return '+998 ** *** ** 12';
  }

  String get _cleanFullPhone {
    final raw = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (raw.length == 9) {
      return '+998$raw';
    }
    if (raw.length == 12 && raw.startsWith('998')) {
      return '+$raw';
    }
    return '+998$raw';
  }

  // -------------------------------------------------------------
  // STEP 1: SEND OTP
  // -------------------------------------------------------------
  Future<void> _handleSendOtp() async {
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 9) {
      setState(() {
        _errorMessage = 'Iltimos, telefon raqamingizni to\'liq kiriting (9 ta raqam)';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    HapticUtil.medium();

    try {
      final fullPhone = _cleanFullPhone;
      _rawPhoneNumber = fullPhone;
      final repo = ref.read(financeRepositoryProvider);
      final res = await repo.sendOtp(fullPhone);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _receivedDevOtp = res['otp']?.toString();
          _currentStep = AuthStep.otpVerification;
        });
        _startTimer();
        // Clear previous OTP inputs
        for (final c in _otpControllers) {
          c.clear();
        }
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _otpFocusNodes[0].requestFocus();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('ApiException: ', '');
        });
      }
    }
  }

  // -------------------------------------------------------------
  // STEP 2: VERIFY OTP
  // -------------------------------------------------------------
  Future<void> _handleVerifyOtp() async {
    final enteredOtp = _otpControllers.map((c) => c.text.trim()).join();
    if (enteredOtp.length != 4) {
      setState(() {
        _errorMessage = 'Iltimos, 4 xonali tasdiqlash kodini to\'liq kiriting';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    HapticUtil.medium();

    try {
      final repo = ref.read(financeRepositoryProvider);
      final res = await repo.verifyOtp(_rawPhoneNumber, enteredOtp);

      if (!mounted) return;

      final isNewUser = res['isNewUser'] == true;

      if (isNewUser) {
        // Unregistered phone -> Ask for name in Step 3!
        setState(() {
          _isLoading = false;
          _currentStep = AuthStep.nameInput;
        });
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _nameFocusNode.requestFocus();
        });
      } else {
        // Already registered -> User logged in immediately!
        final user = res['user'] as Map<String, dynamic>?;
        _userName = user?['fullName']?.toString() ??
            repo.currentUserName ??
            'Foydalanuvchi';

        await repo.storage.setHasSeenOnboarding(true);

        setState(() {
          _isLoading = false;
          _currentStep = AuthStep.welcome;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('ApiException: ', '');
        });
      }
    }
  }

  // -------------------------------------------------------------
  // STEP 3: COMPLETE REGISTRATION (NAME)
  // -------------------------------------------------------------
  Future<void> _handleCompleteRegistration() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _errorMessage = 'Iltimos, ismingizni kiriting';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    HapticUtil.medium();

    try {
      final repo = ref.read(financeRepositoryProvider);
      await repo.completeRegistration(_rawPhoneNumber, name);
      await repo.storage.setHasSeenOnboarding(true);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _userName = name;
          _currentStep = AuthStep.welcome;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('ApiException: ', '');
        });
      }
    }
  }

  void _navigateToDashboard() {
    HapticUtil.light();
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        inputDecorationTheme: const InputDecorationTheme(
          filled: false,
          fillColor: Colors.transparent,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            transitionBuilder: (child, animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: _buildCurrentStep(),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case AuthStep.phoneInput:
        return _buildPhoneInputStep();
      case AuthStep.otpVerification:
        return _buildOtpVerificationStep();
      case AuthStep.nameInput:
        return _buildNameInputStep();
      case AuthStep.welcome:
        return _buildWelcomeStep();
    }
  }

  // =============================================================
  // SCREEN 1: PHONE INPUT
  // =============================================================
  Widget _buildPhoneInputStep() {
    return SingleChildScrollView(
      key: const ValueKey('step_phone'),
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: AppDimensions.space12),

          // Header: Logo & Language Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF007A55),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'QarzDaftr',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF007A55),
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),

              // Language Selector Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.language_rounded,
                      size: 16,
                      color: Color(0xFF4A5568),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _selectedLanguage,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: Color(0xFF718096),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Illustration: Wallet inside Mint Green Circle
          Center(
            child: Container(
              width: 140,
              height: 140,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Decorative dots
                  Positioned(
                    top: 24,
                    right: 28,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF81C784),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 28,
                    left: 24,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFA5D6A7),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // Wallet Graphic
                  Container(
                    width: 74,
                    height: 58,
                    decoration: BoxDecoration(
                      color: const Color(0xFF007A55),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF007A55).withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 10,
                          left: 12,
                          right: 12,
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E8B57).withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                        // Mini '+' badge
                        Positioned(
                          bottom: 6,
                          right: 8,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.add_rounded,
                                size: 16,
                                color: Color(0xFF007A55),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Title & Subtitle
          const Text(
            'Xush kelibsiz 👋',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A202C),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Telefon raqamingizni kiriting,\ndavom etamiz.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Color(0xFF718096),
              height: 1.4,
            ),
          ),

          const SizedBox(height: 32),

          // Phone Input Section
          Align(
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                const Icon(
                  Icons.phone_iphone_rounded,
                  size: 16,
                  color: Color(0xFF007A55),
                ),
                const SizedBox(width: 6),
                Text(
                  'Telefon raqamingiz',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Phone Field Box
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _errorMessage != null
                    ? AppColors.error
                    : (_phoneFocusNode.hasFocus
                        ? const Color(0xFF007A55)
                        : const Color(0xFFE2E8F0)),
                width: _phoneFocusNode.hasFocus || _errorMessage != null ? 2.0 : 1.5,
              ),
              boxShadow: _phoneFocusNode.hasFocus
                  ? [
                      BoxShadow(
                        color: const Color(0xFF007A55).withValues(alpha: 0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Flag and Prefix (Clean and seamless with wrapper)
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🇺🇿', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 8),
                    Text(
                      '+998',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 14),
                Container(
                  width: 1.5,
                  height: 24,
                  color: const Color(0xFFE2E8F0),
                ),
                const SizedBox(width: 14),

                // Number textfield (100% transparent, matching wrapper color & height)
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    focusNode: _phoneFocusNode,
                    keyboardType: TextInputType.phone,
                    textAlignVertical: TextAlignVertical.center,
                    cursorColor: const Color(0xFF007A55),
                    inputFormatters: [
                      _UzbekPhoneFormatter(),
                    ],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A202C),
                      letterSpacing: 1.2,
                    ),
                    decoration: const InputDecoration(
                      filled: false,
                      fillColor: Colors.transparent,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      hintText: '90 123 45 67',
                      hintStyle: TextStyle(
                        color: Color(0xFFA0AEC0),
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 1.0,
                      ),
                      isDense: false,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    onSubmitted: (_) => _handleSendOtp(),
                  ),
                ),

                // Clear button
                if (_phoneController.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _phoneController.clear();
                      setState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEDF2F7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: Color(0xFF718096),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Primary Button: "Davom etish ->"
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSendOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007A55),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                disabledBackgroundColor: const Color(0xFF007A55).withValues(alpha: 0.6),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Davom etish',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 28),

          // Divider with "Yoki"
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  color: const Color(0xFFEDF2F7),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Yoki',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFFA0AEC0),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  color: const Color(0xFFEDF2F7),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Footer Terms & Privacy
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: RichText(
              textAlign: TextAlign.center,
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF718096),
                  height: 1.5,
                ),
                children: [
                  TextSpan(text: 'Davom etish orqali siz\n'),
                  TextSpan(
                    text: 'Maxfiylik siyosati',
                    style: TextStyle(
                      color: Color(0xFF007A55),
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  TextSpan(text: ' va '),
                  TextSpan(
                    text: 'Foydalanish shartlari',
                    style: TextStyle(
                      color: Color(0xFF007A55),
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  TextSpan(text: ' bilan rozilik bildirasiz.'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // =============================================================
  // SCREEN 2: 4-DIGIT OTP VERIFICATION
  // =============================================================
  Widget _buildOtpVerificationStep() {
    return SingleChildScrollView(
      key: const ValueKey('step_otp'),
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: AppDimensions.space12),

          // Top Header: Back Arrow & Title
          Row(
            children: [
              IconButton(
                onPressed: () {
                  HapticUtil.selection();
                  setState(() {
                    _currentStep = AuthStep.phoneInput;
                    _errorMessage = null;
                  });
                },
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: Color(0xFF1A202C),
                ),
              ),
              const Expanded(
                child: Text(
                  'Tasdiqlash kodi',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A202C),
                  ),
                ),
              ),
              const SizedBox(width: 48), // Balancing back button
            ],
          ),

          const SizedBox(height: 28),

          // Illustration: Shield with Checkmark inside Mint Circle
          Center(
            child: Container(
              width: 140,
              height: 140,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Decorative dots
                  Positioned(
                    top: 22,
                    right: 32,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF81C784),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 26,
                    left: 28,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFA5D6A7),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // Shield Graphic
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: const Color(0xFF007A55),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF007A55).withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 38,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Title & Subtitle with masked phone
          const Text(
            'Tasdiqlash kodi',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A202C),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$_maskedPhone raqamiga\n4 xonali kod yuborildi.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Color(0xFF718096),
              height: 1.4,
            ),
          ),

          const SizedBox(height: 32),

          // 4-Digit OTP Boxes
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              final isFocused = _otpFocusNodes[index].hasFocus;
              final hasValue = _otpControllers[index].text.isNotEmpty;

              return Focus(
                onKeyEvent: (node, event) {
                  if (event is KeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.backspace) {
                    if (_otpControllers[index].text.isEmpty && index > 0) {
                      _otpControllers[index - 1].clear();
                      _otpFocusNodes[index - 1].requestFocus();
                      setState(() {});
                      return KeyEventResult.handled;
                    }
                  }
                  return KeyEventResult.ignored;
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 60,
                  height: 62,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: hasValue ? const Color(0xFFF0FDF4) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isFocused
                          ? const Color(0xFF007A55)
                          : (hasValue
                              ? const Color(0xFF007A55).withValues(alpha: 0.45)
                              : const Color(0xFFE2E8F0)),
                      width: isFocused ? 2.2 : 1.5,
                    ),
                    boxShadow: isFocused
                        ? [
                            BoxShadow(
                              color: const Color(0xFF007A55).withValues(alpha: 0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : (hasValue
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF007A55).withValues(alpha: 0.05),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : []),
                  ),
                  child: Center(
                    child: TextField(
                      controller: _otpControllers[index],
                      focusNode: _otpFocusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      textAlignVertical: TextAlignVertical.center,
                      cursorColor: const Color(0xFF007A55),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF007A55),
                      ),
                      maxLength: 4,
                      decoration: const InputDecoration(
                        filled: false,
                        fillColor: Colors.transparent,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        counterText: '',
                      ),
                      onChanged: (value) {
                        final digits = value.replaceAll(RegExp(r'\D'), '');
                        if (digits.length >= 4) {
                          for (int i = 0; i < 4; i++) {
                            _otpControllers[i].text = digits[i];
                          }
                          _otpFocusNodes[3].unfocus();
                          setState(() {});
                          _handleVerifyOtp();
                          return;
                        }

                        if (value.isNotEmpty) {
                          if (value.length > 1) {
                            _otpControllers[index].text = value.substring(value.length - 1);
                          }
                          if (index < 3) {
                            _otpFocusNodes[index + 1].requestFocus();
                          } else {
                            _otpFocusNodes[index].unfocus();
                            _handleVerifyOtp();
                          }
                        }
                        setState(() {});
                      },
                    ),
                  ),
                ),
              );
            }),
          ),

          // Helper Dev OTP autofill banner
          if (_receivedDevOtp != null) ...[
            const SizedBox(height: 16),
            InkWell(
              onTap: () {
                HapticUtil.light();
                final code = _receivedDevOtp!;
                for (int i = 0; i < 4 && i < code.length; i++) {
                  _otpControllers[i].text = code[i];
                }
                setState(() {});
                _handleVerifyOtp();
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFC8E6C9)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.flash_on_rounded, size: 16, color: Color(0xFF007A55)),
                    const SizedBox(width: 6),
                    Text(
                      'Test kodi: $_receivedDevOtp (bosing va tasdiqlang)',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF007A55),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Timer & Resend Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 16,
                color: Color(0xFF007A55),
              ),
              const SizedBox(width: 6),
              Text(
                _formatTimer(_secondsRemaining),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF007A55),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 1,
                height: 14,
                color: const Color(0xFFCBD5E0),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _secondsRemaining == 0
                    ? () {
                        HapticUtil.selection();
                        _handleSendOtp();
                      }
                    : null,
                child: Text(
                  'Kodni qayta yuborish',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _secondsRemaining == 0
                        ? const Color(0xFF007A55)
                        : const Color(0xFFA0AEC0),
                    decoration: _secondsRemaining == 0
                        ? TextDecoration.underline
                        : TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Primary Button: "Tasdiqlash ->"
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleVerifyOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007A55),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Tasdiqlash',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 12),

          // Secondary Button: "<- Orqaga"
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () {
                HapticUtil.selection();
                setState(() {
                  _currentStep = AuthStep.phoneInput;
                  _errorMessage = null;
                });
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                backgroundColor: const Color(0xFFF7FAFC),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.arrow_back_rounded,
                    size: 18,
                    color: Color(0xFF4A5568),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Orqaga',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A5568),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // =============================================================
  // SCREEN 3: NAME INPUT (NEW USERS ONLY)
  // =============================================================
  Widget _buildNameInputStep() {
    return SingleChildScrollView(
      key: const ValueKey('step_name'),
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: AppDimensions.space12),

          // Top Header: Back Arrow & Title
          Row(
            children: [
              IconButton(
                onPressed: () {
                  HapticUtil.selection();
                  setState(() {
                    _currentStep = AuthStep.otpVerification;
                    _errorMessage = null;
                  });
                },
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: Color(0xFF1A202C),
                ),
              ),
              const Expanded(
                child: Text(
                  'Yangi foydalanuvchi',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A202C),
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),

          const SizedBox(height: 32),

          // Illustration: Avatar with '+' badge inside Mint Circle
          Center(
            child: Container(
              width: 140,
              height: 140,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Decorative dots
                  Positioned(
                    top: 24,
                    right: 28,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF81C784),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 24,
                    left: 28,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFA5D6A7),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // User Avatar Graphic
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFF007A55),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF007A55).withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 42,
                    ),
                  ),
                  // '+' badge on bottom-right of avatar
                  Positioned(
                    bottom: 34,
                    right: 34,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E8B57),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.add_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Title & Subtitle
          const Text(
            'Ismingiz nima?',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A202C),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Profilingizni yaratish uchun\nismingizni kiriting.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Color(0xFF718096),
              height: 1.4,
            ),
          ),

          const SizedBox(height: 32),

          // Input Label
          Align(
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                const Icon(
                  Icons.person_rounded,
                  size: 16,
                  color: Color(0xFF007A55),
                ),
                const SizedBox(width: 6),
                Text(
                  'Ism familiyangiz',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Name Input Field
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _errorMessage != null
                    ? AppColors.error
                    : (_nameFocusNode.hasFocus
                        ? const Color(0xFF007A55)
                        : const Color(0xFFE2E8F0)),
                width: _nameFocusNode.hasFocus || _errorMessage != null ? 2.0 : 1.5,
              ),
              boxShadow: _nameFocusNode.hasFocus
                  ? [
                      BoxShadow(
                        color: const Color(0xFF007A55).withValues(alpha: 0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.badge_outlined,
                  color: Color(0xFF007A55),
                  size: 22,
                ),
                const SizedBox(width: 14),
                Container(
                  width: 1.5,
                  height: 24,
                  color: const Color(0xFFE2E8F0),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    focusNode: _nameFocusNode,
                    textCapitalization: TextCapitalization.words,
                    textAlignVertical: TextAlignVertical.center,
                    cursorColor: const Color(0xFF007A55),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A202C),
                    ),
                    decoration: const InputDecoration(
                      filled: false,
                      fillColor: Colors.transparent,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      hintText: 'Masalan: Baxtiyor',
                      hintStyle: TextStyle(
                        color: Color(0xFFA0AEC0),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                      isDense: false,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    onSubmitted: (_) => _handleCompleteRegistration(),
                  ),
                ),
                if (_nameController.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _nameController.clear();
                      setState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEDF2F7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: Color(0xFF718096),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],

          const SizedBox(height: 32),

          // Primary Button: "Davom etish ->"
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleCompleteRegistration,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007A55),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Davom etish',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // =============================================================
  // SCREEN 4: WELCOME SCREEN
  // =============================================================
  Widget _buildWelcomeStep() {
    final displayName = _userName.trim().isNotEmpty ? _userName.trim() : 'Foydalanuvchi';

    return SingleChildScrollView(
      key: const ValueKey('step_welcome'),
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: AppDimensions.space12),

          // Header: Logo & Notification Bell
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF007A55),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'QarzDaftr',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF007A55),
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),

              // Bell icon
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Color(0xFF2D3748),
                  size: 24,
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Illustration: Financial Balance Card with Graph & Checkmark
          Center(
            child: SizedBox(
              width: 240,
              height: 150,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Soft background glow
                  Container(
                    width: 180,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),

                  // Decorative floating sparkles
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Transform.rotate(
                      angle: -0.3,
                      child: Container(
                        width: 14,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFF007A55),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 20,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFD54F),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                  // The Main Balance Card
                  Positioned(
                    child: Transform.rotate(
                      angle: -0.04,
                      child: Container(
                        width: 210,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                          border: Border.all(color: const Color(0xFFEDF2F7)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Jami balans',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF718096),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '2 450 000 so\'m',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A202C),
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Mini green progress bar
                            Container(
                              height: 6,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFF007A55),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Floating check badge top-right
                  Positioned(
                    top: 2,
                    right: 8,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFF007A55),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.check_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  // Floating chart icon on right
                  Positioned(
                    bottom: 24,
                    right: 22,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(width: 4, height: 12, color: const Color(0xFF007A55)),
                        const SizedBox(width: 2),
                        Container(width: 4, height: 20, color: const Color(0xFF007A55)),
                        const SizedBox(width: 2),
                        Container(width: 4, height: 26, color: const Color(0xFF007A55)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Title: "Xush kelibsiz, [Ism]! 👋"
          Text(
            'Xush kelibsiz,\n$displayName! 👋',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A202C),
              letterSpacing: -0.5,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Endi siz o\'z moliyangizni boshqarishingiz\nmumkin. Keling, boshlaymiz!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF718096),
              height: 1.4,
            ),
          ),

          const SizedBox(height: 32),

          // 3 Feature Badges in Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildFeatureBadge(
                icon: Icons.shield_outlined,
                title: 'Xavfsiz',
              ),
              _buildFeatureBadge(
                icon: Icons.bolt_rounded,
                title: 'Tezkor',
              ),
              _buildFeatureBadge(
                icon: Icons.bar_chart_rounded,
                title: 'Qulay',
              ),
            ],
          ),

          const SizedBox(height: 36),

          // Primary Button: "Boshlash ->"
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _navigateToDashboard,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007A55),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Boshlash',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Secondary link: "Bosh sahifaga o'tish >"
          TextButton(
            onPressed: _navigateToDashboard,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Bosh sahifaga o\'tish',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4A5568),
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: Color(0xFF718096),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFeatureBadge({required IconData icon, required String title}) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDF2F7)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 22,
            color: const Color(0xFF007A55),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
        ],
      ),
    );
  }
}

/// Formatter for Uzbek phone number formatting e.g. 90 123 45 67
class _UzbekPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 1. Strip all non-digit characters
    String digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    // 2. Intelligently remove 998 prefix if pasted
    if (digits.startsWith('998') && digits.length > 9) {
      digits = digits.substring(3);
    }

    // 3. Limit to max 9 digits
    if (digits.length > 9) {
      digits = digits.substring(0, 9);
    }

    // 4. Format into 'XX XXX XX XX'
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 2 || i == 5 || i == 7) {
        buffer.write(' ');
      }
      buffer.write(digits[i]);
    }

    final formatted = buffer.toString();

    // 5. Smart cursor position calculation
    int cursorPosition = formatted.length;
    if (newValue.selection.end < newValue.text.length) {
      int digitsBeforeCursor = 0;
      for (int i = 0; i < newValue.selection.end && i < newValue.text.length; i++) {
        if (RegExp(r'\d').hasMatch(newValue.text[i])) {
          digitsBeforeCursor++;
        }
      }
      if (newValue.text.startsWith('+998') ||
          (digits.startsWith('998') && newValue.text.contains('998'))) {
        digitsBeforeCursor = (digitsBeforeCursor - 3).clamp(0, 9);
      }

      int pos = 0;
      int countedDigits = 0;
      while (pos < formatted.length && countedDigits < digitsBeforeCursor) {
        if (RegExp(r'\d').hasMatch(formatted[pos])) {
          countedDigits++;
        }
        pos++;
      }
      cursorPosition = pos.clamp(0, formatted.length);
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }
}
