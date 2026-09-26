# AGENTS.md: Media Organizer (macOS)

Native macOS app (Swift, SwiftUI) that renames and organizes files by reading their real content. Xcode project only.

## Build
- There is no `Package.swift`, so `swift build` fails. Build with:
  `xcodebuild -project "Media Organizer.xcodeproj" -scheme "Media Organizer" -configuration Debug build`
- If your environment can't run Xcode (for example on Linux), say so in the PR. Don't claim a build passed.

## Hard rules
- Native frameworks only (SwiftUI, AppKit, Vision, NaturalLanguage, FoundationModels). Don't add third-party dependencies.
- Respect the macOS sandbox: use security-scoped URLs for user-selected paths. Never work around it with chmod or symlinks.
- Never put API keys or secrets in source, especially `LLMService.swift`.
- The app icon is Icon Composer SVG layers in `AppIcon.icon/`. Don't reintroduce runtime-drawn or PNG icon code.

## Careful areas
- Detection and naming logic in `EmbeddedAIEngine.swift` and `FileProcessor.swift`: keep behavior stable. If you change it, explain the before and after in the PR, with example inputs and outputs.

## PRs
- Small and focused, with a description of what changed, how you checked it, and what could not be verified.

## On every PR: talk, and keep it green
- Keep the PR description current: what changed, how you verified it, and anything still unfinished.
- Reply to every review comment, and say what you changed in response.
- Every check must pass. If one fails (a red X), open its log, fix the cause, and push again.
- Never merge, close, or abandon a PR with a failing check. If you can't fix it, leave a comment explaining the failure and what is needed.
- If the same check already fails on the base branch, say so in a comment and fix it in a separate small PR.
