# Namida History Analyzer

[English](README.md) | [简体中文](README_zh.md)

---

A beautiful, cross-platform desktop application built with **Flutter** and **Python** to analyze and visualize your listening history from Namida.

## 🌟 Features

- **Automated Data Analysis**: Extracts and crunches data directly from your Namida Backup ZIP file.
- **Rich Dashboard**: Provides an elegant dashboard displaying key metrics (total listening hours, daily average, unique tracks, etc.).
- **Interactive Charts**: Visualizes your listening history trends over time with smooth, interactive line charts.
- **Detailed Leaderboards**: View your personal Top 10 tracks, artists, and albums, complete with dedicated detail pages.
- **Listening Habits**: Analyzes your listening periods (Morning, Afternoon, Evening, Night) and weekly patterns.
- **Local Metadata Matching**: Optional integration with your local music directory to supplement missing metadata and enhance the analysis.

## 🛠️ Prerequisites

To run and build this project, you will need:

- **Flutter SDK**: Ensure you have Flutter installed. [Installation Guide](https://docs.flutter.dev/get-started/install)
- **Python 3.x**: Ensure Python is installed and accessible from your system's `PATH`. The Flutter app invokes a Python script (`scripts/run_analysis.py`) to process the data.

## 🚀 Getting Started

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

## 📂 Project Structure

- `lib/`: Contains the Flutter frontend source code.
  - `screens/`: Application screens (`home_screen.dart`, detail screens, etc.).
  - `widgets/`: Reusable UI components like `interactive_line_chart.dart`.
  - `main.dart`: Application entry point.
- `scripts/`: Contains the Python data analysis engine.
  - `run_analysis.py`: The core script that parses the Namida backup ZIP and outputs a structured JSON report.

## 📝 How to Use

1. Launch the application.
2. *(Optional)* Click the **Settings (⚙️)** icon in the top right to select your local music directory for better metadata extraction.
3. Click the **Select Backup ZIP** button and choose your exported Namida backup file (`.zip`).
4. Wait a moment for the Python engine to extract and analyze the data.
5. Explore your personal listening reports, discover your highest repeat tracks, and dive deep into specific artists or albums!

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! Feel free to check the issues page.

## 📄 License

This project is open-source and available under the [MIT License](LICENSE).