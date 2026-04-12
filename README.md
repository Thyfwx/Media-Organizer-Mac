# 📁 Media Organizer (macOS) - Alpha 1.0.1

Media Organizer is a premium, AI-powered "Naming Rehab" tool for macOS. It transforms messy, "jibber-jabber" filenames and unorganized folders into professional, human-readable assets using cutting-edge Artificial Intelligence.

![App Icon](Media%20Organizer/Assets.xcassets/AppIcon.appiconset/icon_512x512.png)

## ✨ The "Naming Rehab" Philosophy
Stop wondering what `IMG_4921_final_v2.pdf` is. Media Organizer reads the *actual content* of your files to propose names that make sense at a glance (e.g., `Amazon Receipt - 2026-04-11.pdf`).

---

## 🧠 AI Engines (The Brains)
Media Organizer features three distinct AI strategies to suit your needs:

### 1. ✨ Apple Intelligence (Native Mode)
The "Pro" choice for privacy and speed. 
- **Privacy First:** 100% on-device. No data ever leaves your Mac.
- **Elite Heuristics:** Uses a custom-built local engine (`EmbeddedAIEngine`) that performs deep context analysis.
- **Content Awareness:** 
    - **Documents:** Scans text for dates, sources (like Amazon, IRS), and subjects.
    - **Media:** Extracts Artist, Title, and Album metadata from audio/video files.
    - **Visuals:** Uses Computer Vision to classify images (e.g., distinguishing a "Golden Retriever" from a generic "Dog") and detects Screenshots automatically.

### 2. 🦙 Local Ollama
Hook into your local Ollama server (`llama3.2` recommended) for high-performance open-source modeling without the need for cloud API keys.

### 3. ☁️ Cloud API (Pro Presets)
Support for the world's most powerful models with zero-configuration presets:
- **OpenAI:** GPT-4o, GPT-4o-mini
- **Anthropic:** Claude 3.5 Sonnet
- **Groq:** Llama 3.1 70B (for blazing fast speed)

---

## 🚀 Key Features

### 🛠️ Intelligent "In-Place" Renaming
By default, your files stay exactly where they are. No more losing files in deep subfolder structures unless you explicitly want them sorted.

### 🏷️ Native macOS Integration
- **Finder Tags:** Automatically applies searchable macOS Finder tags based on the AI's categorization.
- **ID3 Metadata:** Reaches inside `.mp4` and `.m4a` files to write Artist/Title/Album tags directly into the file.
- **Spotlight Ready:** Every rehabilitated file is instantly indexed and searchable via Spotlight.

### 🎨 Liquid Glass UI
A premium, native macOS experience featuring:
- **Frosted Glass (Visual Effects):** A translucent, animated background that matches the system theme.
- **Interactive Feedback:** Custom "Pop" and "Glass" sound effects and native macOS notifications.
- **Descriptive History:** A beautiful log of every file you've organized, complete with category icons and "Undo" support.

### 🛡️ Safety & Collision Handling
- **Non-Destructive:** Files are safely moved/renamed.
- **Collision Logic:** If multiple files get the same name, it automatically adds suffixes like `(1)`, `(2)`, etc., so no data is ever lost.

---

## 🛠️ Installation & Updates

1. **Download:** Grab the latest `Media-Organizer-Alpha-1.0.dmg` from the [Releases](https://github.com/Thyfwx/Media-Organizer-Mac/releases/tag/v1.0.1-alpha) page.
2. **Install:** Drag the app into your **Applications** folder.
3. **Stay Current:** Use the built-in **"Check for Updates"** button in Settings. It connects directly to the GitHub API to let you know if a new version is ready.

---
*Created with ❤️ by Xavier Scott*
