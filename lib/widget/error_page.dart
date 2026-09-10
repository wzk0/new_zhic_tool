import 'package:flutter/services.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:new_zhic_tool/page/login_page.dart';

class ErrorPage extends StatefulWidget {
  final String text;
  final IconData icon;
  const ErrorPage({super.key, required this.text, required this.icon});

  @override
  State<ErrorPage> createState() => _ErrorPageState();
}

class _ErrorPageState extends State<ErrorPage> {
  @override
  Widget build(BuildContext context) {
    ColorScheme cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: .center,
        spacing: 20,
        children: [
          Icon(widget.icon, size: 32, color: cs.error),
          Text(
            widget.text,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: cs.outline),
          ),
          M3EButton(
            style: .filled,
            child: Text('登入账号'),
            onPressed: () async {
              HapticFeedback.lightImpact();
              await _openLoginPage();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _openLoginPage() async {
    await LoginPage.open(context);
  }
}
