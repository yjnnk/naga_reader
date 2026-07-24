import Foundation

public struct ReadingDocumentBuilder {
    public init() {}

    public func buildDocument(chapterBody: String, settings: ReadingSettings = .default) -> String {
        let colors = ThemeColors(theme: settings.theme)
        let layout = LayoutCSS(settings: settings)

        return """
        <!doctype html>
        <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <style>
            body {
              margin: 0;
              background: \(colors.background);
              color: \(colors.text);
              font: \(settings.fontSize)px -apple-system, BlinkMacSystemFont, "New York", Georgia, serif;
              line-height: \(format(settings.lineHeight));
              \(layout.bodyOverflow)
            }
            .reader {
              box-sizing: border-box;
              max-width: \(settings.columnWidth)px;
              margin: 0 auto;
              padding: \(settings.pageMargin)px;
              \(layout.readerLayout)
            }
            .reader::-webkit-scrollbar {
              display: none;
            }
            .reader * {
              box-sizing: border-box;
              max-width: 100% !important;
              overflow-wrap: break-word;
            }
            .reader table,
            .reader pre {
              display: block;
              overflow-x: auto;
            }
            img {
              max-width: 100% !important;
              height: auto !important;
            }
          </style>
        </head>
        <body>
          <main class="reader">
            \(chapterBody)
          </main>
        </body>
        </html>
        """
    }

    private func format(_ value: Double) -> String {
        String(format: "%.2g", value)
    }
}

private struct LayoutCSS {
    let bodyOverflow: String
    let readerLayout: String

    init(settings: ReadingSettings) {
        switch settings.readingMode {
        case .paged:
            bodyOverflow = "overflow: hidden;"
            readerLayout = """
              overflow-x: auto;
              overflow-y: hidden;
              column-width: \(settings.columnWidth)px;
              column-gap: \(settings.pageMargin * 2)px;
              height: calc(100vh - \(settings.pageMargin * 2)px);
              scrollbar-width: none;
            """
        case .scroll:
            bodyOverflow = "overflow-y: auto;"
            readerLayout = """
              overflow-x: hidden;
              overflow-y: visible;
              min-height: calc(100vh - \(settings.pageMargin * 2)px);
            """
        }
    }
}

private struct ThemeColors {
    let background: String
    let text: String

    init(theme: ReadingTheme) {
        switch theme {
        case .light:
            background = "#fbfbf8"
            text = "#1d1d1f"
        case .dark:
            background = "#101114"
            text = "#e7e1d7"
        case .sepia:
            background = "#f4ecd8"
            text = "#2c2418"
        }
    }
}
