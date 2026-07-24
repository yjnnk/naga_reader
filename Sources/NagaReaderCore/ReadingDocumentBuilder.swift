import Foundation

public struct ReadingDocumentBuilder {
    public init() {}

    public func buildDocument(chapterBody: String) -> String {
        """
        <!doctype html>
        <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <style>
            body {
              margin: 0;
              background: #f4ecd8;
              color: #2c2418;
              font: 19px -apple-system, BlinkMacSystemFont, "New York", Georgia, serif;
              line-height: 1.55;
            }
            .reader {
              box-sizing: border-box;
              max-width: 680px;
              margin: 0 auto;
              padding: 72px;
              overflow-x: hidden;
            }
            .reader, .reader * {
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
}
