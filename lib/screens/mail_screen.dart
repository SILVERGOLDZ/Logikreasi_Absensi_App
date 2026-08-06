import 'package:flutter/material.dart';
import 'package:absensi_app/widgets/app_scaffold.dart';

class MailScreen extends StatefulWidget {
  const MailScreen({super.key});

  @override
  State<MailScreen> createState() => _MailScreenState();
}

class _MailScreenState extends State<MailScreen> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return AppScaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/Logo_LGradient.png',
              width: 32,
            ),
            const SizedBox(width: 8),
            const Text('Kotak Masuk'),
          ],
        ),
      ),
      body: Center(
          child: Text("Belum tersedia pada versi ini")),
    );
  }
}