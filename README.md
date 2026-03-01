# Namida History Analyzer

[English](#english) | [简体中文](#简体中文)

---

<a id="english"></a>
## 🇬🇧 English

A beautiful, cross-platform desktop application built with **Flutter** and **Python** to analyze and visualize your listening history from Namida.

### 🌟 Features

- **Automated Data Analysis**: Extracts and crunches data directly from your Namida Backup ZIP file.
- **Rich Dashboard**: Provides an elegant dashboard displaying key metrics (total listening hours, daily average, unique tracks, etc.).
- **Interactive Charts**: Visualizes your listening history trends over time with smooth, interactive line charts.
- **Detailed Leaderboards**: View your personal Top 10 tracks, artists, and albums, complete with dedicated detail pages.
- **Listening Habits**: Analyzes your listening periods (Morning, Afternoon, Evening, Night) and weekly patterns.
- **Local Metadata Matching**: Optional integration with your local music directory to supplement missing metadata and enhance the analysis.

### 🛠️ Prerequisites

To run and build this project, you will need:

- **Flutter SDK**: Ensure you have Flutter installed. [Installation Guide](https://docs.flutter.dev/get-started/install)
- **Python 3.x**: Ensure Python is installed and accessible from your system's `PATH`. The Flutter app invokes a Python script (`scripts/run_analysis.py`) to process the data.

### 🚀 Getting Started

1. **Clone the repository:**
   ```bash
   git clone <your-repository-url>
   cd namida_history_app
   ```

2. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

3. **Python Environment Preparation:**
   Ensure your Python environment has the necessary standard libraries (or third-party packages if `run_analysis.py` requires them).
   
4. **Run the app:**
   ```bash
   flutter run -d windows  # Or macOS/Linux depending on your OS
   ```

### 📂 Project Structure

- `lib/`: Contains the Flutter frontend source code.
  - `screens/`: Application screens (`home_screen.dart`, detail screens, etc.).
  - `widgets/`: Reusable UI components like `interactive_line_chart.dart`.
  - `main.dart`: Application entry point.
- `scripts/`: Contains the Python data analysis engine.
  - `run_analysis.py`: The core script that parses the Namida backup ZIP and outputs a structured JSON report.

### 📝 How to Use

1. Launch the application.
2. *(Optional)* Click the **Settings (⚙️)** icon in the top right to select your local music directory for better metadata extraction.
3. Click the **Select Backup ZIP** button and choose your exported Namida backup file (`.zip`).
4. Wait a moment for the Python engine to extract and analyze the data.
5. Explore your personal listening reports, discover your highest repeat tracks, and dive deep into specific artists or albums!

### 🤝 Contributing

Contributions, issues, and feature requests are welcome! Feel free to check the issues page.

### 📄 License

This project is open-source and available under the [MIT License](LICENSE).

---

<a id="简体中文"></a>
## 🇨🇳 简体中文

一款使用 **Flutter** 和 **Python** 构建的精美跨平台桌面应用程序，用于分析和可视化您的 Namida 听歌历史记录。

### 🌟 特性

- **自动数据分析**：直接从 Namida 备份 ZIP 文件中提取并处理数据。
- **丰富的数据看板**：提供优雅的数据仪表盘，展示关键指标（总听歌时长、日均听歌时长、播放歌曲数等）。
- **交互式图表**：通过流畅的交互式折线图，可视化您的历史听歌趋势。
- **详细排行榜**：查看您的个人 Top 10 歌曲、歌手和专辑，并提供专属的详情页面。
- **听歌习惯分析**：分析您的听歌时段（早晨、下午、傍晚、夜晚）以及周维度规律。
- **本地元数据匹配**：可选配置本地音乐目录，以补充缺失的元数据并增强分析效果。

### 🛠️ 环境依赖

要运行和构建此项目，您需要：

- **Flutter SDK**：确保您已安装 Flutter。[安装指南](https://docs.flutter.dev/get-started/install)
- **Python 3.x**：确保已安装 Python，并且可以通过系统的 `PATH` 环境变量访问。Flutter 应用将调用 Python 脚本 (`scripts/run_analysis.py`) 来处理数据。

### 🚀 快速开始

1. **克隆仓库：**
   ```bash
   git clone <your-repository-url>
   cd namida_history_app
   ```

2. **安装 Flutter 依赖：**
   ```bash
   flutter pub get
   ```

3. **准备 Python 环境：**
   请确保您的 Python 环境具备必要的标准库（如果 `run_analysis.py` 依赖第三方包，请一并安装）。
   
4. **运行应用：**
   ```bash
   flutter run -d windows  # 或 macOS/Linux，取决于您的操作系统
   ```

### 📂 项目结构

- `lib/`：包含 Flutter 前端源代码。
  - `screens/`：应用程序页面（`home_screen.dart`、各个详情页等）。
  - `widgets/`：可复用的 UI 组件，如 `interactive_line_chart.dart`。
  - `main.dart`：应用入口文件。
- `scripts/`：包含 Python 数据分析引擎。
  - `run_analysis.py`：核心脚本，用于解析 Namida 备份 ZIP 文件并输出结构化的 JSON 报告。

### 📝 使用方法

1. 启动应用程序。
2. *（可选）* 点击右上角的 **设置 (⚙️)** 图标，选择您的本地音乐目录，以便更好地提取元数据。
3. 点击 **Select Backup ZIP (选择备份文件)** 按钮，然后选择您导出的 Namida 备份文件（`.zip`）。
4. 稍等片刻，让 Python 引擎提取并分析数据。
5. 探索您的个人听歌报告，发现您循环播放最多的歌曲，并深入了解特定的歌手或专辑！

### 🤝 贡献与反馈

欢迎提交贡献、问题 (Issues) 和功能请求！请随时查看 Issues 页面。

### 📄 开源协议

本项目为开源项目，遵循 [MIT 协议](LICENSE)。