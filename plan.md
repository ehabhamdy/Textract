## Plan: macOS Text Extractor MVP

Build the first release as a native Swift menu-bar utility that uses the exact macOS region-selection workflow and Apple Vision for OCR. Keep the app single-process for the default path: a status-bar app triggers `/usr/sbin/screencapture -i -x`, runs `VNRecognizeTextRequest` on the captured image, and copies the recognized text to the clipboard. Treat MLX-based local AI as an optional second-stage engine only after the native OCR path is measured on real screenshots. This keeps the MVP fast, deterministic, simpler to ship, and aligned with the chosen direct-notarized distribution path.

**Steps**
1. Define the MVP envelope and platform baseline. Create a native macOS menu-bar app with no dock presence, target macOS 14+ by default for a simpler modern stack, and keep the first release optimized for direct Developer ID signing plus notarization rather than App Store constraints.
2. Establish the app shell. Use AppKit for the status item and menu, with a SwiftUI Settings window for user preferences and onboarding. Keep the root architecture modular so capture, OCR, clipboard, and optional AI fallback are isolated services.
3. Implement the hotkey subsystem. Use the KeyboardShortcuts Swift package for a user-configurable global shortcut instead of low-level event monitors. Ship with a first-run shortcut recorder or settings recorder rather than forcing a public default shortcut, because that avoids collisions and follows the package’s guidance.
4. Implement capture using the native box-selection UX. Invoke `/usr/sbin/screencapture -i -x <temporary-file>` through `Process`, store captures in `FileManager.default.temporaryDirectory`, detect cancellation via process exit status and missing output, and clean up temporary images immediately after OCR completes.
5. Build the OCR engine on Vision. Use `VNRecognizeTextRequest` as the primary extraction engine, default to `.accurate`, make supported recognition languages configurable, enable language correction where appropriate, and allow custom words for domain-specific vocabularies.
6. Preserve output quality. Sort observations into reading order, normalize whitespace conservatively, preserve line breaks when requested, and expose a lightweight text post-processing layer so the copied output resembles what users expect from PowerToys Text Extractor rather than a raw OCR dump.
7. Implement clipboard and user feedback. Copy the final text to `NSPasteboard`, surface success and failure states with a subtle sound or notification, and make sure cancel paths leave the previous clipboard contents untouched.
8. Add settings and lifecycle polish. Include launch-at-login, sound on success, preferred OCR mode, language list, custom words, and an “Enable AI fallback” switch that stays off by default. Use `SMAppService.mainApp` for launch-at-login on modern macOS instead of older helper-app plumbing.
9. Create an engine boundary for future fallback. Define a `TextExtractionEngine`-style abstraction so the default Vision engine and any later AI engine share the same request and response flow. Keep the capture and clipboard layers unaware of which engine is active.
10. Evaluate AI fallback only after measuring the native path. If Vision underperforms on your screenshot corpus, add a separate local Python service behind the engine boundary. Use MLX-VLM only as an optional extension, not a startup dependency for the main app.
11. Benchmark OCR-focused MLX models before defaulting to Gemma. The current MLX-VLM project supports OCR-oriented models as well as Gemma-family vision models; if fallback is needed, compare at least one OCR-specialized model against the Gemma option on your actual screenshots and select the smallest model that wins on accuracy, latency, and memory footprint.
12. Package the MVP for direct distribution. Sign and notarize the native app, verify all first-run prompts on a clean machine, and defer sandbox/App Store work until the OCR and UX are proven.
13. Document the App Store delta explicitly. If you later pursue App Store distribution, reassess capture implementation, permission flows, sandboxing, and any helper-process requirements as a follow-on project rather than polluting the MVP path.

