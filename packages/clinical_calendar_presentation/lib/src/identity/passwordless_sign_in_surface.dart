import 'dart:async';

import 'package:clinical_calendar_application/clinical_calendar_identity.dart';
import 'package:flutter/material.dart';

final class PasswordlessSignInSurface extends StatefulWidget {
  const PasswordlessSignInSurface({
    required this.identity,
    required this.onSignedIn,
    super.key,
  });

  final PasswordlessIdentityService identity;
  final Future<void> Function(IdentitySession session) onSignedIn;

  @override
  State<PasswordlessSignInSurface> createState() =>
      _PasswordlessSignInSurfaceState();
}

final class _PasswordlessSignInSurfaceState
    extends State<PasswordlessSignInSurface> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;
  String? _error;
  Timer? _resendCooldown;
  bool _canResend = false;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _resendCooldown?.cancel();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_busy || _email.text.trim().isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.identity.sendSignInCode(_email.text);
      if (mounted) {
        setState(() {
          _codeSent = true;
          _canResend = false;
        });
        _startResendCooldown();
      }
    } on IdentityException catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _startResendCooldown() {
    _resendCooldown?.cancel();
    _resendCooldown = Timer(const Duration(seconds: 30), () {
      if (mounted) setState(() => _canResend = true);
    });
  }

  Future<void> _verify() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final session = await widget.identity.verifySignInCode(
        _email.text,
        _code.text,
      );
      await widget.onSignedIn(session);
    } on IdentityException catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.calendar_month_outlined, size: 44),
                    const SizedBox(height: 16),
                    Text(
                      'Clinical Calendar',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sign in with a one-time code sent to your email. '
                      'No password or Google account is required.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      key: const Key('identity-email'),
                      controller: _email,
                      enabled: !_codeSent && !_busy,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Email address',
                      ),
                    ),
                    if (_codeSent) ...[
                      const SizedBox(height: 12),
                      TextField(
                        key: const Key('identity-otp'),
                        controller: _code,
                        enabled: !_busy,
                        keyboardType: TextInputType.number,
                        autofillHints: const [AutofillHints.oneTimeCode],
                        maxLength: 8,
                        decoration: const InputDecoration(
                          labelText: 'One-time code',
                        ),
                      ),
                    ],
                    if (_error case final message?) ...[
                      const SizedBox(height: 8),
                      Text(
                        message,
                        key: const Key('identity-error'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton(
                      key: Key(
                        _codeSent
                            ? 'verify-identity-code'
                            : 'send-identity-code',
                      ),
                      onPressed: _busy
                          ? null
                          : (_codeSent ? _verify : _sendCode),
                      child: Text(
                        _busy
                            ? 'Please wait…'
                            : _codeSent
                            ? 'Verify and sign in'
                            : 'Email me a code',
                      ),
                    ),
                    if (_codeSent)
                      Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          TextButton(
                            key: const Key('resend-identity-code'),
                            onPressed: _busy || !_canResend ? null : _sendCode,
                            child: Text(
                              _canResend
                                  ? 'Resend code'
                                  : 'Resend available in 30 seconds',
                            ),
                          ),
                          TextButton(
                            key: const Key('change-identity-email'),
                            onPressed: _busy
                                ? null
                                : () {
                                    _resendCooldown?.cancel();
                                    setState(() {
                                      _codeSent = false;
                                      _canResend = false;
                                      _code.clear();
                                      _error = null;
                                    });
                                  },
                            child: const Text('Use a different email'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

String _message(IdentityException error) => switch (error.code) {
  'expired_otp' => 'That code expired. Request a new code and try again.',
  'invalid_otp' => 'Enter the numeric code from the email.',
  'rate_limited' => 'Too many requests. Wait a moment before trying again.',
  _ when error.offline => 'A connection is required to sign in on this device.',
  _ => 'Sign-in could not be completed. Try again.',
};
