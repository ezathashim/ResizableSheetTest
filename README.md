# ResizableSheetOverlay Demo App

[![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%2016%2B%20%7C%20Mac%20Catalyst-blue.svg)](https://developer.apple.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

An interactive test app demonstrating the features and layout capabilities of the [`ResizableSheetOverlay`](https://github.com/ezathashim/ResizableSheetOverlay) Swift package on iOS and Mac Catalyst.

---

## Overview

This repository provides a sandbox project to test and verify resizable sheet overlay behavior in real-time. It includes interactive examples covering:

* 📐 **Standard Resizable Sheets:** Testing continuous edge and corner drag handles with custom min/max dimensions.
* 🧭 **NavigationStack & Toolbars:** Verifying that nested navigation bars, interactive buttons, and header exclusions work seamlessly alongside drag gestures.
* 📱 **Platform Adaptability:** Smooth performance and zero-latency resizing under touch, Apple Pencil, pointer/trackpad interaction, and Mac Catalyst window environments.

---

## Requirements

* **Xcode:** 15.0 or later
* **Swift:** 6.0+
* **Deployment Target:** iOS 16.0+ / Mac Catalyst 16.0+

---

## Getting Started

1. **Clone the repository:**
   ```bash
   git clone [https://github.com/ezathashim/ResizableSheetOverlay-Demo.git](https://github.com/ezathashim/ResizableSheetOverlay-Demo.git)
   ```

2. **Open the project in Xcode:**
   ```bash
   cd ResizableSheetOverlay-Demo
   open ResizableSheetOverlayDemo.xcodeproj
   ```

3. **Select a Target & Run:**
   * Choose an **iOS Simulator / iPadOS Simulator** or set the destination target to **My Mac (Mac Catalyst)**.
   * Press `Cmd + R` to build and run.

---

## Related Package

This app depends on the official Swift package:
* 📦 **[ResizableSheetOverlay Repository](https://github.com/ezathashim/ResizableSheetOverlay)**

---

## License

This demo project is released under the MIT License. See [LICENSE](LICENSE) for details.
