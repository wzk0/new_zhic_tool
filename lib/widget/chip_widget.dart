import 'package:material_ui/material_ui.dart';

class ChipWidget extends StatefulWidget {
  final String text;
  final bool isPrimary;

  const ChipWidget({super.key, required this.text, this.isPrimary = true});

  @override
  State<ChipWidget> createState() => _ChipWidgetState();
}

class _ChipWidgetState extends State<ChipWidget> {
  @override
  Widget build(BuildContext context) {
    ColorScheme cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: widget.isPrimary ? cs.primaryContainer : cs.tertiaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 5, right: 5, top: 1, bottom: 1),
        child: Text(widget.text, style: Theme.of(context).textTheme.labelSmall),
      ),
    );
  }
}
