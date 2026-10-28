import 'package:material_ui/material_ui.dart';

class EmptyPage extends StatelessWidget {
  final String text;
  final IconData icon;
  const EmptyPage({super.key, required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    ColorScheme cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: .center,
        spacing: 20,
        children: [
          Icon(icon, size: 32, color: cs.primary),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: cs.outline),
          ),
        ],
      ),
    );
  }
}
