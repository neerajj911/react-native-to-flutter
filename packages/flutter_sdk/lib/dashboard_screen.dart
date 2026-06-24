import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const _channel = MethodChannel('sdk_channel');

  String _name = '';
  String _email = '';

  @override
  void initState() {
    super.initState();
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'setUser') {
        _applyArgs(call.arguments);
      }
    });
    _pullParams();
  }

  Future<void> _pullParams() async {
    try {
      final result = await _channel.invokeMethod<dynamic>('getParams');
      _applyArgs(result);
    } catch (_) {
      // ignore — native side may not have responded yet
    }
  }

  void _applyArgs(dynamic raw) {
    if (raw is! Map) return;
    final args = Map<String, dynamic>.from(raw);
    if (!mounted) return;
    setState(() {
      _name = (args['name'] ?? args['userName'] ?? '').toString();
      _email = (args['email'] ?? args['userId'] ?? '').toString();
    });
  }

  static const _messages = <_Msg>[
    _Msg('Welcome to Live Support', false),
    _Msg('Hi there! How can I help today?', false),
    _Msg('I have a question about my account.', true),
    _Msg('Of course — happy to help. What\'s up?', false),
  ];

  @override
  Widget build(BuildContext context) {
    final initial = _name.isNotEmpty ? _name[0].toUpperCase() : '?';
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            _header(initial),
            _paramsBanner(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (_, i) => _bubble(_messages[i]),
              ),
            ),
            _composer(),
          ],
        ),
      ),
    );
  }

  Widget _paramsBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF02569B),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'FLUTTER SCREEN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Params received from RN',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF718096),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _paramRow('name',  _name.isEmpty ? '(empty)'  : _name),
          const SizedBox(height: 4),
          _paramRow('email', _email.isEmpty ? '(empty)' : _email),
        ],
      ),
    );
  }

  Widget _paramRow(String key, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 56,
          child: Text(
            '$key:',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: Color(0xFF718096),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: Color(0xFF1A202C),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _header(String initial) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF3182CE),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => SystemNavigator.pop(),
          ),
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white,
            child: Text(
              initial,
              style: const TextStyle(
                color: Color(0xFF3182CE),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _name.isEmpty ? 'Guest' : _name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _email,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Color(0xFF48BB78),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          const Text('Online',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _bubble(_Msg m) {
    final isMine = m.fromMe;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine)
            const CircleAvatar(
              radius: 14,
              backgroundColor: Color(0xFF3182CE),
              child: Text('A',
                  style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          if (!isMine) const SizedBox(width: 8),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMine ? const Color(0xFF3182CE) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isMine ? 14 : 4),
                  bottomRight: Radius.circular(isMine ? 4 : 14),
                ),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 2,
                      offset: Offset(0, 1)),
                ],
              ),
              child: Text(
                m.text,
                style: TextStyle(
                  fontSize: 14,
                  color:
                      isMine ? Colors.white : const Color(0xFF1A202C),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _composer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black12, blurRadius: 4, offset: Offset(0, -1)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F2F5),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Text(
                'Type a message…',
                style: TextStyle(color: Color(0xFFA0AEC0)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF3182CE),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }
}

class _Msg {
  final String text;
  final bool fromMe;
  const _Msg(this.text, this.fromMe);
}
