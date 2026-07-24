# EPUB Reader for macOS Spec

## Problem Statement

The user reads EPUB books on a widescreen monitor and finds existing macOS reading experiences uncomfortable because the text spreads too far horizontally. Long line lengths make reading harder. The user wants a local macOS EPUB reader, analogous in spirit to Apple Books/Reader, but with stronger control over centered text, margins, readable column width, and reading layout.

The project is for personal local use only. It does not need accounts, cloud sync, analytics, store integration, social features, or distribution polish in the MVP.

## Solution

Build a native macOS app for local EPUB reading. The app imports local EPUB files, stores a local copy, renders reflowable textual EPUB content in a clean centered reading column, and lets the user configure the reading experience.

The MVP should support EPUB reflowable/textual books only. It should render chapters using WebKit through a controlled HTML/CSS wrapper, preserving simple inline images while applying app-owned reading styles. The default reading mode should be simple pagination, with continuous scrolling available as a configurable alternative.

The interface should be a single-window, elegant, minimal, highly functional macOS app inspired by Apple Books without trying to clone it pixel-perfect. It should include a reading area, a simple table-of-contents sidebar, and reading appearance controls.

## User Stories

1. As the reader, I want to open a local EPUB file, so that I can read books already on my Mac.
2. As the reader, I want the app to copy imported EPUBs into local app storage, so that books continue working if the original file is moved.
3. As the reader, I want the app to remember recently opened books, so that I can return to reading without browsing the filesystem every time.
4. As the reader, I want the app to reopen my last book, so that I can continue quickly.
5. As the reader, I want the app to remember my position in each book, so that I can resume where I stopped.
6. As the reader, I want the text to be centered on a widescreen monitor, so that my eyes do not need to track long horizontal lines.
7. As the reader, I want to configure the maximum text column width, so that line length feels comfortable.
8. As the reader, I want to configure side margins, so that the reading area has enough breathing room.
9. As the reader, I want to configure font size, so that text is comfortable at my monitor distance.
10. As the reader, I want to configure line height, so that paragraphs are easier to scan.
11. As the reader, I want light, dark, and sepia themes, so that I can read comfortably in different lighting.
12. As the reader, I want pagination to be the default reading mode, so that the app feels like a book reader.
13. As the reader, I want a continuous scrolling mode, so that I can switch when scrolling feels better for a book.
14. As the reader, I want reading mode to be configurable, so that I can choose between pagination and scrolling.
15. As the reader, I want simple previous/next page controls, so that pagination works without complex animations.
16. As the reader, I want keyboard navigation for simple pagination, so that reading does not require the mouse.
17. As the reader, I want a table-of-contents sidebar, so that I can jump between chapters.
18. As the reader, I want the sidebar to be simple and unobtrusive, so that it supports navigation without distracting from reading.
19. As the reader, I want chapters to render with app-controlled reading styles, so that badly wide EPUB styling does not defeat the purpose of the app.
20. As the reader, I want simple images inside chapters to render inline, so that books with maps, diagrams, or illustrations remain usable.
21. As the reader, I want inline images to fit the reading column, so that they do not break the layout.
22. As the reader, I want unsupported EPUB layout types to fail clearly, so that I understand when a book is outside the MVP scope.
23. As the reader, I want the app to focus on local files only, so that it remains simple and private.
24. As the reader, I want an interface that feels native to macOS, so that the app feels comfortable alongside other Mac apps.
25. As the reader, I want an elegant minimal UI, so that the reading experience stays focused on the text.

## Implementation Decisions

- Build a native macOS app for personal local use.
- Use SwiftUI for the application shell.
- Use WebKit/WKWebView for chapter rendering.
- Use Swift Package Manager for project dependencies.
- Support only EPUB reflowable/textual books in the MVP.
- Treat fixed-layout EPUBs, comics, heavily designed children books, PDFs, and other non-reflowable formats as unsupported in the MVP.
- Use existing EPUB libraries if a mature, maintained, macOS-compatible, SPM-friendly option is available.
- If no suitable library exists, implement a minimal EPUB parser for the MVP.
- The EPUB parser/import layer should handle ZIP container reading, container metadata, package document discovery, manifest, spine, and table-of-contents extraction.
- Render chapters through an app-controlled HTML wrapper rather than trusting the EPUB's original styling completely.
- Preserve essential textual content and simple inline images.
- Apply app-owned CSS for centered reading, maximum column width, margins, font size, line height, themes, pagination, and scrolling.
- Make pagination the default reading mode.
- Provide continuous scrolling as a user-selectable reading mode.
- Keep pagination simple in the MVP: chapter-level pagination, previous/next navigation, and no sophisticated page-turn animations.
- Use a single-window app architecture in the MVP.
- Include a simple table-of-contents sidebar.
- Include a reading appearance control surface for column width, side margin, font size, line height, theme, and reading mode.
- Persist reading settings globally.
- Persist reading position per book.
- Copy imported EPUBs into local application storage.
- Maintain recent books and last-opened book state locally.
- Keep highlights, notes, full-book search, cloud sync, user accounts, and distribution polish out of the MVP.

## Testing Decisions

- Good tests should verify external behavior and stable contracts, not internal implementation details.
- The highest-value test seam is the EPUB import/parsing boundary: given an EPUB fixture, the app can extract metadata, manifest entries, spine order, table-of-contents entries, chapter resources, and unsupported-layout signals.
- A second important seam is the reading-settings-to-rendering-configuration boundary: given global settings, the app produces the expected reading configuration for WebView rendering.
- A third seam is reading-position persistence: given a book identity and location, the app can save and restore the last position.
- A fourth seam is import/storage behavior: given a source EPUB, the app creates a stable local copy and tracks the stored book record.
- WebView rendering should be tested mostly through generated HTML/CSS contracts and manual visual QA, not brittle implementation-detail tests.
- SwiftUI visual behavior should be kept thin and driven by testable models/view models where practical.
- There is no existing test prior art in this repository because the project currently has no source code.

## Proposed Test Seams

- `EPUBImporter`: accepts a local EPUB file and produces a stored book record plus parsed package data.
- `EPUBParser`: accepts EPUB container data and produces metadata, manifest, spine, table of contents, and resource references.
- `ReadingDocumentBuilder`: accepts chapter content, resource references, and reading settings, then produces the controlled HTML/CSS document loaded into WKWebView.
- `ReadingPositionStore`: saves and restores per-book reading position.
- `ReadingSettingsStore`: saves and restores global reading preferences.

These are new seams because the repository is currently empty. The preferred architecture keeps parsing, document building, and persistence separate from SwiftUI views and WKWebView glue.

## Out of Scope

- Fixed-layout EPUB support.
- PDF support.
- Comics, manga, or image-first book formats.
- Highlights and annotations.
- Full-book search.
- Cloud sync.
- User accounts.
- Store/catalog features.
- Social features.
- Analytics.
- Multi-window reading.
- Polished Apple Books clone fidelity.
- Sophisticated page-turn animations.
- Public distribution, signing, notarization, packaging, and support workflows beyond what is needed for local development.

## Further Notes

The defining product constraint is comfortable reading on a widescreen monitor. Most implementation choices should be judged by whether they preserve control over line length, centered composition, margins, and reading focus.

The first executable MVP should open a reflowable EPUB, copy it into local app storage, show a table of contents, render a chapter in WKWebView using a centered controlled layout, allow switching between simple pagination and scrolling, expose appearance controls, and restore reading position after closing and reopening.

No project issue tracker is currently configured, so this spec is stored locally rather than published as a tracker issue with `ready-for-agent`.
