# bnotch

**Your bookmarks, right where you need them — in the notch.**

<!-- screenshot -->

bnotch is a lightweight macOS bookmark manager that lives in your MacBook's hardware notch. Hover over the notch and it expands with a smooth Dynamic Island-style animation, giving you instant access to your bookmarks.

## Features

- **Dynamic Island animation** — hover over the notch to reveal your bookmarks
- **Smart browser detection** — auto-detects Chrome, Safari, Firefox, Edge, Brave, Arc, Opera, and Vivaldi
- **Flexible open modes** — open bookmarks in a new tab, new window, or incognito/private mode
- **Auto-fetched favicons** — bookmark icons are pulled automatically from the web
- **Folders & grouping** — organize bookmarks into folders (up to 8 top-level entries)
- **Two view modes** — List view or Icon view with folder navigation
- **Right-click context menu** — quickly edit or delete bookmarks
- **Multilingual** — English and German with automatic system language detection (switchable in settings)
- **Menu bar icon** — quick-access menu always available
- **Dark theme** — clean, dark-only UI at a fixed 380px width
- **Auto-updates** — built-in update checks via Sparkle

## Requirements

- macOS 14.0 or later
- MacBook with notch (2021 MacBook Pro or newer)

## Installation

Download the latest `.dmg` from [GitHub Releases](../../releases), open it, and drag bnotch to your Applications folder.

## Building from Source

```bash
git clone https://github.com/klotzbrocken/bnotch.git
cd bnotch
open bnotch.xcodeproj
```

Build and run with Xcode 15 or later. The project uses Swift and SwiftUI.

## Auto-Updates

bnotch uses the [Sparkle](https://sparkle-project.org/) framework to check for updates. You can trigger a manual check from the menu bar icon > **Check for Updates**.

## Support

If you find bnotch useful, consider supporting development:

[![Ko-fi](https://img.shields.io/badge/Ko--fi-Support%20bnotch-FF5E5B?logo=ko-fi&logoColor=white)](https://ko-fi.com/klotzbrocken)

## License

[MIT](LICENSE)
