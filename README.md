# Media Organizer

Media Organizer is a macOS app that renames messy files by reading what's inside them, so `IMG_4921_final_v2.pdf` becomes something like `Amazon Receipt - 2026-04-11.pdf`.

![Media Organizer app icon](Media%20Organizer/Assets.xcassets/AppIcon.appiconset/icon_512x512.png)

## What it does

You drop files in, the app proposes a new name for each one, and you approve the changes. It reads:

- PDFs: the text of the first five pages.
- Text files (`txt`, `md`, `csv`, `json`): the start of the file.
- Images (`png`, `jpg`, `jpeg`, `heic`, `tiff`): text found in the picture, what the picture shows, and camera and capture date from its EXIF data.
- Audio and video (`mp4`, `mov`, `m4a`, `mp3`, `wav`): duration and the tags already in the file. For `mp4`, `m4a` and `mov` files it can write artist, title and album back into the file.

Other things it does:

- Renames in place by default. An option sorts files into category subfolders instead.
- Name formats: name only, category and name, date and name, or date, category and name.
- Adds the category as a Finder tag, which you can turn off in Settings.
- Adds `(2)`, `(3)` and so on when a new name is already taken, so nothing is overwritten.
- Keeps a history of what it renamed, with an Undo button on each entry.
- Checks GitHub for a newer release when you press Check for Updates in Settings.

## Choosing an engine

Settings has four engine choices.

| Engine | What it does | Where your data goes |
| --- | --- | --- |
| Core | Built in rules that work from the text and metadata the app extracts. No network call. | Stays on your Mac. |
| Ollama | Sends the file excerpt to a model on your own Ollama server at `localhost:11434`. The default model is `llama3.2`. | Stays on your Mac. |
| Cloud | Sends the excerpt to OpenAI, Anthropic, Groq or an endpoint you enter. You supply the API key. | Goes to that provider. |
| Pro Local | Present in Settings. Not described here, because I could not confirm it works in the released build. | Unknown. |

## Install

1. Download `Media-Organizer-v1.1.1.dmg` from the [latest release](https://github.com/Thyfwx/Media-Organizer-Mac/releases/latest).
2. Open it and drag the app into Applications.

To build it yourself, open `Media Organizer.xcodeproj` in Xcode, or run:

```sh
xcodebuild -project "Media Organizer.xcodeproj" -scheme "Media Organizer" -configuration Debug build
```

The project's deployment target is macOS 26.4. The release is marked alpha, and the repo has no automated tests.

## Limits

- Only the file types listed above are read for content. Anything else gets no content to work from.
- With the Cloud engine, a short excerpt of each file leaves your Mac. Use Core or Ollama if that matters.
- The release isn't confirmed to be signed or notarized. If macOS blocks it, right click the app and choose Open.

## License

MIT, see [LICENSE.md](LICENSE.md).

Site: [thyfwxit.com](https://thyfwxit.com)
