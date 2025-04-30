import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prosmart/service/kimlikislemleri/auth_provider.dart';

class PendingApprovalScreen extends ConsumerWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mevcut oturum açmış kullanıcıyı al
    final authState = ref.watch(authStateProvider);

    // Kullanıcı e-postası
    final email = authState.value?.email ?? '';

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animasyon veya illüstrasyon
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.hourglass_top,
                  size: 100,
                  color: Colors.blue.shade300,
                ),
              ),

              const SizedBox(height: 32),

              // Başlık
              const Text(
                'Hesap Onayı Bekleniyor',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Açıklama
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Merhaba! Hesabınız şu anda yönetici onayı bekliyor. Onaylandığında size bildirim göndereceğiz.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 16),

              // E-posta bilgisi
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.email, color: Colors.blue),
                    const SizedBox(width: 12),
                    Text(
                      email,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Tahmini süre
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Column(
                  children: [
                    Text(
                      'Tahmini Onay Süresi',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '24 saat içinde',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // İletişim bilgisi
              const Text(
                'Herhangi bir sorunuz varsa veya onay sürecini hızlandırmak istiyorsanız:',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                icon: const Icon(Icons.support_agent),
                label: const Text('Destek ile İletişime Geçin'),
                onPressed: () {
                  // Destek iletişim aksiyonu
                },
              ),

              const SizedBox(height: 24),

              // Çıkış yapma
              OutlinedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Çıkış Yap'),
                onPressed: () async {
                  await ref.read(logoutProvider.future);
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
              ),

              const SizedBox(height: 16),

              // Sayfayı yenile
              TextButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Durumu Kontrol Et'),
                onPressed: () {
                  // AuthStatus'u yeniden kontrol et
                  ref.invalidate(authStatusProvider);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
