
from pathlib import Path
import sys

package = (
    Path.home()
    / ".pub-cache/hosted/pub.dev/m3e_core-1.1.4"
    / "lib/src/loading-indicator/m3e_loading_indicator.dart"
)

if not package.is_file():
    sys.exit(f"错误：找不到依赖文件：{package}")

source = package.read_text()
original = "import 'package:material_ui/material_ui.dart';"
patched = (
    "import 'package:material_ui/material_ui.dart' "
    "hide RoundedPolygon;"
)

if patched in source:
    print("m3e_core 补丁已经应用，无需重复处理。")
elif original in source:
    package.write_text(source.replace(original, patched, 1))
    print("已应用 m3e_core RoundedPolygon 兼容性补丁。")
else:
    sys.exit("错误：未找到预期的 import，依赖源码可能已变化。")
