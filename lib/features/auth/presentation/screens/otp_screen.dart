import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:s2_bazaar/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_router.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../core/services/auth_service.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phone;

  const OtpScreen({super.key, required this.phone});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final List<TextEditingController> _ctrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  int _timerSeconds = 30;
  Timer? _timer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    // Focus first box
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _timerSeconds = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timerSeconds == 0) {
        t.cancel();
      } else {
        setState(() => _timerSeconds--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _ctrls) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  String get _otp => _ctrls.map((c) => c.text).join();

  Future<void> _verify() async {
    final l10n = AppLocalizations.of(context)!;
    if (_otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.enterOtp)),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final ok = await ref.read(authServiceProvider).verifyOtp(
        phone: widget.phone,
        token: _otp,
      );
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.invalidOtp)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  S2IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.text1),
                    onTap: () => context.pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 40, 28, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 88, height: 88,
                      decoration: BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
                      child: Center(
                        child: Container(
                          width: 54, height: 54,
                          decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                          child: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 24),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(l10n.verifyNumber, style: AppTextStyles.h1()),
                    const SizedBox(height: 10),
                    Text(l10n.otpSentTo, style: AppTextStyles.body()),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(widget.phone, style: AppTextStyles.title()),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Text(l10n.edit, style: AppTextStyles.captionBold(color: AppColors.primary)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 36),
                    Row(
                      children: List.generate(6, (i) => _OtpBox(
                        controller: _ctrls[i],
                        focusNode: _focusNodes[i],
                        onChanged: (v) {
                          if (v.isNotEmpty && i < 5) {
                            _focusNodes[i + 1].requestFocus();
                          } else if (v.isEmpty && i > 0) {
                            _focusNodes[i - 1].requestFocus();
                          }
                          setState(() {});
                        },
                      )).expand((w) => [w, if (_ctrls.indexOf((w as _OtpBox).controller) < 5) const SizedBox(width: 10)]).toList(),
                    ),
                    const SizedBox(height: 32),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.timer_outlined, size: 14, color: AppColors.text2),
                          ),
                          const SizedBox(width: 8),
                          Text('${l10n.resendOtpIn} ', style: AppTextStyles.caption()),
                          Text('00:${_timerSeconds.toString().padLeft(2, '0')}',
                            style: AppTextStyles.captionBold(color: AppColors.primary)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: GestureDetector(
                        onTap: _timerSeconds == 0 ? _startTimer : null,
                        child: RichText(
                          text: TextSpan(children: [
                            TextSpan(text: l10n.didntReceiveOtp, style: AppTextStyles.caption()),
                            TextSpan(
                              text: l10n.resend,
                              style: AppTextStyles.captionBold(
                                color: _timerSeconds == 0 ? AppColors.primary : AppColors.text3,
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    PrimaryButton(
                      label: l10n.verifyAndContinue,
                      subtitle: '${_otp.length} digit${_otp.length == 1 ? '' : 's'} entered · ${6 - _otp.length} remaining',
                      onPressed: _otp.length == 6 ? _verify : null,
                      isLoading: _isLoading,
                      trailing: const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                    ),
                  ],
                ),
              ),
            ),
            _NumberPad(
              onDigit: (d) {
                for (int i = 0; i < 6; i++) {
                  if (_ctrls[i].text.isEmpty) {
                    _ctrls[i].text = d;
                    if (i < 5) _focusNodes[i + 1].requestFocus();
                    setState(() {});
                    return;
                  }
                }
              },
              onDelete: () {
                for (int i = 5; i >= 0; i--) {
                  if (_ctrls[i].text.isNotEmpty) {
                    _ctrls[i].text = '';
                    _focusNodes[i].requestFocus();
                    setState(() {});
                    return;
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isFocused = focusNode.hasFocus;
    final hasValue = controller.text.isNotEmpty;

    return Expanded(
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: hasValue ? AppColors.primarySoft : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isFocused || hasValue ? AppColors.primary : AppColors.border,
            width: isFocused || hasValue ? 2 : 1,
          ),
        ),
        child: Center(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: AppTextStyles.h2(color: AppColors.text1),
            onChanged: onChanged,
            showCursor: false,
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
            ),
          ),
        ),
      ),
    );
  }
}

class _NumberPad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;

  const _NumberPad({required this.onDigit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
      child: Column(
        children: [
          Row(children: [
            _PadKey(label: '1', onTap: () => onDigit('1')),
            _PadKey(label: '2', onTap: () => onDigit('2')),
            _PadKey(label: '3', onTap: () => onDigit('3')),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            _PadKey(label: '4', onTap: () => onDigit('4')),
            _PadKey(label: '5', onTap: () => onDigit('5')),
            _PadKey(label: '6', onTap: () => onDigit('6')),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            _PadKey(label: '7', onTap: () => onDigit('7')),
            _PadKey(label: '8', onTap: () => onDigit('8')),
            _PadKey(label: '9', onTap: () => onDigit('9')),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            const Expanded(child: SizedBox()),
            _PadKey(label: '0', onTap: () => onDigit('0')),
            Expanded(
              child: GestureDetector(
                onTap: onDelete,
                child: Container(
                  height: 48,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    boxShadow: AppShadows.soft,
                  ),
                  child: const Icon(Icons.backspace_outlined,
                      size: 20, color: AppColors.text1),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _PadKey extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PadKey({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 48,
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: AppShadows.soft,
          ),
          child: Center(
            child: Text(label, style: AppTextStyles.h3()),
          ),
        ),
      ),
    );
  }
}
