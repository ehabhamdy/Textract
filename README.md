# TextExtractor

TextExtractor is a native macOS menu-bar app that captures a user-selected screen region, runs on-device OCR with Apple's Vision framework, and copies the recognized text to the clipboard.

## Requirements

- macOS 14 or later
- Xcode 26 or later
- Command Line Tools for Xcode
- Homebrew, if you need to install `xcodegen`

## Project Layout

- `project.yml`: XcodeGen specification for the app project
- `TextExtractor.xcodeproj`: generated Xcode project
- `TextExtractor/`: app source code
- `scripts/build_app.sh`: release-oriented helper that generates and builds a runnable `.app`

## Install Tooling

Install XcodeGen if it is not already available:

```bash
brew install xcodegen
```

Verify the tool is installed:

```bash
xcodegen --version
```

## Generate the Xcode Project

From the project root, generate or refresh the Xcode project:

```bash
xcodegen generate
```

This reads `project.yml` and recreates `TextExtractor.xcodeproj`.

## Run in Xcode

1. Open the generated project:

```bash
open TextExtractor.xcodeproj
```

2. In Xcode, select the `TextExtractor` scheme.
3. Choose `My Mac` as the run destination.
4. Press Run.

The app runs as a menu-bar utility, so it will not appear in the Dock or Command-Tab app switcher. Look for the menu-bar icon with the text viewfinder symbol. Opening Settings activates the app so the settings window appears in front of other apps.

## Screen Recording Permission

On first capture macOS will prompt for screen recording access. If the prompt does not appear, open **System Settings → Privacy & Security → Screen Recording** and enable TextExtractor manually.

## Run the App Workflow

On first launch:

1. Click the TextExtractor menu-bar icon.
2. Open `Settings...`.
3. Assign a shortcut in the `Capture selected text` recorder.
4. Optionally set recognition languages and custom words.

To extract text:

1. Trigger the shortcut you recorded, or choose `Capture Text` from the menu-bar menu.
2. Drag to select a screen region using the native macOS capture UI.
3. Release the mouse to confirm the selection.
4. The recognized text is copied to the clipboard automatically.

If `Play success sound` is enabled in settings, the app plays a short confirmation sound after a successful extraction.

## Build from the Command Line

You can build the app without opening Xcode:

```bash
xcodebuild -project TextExtractor.xcodeproj -scheme TextExtractor -configuration Debug build
```

## Create a Runnable `.app`

The simplest way to create a local app bundle is to use the included build script:

```bash
./scripts/build_app.sh
```

That script:

1. Regenerates the Xcode project from `project.yml`
2. Builds the app in `Release` configuration
3. Copies the finished app bundle to `dist/TextExtractor.app`

Open the generated app bundle with:

```bash
open dist/TextExtractor.app
```

If you want to move it into Applications:

```bash
cp -R dist/TextExtractor.app /Applications/
```

You can also build the `.app` manually without the helper script:

```bash
xcodegen generate
xcodebuild \
    -project TextExtractor.xcodeproj \
    -scheme TextExtractor \
    -configuration Release \
    -derivedDataPath build/derived-data \
    build
```

The resulting app bundle will be at:

```bash
build/derived-data/Build/Products/Release/TextExtractor.app
```

## Production Prep

Before distributing the app outside your machine:

1. Review the bundle identifier in `project.yml` and adjust it if you need a different production identifier. It is currently set to `com.ehapps.TextExtractor`.
2. Configure your Apple Developer team and signing settings in Xcode.
3. Build a `Release` app bundle instead of using the default `Debug` build.
4. Verify the first-run experience on a clean machine, including screen capture permission prompts, shortcut setup, and launch-at-login behavior.
5. If you plan to share the app, archive, sign, notarize, and staple the build before distribution.

## Project Structure

```
TextExtractor/
├── App/
│   ├── TextExtractorApp.swift        # @main entry point
│   ├── AppDelegate.swift             # App lifecycle
│   └── AppController.swift           # Capture → OCR → clipboard pipeline + hotkey
├── MenuBar/
│   └── MenuBarContentView.swift      # SwiftUI MenuBarExtra content and native SettingsLink
├── Capture/
│   └── ScreenCaptureService.swift    # screencapture -i wrapper, cancellation handling
├── OCR/
│   ├── TextExtractionEngine.swift    # Protocol and error types
│   ├── VisionTextExtractor.swift     # Apple Vision OCR engine
│   └── TextPostProcessor.swift       # Reading-order sort and whitespace cleanup
├── Clipboard/
│   └── ClipboardService.swift        # NSPasteboard write
├── Settings/
│   ├── SettingsView.swift            # Preferences UI (SwiftUI)
│   └── LaunchAtLoginController.swift # SMAppService wrapper
└── Support/
    ├── AppPreferences.swift          # UserDefaults-backed settings
    ├── AppShortcuts.swift            # KeyboardShortcuts name definitions
    ├── Info.plist                    # LSUIElement, usage descriptions
    └── TextExtractor.entitlements    # Hardened runtime, non-sandboxed
```

## Notes

- The current implementation uses Apple's Vision OCR engine only. There is no MLX or Python backend in the app today.
- The global shortcut has no default value. You must assign one in Settings before using the hotkey path.
- `Launch at login` is wired through `SMAppService`. Test that feature in a normal signed app environment, not just a transient debug run.
- The app uses `/usr/sbin/screencapture` for the interactive selection flow.
- The bundle identifier is currently set to `com.ehapps.TextExtractor`.

## Troubleshooting

If the project does not open or build correctly:

1. Regenerate the project with `xcodegen generate`.
2. Resolve packages in Xcode if Swift Package Manager dependencies are stale.
3. Rebuild from the command line to confirm the active scheme and project are valid.

```bash
xcodebuild -project TextExtractor.xcodeproj -scheme TextExtractor -configuration Debug build
```
