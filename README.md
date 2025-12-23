# SoulSound - Premium Offline Music Player

SoulSound  is a sleek, modern, offline-first music player built with Flutter. It focuses on aesthetics, smooth animations, and a premium user experience.

![SoulSound Interface](assets/images/android/main_screen_logo.png)
[![Build and Release APK](https://github.com/G0biKrish/SoundFlow/actions/workflows/flutter_release.yml/badge.svg?branch=main)](https://github.com/G0biKrish/SoundFlow/actions/workflows/flutter_release.yml)
## ✨ Key Features

### 🎧 Audio & Playback
-   **Local Music Scanning**: Automatically finds audio files (MP3, M4A, FLAC, WAV) on your device.
-   **Gapless Playback**: Powered by `audio_service` and `just_audio` for seamless listening.
-   **Background Playback**: Full support for background audio with rich notification controls.
-   **Waveform Seek Bar**: Interactive visual waveform for seeking through tracks.

### 🎨 Modern UI/UX
-   **Floating Dock Navigation**: A unique, pill-shaped floating dock with animated indicators.
-   **Dynamic "Now Playing" Card**: A draggable bottom sheet that seamlessly transitions from a mini-player to a full-screen player.
-   **Visual Enhancements**:
    -   Glassmorphism and gradient accents.
    -   Smooth "Pop-up" animations for navigation items.
    -   Custom animated linear progress bars.
    -   Clean, dark-mode-first aesthetic.

### 📂 Organization & Sorting
-   **Smart Sorting**: Sort tracks by:
    -   Newest Added
    -   Most Played
    -   A to Z (Title)
    -   Artist Name
    -   Duration (Longest First)
-   **Library Management**: (In Progress) Dedicated tabs for Songs, Artists, Albums, Genres, and Playlists.

## 🚀 Changelog


### v1.0.0 Release Notes
## 🌟 New Features
- **Floating Dock Navigation**: A sleek, pill dock that floats at the bottom of the screen, featuring smooth animations and "pop-up" selection effects.
- **Visual Waveform Seek Bar**: A stunning, interactive waveform visualization in the player for precise scrubbing.
- **Dynamic "Now Playing" Card**:
    - **Draggable Interface**: Seamlessly swipe up from the mini-player to reveal the full player.
    - **Auto-Hide**: The entire player interface intelligently hides when no music is playing, keeping your home screen clean.
- **Improved Sorting**: Sort your library by Title, Artist, Duration, Date Added, or Play Count.
- **Glassmorphism UI**: Updated `MiniPlayer` and various UI elements with modern transparency and blur effects.

## 🐛 Fixes & Improvements
- Fixed text shadow rendering issues on some devices.
- optimized app startup time.
- Enhanced stability of file permission handling.

---

### v1.1.0 - The Playlist Update
## 🌟 New Features
-   **Rich Playlist Creation**: Redesigned creation dialog with a premium dark theme.
-   **Customization**: Added support for picking custom icons (12 presets) or uploading cover images from the gallery.
-   **Safe Storage**: Automated secure storage for playlist artwork.
-   **Smart Playlists**: Added "Most Played" and "Liked Songs" auto-generated playlists.

**🐛 Bug Fixes & Improvements**
*   **UI Stability**: Fixed keyboard overlay issues causing the navigation bar/mini-player to shift upwards.
*   **Performance**: Optimized playlist rendering efficiently handles custom assets.

---

### v1.1.1 - Streaks & Selection Update
## 🌟 New Features
-   **🔥 Streak System**: 
    -   Track your music habits with monthly play counts.
    -   **Fire Icons**: Songs show a fire icon based on monthly plays.
    -   **Burning #1**: The most-played song of the month gets a special animated burning effect.
-   **✨ Multi-Select Mode**:
    -   **Long-Press Selection**: Long-press any song to enter selection mode.
    -   **Bulk Actions**: Easily manage multiple songs at once:
        -   **Add to Playlist**: Bulk add songs to any playlist.
        -   **Play Next**: Queue multiple songs instantly.
        -   **Delete**: Remove multiple songs from your library in one tap.
    -   **Smart Dock**: A dedicated action dock appears when items are selected.
-   **Performance**: Added `const` constructors to critical widgets for smoother scrolling.
