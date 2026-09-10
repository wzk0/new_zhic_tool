import 'package:m3e_core/m3e_core.dart';
import 'package:material_ui/material_ui.dart';

class LoadPage extends StatefulWidget {
  final String text;
  final bool ifok;

  const LoadPage({super.key, required this.text, required this.ifok});

  @override
  State<LoadPage> createState() => _LoadPageState();
}

class _LoadPageState extends State<LoadPage> {
  bool _showText = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showText = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    ColorScheme cs = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: .center,
        spacing: 20,
        children: [
          M3ELoadingIndicator(),
          AnimatedOpacity(
            opacity: _showText ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            child: Text(
              textAlign: .center,
              widget.text,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: cs.outline),
            ),
          ),
        ],
      ),
    );
  }
}
