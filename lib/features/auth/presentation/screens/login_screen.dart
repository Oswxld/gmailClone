import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/repositories/supabase_auth_repository.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    required this.configured,
    required this.onDemo,
    super.key,
  });

  final bool configured;
  final VoidCallback onDemo;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _registering = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !widget.configured ||
        !_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _busy = true);
    try {
      final auth = SupabaseAuthRepository(Supabase.instance.client);
      if (_registering) {
        final signedIn = await auth.signUp(
          email: _email.text.trim(),
          password: _password.text,
        );
        if (!mounted) return;
        if (!signedIn) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Check your email to confirm your account, then sign in.'),
            ),
          );
          setState(() => _registering = false);
        }
      } else {
        await auth.signIn(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to connect. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.mark_email_read_outlined,
                        color: AppPalette.blue, size: 58),
                    const SizedBox(height: 22),
                    const Center(
                      child: Text('Mail Demo',
                        style: TextStyle(fontSize: 32,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.8)),
                    ),
                    const SizedBox(height: 7),
                    const Center(
                      child: Text('A demonstration inbox, not a Google service',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppPalette.muted)),
                    ),
                    const SizedBox(height: 36),
                    TextFormField(
                      controller: _email,
                      enabled: widget.configured && !_busy,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Email address',
                        border: OutlineInputBorder()),
                      validator: (value) => value == null ||
                          !value.contains('@')
                          ? 'Enter a valid email address' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      enabled: widget.configured && !_busy,
                      obscureText: _hidePassword,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          tooltip: _hidePassword ? 'Show password' : 'Hide password',
                          onPressed: () =>
                              setState(() => _hidePassword = !_hidePassword),
                          icon: Icon(_hidePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                        ),
                      ),
                      validator: (value) =>
                          value == null || value.length < 6
                              ? 'Password must have at least 6 characters' : null,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: widget.configured && !_busy ? _submit : null,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: AppPalette.blue),
                      child: _busy
                          ? const SizedBox(height: 20, width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(_registering ? 'Create account' : 'Sign in'),
                    ),
                    TextButton(
                      onPressed: widget.configured && !_busy
                          ? () => setState(() => _registering = !_registering)
                          : null,
                      child: Text(_registering
                          ? 'Already registered? Sign in'
                          : 'Create a demo account'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _busy ? null : widget.onDemo,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48)),
                      child: const Text('Explore without signing in'),
                    ),
                    if (!widget.configured) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Supabase sign-in is disabled until you launch with a '
                        'SUPABASE_PUBLISHABLE_KEY dart-define. Demo mode works now.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppPalette.muted, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
