# 🎵 Namida History Analyzer

**English** | [简体中文](README_zh.md)

---

A beautiful, cross-platform desktop application built with **Flutter** to analyze and visualize your listening history from [Namida](https://github.com/namidaco/namida). Import your backup file and get your personal annual listening report.

## 🌟 Features

### 📊 Dashboard
- **Key Metrics at a Glance**: Total listening hours, companion days, daily average, total plays, unique tracks/artists/albums, and favorite genre — all displayed in elegant color-coded cards.
- **Year / All-Time Toggle**: Switch between different years or all-time stats via the top dropdown.

### 📈 Interactive Charts
- **Play Trend Line Chart**: Smooth, animated line chart showing daily play counts over time.
- **Scroll to Zoom**: Mouse wheel zooms in/out on the timeline.
- **Drag to Pan**: Click and drag to navigate across different time periods.
- **Hover Tooltips**: Hover over any point to see the exact date and play count.

### 🏆 Leaderboards
- **Top 10 Tracks / Artists / Albums**: Displayed on the home screen, tap any item to open its dedicated detail page.
- **Full Rankings**: Browse up to Top 500 tracks and Top 200 artists/albums.
- **Monthly Top Song**: Track your most-looped song for each month of the year.
- **Seamless Artist / Album Drill-Down**: From any artist or album detail page, tap a song in its top-10 list to jump directly to the track detail page.

### ⏰ Listening Habits
- **Period Distribution**: Bar charts for Night (0-6), Morning (6-12), Afternoon (12-18), and Evening (18-23).
- **Weekly Patterns**: Monday-to-Sunday play count visualization.

### ⭐ Personalized Highlights
- **Obsession Moment**: The day you looped a single song the most times.
- **Latest Night Song**: The first track you listened to after midnight.
- **Most Immersive Day**: The day with the highest total play count.

### 🔧 Additional Capabilities
- **Local Metadata Matching**: Optionally configure a local music directory to auto-scan audio file metadata (supports MP3, FLAC, M4A, WAV, OGG, OPUS, AAC, WMA) and enrich the analysis.
- **Lazy Track Detail Loading**: The top 300 tracks are pre-computed for instant access; all remaining tracks are resolved on-demand when you tap them and cached for subsequent views — no data is ever missing.
- **Play in Namida**: On any track detail page, a play button lets you instantly start playback in the Namida player (if its executable is configured) or fall back to the system default player.
- **Bilingual UI**: Built-in English and Chinese (中文) interface, switchable in settings.
- **Material Design 3**: Deep purple themed, with automatic light/dark mode adaptation.

## 🛠️ Prerequisites

| Dependency | Version | Notes |
|------------|---------|-------|
| **Flutter SDK** | ≥ 3.8.1 | [Installation Guide](https://docs.flutter.dev/get-started/install) |

## 🚀 Getting Started

1. **Clone the repository:**
   ```bash
   git clone https://github.com/DiWu17/namida_history_app
   cd namida_history_app
   ```

2. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the app:**
   ```bash
   flutter run -d windows  # Or macOS / Linux
   ```

## 📝 How to Use

1. Launch the application.
2. *(Optional)* Click the **Settings (⚙️)** icon in the top right to:
   - Select your **local music directory** for richer audio metadata.
   - Set the **Namida executable path** (`namida.exe`) to enable one-click playback from track detail pages.
3. Click the **Select Backup ZIP** button and choose your exported Namida backup file (`.zip`).
4. Wait for the analysis engine to process the data (usually takes a few seconds).
5. Explore your personal listening report! Check out leaderboards, play trends, listening habits, and tap on any track/artist/album for detailed insights.
6. On a track detail page, click the **▶ Play** button to open the song in Namida or your system default player.

## 📂 Project Structure

```
namida_history_app/
├── lib/                          # Flutter frontend
│   ├── main.dart                 # App entry point, theme & routing
│   ├── l10n/                     # Localization resource files
│   ├── providers/                # State management (Provider)
│   │   └── locale_provider.dart  # Language switching
│   ├── screens/                  # App screens
│   │   ├── home_screen.dart      # Main dashboard
│   │   ├── track_detail_screen.dart   # Track details + Namida playback
│   │   ├── artist_detail_screen.dart  # Artist details
│   │   ├── album_detail_screen.dart   # Album details
│   │   └── full_list_screen.dart      # Full leaderboard
│   ├── services/                 # Business logic & utilities
│   │   ├── analysis_service.dart # Analysis engine (Dart isolate)
│   │   ├── config_service.dart   # Persistent settings storage
│   │   └── track_detail_resolver.dart # Lazy track detail lookup & cache
│   └── widgets/                  # Reusable components
│       └── interactive_line_chart.dart # Interactive line chart
└── pubspec.yaml                  # Flutter project configuration
```

## 🏗️ Tech Stack

| Layer | Technology |
|-------|------------|
| **Frontend** | Flutter (Dart) |
| **Charting** | fl_chart |
| **State Management** | Provider |
| **Localization** | intl + flutter_localizations |
| **File Selection** | file_picker |
| **ZIP Processing** | archive (Dart) |
| **Audio Metadata** | metadata_audio (Dart) |
| **Persistent Config** | shared_preferences |

## 🔄 Data Flow

```
User selects Namida backup ZIP
       ↓
Dart Isolate: Extract ZIP → Scan local music directory (optional) → Parse history JSON → Analyze
       ↓
Return structured data (grouped by year: "All Time", "2024", …)
       ↓
Flutter renders dashboard → User browses & interacts
       ↓
Tap any track → resolveTrackDetail() checks top-300 cache,
falls back to on-demand compute → TrackDetailScreen
       ↓
(Optional) Press ▶ Play → launch Namida or system default player
```

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! Feel free to check the [issues page](https://github.com/DiWu17/namida_history_app/issues).

## 📄 License

This project is open-source and available under the [MIT License](LICENSE).