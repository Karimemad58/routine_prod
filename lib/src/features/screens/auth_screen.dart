import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/config.dart';
import '../../core/theme.dart';
import '../app_state.dart';
import '../widgets/common.dart';

enum _AuthMode { signIn, signUp }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  _AuthMode _mode = _AuthMode.signIn;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  static final _emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  String? _validate(String email, String password) {
    if (email.isEmpty) return 'Enter your email.';
    if (!_emailRegex.hasMatch(email)) return 'That email looks invalid.';
    if (password.length < 6) return 'Password must be at least 6 characters.';
    return null;
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;
    final validation = _validate(email, password);
    if (validation != null) {
      setState(() => _error = validation);
      return;
    }

    TextInput.finishAutofillContext();

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final state = context.read<AppState>();
      if (_mode == _AuthMode.signIn) {
        await state.signIn(email, password);
      } else {
        await state.signUp(
          email: email,
          password: password,
          name: _name.text.trim(),
        );
        if (!state.isSignedIn) {
          // Email confirmation may be on; sign in directly so the user
          // never has to leave the app.
          try {
            await state.signIn(email, password);
          } catch (_) {
            // Fall through — handled below.
          }
        }
      }
      if (!mounted) return;
      if (!state.isSignedIn) {
        setState(() {
          _error =
              'Account created. Disable email confirmation in Supabase → Auth → Providers, then sign in.';
          _mode = _AuthMode.signIn;
        });
      }
    } catch (e) {
      setState(() => _error = _humanize(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _humanize(Object e) {
    final msg = e.toString();
    if (msg.contains('Invalid login')) return 'Wrong email or password.';
    if (msg.contains('User already registered')) return 'Account already exists. Try signing in.';
    if (msg.contains('not configured')) {
      return 'Supabase is not configured. You can still preview the app as a guest.';
    }
    return msg.replaceFirst('Exception: ', '');
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Stack(
        children: [
          const _AuroraBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE0E8F5), Color(0xFFF0E8F5)],
                          ),
                          boxShadow: AppTheme.microShadow,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.spa_outlined,
                          color: AppTheme.charcoal,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Routine',
                        style: TextStyle(
                          color: AppTheme.charcoal,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),
                  Text(
                    _mode == _AuthMode.signIn
                        ? 'Welcome back.'
                        : 'Begin your\ndaily ritual.',
                    style: const TextStyle(
                      color: AppTheme.charcoal,
                      fontSize: 36,
                      height: 1.05,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _mode == _AuthMode.signIn
                        ? 'Sign in to sync your routine and AI insights.'
                        : 'Create an account to track skin progress over time.',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: AutofillGroup(
                      child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SegmentedToggle(
                          selected: _mode,
                          onChanged: (m) => setState(() {
                            _mode = m;
                            _error = null;
                          }),
                        ),
                        const SizedBox(height: 18),
                        if (_mode == _AuthMode.signUp) ...[
                          _AuthField(
                            controller: _name,
                            icon: Icons.person_outline,
                            hint: 'Your name',
                            autofillHints: const [AutofillHints.name],
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 12),
                        ],
                        _AuthField(
                          controller: _email,
                          icon: Icons.alternate_email_outlined,
                          hint: 'Email address',
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email, AutofillHints.username],
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                        _AuthField(
                          controller: _password,
                          icon: Icons.lock_outline,
                          hint: 'Password',
                          obscure: true,
                          autofillHints: _mode == _AuthMode.signUp
                              ? const [AutofillHints.newPassword]
                              : const [AutofillHints.password],
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.peach.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: AppTheme.charcoal,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: const TextStyle(
                                      color: AppTheme.charcoal,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        PillButton(
                          label: _busy
                              ? 'Please wait…'
                              : (_mode == _AuthMode.signIn
                                  ? 'Sign in'
                                  : 'Create account'),
                          icon: _busy ? null : Icons.arrow_forward,
                          onPressed: _busy ? null : _submit,
                        ),
                      ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: TextButton(
                      onPressed: () => state.continueAsGuest(),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      child: const Text(
                        'Continue as guest',
                        style: TextStyle(fontSize: 13, letterSpacing: 0.3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (!AppConfig.hasSupabase)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Supabase is not configured — running in guest mode.',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                            letterSpacing: 0.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuroraBackground extends StatelessWidget {
  const _AuroraBackground();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(color: AppTheme.bg),
              Positioned(
                top: -160,
                left: -120,
                child: _Blob(
                  color: AppTheme.sage.withValues(alpha: 0.85),
                  size: 360,
                ),
              ),
              Positioned(
                top: 40,
                right: -140,
                child: _Blob(
                  color: AppTheme.lavender.withValues(alpha: 0.8),
                  size: 320,
                ),
              ),
              Positioned(
                bottom: -160,
                left: -80,
                child: _Blob(
                  color: AppTheme.peach.withValues(alpha: 0.85),
                  size: 360,
                ),
              ),
              Positioned(
                bottom: -40,
                right: -80,
                child: _Blob(
                  color: AppTheme.blush.withValues(alpha: 0.65),
                  size: 240,
                ),
              ),
              // Soft luminous wash on top so the form stays readable.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.bg.withValues(alpha: 0.0),
                        AppTheme.bg.withValues(alpha: 0.55),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
            stops: const [0.15, 1.0],
          ),
        ),
      ),
    );
  }
}

class _SegmentedToggle extends StatelessWidget {
  const _SegmentedToggle({required this.selected, required this.onChanged});

  final _AuthMode selected;
  final ValueChanged<_AuthMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.bg.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentedItem(
              label: 'Sign in',
              active: selected == _AuthMode.signIn,
              onTap: () => onChanged(_AuthMode.signIn),
            ),
          ),
          Expanded(
            child: _SegmentedItem(
              label: 'Sign up',
              active: selected == _AuthMode.signUp,
              onTap: () => onChanged(_AuthMode.signUp),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentedItem extends StatelessWidget {
  const _SegmentedItem({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppTheme.charcoal : Colors.transparent,
          borderRadius: BorderRadius.circular(40),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : AppTheme.charcoal,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.icon,
    required this.hint,
    this.obscure = false,
    this.keyboardType,
    this.autofillHints,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final IconData icon;
  final String hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              keyboardType: keyboardType,
              autofillHints: autofillHints,
              textInputAction: textInputAction,
              onSubmitted: onSubmitted,
              style: const TextStyle(color: AppTheme.charcoal, fontSize: 14),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
