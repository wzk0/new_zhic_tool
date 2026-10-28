# 掌环

> 面向天津理工大学中环信息学院学生的校园助手，基于 Flutter 构建，把教务查询、学习资料与常用校园服务整合进一个应用。

---

## ✨ 功能特性

### 📚 学习与教务

* **课表查询**：在线拉取整学期课表，支持 20 周切换，启动时自动定位到本周；网络异常时自动回落到本地缓存。
* **课表分享**：把当前查看的周课表导出为图片，调用系统分享面板发送。
* **培养方案**：内置 WebView 读取个人培养方案并解析，按模块统计已完成 / 未完成学分，支持按课程名称、代码、性质、状态搜索。
* **空教室查询**：按周查询空闲教室，支持多选教室、查看 12 节 × 7 天占用表与教室详情，可分享为图片。
* **成绩查询**：按学期查看成绩，自动汇总平均分、总学分与 GPA，可分享成绩单图片。
* **考试查询**：按「进行中 / 未开始」与「已结束」分组展示考试时间与地点，可分享考试安排图片。
* **校历查看**：从 Gitee 拉取校历图片并缓存到本地，支持展开预览与全屏缩放查看。

### 📝 题库共享

* **期末题库**：由 Gitee 仓库的索引驱动，支持多级目录浏览，免费下载、自由分发。
* **自主上传**：Fork 题库仓库、放入题目并生成索引后提交 PR，即可参与共建。

### 🏫 校园服务

* **图书馆、选课、评教、请假、学信网**：内置浏览器直接访问学校系统，支持页面前进后退。
* **教育考试查询**：四六级、计算机等级、教师资格、英语等级等成绩查询入口。

### 🎨 个性化

* **Monet 取色**：Android 12+ 跟随系统壁纸动态取色，可随时关闭。
* **自定义主题色**：内置调色盘（12 个预设色 + 色相 / 饱和度 / 明度调节），实时预览所选颜色。
* **课表高亮策略**：可设置「仅突出显示当天」——关闭时每周的同一天都会高亮，开启时只高亮今天；开启后翻到其它周还会出现「回到本周」浮动按钮。
* **明暗主题**：跟随系统深浅色切换。

### ⚙️ 其他

* **账号管理**：本地保存最多 5 组账号密码，点选即登入，可单独删除；支持「以上次登录学号重新登入」与一键登出。
* **检查更新**：读取 GitHub Release 版本信息并跳转下载页面。
* **赞赏作者**：展示微信 / 支付宝赞赏码，支持分别保存到相册。
* **彩蛋**：侧边栏与关于页点击头像可让头像转起来。

---

## 🛠️ 技术栈

| 方向 | 选型 |
| --- | --- |
| 框架 | Flutter（Dart 3） |
| 状态管理 | Riverpod |
| UI | Material 3 Expressive（`m3e_core`）、`material_ui`、`dynamic_color` |
| 图标 | `flutter_material_design_icons` |
| 网络 | `http`（自建 `NetworkService`，统一携带 Cookie 与超时处理） |
| 本地存储 | `shared_preferences`（账号、Cookie、课表缓存、设置项） |
| 内置浏览器 | `flutter_inappwebview` |
| 分享 / 相册 | `share_plus`、`gal` |
| 其他 | `html`（培养方案解析）、`fluttertoast`、`flutter_confetti`、`url_launcher`、`package_info_plus` |

所有数据均来自学校官网公开接口与自建 Gitee 题库仓库，应用不采集用户数据，也不会向第三方上传账号密码。

---

## 📤 题库上传

欢迎大家共同维护题库资源，让更多同学受益。

1. Fork 题库仓库：[zhanghuan_data](https://gitee.com/thdbd/zhanghuan_data)
2. 在 `tiku` 目录下放入或更新题库文件。
3. 提交前运行 `update.py`，重新生成题库索引。
4. Push 并提交 Pull Request。

---

## 🔨 编译指南

### 环境要求

* Flutter SDK（stable，Dart 3.13+）
* Android 开发环境（JDK 17）

### 编译步骤

1. 克隆仓库：

   ```bash
   git clone https://github.com/wzk0/new_zhic_tool
   cd new_zhic_tool
   ```

2. 获取依赖：

   ```bash
   flutter pub get
   ```

3. 处理依赖兼容性（首次或升级 `m3e_core` 后执行一次，脚本会修正 `m3e_core` 与 `material_ui` 的 `RoundedPolygon` 导入冲突）：

   ```bash
   python3 tool/apply_dependency_patches.py
   ```

4. 配置签名：release 构建读取 `android/app/upload-keystore.jks`，密码与别名来自环境变量 `APP_KEYSTORE_PASSWORD`、`APP_KEY_ALIAS`、`APP_KEY_PASSWORD`。本地调试可直接用 debug 构建，无需配置签名。

5. 构建 APK：

   ```bash
   # 只出常用架构
   flutter build apk --target-platform android-arm64

   # 或按 ABI 拆包（CI 使用的方式）
   flutter build apk --release --split-per-abi
   ```

产物位于 `build/app/outputs/flutter-apk/`。

### 自动发布

推送 `v*` 标签即触发 GitHub Actions（`.github/workflows/release.yml`）：自动安装依赖、打补丁、签名构建 armeabi-v7a / arm64-v8a / x86_64 三个 APK，并创建带说明的 Release。

---

## 💡 项目初衷

掌环希望把校园里高频使用的教务查询、学习资料与在线服务收进一个应用，减少反复登录、翻找入口的琐碎操作，让校园生活简单一点、高效一点。

欢迎体验、反馈问题，也欢迎参与开发与题库共建。