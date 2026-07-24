import Foundation

enum EPUBFixture {
    static func makeReflowableEPUB(title: String = "Fixture Book", navHref: String = "chapters/chapter1.xhtml") throws -> URL {
        try makeEPUB(title: title, fixedLayout: false, navHref: navHref)
    }

    static func makeFixedLayoutEPUB(title: String = "Fixed Book") throws -> URL {
        try makeEPUB(title: title, fixedLayout: true, brokenSpine: false)
    }

    static func makeEPUBWithBrokenSpine(title: String = "Broken Book") throws -> URL {
        try makeEPUB(title: title, fixedLayout: false, brokenSpine: true)
    }

    static func makeEPUB2WithNCX(title: String = "EPUB2 Book") throws -> URL {
        try makeEPUB(title: title, fixedLayout: false, includeNavigationDocument: false, includeNCX: true)
    }

    private static func makeEPUB(
        title: String,
        fixedLayout: Bool,
        brokenSpine: Bool = false,
        navHref: String = "chapters/chapter1.xhtml",
        includeNavigationDocument: Bool = true,
        includeNCX: Bool = false
    ) throws -> URL {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let metaINF = root.appendingPathComponent("META-INF", isDirectory: true)
        let oebps = root.appendingPathComponent("OEBPS", isDirectory: true)
        let chapters = oebps.appendingPathComponent("chapters", isDirectory: true)

        try FileManager.default.createDirectory(at: metaINF, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: chapters, withIntermediateDirectories: true)

        try "application/epub+zip".write(
            to: root.appendingPathComponent("mimetype"),
            atomically: true,
            encoding: .utf8
        )
        try """
        <?xml version="1.0" encoding="UTF-8"?>
        <container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
          <rootfiles>
            <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
          </rootfiles>
        </container>
        """.write(to: metaINF.appendingPathComponent("container.xml"), atomically: true, encoding: .utf8)

        let layoutMetadata = fixedLayout ? "<meta property=\"rendition:layout\">pre-paginated</meta>" : ""
        let navManifestItem = includeNavigationDocument
            ? "<item id=\"nav\" href=\"nav.xhtml\" media-type=\"application/xhtml+xml\" properties=\"nav\"/>"
            : ""
        let ncxManifestItem = includeNCX
            ? "<item id=\"ncx\" href=\"toc.ncx\" media-type=\"application/x-dtbncx+xml\"/>"
            : ""
        let spineTOCAttribute = includeNCX ? " toc=\"ncx\"" : ""
        try """
        <?xml version="1.0" encoding="UTF-8"?>
        <package version="3.0" unique-identifier="bookid" xmlns="http://www.idpf.org/2007/opf">
          <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
            <dc:title>\(title)</dc:title>
            \(layoutMetadata)
          </metadata>
          <manifest>
            \(navManifestItem)
            \(ncxManifestItem)
            <item id="chapter1" href="chapters/chapter1.xhtml" media-type="application/xhtml+xml"/>
            <item id="style" href="styles/book.css" media-type="text/css"/>
            <item id="cover" href="images/cover.jpg" media-type="image/jpeg"/>
          </manifest>
          <spine\(spineTOCAttribute)>
            <itemref idref="\(brokenSpine ? "missing" : "chapter1")"/>
          </spine>
        </package>
        """.write(to: oebps.appendingPathComponent("content.opf"), atomically: true, encoding: .utf8)
        if includeNavigationDocument {
            try """
            <?xml version="1.0" encoding="UTF-8"?>
            <html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
              <body>
                <nav epub:type="toc">
                  <ol>
                    <li><a href="\(navHref)">Chapter One</a></li>
                  </ol>
                </nav>
              </body>
            </html>
            """.write(to: oebps.appendingPathComponent("nav.xhtml"), atomically: true, encoding: .utf8)
        }
        if includeNCX {
            try """
            <?xml version="1.0" encoding="UTF-8"?>
            <ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
              <navMap>
                <navPoint id="chapter1" playOrder="1">
                  <navLabel><text>NCX Chapter One</text></navLabel>
                  <content src="chapters/chapter1.xhtml"/>
                </navPoint>
              </navMap>
            </ncx>
            """.write(to: oebps.appendingPathComponent("toc.ncx"), atomically: true, encoding: .utf8)
        }
        try """
        <?xml version="1.0" encoding="UTF-8"?>
        <html xmlns="http://www.w3.org/1999/xhtml">
          <body><h1>Chapter One</h1><p>Hello from EPUB.</p></body>
        </html>
        """.write(to: chapters.appendingPathComponent("chapter1.xhtml"), atomically: true, encoding: .utf8)

        let epubURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("epub")
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
        process.arguments = ["-qr", epubURL.path, "."]
        process.currentDirectoryURL = root
        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            throw CocoaError(.fileWriteUnknown)
        }

        return epubURL
    }
}
