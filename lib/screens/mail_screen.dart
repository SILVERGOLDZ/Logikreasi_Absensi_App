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
      appBar: AppBar(),
      body: Center(
          child: Text("Belum tersedia pada versi ini")),
    );
  }
}