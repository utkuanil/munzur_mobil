import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/auth_repository.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key, required this.email});

  final String email;

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  final _repo = AuthRepository();

  bool _loading = false;
  String? _message;

  Future<void> _checkVerification() async {
    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      final emailVerified = await _repo.refreshAndCheckEmailVerified();

      final userDoc = await _repo.getCurrentUserDoc();
      final data = userDoc.data() ?? {};

      final isVerifiedByCode = data['isVerifiedByCode'] == true;
      final verified = emailVerified || isVerifiedByCode;

      if (!verified) {
        setState(() {
          _message =
          'E-posta henüz doğrulanmamış. Mail kutunu kontrol edip doğrulama linkine tıkla.';
        });
        return;
      }

      await _repo.activateIfVerified(forceVerifiedByCode: isVerifiedByCode);

      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      setState(() {
        _message = 'Doğrulama kontrolü sırasında hata oluştu: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _resendEmail() async {
    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      await _repo.sendVerificationEmail();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Doğrulama e-postası tekrar gönderildi.'),
        ),
      );
    } catch (e) {
      setState(() {
        _message = 'E-posta tekrar gönderilemedi: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _logout() async {
    await _repo.signOut();
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('E-posta Doğrulama'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(
                      Icons.mark_email_read_outlined,
                      size: 64,
                      color: Color(0xFF1D8FA3),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'E-postanı Doğrula',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${widget.email} adresine doğrulama bağlantısı gönderildi. Spam posta kutunuzu da kontrol ediniz.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Mail kutundaki bağlantıya tıkladıktan sonra aşağıdaki butona bas.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    if (_message != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _message!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _loading ? null : _checkVerification,
                        child: _loading
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                            : const Text('Doğrulamayı Kontrol Et'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _loading ? null : _resendEmail,
                      child: const Text('Doğrulama mailini tekrar gönder'),
                    ),
                    TextButton(
                      onPressed: _loading ? null : _logout,
                      child: const Text('Çıkış Yap'),
                    ),
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