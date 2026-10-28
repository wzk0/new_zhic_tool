import 'package:flutter/services.dart';
import 'package:flutter_confetti/flutter_confetti.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:new_zhic_tool/core/icon.dart';

class BottomsheetWidget extends StatelessWidget {
  final List<Map<String, dynamic>> items;

  const BottomsheetWidget({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: .zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [_buildPart(context, items)],
      ),
    );
  }

  Widget _buildPart(BuildContext context, List<Map<String, dynamic>> items) {
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
        final name = item['name']?.toString() ?? '';

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _getItem(
                context,
                item['icon'] as IconData,
                name,
                item['value']?.toString() ?? '',
              ),
            ),
            CircleAvatar(
              backgroundColor: Colors.transparent,
              child: IconButton(
                icon: Icon(Mdi.contentCopy),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Clipboard.setData(ClipboardData(text: name));
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _getItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          child: Icon(icon),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.titleSmall,
                overflow: .ellipsis,
                maxLines: 1,
              ),
              Text(
                subtitle,
                style: textTheme.bodySmall,
                overflow: .ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