**Relevant files**
- `/Users/I575965/Documents/Code/Projects/macos/textract/inspiration.md` — existing rough architecture note that should remain as historical context and a scope-check reference.
- `/Users/I575965/Documents/Code/Projects/macos/textract/TextExtractor.xcodeproj` — planned Xcode project root for the native app.
- `/Users/I575965/Documents/Code/Projects/macos/textract/TextExtractor/App/TextExtractorApp.swift` — planned app entry point, app lifecycle wiring, and settings registration.
- `/Users/I575965/Documents/Code/Projects/macos/textract/TextExtractor/MenuBar/StatusItemController.swift` — planned status-bar item, menu actions, and command routing.
- `/Users/I575965/Documents/Code/Projects/macos/textract/TextExtractor/Capture/ScreenCaptureService.swift` — planned `screencapture` wrapper and cancellation/temporary-file handling.
- `/Users/I575965/Documents/Code/Projects/macos/textract/TextExtractor/OCR/VisionTextExtractor.swift` — planned Vision-based OCR service built on `VNRecognizeTextRequest`.
- `/Users/I575965/Documents/Code/Projects/macos/textract/TextExtractor/OCR/TextPostProcessor.swift` — planned reading-order normalization and text cleanup rules.
- `/Users/I575965/Documents/Code/Projects/macos/textract/TextExtractor/Clipboard/ClipboardService.swift` — planned pasteboard output and clipboard preservation logic.
- `/Users/I575965/Documents/Code/Projects/macos/textract/TextExtractor/Settings/SettingsView.swift` — planned preferences UI for shortcut, languages, login item, and optional AI fallback.
- `/Users/I575965/Documents/Code/Projects/macos/textract/ai-backend/` — optional future directory for a local MLX service only if the fallback phase is approved after OCR benchmarking.

**Verification**
1. Verify the hotkey triggers capture from arbitrary foreground apps and still works after relaunch and login-item startup.
2. Verify the cancel path from the region selector exits cleanly, leaves clipboard contents unchanged, and does not leave temporary files behind.
3. Verify Vision OCR quality on a representative screenshot corpus: terminal output, browser text, PDFs, retina UI, dark mode UI, mixed languages, and low-contrast UI text.
4. Measure end-to-end latency from hotkey press to clipboard update and record the baseline before considering any AI fallback.
5. Test first-run behavior on a clean machine for any screen capture or privacy prompts triggered by the chosen capture approach, and update onboarding text to match observed system behavior.
6. Verify direct-signed and notarized distribution on a second machine, including launch-at-login, hotkey registration, capture, OCR, and clipboard output.
7. If the AI fallback phase is implemented, benchmark cold start, warm latency, steady-state RAM use, disable/enable flows, and failure handling when the daemon is unavailable.

**Decisions**
- Chosen direction: native Vision OCR is the default engine for the MVP; MLX is an optional fallback path only.
- Chosen scope: OCR MVP plus optional AI fallback, not AI-first architecture.
- Chosen distribution path: direct notarized distribution first, not App Store-first.
- Hotkey decision: use KeyboardShortcuts rather than raw event monitoring because the package provides global shortcuts without the extra permission friction associated with accessibility-style monitoring.
- Launch-at-login decision: use `SMAppService` on modern macOS instead of older helper-based packages unless backward compatibility becomes a hard requirement.
- Capture decision: prefer `screencapture` for the MVP because it provides the native drag-box UX immediately; revisit ScreenCaptureKit only if later product goals need managed capture streams or App Store-specific work.
- AI model decision: do not assume Gemma is the right fallback model; benchmark OCR-specialized MLX-VLM options against Gemma before locking the fallback engine.

**Further Considerations**
1. Recommended platform floor: macOS 14+ unless you have a strong need for macOS 13 support; that keeps the stack current while still allowing `SMAppService` and a modern SwiftUI/AppKit hybrid.
2. Recommended hardware stance: support Intel only for the native OCR path if you must, but treat Apple Silicon as the primary target because any MLX fallback will be Apple Silicon only.
3. Recommended UX policy: keep the first release clipboard-only, and add an editable result panel only if user testing shows that direct copy is too opaque or too lossy for common workflows.
