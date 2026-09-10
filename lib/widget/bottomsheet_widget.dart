import 'package:flutter/services.dart';
import 'package:flutter_confetti/flutter_confetti.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:new_zhic_tool/core/icon.dart';

class BottomsheetWidget extends StatefulWidget {
  final List<Map<String, dynamic>> items;

  const BottomsheetWidget({super.key, required this.items});

  @override
  State<BottomsheetWidget> createState() => _BottomsheetWidgetState();
}

class _BottomsheetWidgetState extends State<BottomsheetWidget> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: .zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [_buildPart(widget.items)],
      ),
    );
  }

  Widget _buildPart(List<Map<String, dynamic>> items) {
    return M3ESegmentedList(
      itemCount: items.length,
      onTap: (index) {
        HapticFeedback.lightImpact();
        Confetti.launch(
          context,
          options: const ConfettiOptions(
            particleCount: 150,
            spread: 70,
            y: 0.7,
          ),
        );
      },
      itemBuilder: (context, index) {
        final item = items[index];
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _getItem(
              item['icon'] as IconData,
              item['name'] as String,
              item['value'] as String,
            ),
            CircleAvatar(
              backgroundColor: Colors.transparent,
              child: IconButton(
                icon: Icon(Mdi.contentCopy),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Clipboard.setData(
                    ClipboardData(text: item['name'].toString()),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _getItem(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          child: Icon(icon),
        ),
        const SizedBox(width: 13),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall,
              overflow: .ellipsis,
              maxLines: 1,
            ),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall,
              overflow: .ellipsis,
            ),
          ],
        ),
      ],
    );
  }
}
