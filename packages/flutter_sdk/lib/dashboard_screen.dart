import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const _channel = MethodChannel('sdk_channel');

  String _userName = '';
  String _userId = '';

  @override
  void initState() {
    super.initState();
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'setUser') {
        final args = Map<String, dynamic>.from(call.arguments as Map);
        setState(() {
          _userName = args['userName']?.toString() ?? '';
          _userId = args['userId']?.toString() ?? '';
        });
      }
    });
    _channel.invokeMethod('ready');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Screen')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Hello $_userName', style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 8),
            Text('User ID: $_userId', style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
