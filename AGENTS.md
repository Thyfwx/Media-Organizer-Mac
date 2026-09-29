# AGENTS.md: Media Organizer (macOS)

Native macOS app (Swift, SwiftUI) that renames and organizes files by reading their real content. Xcode project only.


## Branches
- Base every task on `main`, and open every PR against `main`.

## Build
- There is no `Package.swift`, so `swift build` fails. Build with:
  `xcodebuild -project "Media Organizer.xcodeproj" -scheme "Media Organizer" -configuration Debug build`
- There are no tests yet, so the build is the main check.
- If your environment can't run Xcode (for example on Linux), say so in the PR. Don't claim a build passed.

## Hard rules
- Native frameworks only (SwiftUI, AppKit, Vision, NaturalLanguage, FoundationModels). Don't add third-party dependencies.
- Respect the macOS sandbox: use security-scoped URLs for user-selected paths. Never work around it with chmod or symlinks.
- Never put API keys or secrets in source, especially `LLMService.swift`.
- The app icon lives in `Media Organizer/Assets.xcassets/AppIcon.appiconset/`. Don't change icon assets unless the task asks.

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
- If an automated reviewer (for example CodeRabbit) was rate limited or skipped the review, say so in a comment so another reviewer reads it.
- Never merge a PR, including your own. Only the owner (@Thyfwx) merges.
- Before a PR is merged or closed, post a final summary comment that mentions @Thyfwx: what changed, how it was verified, the final check status, and anything still open.

## Code finish and attribution

- After each code change, review the touched code for clarity, dead scaffolding, and sensible module boundaries. Keep unrelated behavior stable.
- Run the relevant formatter, lint, build, and behavior checks for the changed area. Report the commands and results; identify anything unverified.
- Do not add decorative AI-company signatures, generator banners, invisible tracking characters, or assistant co-author trailers to source, commits, or pull request text you control. Preserve required copyright, license, and third-party attribution notices and existing Git history.
- Use invisible Unicode characters only when functionality requires them; prefer visible escape sequences and explain their purpose.
