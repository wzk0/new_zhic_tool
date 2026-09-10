import 'package:material_ui/material_ui.dart';

class EmptyPage extends StatefulWidget {
  final String text;
  final IconData icon;
  const EmptyPage({super.key, required this.text, required this.icon});

  @override
  State<EmptyPage> createState() => _EmptyPageState();
}

class _EmptyPageState extends State<EmptyPage> {
  @override
  Widget build(BuildContext context) {
    ColorScheme cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: .center,
        spacing: 20,
        children: [
          Icon(widget.icon, size: 32, color: cs.primary),
          Text(
            widget.text,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: cs.outline),
          ),
        ],
      ),
    );
  }
}
