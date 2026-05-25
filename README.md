# Brigt

A minimal macOS menu bar application for software-only dimming of external displays.

### Demo

https://github.com/user-attachments/assets/8ab0cada-e2cf-47b7-8e99-349feaae6d50

## Features
- Minimalist menu bar interface.
- Software-based brightness control (overlay dimming).
- Persists brightness state between launches.
- Lightweight and fast.

## Versioning
- **Current Version:** 1.0.0
- **Requirements:** macOS 13.0+ (Ventura or later).
- **Architecture:** Optimized for Apple Silicon (arm64).

## How to Start
1. **Build the app:**
   ```bash
   ./build_app.sh
   ```
2. **Launch:**
   Double-click `Brigt.app` in the project root or run:
   ```bash
   open Brigt.app
   ```

## Development
To rebuild after changes:
```bash
./build_app.sh
```
