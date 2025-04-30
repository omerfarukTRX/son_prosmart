import 'package:flutter/material.dart';
import 'package:prosmart/screens/main_container.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainContainer(
      title: 'Gösterge Paneli',
      child: Center(
        child: Text('Hoş Geldiniz'),
      ),
    );
  }
}

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainContainer(
      title: 'Analitik',
      child: Center(
        child: Text('Analitik Sayfası'),
      ),
    );
  }
}

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainContainer(
      title: 'Müşteriler',
      child: Center(
        child: Text('Müşteri Listesi'),
      ),
    );
  }
}

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainContainer(
      title: 'Siparişler',
      child: Center(
        child: Text('Sipariş Listesi'),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainContainer(
      title: 'Ayarlar',
      child: Center(
        child: Text('Uygulama Ayarları'),
      ),
    );
  }
}
