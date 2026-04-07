# 🎵 Namida History Analyzer

[English](README.md) | **简体中文**

---

一款使用 **Flutter** 和 **Python** 构建的精美跨平台桌面应用程序，用于分析和可视化您的 [Namida](https://github.com/namidaco/namida) 听歌历史记录。导入备份文件，即可获得属于你的年度听歌报告。

## 🌟 特性

### 📊 数据看板
- **核心指标概览**：总听歌时长、陪伴天数、日均收听时长、播放次数、不重复曲目/歌手/专辑数、最爱曲风，一目了然。
- **年度/全时段切换**：通过顶部下拉菜单，自由切换查看不同年份或全部时间的分析报告。

### 📈 交互式图表
- **播放趋势折线图**：流畅的交互式折线图展示每日播放次数走势。
- **鼠标滚轮缩放**：滚轮上下滚动即可放大/缩小时间轴。
- **拖拽平移**：鼠标拖拽左右浏览不同时间段。
- **悬浮提示**：鼠标悬停可查看具体日期与播放次数。

### 🏆 排行榜
- **歌曲 / 歌手 / 专辑 Top 10**：首页直接展示，点击即可跳转专属详情页。
- **完整排行榜**：支持查看 Top 500 歌曲、Top 200 歌手/专辑完整列表。
- **月度最佳单曲**：按月追踪你每个月循环最多的歌。

### ⏰ 听歌习惯分析
- **时段分布**：夜晚 (0-6)、早晨 (6-12)、下午 (12-18)、傍晚 (18-23) 四时段播放量柱状图。
- **每周规律**：周一到周日的播放习惯可视化分析。

### ⭐ 个性化亮点
- **单曲循环之最**：某天循环某首歌次数最多的纪录。
- **深夜之歌**：午夜后你听的第一首歌。
- **最沉浸的一天**：单日播放次数最多的一天。

### 🔧 更多能力
- **本地元数据匹配**：可选配置本地音乐目录，自动扫描音频文件元数据（支持 MP3、FLAC、M4A、WAV、OGG、OPUS、AAC、WMA），补充缺失信息。
- **多语言支持**：内置中文 / 英文双语 UI，可在设置中一键切换。
- **Material Design 3**：基于深紫色主题色，自适应系统亮/暗模式。

## 🛠️ 环境依赖

| 依赖 | 版本要求 | 说明 |
|------|---------|------|
| **Flutter SDK** | ≥ 3.8.1 | [安装指南](https://docs.flutter.dev/get-started/install) |
| **Python** | ≥ 3.x | 需要在系统 `PATH` 中可访问 |
| **pandas** | - | Python 数据处理库 |
| **tinytag** | - | Python 音频元数据读取库（可选，用于本地元数据匹配） |

## 🚀 快速开始

1. **克隆仓库：**
   ```bash
   git clone https://github.com/DiWu17/namida_history_app
   cd namida_history_app
   ```

2. **安装 Flutter 依赖：**
   ```bash
   flutter pub get
   ```

3. **安装 Python 依赖：**
   ```bash
   pip install pandas tinytag
   ```

4. **运行应用：**
   ```bash
   flutter run -d windows  # 或 macOS / Linux
   ```

## 📝 使用方法

1. 启动应用程序。
2. *（可选）* 点击右上角 **设置 (⚙️)** 图标，选择本地音乐目录以获取更完整的元数据。
3. 点击 **选择备份文件** 按钮，选择从 Namida 导出的备份 `.zip` 文件。
4. 等待 Python 分析引擎处理数据（通常十几秒即可完成）。
5. 尽情探索你的听歌报告吧！查看排行榜、播放趋势、听歌习惯，点击歌曲/歌手/专辑查看详细信息。

## 📂 项目结构

```
namida_history_app/
├── lib/                          # Flutter 前端
│   ├── main.dart                 # 应用入口，主题与路由配置
│   ├── l10n/                     # 国际化资源文件
│   ├── providers/                # 状态管理 (Provider)
│   │   └── locale_provider.dart  # 语言切换
│   ├── screens/                  # 应用页面
│   │   ├── home_screen.dart      # 主仪表盘
│   │   ├── track_detail_screen.dart   # 歌曲详情
│   │   ├── artist_detail_screen.dart  # 歌手详情
│   │   ├── album_detail_screen.dart   # 专辑详情
│   │   └── full_list_screen.dart      # 完整排行榜
│   └── widgets/                  # 可复用组件
│       └── interactive_line_chart.dart # 交互式折线图
├── scripts/                      # Python 数据分析引擎
│   ├── run_analysis.py           # 分析入口脚本
│   ├── extractor.py              # ZIP 备份解压
│   └── parser.py                 # 核心数据解析与统计
└── pubspec.yaml                  # Flutter 项目配置
```

## 🏗️ 技术栈

| 层级 | 技术 |
|------|------|
| **前端框架** | Flutter (Dart) |
| **图表库** | fl_chart |
| **状态管理** | Provider |
| **国际化** | intl + flutter_localizations |
| **文件选择** | file_picker |
| **后端引擎** | Python 3 |
| **数据处理** | pandas |
| **音频元数据** | tinytag |

## 🔄 数据流

```
用户选择 Namida 备份 ZIP
       ↓
Flutter 调用 Python 脚本 (scripts/run_analysis.py)
       ↓
解压 ZIP → 扫描本地音乐目录（可选）→ 解析历史 JSON → 统计分析
       ↓
返回结构化 JSON（按年份分组：「所有时间」「2024年」…）
       ↓
Flutter 渲染仪表盘 → 用户浏览 & 交互
```

## 🤝 贡献与反馈

欢迎提交贡献、问题 (Issues) 和功能请求！请随时查看 [Issues 页面](https://github.com/DiWu17/namida_history_app/issues)。

## 📄 开源协议

本项目为开源项目，遵循 [MIT 协议](LICENSE)。