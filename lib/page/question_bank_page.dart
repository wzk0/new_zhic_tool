import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_confetti/flutter_confetti.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:m3e_core/m3e_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:new_zhic_tool/core/icon.dart';
import 'package:new_zhic_tool/widget/error_page.dart';
import 'package:new_zhic_tool/widget/load_page.dart';
import 'package:url_launcher/url_launcher.dart';

class QuestionBankPage extends ConsumerStatefulWidget {
  const QuestionBankPage({super.key});

  @override
  ConsumerState<QuestionBankPage> createState() => _QuestionBankPageState();
}

class _QuestionBankPageState extends ConsumerState<QuestionBankPage> {
  List<_GiteeItem> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadIndex();
  }

  Future<void> _loadIndex() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _items = const [];
    });

    try {
      final items = await _GiteeApi.loadIndex();

      if (!mounted) {
        return;
      }

      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _openDirectory(_GiteeItem item) {
    HapticFeedback.lightImpact();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            _QuestionBankDirectoryPage(name: item.name, items: item.children),
      ),
    );
  }

  Future<void> _openFile(_GiteeItem item) async {
    HapticFeedback.lightImpact();

    Confetti.launch(
      context,
      options: const ConfettiOptions(particleCount: 150, spread: 70, y: 0.7),
    );
  }

  Future<void> _downloadFile(_GiteeItem item) async {
    HapticFeedback.lightImpact();

    final rawUrl = _GiteeApi.buildRawUrl(item.path);

    final success = await launchUrl(
      Uri.parse(rawUrl),
      mode: LaunchMode.externalApplication,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('无法打开默认浏览器')));
    }
  }

  Future<void> _onTap(_GiteeItem item) async {
    if (item.isDirectory) {
      _openDirectory(item);
      return;
    }

    await _openFile(item);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: _QuestionBankBody(
        items: _items,
        loading: _loading,
        error: _error,
        emptyIcon: Mdi.fileQuestionOutline,
        emptyTitle: '暂无题库',
        emptySubtitle: '题库文件会显示在这里',
        onTap: _onTap,
        onDownload: _downloadFile,
      ),
    );
  }
}

class _QuestionBankDirectoryPage extends StatelessWidget {
  const _QuestionBankDirectoryPage({required this.name, required this.items});

  final String name;
  final List<_GiteeItem> items;

  void _openDirectory(BuildContext context, _GiteeItem item) {
    HapticFeedback.lightImpact();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            _QuestionBankDirectoryPage(name: item.name, items: item.children),
      ),
    );
  }

  Future<void> _openFile(BuildContext context, _GiteeItem item) async {
    HapticFeedback.lightImpact();

    Confetti.launch(
      context,
      options: const ConfettiOptions(particleCount: 150, spread: 70, y: 0.7),
    );
  }

  Future<void> _downloadFile(BuildContext context, _GiteeItem item) async {
    HapticFeedback.lightImpact();

    final rawUrl = _GiteeApi.buildRawUrl(item.path);

    final success = await launchUrl(
      Uri.parse(rawUrl),
      mode: LaunchMode.externalApplication,
    );

    if (!success && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('无法打开默认浏览器')));
    }
  }

  Future<void> _onTap(BuildContext context, _GiteeItem item) async {
    if (item.isDirectory) {
      _openDirectory(context, item);
      return;
    }

    await _openFile(context, item);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: _QuestionBankBody(
        items: items,
        loading: false,
        error: null,
        emptyIcon: Mdi.folderOpenOutline,
        emptyTitle: '此文件夹为空',
        onTap: (item) => _onTap(context, item),
        onDownload: (item) => _downloadFile(context, item),
      ),
    );
  }
}

class _QuestionBankBody extends StatelessWidget {
  const _QuestionBankBody({
    required this.items,
    required this.loading,
    required this.error,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.onTap,
    required this.onDownload,
    this.emptySubtitle,
  });

