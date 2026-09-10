import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:new_zhic_tool/widget/empty_page.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:new_zhic_tool/core/debug.dart';
import 'package:new_zhic_tool/core/icon.dart';
import 'package:new_zhic_tool/widget/error_page.dart';
import 'package:new_zhic_tool/widget/load_page.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<File> _cachedImages = [];

  static const String _giteeApiUrl =
      'https://gitee.com/api/v5/repos/thdbd/zhanghuan_data/contents/xiao_li';

  static const String _cacheKey = 'calendar_images_cache_paths';

  @override
  void initState() {
    super.initState();
    _loadCalendarImages();
  }

  Future<void> _loadCalendarImages() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      final response = await http
          .get(
            Uri.parse('$_giteeApiUrl?page=1&per_page=100'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      debugShow('Gitee 校历 API 状态码: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw Exception(
          'Gitee API HTTP ${response.statusCode}: ${response.body}',
        );
      }

      final dynamic decoded = jsonDecode(response.body);

      if (decoded is! List) {
        throw Exception('Gitee API 返回的数据格式错误');
      }

      final dir = await getApplicationDocumentsDirectory();

      final xiaoLiDir = Directory('${dir.path}/xiao_li');

      if (!await xiaoLiDir.exists()) {
        await xiaoLiDir.create(recursive: true);
      }

      final List<File> downloadedFiles = [];

      for (final item in decoded) {
        if (item is! Map) {
          continue;
        }

        if (item['type'] != 'file') {
          continue;
        }

        final String name = item['name']?.toString() ?? '';

        final String downloadUrl = item['download_url']?.toString() ?? '';

        if (!_isImageFile(name)) {
          continue;
        }

        if (downloadUrl.isEmpty) {
          debugShow('Gitee 未提供 $name 的 download_url');
          continue;
        }

        final file = File('${xiaoLiDir.path}/$name');

        try {
          debugShow('正在下载校历图片: $name');

          final imageResponse = await http
              .get(Uri.parse(downloadUrl))
              .timeout(const Duration(seconds: 15));

          if (imageResponse.statusCode == 200) {
            await file.writeAsBytes(imageResponse.bodyBytes, flush: true);

            downloadedFiles.add(file);

            debugShow(
              '校历图片下载成功: $name '
              '(${imageResponse.bodyBytes.length} bytes)',
            );
          } else {
            debugShow(
              '下载校历图片 $name 失败: '
              'HTTP ${imageResponse.statusCode}',
            );
          }
        } catch (e) {
          debugShow('下载校历图片 $name 失败: $e');
        }
      }

      if (downloadedFiles.isNotEmpty) {
        _sortCalendarFiles(downloadedFiles);

        final paths = downloadedFiles.map((file) => file.path).toList();

        await prefs.setStringList(_cacheKey, paths);

        if (mounted) {
          setState(() {
            _cachedImages = downloadedFiles;
            _isLoading = false;
          });
        }

        debugShow(
          '成功从 Gitee 获取并缓存 '
          '${downloadedFiles.length} 张校历图片',
        );

        return;
      }

      throw Exception('Gitee API 返回成功, 但目录中没有可用的校历图片');
    } catch (e, stackTrace) {
      debugShow('Gitee 远程校历获取失败: $e');
      debugShow(stackTrace.toString());

      Fluttertoast.showToast(msg: '校历获取失败, 正在使用本地缓存');
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      final paths = prefs.getStringList(_cacheKey);

      if (paths != null && paths.isNotEmpty) {
        final List<File> localFiles = [];

        for (final path in paths) {
          final file = File(path);

          if (await file.exists()) {
            localFiles.add(file);
          }
        }

        if (localFiles.isNotEmpty) {
          _sortCalendarFiles(localFiles);

          if (mounted) {
            setState(() {
              _cachedImages = localFiles;
              _isLoading = false;
            });
          }

          debugShow(
            '从本地缓存恢复校历图片, '
            '共 ${localFiles.length} 张',
          );

          return;
        }
      }
    } catch (e, stackTrace) {
      debugShow('加载校历本地缓存失败: $e');
      debugShow(stackTrace.toString());
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        _errorMessage = '暂无校历图片, 请检查网络连接';
      });
    }
  }

  bool _isImageFile(String filename) {
    final ext = filename.toLowerCase();

    return ext.endsWith('.jpg') ||
        ext.endsWith('.jpeg') ||
        ext.endsWith('.png') ||
        ext.endsWith('.webp') ||
        ext.endsWith('.bmp');
  }

  String _getFileNameWithoutExtension(String path) {
    final fileName = path.split(Platform.pathSeparator).last;

    final lastDotIndex = fileName.lastIndexOf('.');

    if (lastDotIndex == -1) {
      return fileName;
    }

    return fileName.substring(0, lastDotIndex);
  }

  void _sortCalendarFiles(List<File> files) {
    files.sort((a, b) {
      final nameA = _getFileNameWithoutExtension(a.path);

      final nameB = _getFileNameWithoutExtension(b.path);

      return nameB.compareTo(nameA);
    });
  }

  void _showFullScreenImage(BuildContext context, File file) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 1.0,
              maxScale: 5.0,
              child: SizedBox.expand(
                child: Center(child: Image.file(file, fit: BoxFit.contain)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(), body: _buildBody(context));
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const LoadPage(text: '正在获取校历图片...', ifok: true);
    }

    if (_errorMessage != null && _cachedImages.isEmpty) {
      return ErrorPage(text: _errorMessage!, icon: Mdi.cloudOffOutline);
    }

    if (_cachedImages.isEmpty) {
      return EmptyPage(text: '暂无校历图片', icon: Mdi.calendarBlankOutline);
    }

    final data = _cachedImages.map((file) {
      final fileName = _getFileNameWithoutExtension(file.path);

      return M3EExpandableData(
        leading: CircleAvatar(child: Icon(Mdi.calendarMonthOutline)),
        title: fileName,
        body: GestureDetector(
          onTap: () => _showFullScreenImage(context, file),
          child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            clipBehavior: Clip.antiAlias,
            child: Image.file(
              file,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  alignment: Alignment.center,
                  child: Text(
                    '图片加载失败',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    }).toList();

    return M3EExpandableCardList(
      data: data,
      allowMultipleExpanded: true,
      initiallyExpanded: _cachedImages.isNotEmpty ? {0} : const {},
      padding: const EdgeInsets.all(16),
      style: M3EExpandableStyle(
        headerPadding: .only(left: 18, right: 12, top: 12, bottom: 12),
        expandIcon: const Icon(Mdi.chevronDown),
        expandTooltip: '展开校历',
        collapseTooltip: '收起校历',
      ),
    );
  }
}
