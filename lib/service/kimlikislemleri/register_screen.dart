import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prosmart/enums/kullanici_rolleri.dart';
import 'package:prosmart/service/kimlikislemleri/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _siteNameController = TextEditingController();
  final _blockController = TextEditingController();
  final _apartmentController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _showPassword = false;
  bool _isOwner = true; // true: Kat Maliki, false: Kiracı

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _siteNameController.dispose();
    _blockController.dispose();
    _apartmentController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo ve başlık
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Image.asset(
                          'assets/images/logo.png',
                          height: 80,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Yeni Hesap Oluştur',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 24),

                    // Hata mesajı
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.red.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: Colors.red.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Ad Soyad
                    TextFormField(
                      controller: _displayNameController,
                      decoration: const InputDecoration(
                        labelText: 'Ad Soyad',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen adınızı ve soyadınızı girin';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // E-posta
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'E-posta',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen e-posta adresinizi girin';
                        }

                        final emailRegex =
                            RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (!emailRegex.hasMatch(value)) {
                          return 'Geçerli bir e-posta adresi giriniz';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Telefon
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Telefon',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen telefon numaranızı girin';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Site Adı Manuel Giriş
                    TextFormField(
                      controller: _siteNameController,
                      decoration: const InputDecoration(
                        labelText: 'Site Adı',
                        prefixIcon: Icon(Icons.apartment),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen site adını girin';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Blok ve Daire
                    Row(
                      children: [
                        // Blok
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: _blockController,
                            decoration: const InputDecoration(
                              labelText: 'Blok',
                              prefixIcon: Icon(Icons.business),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Lütfen blok bilgisini girin';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Daire
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: _apartmentController,
                            decoration: const InputDecoration(
                              labelText: 'Daire No',
                              prefixIcon: Icon(Icons.door_front_door),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Lütfen daire no girin';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Kat Maliki / Kiracı seçimi
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withOpacity(0.5)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text('Kat Maliki'),
                              value: true,
                              groupValue: _isOwner,
                              onChanged: (value) {
                                setState(() {
                                  _isOwner = value!;
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text('Kiracı'),
                              value: false,
                              groupValue: _isOwner,
                              onChanged: (value) {
                                setState(() {
                                  _isOwner = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Şifre
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Şifre',
                        prefixIcon: const Icon(Icons.lock),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _showPassword = !_showPassword;
                            });
                          },
                        ),
                      ),
                      obscureText: !_showPassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen şifre girin';
                        }

                        if (value.length < 6) {
                          return 'Şifre en az 6 karakter olmalıdır';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Şifre onay
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: const InputDecoration(
                        labelText: 'Şifre Onay',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(),
                      ),
                      obscureText: !_showPassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen şifrenizi tekrar girin';
                        }

                        if (value != _passwordController.text) {
                          return 'Şifreler eşleşmiyor';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Kayıt ol butonu
                    ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('KAYIT OL'),
                    ),

                    const SizedBox(height: 16),

                    // Giriş ekranına dön
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child:
                          const Text('Zaten bir hesabınız var mı? Giriş yapın'),
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

  // Kayıt olma işlemi
  Future<void> _register() async {
    // Form doğrulama
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Kullanıcı rolü ve site bilgilerini içeren ek veriler
      final Map<String, dynamic> ekBilgiler = {
        'siteName': _siteNameController.text,
        'block': _blockController.text,
        'apartment': _apartmentController.text,
        'role': _isOwner ? 'siteSakini' : 'kiraci', // Rol bilgisi
      };

      // RegisterParams kullanarak güncelleyin
      final params = RegisterParams(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _displayNameController.text.trim(),
        telefon: _phoneController.text.trim(),
        rol: _isOwner ? KullaniciRolu.siteSakini : KullaniciRolu.kiraci,
        ekBilgiler: ekBilgiler,
      );

      await ref.read(registerProvider(params).future);

      // Bu çok önemli - kullanıcı oluşturulduktan sonra AuthStatus'u güncelle
      ref.read(currentAuthStatusProvider.notifier).state =
          AuthStatus.pendingApproval;

      if (mounted) {
        // Onay bekleyen kullanıcı ekranına yönlendir
        context.go('/pending-approval');
      }
    } catch (e) {
      setState(() {
        _errorMessage = _getFirebaseErrorMessage(e.toString());
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Firebase hata mesajını anlaşılır hale getirme
  String _getFirebaseErrorMessage(String errorMessage) {
    if (errorMessage.contains('email-already-in-use')) {
      return 'Bu e-posta adresi zaten kullanılıyor.';
    } else if (errorMessage.contains('invalid-email')) {
      return 'Geçersiz e-posta adresi.';
    } else if (errorMessage.contains('operation-not-allowed')) {
      return 'E-posta/şifre girişi devre dışı bırakılmış.';
    } else if (errorMessage.contains('weak-password')) {
      return 'Şifre çok zayıf. Daha güçlü bir şifre deneyin.';
    }

    return 'Kayıt olurken bir hata oluştu: $errorMessage';
  }
}