  final List<_GiteeItem> items;
  final bool loading;
  final String? error;
  final IconData emptyIcon;
  final String emptyTitle;
  final String? emptySubtitle;
  final Future<void> Function(_GiteeItem item) onTap;
  final Future<void> Function(_GiteeItem item) onDownload;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const LoadPage(text: '正在加载题库...', ifok: true);
    }

    if (error != null) {
      return ErrorPage(text: error!, icon: Mdi.fileDocumentAlertOutline);
    }

    if (items.isEmpty) {
      return _buildEmpty(context);
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: M3ESegmentedList(
        itemCount: items.length,
        onTap: (index) => onTap(items[index]),
        itemBuilder: (context, index) {
          final item = items[index];

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: _QuestionBankItem(item: item)),
              if (!item.isDirectory)
                CircleAvatar(
                  backgroundColor: Colors.transparent,
                  child: IconButton(
                    icon: const Icon(Mdi.downloadOutline),
                    onPressed: () => onDownload(item),
                  ),
                )
              else
                const SizedBox(width: 48),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: 300,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(emptyIcon, size: 42, color: colorScheme.outline),
                const SizedBox(height: 6),
                Text(
                  emptyTitle,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
                if (emptySubtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    emptySubtitle!,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.outlineVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _QuestionBankItem extends StatelessWidget {
  const _QuestionBankItem({required this.item});

  final _GiteeItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final extension = _QuestionBankUtils.extension(item.name);

    return Row(
      children: [
        CircleAvatar(
          backgroundColor: colorScheme.secondaryContainer,
          child: Icon(
            item.isDirectory
                ? Mdi.folderOutline
                : _QuestionBankUtils.fileIcon(extension),
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: textTheme.titleSmall,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              Text(
                item.isDirectory
                    ? _QuestionBankUtils.buildDirectoryInfo(item)
                    : _QuestionBankUtils.buildFileInfo(item, extension),
                style: textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuestionBankUtils {
  const _QuestionBankUtils._();

  static String buildDirectoryInfo(_GiteeItem item) {
    final directories = item.dirCount;
    final files = item.fileCount;

    return [
      if (directories > 0) '$directories 个文件夹',
      if (files > 0) '$files 个文件',
      if (directories == 0 && files == 0) '空文件夹',
    ].join(' · ');
  }

  static String buildFileInfo(_GiteeItem item, String extension) {
    final size = formatFileSize(item.size);
    final modifiedAt = formatDate(item.modifiedAt);

    return [
      if (size.isNotEmpty) size,
      if (modifiedAt.isNotEmpty) modifiedAt,
    ].join(' · ');
  }

  static String formatFileSize(int? size) {
    if (size == null) {
      return '';
    }

    if (size < 1024) {
      return '$size B';
    }

    if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    }

    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(2)} MB';
    }

    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  static String formatDate(DateTime? date) {
    if (date == null) {
      return '';
    }

    final local = date.toLocal();

    return '${local.year}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }

  static String extension(String name) {
    final index = name.lastIndexOf('.');

    if (index == -1 || index == name.length - 1) {
      return '';
    }

    return name.substring(index + 1).toLowerCase();
  }

  static IconData fileIcon(String extension) {
    switch (extension) {
      case 'json':
        return Mdi.codeJson;

      case 'zip':
      case 'rar':
      case '7z':
        return Mdi.zipBoxOutline;

      case 'pdf':
        return Mdi.filePdfBox;

      case 'doc':
      case 'docx':
        return Mdi.fileWordOutline;

      case 'xls':
      case 'xlsx':
        return Mdi.fileExcelOutline;

      case 'txt':
        return Mdi.fileDocumentOutline;

      case 'csv':
        return Mdi.fileDelimitedOutline;

      default:
        return Mdi.fileOutline;
    }
  }
}

class _GiteeApi {
  const _GiteeApi._();

  static const String indexUrl =
      'https://gitee.com/thdbd/zhanghuan_data/raw/main/tiku/index.json';

  static const String rawBase =
      'https://gitee.com/thdbd/zhanghuan_data/raw/main';

  static Future<List<_GiteeItem>> loadIndex() async {
    final response = await http.get(
      Uri.parse(indexUrl),
      headers: const {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('题库索引 HTTP ${response.statusCode}');
    }

    final data = jsonDecode(response.body);

    if (data is! List) {
      throw Exception('题库索引数据格式错误');
    }

    final items = data
        .whereType<Map<String, dynamic>>()
        .map(_GiteeItem.fromJson)
        .toList();

    _sortItems(items);

    return items;
  }

  static String buildRawUrl(String path) {
    return '$rawBase/${_encodePath(path)}';
  }

  static String _encodePath(String path) {
    return path.split('/').map(Uri.encodeComponent).join('/');
  }

  static void _sortItems(List<_GiteeItem> items) {
    items.sort((a, b) {
      if (a.isDirectory != b.isDirectory) {
        return a.isDirectory ? -1 : 1;
      }

      return a.name.compareTo(b.name);
    });

    for (final item in items) {
      if (item.isDirectory) {
        _sortItems(item.children);
      }
    }
  }
}

class _GiteeItem {
  const _GiteeItem({
    required this.name,
    required this.path,
    required this.isDirectory,
    this.size,
    this.modifiedAt,
    this.fileCount = 0,
    this.dirCount = 0,
    this.children = const [],
  });

  factory _GiteeItem.fromJson(Map<String, dynamic> json) {
    final childrenJson = json['children'];

    final children = childrenJson is List
        ? childrenJson
              .whereType<Map<String, dynamic>>()
              .map(_GiteeItem.fromJson)
              .toList()
        : <_GiteeItem>[];

    return _GiteeItem(
      name: json['name'] as String? ?? '',
      path: json['path'] as String? ?? '',
      isDirectory: json['type'] == 'dir',
      size: json['size'] is num ? (json['size'] as num).toInt() : null,
      modifiedAt: _parseDate(json['modified_at']),
      fileCount: json['file_count'] is num
          ? (json['file_count'] as num).toInt()
          : 0,
      dirCount: json['dir_count'] is num
          ? (json['dir_count'] as num).toInt()
          : 0,
      children: children,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is! String || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }

  final String name;
  final String path;
  final bool isDirectory;
  final int? size;
  final DateTime? modifiedAt;
  final int fileCount;
  final int dirCount;
  final List<_GiteeItem> children;
}
